#!/usr/bin/env python3
"""Builds content/quran/dist/mushaf-printed.v1.json: the line layout of the printed
Madinah Mushaf drawn with the King Fahd Complex page fonts (QCF v2, one font per page).
Input: the per-page word lists (glyph code + line number) saved in
content/quran/printed/pages.json.gz (from the quran.com v4 API, field code_v2).
The glyph codes are only drawing codes of the Complex's fonts: the Quran text itself
is not stored or changed here; ayah references link every word to quran.v1.json.
Output per page: 15 lines (8 on pages 1-2); a line is ["S", surah] (title band),
["B", surah] (basmala) or a list of words [surah, ayah, glyphs, end?]."""
import gzip, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pages = json.load(gzip.open(f'{ROOT}/content/quran/printed/pages.json.gz', 'rt', encoding='utf-8'))
out_pages, problems = [], []
raw_rows = []
for p in range(1, 605):
    verses = pages[str(p)]
    lines = {}
    for v in verses:
        s, a = map(int, v['verse_key'].split(':'))
        for w in v['words']:
            lines.setdefault(w['line_number'], []).append([s, a, w['code_v2'], 1 if w['char_type_name'] == 'end' else 0])
    total = 8 if p <= 2 else 15
    rows = [None] * total
    for ln, ws in lines.items():
        rows[ln - 1] = ws
    raw_rows.append(rows)

# Empty lines are surah title bands / basmala lines of the surah that starts after them. A title band
# can close a page (its basmala then opens the next page).
for idx, rows in enumerate(raw_rows):
    p = idx + 1
    total = len(rows)
    ended_with_band = idx > 0 and out_pages[idx - 1][-1][0] == 'S'
    i = 0
    while i < total:
        if rows[i] is not None:
            i += 1
            continue
        j = i
        while j < total and rows[j] is None:
            j += 1
        if j == total:
            # trailing: the title band of the surah that starts on the next page
            nxt = raw_rows[idx + 1]
            first = next(r for r in nxt if r is not None)[0]
            if j - i != 1 or first[1] != 1:
                problems.append(f'page {p}: {j - i} empty lines at the end')
            rows[i] = ['S', first[0]]
            break
        s, a = rows[j][0][0], rows[j][0][1]
        if a != 1:
            problems.append(f'page {p}: empty lines before {s}:{a}')
        run = j - i
        if i == 0 and ended_with_band and run == 1:
            kinds = ['B']
        elif s in (1, 9):
            kinds = ['S'] if run == 1 else None
        else:
            kinds = ['S', 'B'] if run == 2 else None
        if kinds is None:
            problems.append(f'page {p}: {run} empty lines before surah {s}')
            kinds = ['S'] * run
        for k, kind in enumerate(kinds):
            rows[i + k] = [kind, s]
        i = j
    out_pages.append(rows)
if problems:
    print('\n'.join(problems))
    sys.exit(1)
out = {
    'schema': 'mushaf-printed.v1',
    'layout': 'Madinah Mushaf, King Fahd Complex page fonts (QCF v2), 15 lines',
    'fontUrl': 'https://static.qurancdn.com/fonts/quran/hafs/v2/ttf/p{page}.ttf',
    'webFontUrl': 'https://static.qurancdn.com/fonts/quran/hafs/v2/woff2/p{page}.woff2',
    'pages': out_pages,
}
txt = json.dumps(out, ensure_ascii=False, separators=(',', ':'))
os.makedirs(f'{ROOT}/content/quran/dist', exist_ok=True)
for p in ('content/quran/dist/mushaf-printed.v1.json', 'apps/mobile/assets/content/mushaf-printed.v1.json'):
    open(f'{ROOT}/{p}', 'w', encoding='utf-8').write(txt)
print('mushaf-printed.v1.json', len(txt), 'bytes')
