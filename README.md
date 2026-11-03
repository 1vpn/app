# 1VPN

This is 1VPN's cross-platform app. Android ships first. iOS follows. The desktop targets are out
of scope. The app is a fork of [OneXray](https://github.com/OneXray/OneXray). It uses Flutter and
the Xray core.

## Licence and attribution

This app is a modified version of OneXray. 1VPN modifies it and publishes the result under the
GNU General Public License, version 3. [LICENSE](LICENSE) holds the full text.
[CHANGELOG.md](CHANGELOG.md) records each release: its date, the upstream commit it builds on and
the changes it makes.

## About this repository

This repository is a source publication. Each commit is the source of one released version.
Development happens in a private repository.

- This repository accepts no issues or pull requests.
- For support, use the [contact page](https://1vpn.org/contact-us/) on the
  [1VPN website](https://1vpn.org/).
- Users of the v2 app find its final source at the `v2.2.4` tag.

## Build for Android

[docs/onevpn/building.md](docs/onevpn/building.md) has the full steps. In short:

1. Install [mise](https://mise.jdx.dev/) and run `mise install`. `mise.toml` pins Flutter. The
   build also needs the Android SDK and JDK 17.
2. Stage the two native inputs. Neither is committed. `tool/pins.env` pins both.
   - `android/app/libs/libXray.aar`: release builds use the aar that
     `.github/workflows/libxray.yml` publishes, built from the pinned
     [libXray](https://github.com/XTLS/libXray) and Xray-core commits. `tool/build.sh` checks
     that aar against its SHA-256 pin. [building.md](docs/onevpn/building.md#2-the-libxray-aar)
     names the published aar and covers a source build with `--unpinned-core`.
   - `assets/dat/geoip.dat` and `assets/dat/geosite.dat`: the `geoip.dat` asset of the
     [v2fly/geoip](https://github.com/v2fly/geoip) release `GEOIP_RELEASE`, and the `dlc.dat`
     asset of the [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)
     release `GEOSITE_RELEASE`, saved as `geosite.dat`.
   - Check the two geodata files against their SHA-256 pins.
3. Optionally, copy `env/local.example.json` to `env/local.json` and fill in the defines.
4. Run `mise exec -- tool/build.sh --apk`. With an aar built from source, run
   `mise exec -- tool/build.sh --apk --unpinned-core`. The debug APK lands in
   `build/app/outputs/flutter-apk/app-debug.apk`.

### Build-time defines

`env/local.example.json` names the defines. `tool/build.sh` passes `env/local.json` to Flutter
when the file exists. `env/local.json` is gitignored.

| Define | Holds |
|---|---|
| `ONEVPN_UUID`, `ONEVPN_PBK`, `ONEVPN_SID` | The connection credentials for the free locations |
| `ONEVPN_FREE_NODE_IPS` | The IP literal for each free location |
| `ONEVPN_RC_SDK_KEY` | The store SDK key for in-app purchases |
| `ONEVPN_FAKE_PURCHASES` | `true` runs the paywall against a local fake store |
| `ONEVPN_ADMOB_APP_ID_ANDROID`, `ONEVPN_ADMOB_INTERSTITIAL_ANDROID` | The AdMob app and interstitial ids. Empty, the build takes Google's test ids |

An empty define builds and runs. With the three connection defines empty, the free catalogue is
empty. With no store key, the paywall shows placeholder pricing.

### Release bundle

`tool/build.sh --aab` builds the release bundle. It takes the defines from the environment, not
from `env/local.json`. It needs your own store key and connection credentials, and it refuses an
empty or test store key. The bundle is unsigned. Signing it needs your own upload key.

## Not in this repository

The development process files and the release tooling stay in the private repository. So do the
desktop platform trees, upstream's own docs and the upstream tooling the fork does not ship. The
build reads every secret from the environment or a local file. Every secret stays outside the
repository.

## Layout

| Path | Holds |
|---|---|
| `lib/` | The Dart app. `lib/onevpn/` and `lib/main_1vpn.dart` are the fork's code |
| `test/` | The test suite. `test/onevpn/` covers the fork's code |
| `android/` | The Android platform tree and the VPN service |
| `ios/`, `swift/` | The iOS app and its tunnel |
| `assets/` | Icons, region data and the staged geodata |
| `pigeon/`, `c/` | Platform channel and native interface definitions |
| `tool/` | The build script, the pins and the code generators |
| `env/` | The define template |
| `docs/onevpn/` | The fork's developer docs |
| `fastlane/` | The Play listing text, screenshots and release notes |
| `.github/` | The CI workflows |
