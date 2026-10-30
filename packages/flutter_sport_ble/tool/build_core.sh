#!/usr/bin/env bash
# Builds the Kotlin core (sensor-core) as an XCFramework for iOS and copies it where the podspec expects
# it. Android needs no step: it compiles sensor-core/src/commonMain directly (see android/build.gradle.kts).
#
# Usage: tool/build_core.sh [debug|release]   (default: debug)
set -euo pipefail

flavor="${1:-debug}"
root="$(cd "$(dirname "$0")/.." && pwd)"
core="$root/sensor-core"
cd "$core"

case "$flavor" in
  debug)   task="assembleSensorCoreDebugXCFramework" ;;
  release) task="assembleSensorCoreReleaseXCFramework" ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 64 ;;
esac

./gradlew --no-daemon "$task"

rm -rf "$root/ios/Frameworks/SensorCore.xcframework"
mkdir -p "$root/ios/Frameworks"
cp -R "build/XCFrameworks/$flavor/SensorCore.xcframework" "$root/ios/Frameworks/"
echo "SensorCore.xcframework ($flavor) -> ios/Frameworks"
