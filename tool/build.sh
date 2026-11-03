#!/usr/bin/env bash
# Build and gate script. `tool/build.sh --test` is the merge gate: it generates
# sources, checks them, analyzes, and runs the full suite. CI runs exactly this.
#
# `--apk` and `--ios` build the app from the fork entry point after the same
# source generation. App builds go through this script: a bare gradle or
# xcodebuild invocation defaults to lib/main.dart and packages the upstream
# entry point.
#
# Every app build takes its version label and build number from
# tool/release.env: `--apk`, `--ios` and `--aab` alike. A debug build then
# installs over a release candidate of the same build number. The version line
# in pubspec.yaml is upstream's, and the fork's builds never read it.
#
# `--kotlin` compiles the Android Kotlin sources against the staged native
# core. It runs after the resolve and builds no app. `--kotlin`, `--apk` and
# `--aab` refuse a staged aar whose SHA-256 differs from LIBXRAY_AAR_SHA256
# in tool/pins.env.
#
# `--unpinned-core` after the mode drops the hash check, for a core built
# from source. `--kotlin`, `--apk` and `--aab` then take a staged aar of any
# hash and print its SHA-256 beside the pin. A missing aar still fails. The
# other modes ignore the flag.
#
# `--aab` builds the release app bundle from the fork entry point. The bundle
# is unsigned.
# `--aab --signed` signs it with the upload config instead and fails when
# android/keystore/keystore.properties is absent. A release never signs with
# the debug config.
#
# tool/release_signing.gradle reads the release signing from the Gradle project
# property onevpn-release-signing. `none` builds unsigned. `upload` requires
# the upload config. `debug` signs a local release-type build with the debug
# config. Absent, a release signs with the upload config when it exists and
# stays unsigned otherwise. `--aab` sets `none` or `upload` itself and refuses
# `debug`. A developer opts in by name for a local release-type build:
#
#   flutter build apk --release -t lib/main_1vpn.dart -Ponevpn-release-signing=debug
#   flutter run --release -t lib/main_1vpn.dart -Ponevpn-release-signing=debug
#
# Flavor hooks activate as the product layer lands: when lib/onevpn exists its
# localizations are generated and checked; once the entry point reads connection
# credentials, ONEVPN_UUID / ONEVPN_PBK / ONEVPN_SID and ONEVPN_FREE_NODE_IPS
# come from the environment (never in-tree).
#
# Build-time configuration comes from env/local.json when that file exists: the
# store SDK key, the connection credentials, the free node IP literals, the
# AdMob app and interstitial ids, and the fake-purchase toggle. The file is gitignored and absent in CI, so a CI build
# reads the empty-string fallbacks. Only the app builds take the file. The test
# run never does. See env/local.example.json for the names.
#
# `--aab` never reads env/local.json. It takes ONEVPN_RC_SDK_KEY, ONEVPN_UUID,
# ONEVPN_PBK, ONEVPN_SID, ONEVPN_FREE_NODE_IPS, ONEVPN_ADMOB_APP_ID_ANDROID and
# ONEVPN_ADMOB_INTERSTITIAL_ANDROID from the environment and sets
# ONEVPN_FAKE_PURCHASES to false. It refuses an empty store key and a test
# store key. It refuses an empty value for any other of those names. It
# refuses an AdMob id with Google's sample publisher id, and an app id or
# ad unit id of the wrong shape.
#
# In the other app builds an empty AdMob id takes Google's published test id.
# tool/admob.gradle reads the app id. lib/onevpn/ads/admob_ad_gateway.dart
# reads the interstitial id.
#
# ONEVPN_UMP_DEBUG_GEOGRAPHY and ONEVPN_UMP_TEST_DEVICE force a consent debug
# geography on one test device for a demo build. ONEVPN_ADS_TEST_DEVICE makes
# one device receive test creatives. All three are empty by default.
# lib/onevpn/ads/admob_ad_gateway.dart reads them. `--aab` never carries them.
set -euo pipefail
cd "$(dirname "$0")/.."

# The script never reports tool analytics.
# It never checks the SDK version upstream.
export FLUTTER_SUPPRESS_ANALYTICS=true

