# Package release and test-tag flow

The HEAD commit pushed to a branch controls package tagging. Start the commit
subject with exactly one of the markers below. Pub.dev releases are accepted
only from `main`; test tags can be created from feature branches.

| Commit marker | Result |
| --- | --- |
| `[release]` | Build native artifacts, tag every package, and publish every package to pub.dev. |
| `[release:<package>]` | Build, tag, and publish only `<package>`. |
| `[tag]` | Build native artifacts and create Git-consumable test tags for every package. Nothing is published. |
| `[tag:<package>]` | Create a Git-consumable test tag for only `<package>`. Nothing is published. |

Examples:

```text
[release] Prepare all SDK packages for publishing
[release:flutter_tracking_gps] Release missing-altitude fix
[tag] Prepare SDK packages for integration testing
[tag:flutter_tracking_gps] Prepare GPS SDK for integration testing
```

Markers are lowercase, are placed at the start of the commit subject, and
package names must match a directory under `packages/`. A malformed marker,
an unknown package, or multiple distinct markers fails the workflow. Only the
message of the HEAD commit of the current branch push is read; markers in older
commits in the same push are ignored.

## Tag names

Release tags are immutable and match pub.dev's monorepo convention:

```text
flutter_tracking_gps-v0.0.1-beta.3
```

Test tags include the source commit's short SHA, so more than one test snapshot
can be created without moving an existing tag:

```text
flutter_tracking_gps-test-v0.0.1-beta.3-8df4316a
```

Native release XCFrameworks are ignored on `main`. The tag dispatcher builds
them and creates a detached snapshot commit containing the binaries before it
creates either kind of tag. Therefore a test tag can be used directly as a Git
dependency:

```yaml
dependencies:
  flutter_tracking_gps:
    git:
      url: https://github.com/congtuandevmobile/flutter_sport_sdk.git
      ref: flutter_tracking_gps-test-v0.0.1-beta.3-8df4316a
      path: packages/flutter_tracking_gps
```

The detached artifact commit is reachable through the tag only; generated
binaries are never committed to `main`.

Before creating a tag, the selected packages pass `flutter analyze` and
`flutter test`. Native packages additionally pass Kotlin core tests, build
and verify both release XCFramework slices, and build their example for the
iOS simulator. Release markers also require an exact current-version heading
in `CHANGELOG.md`. After publishing, a release marker creates a GitHub
Release from that changelog section; prerelease versions create GitHub
prereleases.

## One-time repository and pub.dev setup

1. Create a fine-grained GitHub personal access token that can write repository
   contents/tags and save it as the repository secret `RELEASE_PAT`. A tag
   pushed with the default `GITHUB_TOKEN` does not trigger another workflow, so
   release markers deliberately fail if this secret is missing. Tag-only
   markers can use `GITHUB_TOKEN`.
2. Publish the first version of each package manually. pub.dev automated
   publishing only supports packages that already exist.
3. In the pub.dev Admin page of every package, enable publishing from GitHub
   Actions for repository `congtuandevmobile/flutter_sport_sdk` and configure
   its own tag pattern, for example
   `flutter_tracking_gps-v{{version}}`.
4. Optional hardening: protect `*-v*` tags in GitHub. If pub.dev is configured
   to require a GitHub Environment, also add the same environment to the
   reusable publish job before enabling that requirement.

Do not store a pub.dev token in GitHub. `.github/workflows/publish.yml` uses
GitHub OIDC through Dart's official reusable publishing workflow.

## Release order and recovery

`[release]` publishes in dependency waves:

1. `flutter_activity`, `flutter_challenge`, `flutter_sport_ble`,
   `flutter_tracking_gps`, `flutter_workout`
2. `flutter_multisport`, `flutter_sport_ble_adapter`,
   `flutter_tracking_gps_adapter`
3. `flutter_multisport_adapters`

The dispatcher waits for pub.dev to expose every version in one wave before it
pushes tags for the next wave. This prevents adapters from being validated
before their newly released dependencies are available.

Before using `[release]`, update each selected package's `version` and its
`CHANGELOG.md`. A release tag is never overwritten. If a publish job fails,
fix its configuration and rerun that existing GitHub Actions job; do not delete
or move the tag. The dispatcher can then be rerun to continue later waves.

The implementation lives in:

- `.github/workflows/release-tags.yml`: parses commit markers and creates tags.
- `.github/workflows/publish.yml`: publishes only `<package>-v<version>` tags.
- `tool/release_plan.sh`: validates marker syntax and package selection.
- `tool/validate_release.sh`: runs the package, core, artifact, and example gates.
- `tool/dispatch_release.sh`: builds binaries, creates snapshot commits/tags,
  and enforces dependency order.
- `tool/release_notes.sh`: validates and extracts versioned changelog notes.
- `tool/release_manifest.sh`: canonical package list, versions, and native
  artifact locations.
