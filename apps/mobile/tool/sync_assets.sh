#!/usr/bin/env bash
# Copies shared content, schemas, fonts and generated design tokens into the
# Flutter app so the bundled copies are reproducible. Run from anywhere:
#   apps/mobile/tool/sync_assets.sh          # copy
#   apps/mobile/tool/sync_assets.sh --check  # fail if any copy is stale
# The Quran files are copied byte-for-byte (cp); nothing here edits content.
# Hadith part files are gzip-compressed on the way (see below); their text is unchanged.
# assets/content/hajj.v1.json is extracted (not copied) from content/pilgrimage/source-hajj.js by
# tool/extract_hajj.mjs (node); test/unit/hajj_content_test.dart checks every string against the source.
set -euo pipefail

APP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$APP/../.." && pwd)"
MODE="${1:-copy}"

# source (relative to repo root) -> destination (relative to apps/mobile)
PAIRS=(
  "content/quran/dist/quran.v1.json:assets/content/quran.v1.json"
  "content/quran/dist/pages.v1.json:assets/content/pages.v1.json"
  "content/quran/dist/integrity.v1.json:assets/content/integrity.v1.json"
  "content/quran/dist/mushaf-lines.v1.json:assets/content/mushaf-lines.v1.json"
  "content/adhkar/dist/adhkar.v1.json:assets/content/adhkar.v1.json"
  "content/adhkar/dist/adhkar-hadith.v1.json:assets/content/adhkar-hadith.v1.json"
  "content/asma/dist/asma-audio.v1.json:assets/content/asma-audio.v1.json"
  "content/adhkar/hisn.json:assets/content/hisn.json"
  "content/adhkar/hisn-sections.json:assets/content/hisn-sections.json"
  "content/pilgrimage/step-duas.v1.json:assets/content/step-duas.v1.json"
  "content/pilgrimage/dist/hajj-guide.v2.json:assets/content/hajj-guide.v2.json"
  "content/pilgrimage/dist/hajj-scenes.v1.json:assets/content/hajj-scenes.v1.json"
  "content/pilgrimage/scene-roles.v1.json:assets/content/scene-roles.v1.json"
  "content/zakat/dar-alifta.v1.json:assets/content/zakat.v1.json"
  "packages/shared-schemas/app-links.json:assets/schemas/app-links.json"
  "content/tafsir/dist/muyassar.v1.json:assets/content/tafsir-muyassar.v1.json"
  "content/word-meanings/dist/siraj.v1.json:assets/content/word-meanings-siraj.v1.json"
  "content/VERSIONS.json:assets/content/VERSIONS.json"
  "content/reels/dist/reels.v1.json:assets/content/reels.v1.json"
  "content/reels/dist/reel-sources.v1.json:assets/content/reel-sources.v1.json"
  "content/stories/dist/stories.v1.json:assets/content/stories.v1.json"
  "content/sharawi/dist/sharawi.v1.json:assets/content/sharawi.v1.json"
  "content/kids/dist/kids.v1.json:assets/content/kids.v1.json"
  "content/quran/dist/mushaf-printed.v1.json:assets/content/mushaf-printed.v1.json"
  "content/shabib/dist/shabib.v1.json:assets/content/shabib.v1.json"
  "packages/shared-schemas/prayer/methods.json:assets/schemas/methods.json"
  "packages/shared-schemas/geo/wmm2025.json:assets/schemas/wmm2025.json"
  "packages/shared-schemas/cities.json:assets/schemas/cities.json"
  "packages/shared-schemas/quran-render.json:assets/schemas/quran-render.json"
  "packages/shared-schemas/search-normalization.json:assets/schemas/search-normalization.json"
  "packages/shared-schemas/audio/reciters.json:assets/schemas/reciters.json"
  "content/fonts/KFGQPC-HAFS-Uthmanic-v18.ttf:assets/fonts/KFGQPC-HAFS-Uthmanic-v18.ttf"
  "content/fonts/IBMPlexSansArabic-Regular.ttf:assets/fonts/IBMPlexSansArabic-Regular.ttf"
  "content/fonts/IBMPlexSansArabic-SemiBold.ttf:assets/fonts/IBMPlexSansArabic-SemiBold.ttf"
  "content/fonts/KFGQPC-HAFS-LICENSE.txt:assets/fonts/KFGQPC-HAFS-LICENSE.txt"
  "content/fonts/OFL-IBMPlexSansArabic.txt:assets/fonts/OFL-IBMPlexSansArabic.txt"
  "packages/design-tokens/dist/design_tokens.dart:lib/theme/design_tokens.dart"
  "packages/design-tokens/dist/rattil_icons.dart:lib/theme/rattil_icons.dart"
)

# Hadith books (content/hadith/dist, built by tools/build_hadith.py): every .json is stored gzip-compressed
# (.json.gz, gzip -n so the bytes are reproducible) except the small catalog books.v1.json. The text inside
# is byte-for-byte the source; --check compares the decompressed bytes.
HADITH_SRC="$ROOT/content/hadith/dist"
HADITH_DST="$APP/assets/hadith"

stale=0
if [[ ! -d "$HADITH_SRC" ]]; then
  echo "missing source folder: $HADITH_SRC" >&2
  exit 1
fi
if [[ "$MODE" != "--check" ]]; then
  rm -rf "$HADITH_DST"
  mkdir -p "$HADITH_DST"
fi
while IFS= read -r -d '' f; do
  rel="${f#$HADITH_SRC/}"
  if [[ "$rel" == "books.v1.json" ]]; then
    out="$HADITH_DST/$rel"
  else
    out="$HADITH_DST/$rel.gz"
  fi
  if [[ "$MODE" == "--check" ]]; then
    if [[ "$out" == *.gz ]]; then
      if [[ ! -f "$out" ]] || ! gzip -dc "$out" | cmp -s - "$f"; then
        echo "stale: ${out#$APP/} (differs from content/hadith/dist/$rel)" >&2
        stale=1
      fi
    elif ! cmp -s "$f" "$out"; then
      echo "stale: ${out#$APP/} (differs from content/hadith/dist/$rel)" >&2
      stale=1
    fi
  else
    mkdir -p "$(dirname "$out")"
    if [[ "$out" == *.gz ]]; then gzip -9 -n -c "$f" >"$out"; else cp "$f" "$out"; fi
  fi
done < <(find "$HADITH_SRC" -type f -name '*.json' -print0 | sort -z)
if [[ "$MODE" == "--check" ]]; then
  n_src=$(find "$HADITH_SRC" -type f -name '*.json' | wc -l)
  n_dst=$(find "$HADITH_DST" -type f | wc -l)
  if [[ "$n_src" != "$n_dst" ]]; then
    echo "stale: assets/hadith has $n_dst files, content/hadith/dist has $n_src" >&2
    stale=1
  fi
else
  echo "compressed content/hadith/dist/ -> assets/hadith/ (gzip)"
fi

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
