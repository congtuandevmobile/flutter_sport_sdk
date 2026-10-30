#!/usr/bin/env bash
# Builds the Kotlin core (challenge-core) as an XCFramework for iOS and copies it where the podspec expects
# it. Android needs no step: it compiles challenge-core/src/commonMain directly (see android/build.gradle.kts).
#
# Usage: tool/build_core.sh [debug|release]   (default: debug)
set -euo pipefail

flavor="${1:-debug}"
root="$(cd "$(dirname "$0")/.." && pwd)"
core="$root/challenge-core"
cd "$core"

case "$flavor" in
  debug)   task="assembleChallengeCoreDebugXCFramework" ;;
  release) task="assembleChallengeCoreReleaseXCFramework" ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 64 ;;
esac

./gradlew --no-daemon "$task"

rm -rf "$root/ios/Frameworks/ChallengeCore.xcframework"
mkdir -p "$root/ios/Frameworks"
cp -R "build/XCFrameworks/$flavor/ChallengeCore.xcframework" "$root/ios/Frameworks/"
echo "ChallengeCore.xcframework ($flavor) -> ios/Frameworks"