MODE="${1:---test}"
case "$MODE" in --test|--build|--apk|--ios|--kotlin|--aab) ;; *) echo "unknown mode: $MODE (expected --test, --build, --apk, --ios, --kotlin, or --aab [--signed], with an optional --unpinned-core)" >&2; exit 2 ;; esac
SIGNED=false
UNPINNED_CORE=false
# Each flag follows the mode at most once, in either order.
for arg in "${@:2}"; do
  if [ "$arg" = "--unpinned-core" ] && [ "$UNPINNED_CORE" = "false" ]; then
    UNPINNED_CORE=true
  elif [ "$arg" = "--signed" ] && [ "$MODE" = "--aab" ] && [ "$SIGNED" = "false" ]; then
    SIGNED=true
  else
    echo "unexpected arguments after $MODE: ${*:2} (only --aab takes --signed)" >&2
    exit 2
  fi
done

# App builds compile this entry point. lib/main.dart stays the desktop entry.
ENTRY_POINT=lib/main_1vpn.dart
CI_MODE="${CI:-false}"

step() { echo "==> $1"; }

# Scratch space for the run, removed on every exit.
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# The build inputs. Each check runs before any tool starts, so a bad input
# fails in seconds. The app builds read the version from tool/release.env.
if [ "$MODE" = "--apk" ] || [ "$MODE" = "--ios" ] || [ "$MODE" = "--aab" ]; then
  . tool/release.env
  [[ "${RELEASE_VERSION:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
    || { echo "tool/release.env: RELEASE_VERSION must be x.y.z" >&2; exit 2; }
  [[ "${RELEASE_BUILD:-}" =~ ^[1-9][0-9]*$ ]] \
    || { echo "tool/release.env: RELEASE_BUILD must be a positive integer" >&2; exit 2; }
fi
if [ "$MODE" = "--aab" ]; then
  # The store SDK crashes at startup on a test key in a release build.
  case "${ONEVPN_RC_SDK_KEY:-}" in
    "") echo "refusing the release build: ONEVPN_RC_SDK_KEY is empty" >&2; exit 4 ;;
    test_*) echo "refusing the release build: ONEVPN_RC_SDK_KEY is a test key" >&2; exit 4 ;;
  esac
  # The mode passes onevpn-release-signing as a command-line -P, which outranks
  # every other source of the property. Its arguments admit only --signed. The
  # mode still refuses each other source, so the signing never rests on Gradle
  # precedence and `debug` never reaches the bundle.
  for source in "environment ORG_GRADLE_PROJECT_onevpn-release-signing" \
      "GRADLE_OPTS" "JAVA_OPTS" "JAVA_TOOL_OPTIONS" \
      "android/gradle.properties" "${GRADLE_USER_HOME:-$HOME/.gradle}/gradle.properties"; do
    case "$source" in
      environment*) value="$(env | grep '^ORG_GRADLE_PROJECT_onevpn-release-signing=' || true)" ;;
      *_OPTS|*_OPTIONS) value="$(printenv "$source" | grep -F 'onevpn-release-signing' || true)" ;;
      *) value="$( [ -f "$source" ] && grep -F 'onevpn-release-signing' "$source" || true)" ;;
    esac
    if [ -n "$value" ]; then
      echo "refusing the release build: ${source#environment } sets onevpn-release-signing" >&2
      exit 4
    fi
  done
  if [ "$SIGNED" = "true" ] && [ ! -f android/keystore/keystore.properties ]; then
    echo "refusing the signed build: android/keystore/keystore.properties is missing" >&2
    exit 4
  fi
  # An empty connection value ships a free tier that cannot connect. An empty
  # or sample AdMob id ships Google's test ads. `--apk` and `--ios` keep both
  # fallbacks.
  for name in ONEVPN_UUID ONEVPN_PBK ONEVPN_SID ONEVPN_FREE_NODE_IPS \
      ONEVPN_ADMOB_APP_ID_ANDROID ONEVPN_ADMOB_INTERSTITIAL_ANDROID; do
    if [ -z "${!name:-}" ]; then
      echo "refusing the release build: $name is empty" >&2
      exit 4
    fi
  done
  for name in ONEVPN_ADMOB_APP_ID_ANDROID ONEVPN_ADMOB_INTERSTITIAL_ANDROID; do
    case "${!name}" in
      ca-app-pub-3940256099942544*) echo "refusing the release build: $name is Google's sample id" >&2; exit 4 ;;
    esac
  done
  # The app id carries a tilde and the unit id a slash. A swapped or malformed
  # id fails here, before it reaches the manifest or the ad request.
  [[ "$ONEVPN_ADMOB_APP_ID_ANDROID" =~ ^ca-app-pub-[0-9]{16}~[0-9]{10}$ ]] \
    || { echo "refusing the release build: ONEVPN_ADMOB_APP_ID_ANDROID is not an AdMob app id" >&2; exit 4; }
  [[ "$ONEVPN_ADMOB_INTERSTITIAL_ANDROID" =~ ^ca-app-pub-[0-9]{16}/[0-9]{10}$ ]] \
    || { echo "refusing the release build: ONEVPN_ADMOB_INTERSTITIAL_ANDROID is not an AdMob ad unit id" >&2; exit 4; }
