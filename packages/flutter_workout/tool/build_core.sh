#!/usr/bin/env bash
# Builds the Kotlin core (workout-core) as an XCFramework for iOS and copies it where the podspec expects
# it. Android needs no step: it compiles workout-core/src/commonMain directly (see android/build.gradle.kts).
#
# Usage: tool/build_core.sh [debug|release]   (default: debug)
set -euo pipefail

flavor="${1:-debug}"
root="$(cd "$(dirname "$0")/.." && pwd)"
core="$root/workout-core"
cd "$core"

case "$flavor" in
  debug)   task="assembleWorkoutCoreDebugXCFramework" ;;
  release) task="assembleWorkoutCoreReleaseXCFramework" ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 64 ;;
esac

./gradlew --no-daemon "$task"

rm -rf "$root/ios/Frameworks/WorkoutCore.xcframework"
mkdir -p "$root/ios/Frameworks"
cp -R "build/XCFrameworks/$flavor/WorkoutCore.xcframework" "$root/ios/Frameworks/"
echo "WorkoutCore.xcframework ($flavor) -> ios/Frameworks"
