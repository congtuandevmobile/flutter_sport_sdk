#!/usr/bin/env bash
# Regression check for the Android merged manifest of an app that uses BOTH plugins. A permission declared by two plugins is merged
# by name, so an attribute of one (a maxSdkVersion) can end up capping the other's permission. It must hold that:
#   - ACCESS_FINE_LOCATION (GPS) has NO maxSdkVersion,
#   - BLUETOOTH_SCAN and BLUETOOTH_CONNECT are there (Android 12+).
# Usage: tool/check_merged_manifest.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/examples/sensors_demo"
(cd "$app" && flutter pub get >/dev/null)
(cd "$app/android" && ./gradlew :app:processDebugMainManifest -q)

manifest="$app/build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml"
python3 - "$manifest" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
perms = {}
for m in re.finditer(r'<uses-permission\b(.*?)/>', text, re.S):
    body = m.group(1)
    name = re.search(r'android:name="([^"]+)"', body)
    if name:
        perms[name.group(1)] = body
failures = []
fine = perms.get("android.permission.ACCESS_FINE_LOCATION")
if fine is None:
    failures.append("ACCESS_FINE_LOCATION is missing")
elif "maxSdkVersion" in fine:
    failures.append("ACCESS_FINE_LOCATION is capped by a maxSdkVersion: GPS would lose it on newer Android")
for p in ("android.permission.BLUETOOTH_SCAN", "android.permission.BLUETOOTH_CONNECT"):
    if p not in perms:
        failures.append(p + " is missing")
if failures:
    print("MERGED MANIFEST CHECK FAILED:")
    for f in failures:
        print(" -", f)
    sys.exit(1)
print("merged manifest ok: location is not capped, Bluetooth permissions present")
PY
