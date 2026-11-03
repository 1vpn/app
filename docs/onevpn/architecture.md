# Architecture

The app is cross-platform. Android ships first and iOS follows. It is the
[OneXray](https://github.com/OneXray/OneXray) codebase plus a product layer. The upstream code
keeps its own structure. The fork's code lives in its own namespaces and reaches
upstream through a small set of hooks.

## Fork namespaces

| Path | Holds |
|---|---|
| `lib/main_1vpn.dart` | The app's entry point. `tool/build.sh` builds every app from it |
| `lib/onevpn/` | The product layer: account, catalogue, connect, paywall, routing and the UI shell |
| `test/onevpn/` | The tests for the product layer and for the fork's contracts on upstream code |
| `android/app/src/main/kotlin/net/yuandev/onexray/onevpn/` | The Kotlin delegate and the fork's platform channels |
| `assets/onevpn/` | The fork's own assets |
| `fastlane/metadata/` | The Play store listing: text, release notes and phone screenshots |
| `tool/` | The build script, the pins, the generators and the build guards |
| `docs/onevpn/` | These docs |

`lib/main.dart` stays upstream's entry point and is not part of the app build.

## How the fork reaches upstream

- Dart: `lib/onevpn/` builds on upstream's core and services. A few upstream files call into
  `lib/onevpn/` at a single hook each.
- Kotlin: each hook in an upstream service file is one line that calls the delegate.
  `OneVpnServiceDelegate` holds the behavior. It runs in the VPN service's process.
- Platform channels: the fork defines its own in `tool/pigeon/`. `tool/gen_onevpn_pigeon.sh`
  generates the Dart and Kotlin sides. Upstream's channels in `pigeon/` keep their names.
- Localization: the fork's strings live in ARB files under `lib/onevpn/l10n/`.
  `tool/gen_onevpn_l10n.sh` generates the Dart. Both generators' outputs are committed, and the
  gate fails when they are stale.
- Adopted files: `tool/adopted-files.txt` lists upstream files whose whole content the fork
  replaced, such as `README.md`.

## Upstream policy

Each change falls into one of three classes:

- Additive: a change only to files that do not exist upstream. Most changes are additive.
- In-place edit: a change to an upstream file. Each one records why no fork-side seam works.
- Upstreamable fix: a fix to an upstream defect, written in upstream's conventions.

The platform channel names, the package namespace and the `onevpn` prefix are frozen. The fork
allocates no identifier from a namespace upstream also allocates from.

## Pinned inputs

`tool/pins.env` is the single source for every pin. The build and CI read it.

| Pin | Fixes |
|---|---|
| `FLUTTER_VERSION` | The Flutter SDK. `mise.toml` mirrors it |
| `UPSTREAM_TAG` | The upstream commit the fork is built on |
| `LIBXRAY_SHA`, `XRAY_CORE_REF` | The libXray commit and the Xray-core tag or commit it carries |
| `GO_VERSION`, `LIBXRAY_GOMOBILE_VERSION`, `ANDROID_NDK_VERSION` | The toolchain that builds the aar |
| `LIBXRAY_AAR_SHA256` | The hash of the aar the release ships |
| `GEOIP_RELEASE`, `GEOSITE_RELEASE` | The v2fly releases of the two geodata files |
| `GEOIP_SHA256`, `GEOSITE_SHA256` | The hashes of the two geodata files |

`pubspec.lock` pins the Dart packages. `tool/release.env` holds the version and build number.

## Release model

- Each released version is one commit in this repository, a snapshot of the release's source.
- Each release commit carries the tag `v<version>`.
- `CHANGELOG.md` records each release with its date, its upstream commit and its changes.
