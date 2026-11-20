"""Builds the kids learning corner (assets/content/kids-learn.v1.json) from content/kids/learn/.
Hadith text is COPIED from hadith600.json (extracted unchanged from the published book's PDF text layer
by tools/kids_hadith600/), never typed here. Pictures (cards, wudu/salah steps, book pages) are the
published pages themselves. Sources: docs/CONTENT_SOURCES.md."""
import json, os, re, unicodedata
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = json.load(open(f'{ROOT}/content/kids/learn/learn.json', encoding='utf-8'))
had = json.load(open(f'{ROOT}/content/kids/learn/hadith600.json', encoding='utf-8'))
assert [h['n'] for h in had] == list(range(1, 601)), 'hadith numbering'
GRADE = re.compile(r'(متفق عليه|رواه البخاري|رواه مسلم|رواه مالك)$')
for h in had:
    assert GRADE.search(h['text']) or h['n'] == 334, h['n']  # 334 ends with the Bukhari variant wording
    assert not re.search(r'[-]', h['text']), h['n']
    assert unicodedata.normalize('NFC', h['text']) == h['text'], h['n']
levels = src['hadithLevels']
for lv in levels:
    assert all(lv['from'] <= h['n'] <= lv['to'] for h in had if h['level'] == lv['level']), lv
for b in src['books']:
    assert b['shelf'] in src['shelves'], b
out = {
    'schema': 'kids-learn.v1',
    'booksBase': src['booksBase'],
    'shelves': src['shelves'],
    'books': [{k: b[k] for k in ('id', 'shelf', 'title', 'author', 'pages')} for b in src['books']],
    'hadithLevels': levels,
    'hadith': [h['text'] for h in had],
    'wudu': src['wudu']['pages'],
    'salah': src['salah']['pages'],
    'stepsCredit': src['stepsCredit'],
    'cards': src['cards']['pages'],
}
s = json.dumps(out, ensure_ascii=False, separators=(',', ':'))
for p in ('content/kids/dist/kids-learn.v1.json', 'apps/mobile/assets/content/kids-learn.v1.json'):
    open(f'{ROOT}/{p}', 'w', encoding='utf-8').write(s)
print('kids-learn.v1:', len(out['books']), 'books,', len(out['hadith']), 'hadith,', len(s) // 1024, 'KB')
