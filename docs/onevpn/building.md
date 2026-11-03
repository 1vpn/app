# Building for Android

Android is the app's first target. These steps build it from a clean clone with the pins in
`tool/pins.env`. `tool/build.sh` needs a git checkout. A bare source archive does not build.

## 1. Toolchain

- Install [mise](https://mise.jdx.dev/) and run `mise install`. `mise.toml` pins Flutter.
- Install the Android SDK, JDK 17 and the NDK at `ANDROID_NDK_VERSION`. Set `ANDROID_HOME`.
- The libXray build needs Python 3.9 or later and Go at `GO_VERSION`.

## 2. The libXray aar

The aar carries the Xray core. It is not committed. Stage it as `android/app/libs/libXray.aar`,
either the published aar or one you build from source.

Release builds use the aar of the prerelease `libxray-<first 7 characters of LIBXRAY_SHA>`. The
libXray workflow, `.github/workflows/libxray.yml`, builds and publishes it. It builds from
`LIBXRAY_SHA` and `XRAY_CORE_REF` with the pinned Go, gomobile and NDK. `tool/build.sh` checks
the aar's SHA-256 against `LIBXRAY_AAR_SHA256` and refuses any other aar.

To build the aar from source, run the workflow's recipe. It checks out libXray at `LIBXRAY_SHA`,
which pins Xray-core at `XRAY_CORE_REF`. Then libXray's own build script builds the aar.

```sh
. tool/pins.env
git clone https://github.com/XTLS/libXray.git ../libXray
git -C ../libXray checkout --detach "$LIBXRAY_SHA"
(cd ../libXray \
  && export LIBXRAY_GOMOBILE_VERSION ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION" \
  && export PATH="$(go env GOPATH)/bin:$PATH" \
  && python3 build/main.py android)
mkdir -p android/app/libs && cp ../libXray/libXray.aar android/app/libs/
unzip -p android/app/libs/libXray.aar jni/arm64-v8a/libgojni.so > /tmp/libgojni.so
go version -m /tmp/libgojni.so | grep -E 'go1|xray-core|x/mobile'
```

The xray-core line names the commit of `XRAY_CORE_REF`, a tag or a full commit. The x/mobile
line matches `LIBXRAY_GOMOBILE_VERSION`. The Go line reads `GO_VERSION`.

Add `--unpinned-core` to each Android build with this aar, as in
`mise exec -- tool/build.sh --apk --unpinned-core`. The build prints `unpinned core:` with the
aar's SHA-256 and the pin. The hash differs from the pin, because each native library in the aar
records the directory libXray was built in. A signed build attestation is coming for the
published aar, so you can verify its origin without a rebuild.

## 3. The geodata

The app bundles two routing lists from pinned v2fly releases. Stage them in `assets/dat/`. An
app build fails when either file is empty or missing. The bundle timestamp in
`assets/dat/timestamp.txt` is the older of the two release times, in Unix seconds. The build
script writes it from the release tags on every run.

```sh
. tool/pins.env
mkdir -p assets/dat
curl -fL -o assets/dat/geoip.dat \
  "https://github.com/v2fly/geoip/releases/download/$GEOIP_RELEASE/geoip.dat"
curl -fL -o assets/dat/geosite.dat \
  "https://github.com/v2fly/domain-list-community/releases/download/$GEOSITE_RELEASE/dlc.dat"
printf '%s  %s\n' "$GEOIP_SHA256" assets/dat/geoip.dat "$GEOSITE_SHA256" assets/dat/geosite.dat \
  | shasum -a 256 -c
```

## 4. The defines

Copy `env/local.example.json` to `env/local.json` and fill in the values you have. The file is
gitignored. App builds read it. The test run does not.

- `ONEVPN_UUID`, `ONEVPN_PBK` and `ONEVPN_SID` configure the free locations. Empty, the free
  catalogue is empty.
- `ONEVPN_FREE_NODE_IPS` names an IP literal for each free location. A build that sets the
  three connection defines fails unless every free location has one.
- `ONEVPN_RC_SDK_KEY` is the store SDK key. Empty, the paywall shows placeholder pricing.
  A RevenueCat Test Store key, with the `test_` prefix, makes the store SDK simulate billing
  in a debug build. That build never opens a Play sheet. A debug build for a device test
  against Google Play takes RevenueCat's public key for the Play app, with the `goog_`
  prefix. Its `env/local.json` also sets `ONEVPN_FAKE_PURCHASES` to `false`. The release
  build refuses a `test_` key.
- `ONEVPN_FAKE_PURCHASES` set to `true` runs the paywall against a local fake store.
- `ONEVPN_ADMOB_APP_ID_ANDROID` and `ONEVPN_ADMOB_INTERSTITIAL_ANDROID` are the AdMob app and
  interstitial ids. Empty, the build takes Google's test ids.
- `ONEVPN_UMP_DEBUG_GEOGRAPHY` and `ONEVPN_UMP_TEST_DEVICE` force a consent debug geography
  for a demo. The geography is `eea` or `other`. The device is the hashed id the consent
  platform logs. Empty, the consent request carries no debug settings.
  `ONEVPN_ADS_TEST_DEVICE` is the hashed id the Mobile Ads SDK logs. It makes that device
  receive test creatives. Empty, the SDK gets no test device. The release bundle never reads
  these three, because `--aab` writes its defines from a fixed list without them.

## 5. Test and build

```sh
mise exec -- tool/build.sh --test                  # the CI gate, with no native input needed
mise exec -- tool/build.sh --apk                   # build/app/outputs/flutter-apk/app-debug.apk
mise exec -- tool/build.sh --apk --unpinned-core   # with an aar built from source
```

## 6. Release bundle

`tool/build.sh --aab` builds the release bundle at
`build/app/outputs/bundle/release/app-release.aab`. It reads the version from
`tool/release.env` and the defines from the environment, never `env/local.json`. It sets
`ONEVPN_FAKE_PURCHASES` to `false` and refuses an empty or `test_` store key.

The bundle is unsigned. `--aab --signed` signs it with your own upload key, named in
`android/keystore/keystore.properties`. A release never signs with the debug key.
