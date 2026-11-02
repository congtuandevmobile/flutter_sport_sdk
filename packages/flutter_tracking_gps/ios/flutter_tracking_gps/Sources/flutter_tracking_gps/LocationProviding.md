

`CoreLocationProvider(monitorSignificantChanges:)` can also monitor significant location changes (a wake source, needs Always). `LiveUpdatesLocationProvider` (iOS 17+) uses `CLLocationUpdate.liveUpdates` and `CLBackgroundActivitySession`, keeping the source compatible with Xcode SDKs that predate the optional iOS 18 Core Location symbols. Both options are off by default and not verified on a device.