fi

# The release define file, written from the environment. It lives in the
# scratch directory and goes with it. Values are never printed. Each value is
# written as a JSON string verbatim. A value with a double quote, a backslash
# or a control character fails the run.
write_release_defines() {
  printf '{"ONEVPN_FAKE_PURCHASES":false'
  for name in ONEVPN_RC_SDK_KEY ONEVPN_UUID ONEVPN_PBK ONEVPN_SID ONEVPN_FREE_NODE_IPS \
      ONEVPN_ADMOB_APP_ID_ANDROID ONEVPN_ADMOB_INTERSTITIAL_ANDROID; do
    case "${!name:-}" in
      *[[:cntrl:]]* | *'"'* | *'\'*) echo "refusing the release build: $name holds a quote, a backslash or a control character" >&2; exit 4 ;;
    esac
    printf ',"%s":"%s"' "$name" "${!name:-}"
  done
  printf '}\n'
}

# A developer's own defines, if they have a file. The app builds take these.
# The suite never does: it runs keyless, so a real store key cannot turn the
# gate red.
#
# An explicit --dart-define overrides a file entry with the same key whatever
# order the flags appear in. Each expansion guards against the empty case: an
# empty array is an unbound variable under `set -u` on bash 3.2.
DEFINE_FILE=env/local.json
DART_DEFINES=()
if [ "$MODE" = "--aab" ]; then
  DEFINE_FILE="$SCRATCH/release-defines.json"
  write_release_defines > "$DEFINE_FILE"
fi
if [ -f "$DEFINE_FILE" ]; then
  DART_DEFINES=(--dart-define-from-file="$DEFINE_FILE")
  step "reading dart-defines from $DEFINE_FILE"
fi

step "flutter pub get"
# In CI the resolve must match the committed lock. A changed version or
# content hash fails here, before the generators run any package code.
# Analyze and test pass --no-pub and reuse this resolve.
if [ "$CI_MODE" = "true" ]; then
  flutter --suppress-analytics --no-version-check pub get --enforce-lockfile
else
  flutter --suppress-analytics --no-version-check pub get
fi

step "placeholder geo assets"
mkdir -p assets/dat
for f in geoip.dat geoip.json geosite.dat geosite.json; do
  [ -e "assets/dat/$f" ] || touch "assets/dat/$f"
done
# timestamp.txt holds the pinned release time after every run. A first install
# rejects an empty file. A failed helper leaves the previous file in place.
tool/geodata_timestamp.sh > assets/dat/timestamp.txt.tmp
mv assets/dat/timestamp.txt.tmp assets/dat/timestamp.txt

