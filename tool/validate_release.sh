#!/usr/bin/env bash
# Release gates adapted from the original flutter_tracking_gps release workflow.
set -euo pipefail

mode="${1:?release or tag}"
packages_csv="${2:?comma-separated packages}"
source_root="$(cd "$(dirname "$0")/.." && pwd)"

[[ "$mode" == "release" || "$mode" == "tag" ]] || {
  echo "mode must be release or tag" >&2
  exit 64
}

# Flutter may migrate checked-in project files even during dependency
# resolution. Run all gates in an archive of HEAD so validation cannot dirty
# the release checkout. Only verified release XCFrameworks are copied back.
work="$(mktemp -d)"
git -C "$source_root" archive HEAD | tar -x -C "$work"
root="$work"
manifest="$root/tool/release_manifest.sh"

cd "$root"
flutter pub get
IFS=',' read -r -a packages <<< "$packages_csv"

for package in "${packages[@]}"; do
  "$manifest" is-known "$package" || {
    echo "Unknown package: $package" >&2
    exit 1
  }

  echo "::group::$package Dart/Flutter checks"
  (
    cd "packages/$package"
    flutter analyze
    flutter test
  )
  echo "::endgroup::"

  if [[ "$mode" == "release" ]]; then
    "$root/tool/release_notes.sh" "$package" >/dev/null
  fi

  if "$manifest" is-native "$package"; then
    core="$("$manifest" core-path "$package")"
    echo "::group::$package Kotlin core tests"
    (cd "$core" && ./gradlew --no-daemon jvmTest)
    echo "::endgroup::"

    "packages/$package/tool/build_core.sh" release
    framework="$("$manifest" framework-path "$package")"
    for slice in ios-arm64 ios-arm64_x86_64-simulator; do
      [[ -d "$framework/$slice" ]] || {
        echo "Missing $slice in $framework" >&2
        exit 1
      }
    done

    echo "::group::$package iOS example build"
    (cd "packages/$package/example" && flutter build ios --simulator --no-codesign)
    echo "::endgroup::"

    destination="$source_root/$framework"
    mkdir -p "$(dirname "$destination")"
    rsync -a --delete "$root/$framework/" "$destination/"
  fi
done

# The source checkout must still match the commit being tagged. Generated
# frameworks are ignored, so they do not make this check dirty.
cd "$source_root"
if ! git diff --exit-code; then
  echo "Validation unexpectedly modified tracked files in the release checkout." >&2
  exit 1
fi
echo "Validation workspace: $work"
