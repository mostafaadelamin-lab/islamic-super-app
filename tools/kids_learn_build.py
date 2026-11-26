"""Builds the kids learning corner (assets/content/kids-learn.v1.json) from content/kids/learn/.
Hadith text is COPIED from hadith600.json (extracted unchanged from the published book's PDF text layer
by tools/kids_hadith600/), never typed here. Book pages are the published pages themselves;
wudu/salah steps are the book's text with our own 3D pictures (tools/kids_steps_3d/). Sources: docs/CONTENT_SOURCES.md."""
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
# Adhkar cards as text (owner 2026-11-21): copied from the cards book's own PDF text layer by
# tools/kids_cards/extract_cards.py (content/kids/learn/card-adhkar.extracted.json), never typed here.
# The repeat counts come from each card's own note, e.g. «ثلاث مرات في الصباح ، و ثلاث في المساء».
NUM = {'مرة واحدة': 1, 'ثلاث': 3, 'أربع': 4, 'عشر': 10, 'مائة': 100}
def count(note, part):
    seg = [x for x in re.split(r'،\s*و', note) if part in x]
    if not seg:
        return 0
    for word, n in NUM.items():
        if word in seg[0]:
            return n
    raise AssertionError(note)
cards_src = json.load(open(f'{ROOT}/content/kids/learn/card-adhkar.extracted.json', encoding='utf-8'))
adhkar = json.load(open(f'{ROOT}/content/adhkar/dist/adhkar.v1.json', encoding='utf-8'))['items']
assert [c['n'] for c in cards_src] == list(range(1, 20)), 'card numbering'
card_adhkar = []
for c in cards_src:
    assert not re.search(r'[\ue000-\uf8ff]', c['text']) and unicodedata.normalize('NFC', c['text']) == c['text'], c['n']
    e = {'n': c['n'], 'card': c['card'], 'text': c['text'], 'note': c['note'],
         'm': count(c['note'], 'الصباح'), 'e': count(c['note'], 'المساء')}
    assert e['m'] or e['e'], c
    if c['n'] == 14:  # «قل هو الله أحد والمعوذتين»: the three surahs, as in the app's Hisn al-Muslim adhkar
        e['surahs'] = adhkar[3:6]
        assert all(t.startswith('قُلْ') for t in e['surahs'])
    card_adhkar.append(e)
# Wudu / salah steps (owner 2026-11-21): the book's own title and text per page + our own 3D picture.
steps = json.load(open(f'{ROOT}/content/kids/learn/steps.json', encoding='utf-8'))
kursi = re.search(r'﴿[^﴾]+﴾', adhkar[1]).group(0)
assert 'الْقَيُّومُ' in kursi
def step(e):
    assert e['title'] and e['text'] and unicodedata.normalize('NFC', e['text']) == e['text'], e
    o = {'title': e['title'], 'text': e['text']}
    if e.get('pic'):
        assert os.path.exists(f"{ROOT}/apps/mobile/assets/kids/steps/{e['pic']}.webp"), e['pic']
        o['pic'] = e['pic']
    if e.get('ayatAlKursi'):
        o['ayah'] = kursi
    return o
# Pillars of Islam / Iman (owner 2026-11-26): every text comes from HadeethEnc (the hadith and verbatim pieces of
# its published explanation), cut here by the `part` rule of each entry; nothing is typed. Titles are short labels.
HE = {h['id']: h for h in json.load(open(f'{ROOT}/content/hadith/hadeethenc-ar.json', encoding='utf-8'))}
def lead_waw(s):
    return s[1:] if s.startswith('و') else s
def pillar_text(e):
    h = HE[e['he']]
    part = e['part']
    lines = [x.strip() for x in h['explanation'].split('\n') if x.strip()]
    if part.startswith('hadith'):
        txt = f"{h['hadeeth']} ({h['attribution']})"
        if '+line:' in part:
            extra = lines[int(part.split('+line:')[1])].rstrip('،').strip() + '.'
            txt += '\n\n' + extra
        return txt
    if part.startswith('line:'):
        return lead_waw(lines[int(part[5:])])
    if part == 'iman-hadith':
        had = h['hadeeth']
        a = had.index('فَأَخْبِرْنِي عَنِ الْإِيمَانِ')
        b = had.index('»', a) + 1
        head = had[:had.index(':') + 1]
        assert head == 'عن عمر بن الخطاب رضي الله عنه قال:', head
        return f"{head} … {had[a:b]} ({h['attribution']})"
    if part.startswith('span:'):
        start, end = part[5:].split('|')
        ex = h['explanation']
        a = ex.index(start)
        b = ex.index(end, a + len(start))
        return ex[a:b].strip().rstrip('،.') + '.'
    raise AssertionError(part)
def pillar(e):
    o = {'title': e['title'], 'text': pillar_text(e)}
    if e.get('pic'):
        assert os.path.exists(f"{ROOT}/apps/mobile/assets/kids/steps/{e['pic']}.webp"), e['pic']
        o['pic'] = e['pic']
    return o
out = {
    'schema': 'kids-learn.v1',
    'booksBase': src['booksBase'],
    'shelves': src['shelves'],
    'books': [{k: b[k] for k in ('id', 'shelf', 'title', 'author', 'pages')} for b in src['books']],
    'hadithLevels': levels,
    'hadith': [h['text'] for h in had],
    'wudu': [step(e) for e in steps['wudu']],
    'salah': [step(e) for e in steps['salah']],
    'islam': [pillar(e) for e in steps['islam']],
    'iman': [pillar(e) for e in steps['iman']],
    'stepsCredit': src['stepsCredit'],
    'cardAdhkar': card_adhkar,
}
s = json.dumps(out, ensure_ascii=False, separators=(',', ':'))
for p in ('content/kids/dist/kids-learn.v1.json', 'apps/mobile/assets/content/kids-learn.v1.json'):
    open(f'{ROOT}/{p}', 'w', encoding='utf-8').write(s)
print('kids-learn.v1:', len(out['books']), 'books,', len(out['hadith']), 'hadith,', len(s) // 1024, 'KB')