# The staged aar must be the pinned build. Its SHA-256 must equal
# LIBXRAY_AAR_SHA256 in tool/pins.env, the pin CI checks the release asset
# against. A missing or different aar fails with exit 3 and names the release
# asset. With --unpinned-core the aar must exist, and the check prints its
# SHA-256 beside the pin instead of comparing them. The body runs in a
# subshell, so the pins it reads stay out of the build.
require_pinned_aar() (
  aar=android/app/libs/libXray.aar
  . tool/pins.env
  core="${LIBXRAY_SHA:-}"
  stage_line="stage the aar built at LIBXRAY_SHA, the release asset libxray-${core:0:7}"
  if [ ! -f "$aar" ]; then
    echo "missing staged native library: $aar" >&2
    echo "$stage_line" >&2
    exit 3
  fi
  step "verify the staged native core against tool/pins.env"
  # Linux has sha256sum. A macOS without it has shasum.
  if command -v sha256sum > /dev/null; then
    actual="$(sha256sum "$aar")"
  else
    actual="$(shasum -a 256 "$aar")"
  fi
  actual="${actual%% *}"
  expected="${LIBXRAY_AAR_SHA256:-}"
  if [ "$UNPINNED_CORE" = "true" ]; then
    echo "unpinned core: sha256 ${actual:0:12} (the release pin is ${expected:0:12})"
    exit 0
  fi
  if [ "$actual" != "$expected" ]; then
    echo "the staged native library does not match the pin: $aar" >&2
    echo "expected sha256 ${expected:0:12} (LIBXRAY_AAR_SHA256 in tool/pins.env), actual ${actual:0:12}" >&2
    echo "$stage_line" >&2
    exit 3
  fi
  echo "the staged libXray.aar matches the pin: sha256 ${actual:0:12}"
)

# The Kotlin compile needs the Gradle wrapper, which --config-only writes.
# It skips the Dart kernel task. The test run covers the Dart side.
if [ "$MODE" = "--kotlin" ]; then
  require_pinned_aar
  step "flutter build apk --config-only"
  flutter --suppress-analytics --no-version-check build apk --config-only
  step "gradle :app:compileDebugKotlin"
  (cd android && ./gradlew :app:compileDebugKotlin -x :app:compileFlutterBuildDebug --no-daemon)
  echo "compiled the Android Kotlin sources"
  exit 0
fi

step "generate sources"
flutter --suppress-analytics --no-version-check gen-l10n
dart --suppress-analytics run build_runner build
dart --suppress-analytics run ffigen

# The fork pigeon outputs and localizations. A fresh generation must leave
# them unchanged: a definition or ARB edit without regenerating fails here.
# A scratch index records the generated paths as they stand before the run,
# so uncommitted outputs that are current pass. The real index is untouched.
# A failed check leaves the regenerated outputs in the worktree for
# inspection.
step "verify fork generated sources"
FORK_GENERATED=(
  lib/onevpn/handover/handover.g.dart
  android/app/src/main/kotlin/net/yuandev/onexray/onevpn/handover/Handover.g.kt
  lib/onevpn/l10n/generated
)
GENERATED_INDEX="$SCRATCH/generated"
mkdir "$GENERATED_INDEX"
generated_git() { GIT_INDEX_FILE="$GENERATED_INDEX/index" git "$@"; }
cp "$(git rev-parse --git-path index)" "$GENERATED_INDEX/index"
generated_git add -A -- "${FORK_GENERATED[@]}"
tool/gen_onevpn_pigeon.sh
tool/gen_onevpn_l10n.sh
# Intent-to-add makes a newly generated file show in the diff.
generated_git add -N -- "${FORK_GENERATED[@]}"
if ! generated_git diff --exit-code -- "${FORK_GENERATED[@]}" >&2; then
  echo "the fork generated sources are stale against tool/pigeon or the ARB files" >&2
  echo "run tool/gen_onevpn_pigeon.sh and tool/gen_onevpn_l10n.sh and commit the outputs" >&2
  exit 1
fi
rm -rf "$GENERATED_INDEX"

# The native core is a staged local artifact, never committed. Without it
# the build fails deep in the toolchain, so the check runs first. $1 is the
# test flag for the artifact's on-disk type: -f for the aar file, -d for
# the xcframework bundle directory. A wrongly staged type fails the check.
require_prebuilt() {
  test "$1" "$2" && return
  echo "missing staged native library: $2" >&2
  echo "stage it from a trusted local build before running app builds" >&2
  exit 3
}

