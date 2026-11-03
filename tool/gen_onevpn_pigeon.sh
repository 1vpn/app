#!/usr/bin/env bash
# Regenerates the fork pigeon outputs and strips trailing whitespace from them.
set -euo pipefail
cd "$(dirname "$0")/.."

ONEVPN_PIGEON_OUTPUTS=(
  lib/onevpn/handover/handover.g.dart
  android/app/src/main/kotlin/net/yuandev/onexray/onevpn/handover/Handover.g.kt
)

dart --suppress-analytics run pigeon --input tool/pigeon/onevpn_handover.dart
perl -pi -e 's/[ \t]+$//' "${ONEVPN_PIGEON_OUTPUTS[@]}"
