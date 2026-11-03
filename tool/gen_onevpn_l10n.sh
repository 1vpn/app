#!/usr/bin/env bash
# Generates OneVpnLocalizations from the fork ARB files in lib/onevpn/l10n.
# The output in lib/onevpn/l10n/generated is committed.
#
# gen-l10n reads the l10n.yaml in its working directory. That file
# overrides every flag. The run happens in a stub project with no
# l10n.yaml. gen-l10n requires the stub pubspec. The script prints the
# untranslated report, which lists the keys each locale lacks.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd -P)"

STUB="$(mktemp -d)"
trap 'rm -rf "$STUB"' EXIT
cat > "$STUB/pubspec.yaml" <<'YAML'
name: onevpn_l10n_stub
environment:
  sdk: ^3.0.0
flutter:
  generate: true
YAML

cd "$STUB"
# Approved Persian text carries direction marks.
flutter --suppress-analytics --no-version-check gen-l10n \
  --arb-dir "$ROOT/lib/onevpn/l10n" \
  --template-arb-file onevpn_en.arb \
  --output-dir "$ROOT/lib/onevpn/l10n/generated" \
  --output-localization-file onevpn_localizations.dart \
  --output-class OneVpnLocalizations \
  --untranslated-messages-file untranslated.json \
  --header '// ignore_for_file: text_direction_code_point_in_literal' \
  --format
if [ -f untranslated.json ]; then cat untranslated.json; fi