# App builds stop here. The gate stages below belong to --test and --build.
# App builds ship the bundled geodata. The gate's zero-byte placeholders
# satisfy the analyzer but produce an empty region catalog at runtime, so
# the setup flow dead-ends. Stage the real files from the core checkout.
require_geodata() {
  for f in geoip.dat geosite.dat; do
    [ -s "assets/dat/$f" ] && continue
    echo "assets/dat/$f is empty or missing" >&2
    echo "stage the dat directory from the pinned libXray checkout" >&2
    exit 3
  done
}

# App builds that set the free triple must name a literal for every free
# node. The guard reads the define file alone, the one source the build passes
# to Flutter. It fails the build on an empty define, a missing host, a rejected
# entry, or an unknown host. It prints hostnames and entry positions only.
if [ "$MODE" = "--apk" ] || [ "$MODE" = "--ios" ] || [ "$MODE" = "--aab" ]; then
  step "verify free node IP literals"
  dart --suppress-analytics run tool/check_free_node_ips.dart "$DEFINE_FILE"
fi

if [ "$MODE" = "--apk" ]; then
  require_pinned_aar
  require_geodata
  step "flutter build apk --debug -t $ENTRY_POINT ($RELEASE_VERSION+$RELEASE_BUILD)"
  flutter --suppress-analytics --no-version-check build apk ${DART_DEFINES[@]+"${DART_DEFINES[@]}"} --debug -t "$ENTRY_POINT" \
    --build-name "$RELEASE_VERSION" --build-number "$RELEASE_BUILD"
  echo "built build/app/outputs/flutter-apk/app-debug.apk ($RELEASE_VERSION+$RELEASE_BUILD)"
  exit 0
fi

# The release bundle. The signing property reaches tool/release_signing.gradle:
# "none" builds unsigned and "upload" requires the upload config. The mode
# never passes "debug".
if [ "$MODE" = "--aab" ]; then
  require_pinned_aar
  require_geodata
  SIGNING=none
  [ "$SIGNED" = "true" ] && SIGNING=upload
  AAB=build/app/outputs/bundle/release/app-release.aab
  rm -f "$AAB"
  step "flutter build appbundle --release -t $ENTRY_POINT ($RELEASE_VERSION+$RELEASE_BUILD, signing $SIGNING)"
  flutter --suppress-analytics --no-version-check build appbundle "${DART_DEFINES[@]}" --release -t "$ENTRY_POINT" \
    --build-name "$RELEASE_VERSION" --build-number "$RELEASE_BUILD" \
    --android-project-arg "onevpn-release-signing=$SIGNING"
  # A signature block entry marks a signed bundle. The count reads a whole
  # listing. A bundle that unzip cannot list stops the build.
  ENTRIES="$(unzip -Z1 "$AAB")" \
    || { echo "cannot list the entries of the bundle: $AAB" >&2; exit 1; }
  # grep exits 1 when it counts no entry. That is a count of zero.
  SIGNATURES="$(grep -cE '^META-INF/[^/]+\.(RSA|DSA|EC)$' <<< "$ENTRIES")" || [ "$?" -eq 1 ]
  if [ "$SIGNING" = "none" ] && [ "$SIGNATURES" -ne 0 ]; then
    echo "the unsigned build carries a signature: $AAB" >&2
    exit 1
  fi
  if [ "$SIGNING" = "upload" ] && [ "$SIGNATURES" -eq 0 ]; then
    echo "the signed build carries no signature: $AAB" >&2
    exit 1
  fi
  echo "built $AAB ($RELEASE_VERSION+$RELEASE_BUILD, signing $SIGNING)"
  exit 0
fi

if [ "$MODE" = "--ios" ]; then
  require_prebuilt -d swift/All/LibXray.xcframework
  require_geodata
  # Release, not debug. A debug Flutter app does not launch from the home
  # screen on iOS 14 and later.
  step "flutter build ios --release -t $ENTRY_POINT ($RELEASE_VERSION+$RELEASE_BUILD)"
  flutter --suppress-analytics --no-version-check build ios ${DART_DEFINES[@]+"${DART_DEFINES[@]}"} --release -t "$ENTRY_POINT" \
    --build-name "$RELEASE_VERSION" --build-number "$RELEASE_BUILD"
  echo "built build/ios/iphoneos/Runner.app ($RELEASE_VERSION+$RELEASE_BUILD)"
  exit 0
