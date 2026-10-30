#!/usr/bin/env bash
# Prints the id of an iPhone simulator that really exists on this machine (the newest runtime, the first iPhone in it), so a
# workflow never names a device that the runner does not have. Usage: id=$(tool/ios_simulator_id.sh)
set -euo pipefail
python3 - <<'PY'
import json, subprocess, sys
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "--json"]))
best = None
for runtime, devices in data["devices"].items():
    if "iOS" not in runtime:
        continue
    version = tuple(int(x) for x in runtime.rsplit("iOS-", 1)[-1].split("-") if x.isdigit())
    for d in devices:
        if d["name"].startswith("iPhone") and d.get("isAvailable", True):
            key = (version, d["name"])
            if best is None or key > best[0]:
                best = (key, d["udid"])
if best is None:
    sys.exit("no iPhone simulator is available")
print(best[1])
PY
