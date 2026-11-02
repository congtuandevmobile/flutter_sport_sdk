#!/usr/bin/env bash
# Canonical package/release metadata for the monorepo workflows.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

all_packages=(
  flutter_activity
  flutter_challenge
  flutter_sport_ble
  flutter_tracking_gps
  flutter_workout
  flutter_multisport
  flutter_sport_ble_adapter
  flutter_tracking_gps_adapter
  flutter_multisport_adapters
)

native_packages=(
  flutter_challenge
  flutter_sport_ble
  flutter_tracking_gps
  flutter_workout
)

contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

package_version() {
  local package="$1"
  local pubspec="$repo_root/packages/$package/pubspec.yaml"
  [[ -f "$pubspec" ]] || {
    echo "Unknown package: $package" >&2
    return 1
  }
  sed -nE 's/^version:[[:space:]]*([^[:space:]#]+).*$/\1/p' "$pubspec" | head -n 1
}

framework_path() {
  case "$1" in
    flutter_challenge) echo "packages/flutter_challenge/ios/flutter_challenge/Frameworks/ChallengeCore.xcframework" ;;
    flutter_sport_ble) echo "packages/flutter_sport_ble/ios/flutter_sport_ble/Frameworks/SensorCore.xcframework" ;;
    flutter_tracking_gps) echo "packages/flutter_tracking_gps/ios/flutter_tracking_gps/Frameworks/TrackingCore.xcframework" ;;
    flutter_workout) echo "packages/flutter_workout/ios/flutter_workout/Frameworks/WorkoutCore.xcframework" ;;
    *) return 1 ;;
  esac
}

core_path() {
  case "$1" in
    flutter_challenge) echo "packages/flutter_challenge/challenge-core" ;;
    flutter_sport_ble) echo "packages/flutter_sport_ble/sensor-core" ;;
    flutter_tracking_gps) echo "packages/flutter_tracking_gps/tracking-core" ;;
    flutter_workout) echo "packages/flutter_workout/workout-core" ;;
    *) return 1 ;;
  esac
}

all_csv() {
  local IFS=,
  echo "${all_packages[*]}"
}

case "${1:-}" in
  all) printf '%s\n' "${all_packages[@]}" ;;
  all-csv) all_csv ;;
  is-known) contains "${2:-}" "${all_packages[@]}" ;;
  is-native) contains "${2:-}" "${native_packages[@]}" ;;
  version) package_version "${2:-}" ;;
  framework-path) framework_path "${2:-}" ;;
  core-path) core_path "${2:-}" ;;
  *)
    echo "usage: $0 {all|all-csv|is-known <package>|is-native <package>|version <package>|framework-path <package>|core-path <package>}" >&2
    exit 64
    ;;
esac
