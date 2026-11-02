#!/usr/bin/env bash
# Parses one release marker from the HEAD commit message and emits GitHub outputs.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$root/tool/release_manifest.sh"
message="${COMMIT_MESSAGE:-}"
subject="${message%%$'\n'*}"

markers="$(printf '%s\n' "$message" | grep -Eo '\[(release|tag)(:[^][]+)?\]' || true)"
subject_marker="$(printf '%s\n' "$subject" | grep -Eo '^\[(release|tag)(:[^][]+)?\]' || true)"

if [[ -z "$subject_marker" ]]; then
  if [[ "$message" == *"[release"* || "$message" == *"[tag"* ]]; then
    echo "The commit subject must start with [release], [release:<package>], [tag], or [tag:<package>]." >&2
    exit 1
  fi
  echo "mode=none"
  echo "packages="
  echo "marker="
  exit 0
fi

marker_count="$(printf '%s\n' "$markers" | wc -l | tr -d '[:space:]')"
if [[ "$marker_count" != "1" ]]; then
  echo "Exactly one release marker is allowed; found:" >&2
  printf '%s\n' "$markers" >&2
  exit 1
fi

marker="$subject_marker"
payload="${marker#[}"
payload="${payload%]}"
mode="${payload%%:*}"

if [[ "$payload" == *:* ]]; then
  package="${payload#*:}"
  if ! "$manifest" is-known "$package"; then
    echo "Unknown package in $marker: $package" >&2
    echo "Known packages:" >&2
    "$manifest" all >&2
    exit 1
  fi
  packages="$package"
else
  packages="$("$manifest" all-csv)"
fi

echo "mode=$mode"
echo "packages=$packages"
echo "marker=$marker"
