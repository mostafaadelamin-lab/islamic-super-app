#!/usr/bin/env bash
# Copies shared content, schemas, fonts and generated design tokens into the
# Flutter app so the bundled copies are reproducible. Run from anywhere:
#   apps/mobile/tool/sync_assets.sh          # copy
#   apps/mobile/tool/sync_assets.sh --check  # fail if any copy is stale
# The Quran files are copied byte-for-byte (cp); nothing here edits content.
set -euo pipefail

APP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$APP/../.." && pwd)"
MODE="${1:-copy}"

# source (relative to repo root) -> destination (relative to apps/mobile)
PAIRS=(
  "content/quran/dist/quran.v1.json:assets/content/quran.v1.json"
  "content/quran/dist/pages.v1.json:assets/content/pages.v1.json"
  "content/quran/dist/integrity.v1.json:assets/content/integrity.v1.json"
  "content/VERSIONS.json:assets/content/VERSIONS.json"
  "packages/shared-schemas/prayer/methods.json:assets/schemas/methods.json"
  "packages/shared-schemas/cities.json:assets/schemas/cities.json"
  "packages/shared-schemas/quran-render.json:assets/schemas/quran-render.json"
  "packages/shared-schemas/search-normalization.json:assets/schemas/search-normalization.json"
  "content/fonts/AmiriQuran-Regular.ttf:assets/fonts/AmiriQuran-Regular.ttf"
  "content/fonts/IBMPlexSansArabic-Regular.ttf:assets/fonts/IBMPlexSansArabic-Regular.ttf"
  "content/fonts/IBMPlexSansArabic-SemiBold.ttf:assets/fonts/IBMPlexSansArabic-SemiBold.ttf"
  "content/fonts/OFL.txt:assets/fonts/OFL-AmiriQuran.txt"
  "content/fonts/OFL-IBMPlexSansArabic.txt:assets/fonts/OFL-IBMPlexSansArabic.txt"
  "packages/design-tokens/dist/design_tokens.dart:lib/theme/design_tokens.dart"
)

stale=0
for pair in "${PAIRS[@]}"; do
  src="$ROOT/${pair%%:*}"
  dst="$APP/${pair#*:}"
  if [[ ! -f "$src" ]]; then
    echo "missing source: $src" >&2
    exit 1
  fi
  if [[ "$MODE" == "--check" ]]; then
    if ! cmp -s "$src" "$dst"; then
      echo "stale: ${pair#*:} (differs from ${pair%%:*})" >&2
      stale=1
    fi
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "copied ${pair%%:*} -> ${pair#*:}"
  fi
done

if [[ "$MODE" == "--check" ]]; then
  if [[ $stale -ne 0 ]]; then
    echo "run apps/mobile/tool/sync_assets.sh" >&2
    exit 1
  fi
  echo "all bundled assets match their sources"
fi
