#!/usr/bin/env bash
# Runs every check and writes the outputs to tests/evidence/mobile/.
# Run from apps/mobile with Flutter 3.41.6 on PATH, e.g. inside
#   docker run --rm -v "$PWD/../..":/w -w /w/apps/mobile instrumentisto/flutter:3 tool/collect_evidence.sh
# Then (on any machine with python3): python3 tool/summarize_evidence.py
set -uo pipefail
APP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(cd "$APP/../.." && pwd)/tests/evidence/mobile"
cd "$APP"
mkdir -p "$OUT/screenshots"

{ flutter --version; } > "$OUT/flutter_version.txt" 2>&1
tool/sync_assets.sh --check > "$OUT/assets_check.txt" 2>&1; echo "exit=$?" >> "$OUT/assets_check.txt"
dart run tool/gen_arb.dart --check > "$OUT/l10n_check.txt" 2>&1; echo "exit=$?" >> "$OUT/l10n_check.txt"
flutter analyze > "$OUT/analyze.txt" 2>&1; echo "exit=$?" >> "$OUT/analyze.txt"
dart format --output=none --set-exit-if-changed lib test test_contract integration_test tool > "$OUT/format.txt" 2>&1
echo "exit=$?" >> "$OUT/format.txt"
RATTIL_SCREENSHOT_DIR="$OUT/screenshots" flutter test --coverage --machine > "$OUT/flutter_test_machine.jsonl" 2> "$OUT/flutter_test_stderr.txt"
echo "exit=$?" > "$OUT/flutter_test_exit.txt"
cp coverage/lcov.info "$OUT/lcov.info"
RATTIL_SCREENSHOT_DIR="$OUT/screenshots" flutter test --reporter expanded > "$OUT/flutter_test_expanded.txt" 2>&1
echo "exit=$?" >> "$OUT/flutter_test_expanded.txt"
