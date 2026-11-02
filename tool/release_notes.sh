#!/usr/bin/env bash
# Validates and extracts the current package version's CHANGELOG section.
set -euo pipefail

package="${1:?package name}"
output="${2:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$root/tool/release_manifest.sh"
changelog="$root/packages/$package/CHANGELOG.md"
version="$("$manifest" version "$package")"

[[ -f "$changelog" ]] || {
  echo "Missing CHANGELOG.md for $package" >&2
  exit 1
}

heading=''
for candidate in "## $version" "## v$version"; do
  if grep -qxF "$candidate" "$changelog"; then
    heading="$candidate"
    break
  fi
done

[[ -n "$heading" ]] || {
  echo "CHANGELOG.md for $package must contain an exact '## $version' or '## v$version' heading." >&2
  exit 1
}

notes="$(awk -v heading="$heading" '
  $0 == heading { found=1; next }
  /^##[[:space:]]/ && found { exit }
  found { print }
' "$changelog")"

[[ -n "${notes//[[:space:]]/}" ]] || {
  echo "CHANGELOG section $heading for $package is empty." >&2
  exit 1
}

if [[ -n "$output" ]]; then
  printf '%s\n' "$notes" > "$output"
else
  printf '%s\n' "$notes"
fi
