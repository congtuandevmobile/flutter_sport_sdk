#!/usr/bin/env bash
# The independence test: package ONE SDK, extract it into an empty directory, create a fresh Flutter app that depends
# on that package alone, and build it. PASS means a customer who receives only that package can build.
# Usage: tool/release_check.sh <package> [android|ios|both]   e.g. tool/release_check.sh flutter_workout both
set -euo pipefail
pkg="${1:?package name}"; target="${2:-both}"
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/packages/$pkg"
work="$(mktemp -d)"; trap 'echo "work dir: $work"' EXIT

"$src/tool/build_core.sh" release                       # the iOS framework must be inside the package
# rsync approximates .pubignore (simple patterns only)
grep -v '^#' "$src/.pubignore" | sed '/^$/d' > "$work/excludes"
rsync -a --exclude-from="$work/excludes" "$src/" "$work/sdk/$pkg/"
# A published package is not part of a workspace: its pubspec must stand alone.
sed -i.bak '/^resolution: workspace/d' "$work/sdk/$pkg/pubspec.yaml"; rm "$work/sdk/$pkg/pubspec.yaml.bak"

cd "$work"
flutter create --no-pub --platforms=android,ios --org test.clean app >/dev/null
cd app
dart pub add "$pkg" --path "../sdk/$pkg" 2>&1 | tail -2
[ "$target" != ios ] && flutter build apk --debug 2>&1 | tail -3
if [ "$target" != android ]; then
  sed -i.bak "s/^# platform :ios.*/platform :ios, '15.0'/" ios/Podfile 2>/dev/null || true
  flutter build ios --simulator --no-codesign --debug 2>&1 | tail -3
fi
echo "PASS: $pkg builds alone from its package"
