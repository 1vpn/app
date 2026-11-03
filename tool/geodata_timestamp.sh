#!/usr/bin/env bash
# Prints the bundled geodata timestamp: the Unix time in whole seconds of the
# older of the two pinned v2fly releases. The app reads assets/dat/timestamp.txt
# in this form as the age of the bundled geodata.
#
# Usage:
#   tool/geodata_timestamp.sh                      reads both tags from tool/pins.env
#   tool/geodata_timestamp.sh <geoip> <geosite>    uses the given tags
#
# A geoip tag is YYYYMMDDHHMM and a geosite tag is YYYYMMDDHHMMSS, both in UTC,
# from the year 2000 on. Any other tag, an impossible date, or a missing pin
# fails with exit 2 and prints nothing.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  . "$(dirname "$0")/pins.env"
  for pin in GEOIP_RELEASE GEOSITE_RELEASE; do
    if [ -z "${!pin:-}" ]; then
      echo "missing pin in tool/pins.env: $pin" >&2
      exit 2
    fi
  done
elif [ "$#" -eq 2 ]; then
  GEOIP_RELEASE=$1
  GEOSITE_RELEASE=$2
else
  echo "usage: tool/geodata_timestamp.sh [<geoip-tag> <geosite-tag>]" >&2
  exit 2
fi

# Prints the Unix time of a UTC tag YYYYMMDDHHMM[SS] from the year 2000 on.
epoch() {
  local tag=$1 digits=$2
  if ! [[ "$tag" =~ ^[0-9]+$ ]] || [ "${#tag}" -ne "$digits" ]; then
    echo "invalid release tag: $tag" >&2
    exit 2
  fi
  local y=$((10#${tag:0:4})) m=$((10#${tag:4:2})) d=$((10#${tag:6:2}))
  local hh=$((10#${tag:8:2})) mm=$((10#${tag:10:2})) ss=0
  [ "$digits" -eq 14 ] && ss=$((10#${tag:12:2}))
  local mdays=31
  case $m in
    4 | 6 | 9 | 11) mdays=30 ;;
    2) mdays=$(((y % 4 == 0 && y % 100 != 0) || y % 400 == 0 ? 29 : 28)) ;;
  esac
  if [ "$y" -lt 2000 ] || [ "$m" -lt 1 ] || [ "$m" -gt 12 ] || [ "$d" -lt 1 ] \
    || [ "$d" -gt "$mdays" ] || [ "$hh" -gt 23 ] || [ "$mm" -gt 59 ] || [ "$ss" -gt 59 ]; then
    echo "invalid release tag: $tag" >&2
    exit 2
  fi
  # March-based year: the leap day falls at the end of the year.
  local ya=$((m <= 2 ? y - 1 : y))
  local era=$((ya / 400))
  local yoe=$((ya - era * 400))
  local doy=$(((153 * (m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1))
  local doe=$((yoe * 365 + yoe / 4 - yoe / 100 + doy))
  local days=$((era * 146097 + doe - 719468))
  echo $((days * 86400 + hh * 3600 + mm * 60 + ss))
}

geoip=$(epoch "$GEOIP_RELEASE" 12)
geosite=$(epoch "$GEOSITE_RELEASE" 14)
echo $((geoip < geosite ? geoip : geosite))
