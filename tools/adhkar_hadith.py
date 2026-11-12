"""Morning/evening adhkar: the hadith, its virtue (fadl) and its source come
verbatim from the Seen-Arabic Morning-And-Evening-Adhkar-DB (MIT,
content/adhkar/seen-adhkar-ar.json), which lists the same 34 items in the same
order. Hisn al-Muslim items: linked to the hadith (morning/evening list and Hisn al-Muslim items) to the hadith
it comes from in the published hadith encyclopedia (HadeethEnc, Arabic): the
hadith text with its narrator, where it is reported (attribution) and its grade,
all quoted verbatim. A dhikr is linked when most of its words (4-word runs)
appear in the hadith text.
usage: adhkar_hadith.py content/hadith/hadeethenc-ar.json content/adhkar content/adhkar/dist/adhkar-hadith.v1.json"""
import json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from fix_tanween import walk  # tanween on the letter before the alif (owner, 2026-11-12)

src, adir, out = sys.argv[1:4]
enc = json.load(open(src)); enc = json.loads(enc) if isinstance(enc, str) else enc
enc = list(enc.values()) if isinstance(enc, dict) else enc

def norm(s):
    s = re.sub(r'[ؐ-ًؚ-ٰٟۖ-ۭـ‌-‏]', '', s)
    s = re.sub('[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    return re.sub(r'[^ء-ي]+', ' ', s).split()

N = 4
def grams(w):
    return {' '.join(w[i:i + N]) for i in range(len(w) - N + 1)}

index = {}
for k, h in enumerate(enc):
    for g in grams(norm(h['hadeeth'])):
        index.setdefault(g, set()).add(k)

def best(text):
    # drop the counts in brackets and the isti'adha before verses
    t = re.sub(r'\([^)]*مر[ةا][^)]*\)', ' ', text)
    g = grams(norm(t))
    if len(g) < 3:
        return None
    c = {}
    for x in g:
        for k in index.get(x, ()):
            c[k] = c.get(k, 0) + 1
    if not c:
        return None
    k, n = max(c.items(), key=lambda kv: kv[1])
    return k if n / len(g) >= 0.6 else None

used, links = {}, {'adhkar': {}, 'hisn': {}}
items = json.load(open(f'{adir}/adhkar.json'))
seen = json.load(open(f'{adir}/seen-adhkar-ar.json'))['items']
assert len(seen) == len(items)
for i, x in enumerate(seen):
    assert norm(x['content'])[:5] == norm(items[i])[:5], i
    e = {'hadith': x.get('hadith_text') or None, 'fadl': x.get('fadl') or None, 'source': x.get('source') or None}
    if any(e.values()):
        links['adhkar'][str(i)] = {k: v.strip() for k, v in e.items() if v}
for ci, (title, chapter) in enumerate(json.load(open(f'{adir}/hisn.json'))):
    for ii, t in enumerate(chapter):
        k = best(t)
        if k is not None:
            h = enc[k]
            src = ' — '.join(x for x in (h.get('attribution'), h.get('grade')) if x)
            links['hisn'][f'{ci}:{ii}'] = {'hadith': h['hadeeth'].strip(), **({'source': src} if src else {})}
json.dump(walk({'version': 1, **links}), open(out, 'w'), ensure_ascii=False, separators=(',', ':'))
print('adhkar', len(links['adhkar']), '/', len(items), 'hisn', len(links['hisn']))
