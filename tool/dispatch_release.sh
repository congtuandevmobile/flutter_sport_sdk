#!/usr/bin/env bash
# Builds native release artifacts, creates immutable snapshot tags, and pushes them.
set -euo pipefail

mode="${1:-}"
packages_csv="${2:-}"
source_sha="${3:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$root/tool/release_manifest.sh"

[[ "$mode" == "release" || "$mode" == "tag" ]] || {
  echo "mode must be release or tag" >&2
  exit 64
}
[[ -n "$packages_csv" && -n "$source_sha" ]] || {
  echo "usage: $0 <release|tag> <comma-separated-packages> <source-sha>" >&2
  exit 64
}
if [[ "$mode" == "release" && -z "${RELEASE_PAT:-}" ]]; then
  echo "RELEASE_PAT is required: tags pushed with GITHUB_TOKEN cannot trigger the publish workflow." >&2
  exit 1
fi
if [[ "$mode" == "release" && "${SOURCE_BRANCH:-}" != "main" ]]; then
  echo "pub.dev releases are allowed only from main; current branch: ${SOURCE_BRANCH:-unknown}" >&2
  exit 1
fi

cd "$root"
git rev-parse --verify "$source_sha^{commit}" >/dev/null

IFS=',' read -r -a selected <<< "$packages_csv"
for package in "${selected[@]}"; do
  "$manifest" is-known "$package" || {
    echo "Unknown package: $package" >&2
    exit 1
  }
done

short_sha="$(git rev-parse --short=8 "$source_sha")"

tag_for() {
  local package="$1"
  local version
  version="$("$manifest" version "$package")"
  if [[ "$mode" == "release" ]]; then
    echo "$package-v$version"
  else
    echo "$package-test-v$version-$short_sha"
  fi
}

pub_response() {
  local package="$1"
  local output="$2"
  curl --retry 3 --retry-all-errors --connect-timeout 15 --max-time 60 \
    -sS -o "$output" -w '%{http_code}' "https://pub.dev/api/packages/$package"
}

pub_has_version() {
  local package="$1"
  local version="$2"
  local body code
  body="$(mktemp)"
  code="$(pub_response "$package" "$body")"
  if [[ "$code" == "200" ]]; then
    if grep -Fq "\"version\":\"$version\"" "$body"; then
      rm -f "$body"
      return 0
    fi
    rm -f "$body"
    return 1
  fi
  rm -f "$body"
  [[ "$code" == "404" ]] && return 1
  echo "pub.dev returned HTTP $code while checking $package" >&2
  return 2
}

pub_package_exists() {
  local package="$1"
  local body code
  body="$(mktemp)"
  code="$(pub_response "$package" "$body")"
  rm -f "$body"
  [[ "$code" == "200" ]] && return 0
  [[ "$code" == "404" ]] && return 1
  echo "pub.dev returned HTTP $code while checking $package" >&2
  return 2
}

declare -a new_packages=()
for package in "${selected[@]}"; do
  tag="$(tag_for "$package")"
  remote_ref="$(git ls-remote --tags origin "refs/tags/$tag" | head -n 1 || true)"
  if [[ -n "$remote_ref" ]]; then
    echo "Tag already exists and will not be moved: $tag"
    if [[ "$mode" == "tag" ]]; then
      continue
    fi
    version="$("$manifest" version "$package")"
    if pub_has_version "$package" "$version"; then
      echo "$package $version is already published."
    else
      echo "$tag exists but $package $version is not published yet; the dispatcher will wait for it." >&2
    fi
    continue
  fi

  if [[ "$mode" == "release" ]]; then
    if pub_package_exists "$package"; then
      :
    else
      status=$?
      if [[ "$status" == "1" ]]; then
        echo "$package does not exist on pub.dev yet. Publish its first version manually before using automated publishing." >&2
      else
        echo "Could not verify $package on pub.dev; no tag was created." >&2
      fi
      exit 1
    fi
    version="$("$manifest" version "$package")"
    if pub_has_version "$package" "$version"; then
      echo "$package $version already exists on pub.dev; bump the pubspec version before releasing." >&2
      exit 1
    fi
  fi
  new_packages+=("$package")
done

