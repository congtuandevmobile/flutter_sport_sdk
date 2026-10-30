# Rules for this repository

This repository builds reusable Flutter SDKs for sport recording and multi-stage challenges. Read [doc/SOURCE_SUMMARY.md](doc/SOURCE_SUMMARY.md) for what exists and [doc/SDK_RULES.md](doc/SDK_RULES.md) for the product and architecture contracts. `CLAUDE.md` and the package-specific docs contain implementation details; keep them consistent when behavior changes.

## Before changing code

- If `.codegraph/` exists, use CodeGraph to locate and understand code before text search or opening files. Do not create an index automatically.
- Identify the owning package, its public API, its core/native boundary, and the tests for the behavior. Inspect callers before changing a shared contract.
- Preserve existing work in the checkout. Do not commit or push without the owner's approval.

## Package boundaries

- `flutter_tracking_gps`, `flutter_sport_ble`, `flutter_workout`, `flutter_challenge`, and `flutter_activity` must remain usable independently of one another. Higher-level packages may compose them through explicit dependencies or source interfaces. A consumer that only needs phone GPS must be able to install `flutter_tracking_gps` without BLE or challenge packages.
- GPS owns phone location tracking and its route; BLE owns connections, decoding, and live device values. `flutter_activity` owns a single activity's sensor history and summary. `flutter_challenge` owns stage progress. `flutter_multisport` owns sport/goal configuration, stage transitions, and stage results. Adapters translate sources; they do not decide progress.
- New provider integrations belong in optional adapter packages. Do not make a base SDK import an unrelated sensor SDK. `flutter_tracking_gps_adapter` and `flutter_sport_ble_adapter` are independently installable; `flutter_multisport_adapters` remains a compatibility bundle.
- An app/backend owns screens, notifications, account sync, persistence of exported summaries, and any judge identity. SDK events describe outcomes; they do not prescribe UI.

## Measurement and persistence

- Carry source ID, connection epoch, measurement time/age, metric, and unit through adapters. Missing sensor data is `null`/absent, never an invented zero. Use one selected source for a cumulative distance or a stage's progress; never sum overlapping GPS and device totals.
- A new session, stage, connection, resumed interval, or source switch starts with a baseline. Do not credit measurements from a pause or a previous stage. Deduplicate retried manual events with a stable event ID and reject stale stage activations.
- Keep progress journals and telemetry history separate. Never claim a value is durable before its store reports it; surface write and restore failures. Preserve route data in GPS and heart-rate/cadence series in the activity or stage telemetry layer.
- The native cores use one phone monotonic clock for decisions. Do not silently replace this with device or wall-clock time. Document the current wall-clock limits of pure-Dart telemetry.

## Changes and evidence

- Change a Pigeon schema at its source and regenerate bindings; never hand-edit generated files. Keep the matching native `.md` companion docs in sync.
- Add focused tests at the layer that owns a changed rule, including pause, reconnect, duplicate, source switch, and recovery cases when relevant. Verify an SDK can build as the sole dependency before claiming independent release readiness.
- Separate **implemented**, **tested with fake/simulator**, and **verified on real hardware** in docs and user-facing claims. Update `doc/QUALITY_GATES.md` and `doc/COMPATIBILITY.yaml` only with observed evidence.