fi

if [ "$CI_MODE" = "true" ]; then
  step "verify toolchain pin"
  . tool/pins.env
  ACTUAL=$(flutter --suppress-analytics --no-version-check --version | head -1 | awk '{print $2}')
  [ "$ACTUAL" = "$FLUTTER_VERSION" ] || { echo "flutter $ACTUAL does not match pinned $FLUTTER_VERSION" >&2; exit 1; }

  step "verify generated sources are committed"
  git add -A
  git diff --cached --exit-code
  git reset -q
fi

step "check format"
find lib test tool -name '*.dart' \
  ! -name '*.g.dart' \
  ! -path 'lib/gen/*' \
  ! -path 'lib/l10n/*' \
  ! -path 'lib/core/pigeon/messages.g.dart' \
  ! -path 'lib/core/ffi/generated_bindings.dart' \
  -print0 | xargs -0 dart --suppress-analytics format --output=none --set-exit-if-changed

step "verify layer dependencies"
dart --suppress-analytics run tool/check_layer_dependencies.dart

step "analyze"
flutter --suppress-analytics --no-version-check analyze --no-pub

step "verify native JSON model contract"
dart --suppress-analytics run tool/check_native_model_contract.dart

if [ "$MODE" = "--test" ]; then
  step "test"
  # The count sums passed and skipped tests. The count line starts
  # "test count N".
  TEST_LOG="$(mktemp)"
  # CI runners have 2 vCPUs. The test_core default then runs one file at a time.
  TEST_FLAGS=(--no-pub)
  if [ "$CI_MODE" = "true" ]; then
    TEST_FLAGS+=(--concurrency=2 --experimental-faster-testing)
    # Faster mode resolves a relative rootUri against the project directory.
    # The project package then fails to load. An absolute rootUri loads it.
    # The rewrite stays in the CI checkout, which CI discards.
    ROOT_URI="file://$(pwd -P)/"
    sed -i "s|\"rootUri\": \"../\"|\"rootUri\": \"$ROOT_URI\"|" .dart_tool/package_config.json
    grep -qF "\"rootUri\": \"$ROOT_URI\"" .dart_tool/package_config.json \
      || { echo "package_config rootUri rewrite failed" >&2; exit 1; }
  fi
  flutter --suppress-analytics --no-version-check test "${TEST_FLAGS[@]}" | tee "$TEST_LOG"
  # The final summary line, from whichever reporter ran: the local compact
  # reporter ("+P ~S: All tests passed!") or the CI reporter ("P tests passed,
  # S skipped"). Parse the count off that one line so per-test output cannot
  # skew it. "|| true" keeps a no-match grep from tripping "set -e".
  SUMMARY="$(grep -E 'All tests passed|[0-9]+ tests? passed' "$TEST_LOG" | tail -1 || true)"
  if printf '%s' "$SUMMARY" | grep -q '+[0-9]'; then
    PASSED="$(printf '%s' "$SUMMARY" | grep -oE '\+[0-9]+' | tr -d '+' || true)"
    SKIPPED="$(printf '%s' "$SUMMARY" | grep -oE '~[0-9]+' | tr -d '~' || true)"
  else
    PASSED="$(printf '%s' "$SUMMARY" | grep -oiE '[0-9]+ tests? passed' | grep -oE '[0-9]+' || true)"
    SKIPPED="$(printf '%s' "$SUMMARY" | grep -oiE '[0-9]+ skipped' | grep -oE '[0-9]+' || true)"
  fi
  TOTAL=$(( ${PASSED:-0} + ${SKIPPED:-0} ))
  # A zero count means the summary did not parse.
  [ "$TOTAL" -gt 0 ] || { echo "no test summary line parsed: the count is unknown" >&2; rm -f "$TEST_LOG"; exit 1; }

  rm -f "$TEST_LOG"

  echo "test count $TOTAL"
fi
step "check whitespace"
# Working-tree diffs are already clean here in CI, so check the committed range.
if MB=$(git merge-base origin/dev HEAD 2>/dev/null); then
  git diff --check "$MB" HEAD
else
  git diff --check
fi

step "gate passed"