if (( ${#new_packages[@]} > 0 )); then
  git switch --detach "$source_sha"

  for package in "${new_packages[@]}"; do
    if "$manifest" is-native "$package"; then
      framework="$("$manifest" framework-path "$package")"
      if [[ "${RELEASE_ARTIFACTS_READY:-}" != "1" ]]; then
        echo "Building release XCFramework for $package"
        "packages/$package/tool/build_core.sh" release
      fi
      [[ -f "$framework/Info.plist" ]] || {
        echo "Missing binary artifact: $framework" >&2
        exit 1
      }
      git add -f "$framework"
    fi
  done

  git -c user.name='github-actions[bot]' \
    -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
    commit --allow-empty -m "chore(release): snapshot $mode artifacts for $source_sha"
  snapshot_sha="$(git rev-parse HEAD)"

  for package in "${new_packages[@]}"; do
    tag="$(tag_for "$package")"
    git tag -a "$tag" "$snapshot_sha" -m "$mode snapshot for $package $("$manifest" version "$package")"
  done

  # Verify from the tracked snapshot, not from the ignored local build output.
  # A tag-only snapshot is intentionally not published to pub.dev, so do not run
  # pub publish validation in that mode (it can fail on pub.dev release metadata
  # such as CHANGELOG version entries even though tag creation is valid).
  if [[ "$mode" == "release" ]]; then
    for package in "${new_packages[@]}"; do
      if "$manifest" is-native "$package"; then
        dry_run_log="$(mktemp)"
        (cd "packages/$package" && flutter pub publish --dry-run) 2>&1 | tee "$dry_run_log"
        framework_name="$(basename "$("$manifest" framework-path "$package")")"
        grep -Fq "$framework_name" "$dry_run_log" || {
          echo "$framework_name is missing from the $package publish archive." >&2
          exit 1
        }
        rm -f "$dry_run_log"
      fi
    done
  fi
fi

push_tag() {
  local package="$1"
  local tag
  tag="$(tag_for "$package")"
  if git show-ref --verify --quiet "refs/tags/$tag"; then
    echo "Pushing $tag"
    git push origin "refs/tags/$tag"
  fi
}

wait_for_publication() {
  local package="$1"
  local version deadline
  version="$("$manifest" version "$package")"
  deadline=$((SECONDS + 1800))
  echo "Waiting for pub.dev to expose $package $version"
  while (( SECONDS < deadline )); do
    if pub_has_version "$package" "$version"; then
      echo "Published: $package $version"
      return 0
    fi
    sleep 15
  done
  echo "Timed out waiting for $package $version on pub.dev. Inspect or rerun its publish workflow." >&2
  return 1
}

create_github_release() {
  local package="$1"
  local tag version notes
  tag="$(tag_for "$package")"
  version="$("$manifest" version "$package")"
  if gh release view "$tag" >/dev/null 2>&1; then
    echo "GitHub Release already exists: $tag"
    return 0
  fi
  notes="$(mktemp)"
  "$root/tool/release_notes.sh" "$package" "$notes"
  args=(release create "$tag" --title "$package $version" --notes-file "$notes")
  [[ "$version" == *-* ]] && args+=(--prerelease)
  gh "${args[@]}"
  rm -f "$notes"
}

is_selected() {
  local wanted="$1"
  local package
  for package in "${selected[@]}"; do
    [[ "$package" == "$wanted" ]] && return 0
  done
  return 1
}

if [[ "$mode" == "tag" ]]; then
  for package in "${new_packages[@]}"; do
    push_tag "$package"
  done
  exit 0
fi

# Publish in dependency order so adapters never race versions that pub.dev has
# not indexed yet. Packages within a wave have no dependencies on each other.
release_waves=(
  'flutter_activity flutter_challenge flutter_sport_ble flutter_tracking_gps flutter_workout'
  'flutter_multisport flutter_sport_ble_adapter flutter_tracking_gps_adapter'
  'flutter_multisport_adapters'
)

for wave in "${release_waves[@]}"; do
  wave_selected=()
  for package in $wave; do
    is_selected "$package" && wave_selected+=("$package")
  done
  (( ${#wave_selected[@]} == 0 )) && continue

  for package in "${wave_selected[@]}"; do
    push_tag "$package"
  done
  for package in "${wave_selected[@]}"; do
    wait_for_publication "$package"
    create_github_release "$package"
  done
done
