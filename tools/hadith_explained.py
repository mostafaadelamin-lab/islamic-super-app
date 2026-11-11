"""Links the simplified explanations of the published hadith encyclopedia
(HadeethEnc, Arabic) to the hadiths of the nine books shipped in the app, by
matching the Prophet's words (the «...» part) word for word.
usage: hadith_explained.py <hadeethenc.json> <apps/mobile/assets/hadith> <out.json>"""
import glob, json, os, re, sys

src, root, out = sys.argv[1:4]
enc = json.load(open(src)); enc = json.loads(enc) if isinstance(enc, str) else enc
enc = list(enc.values()) if isinstance(enc, dict) else enc

def norm(s):
    s = re.sub(r'[ؐ-ًؚ-ٰٟۖ-ۭـ‌-‏]', '', s)
    s = re.sub('[أإآٱ]', 'ا', s).replace('ى', 'ي').replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    return re.sub(r'[^ء-ي]+', ' ', s).split()

N = 4
def grams(words):
    return {' '.join(words[i:i + N]) for i in range(len(words) - N + 1)}

index, texts = {}, {}
for f in glob.glob(os.path.join(root, '*', '*.json')):
    j = json.load(open(f))
    for k, t in enumerate(j['ahadith']):
        key = f"{j['book']}:{j['from'] + k}"
        g = grams(norm(t))
        texts[key] = g
        for x in g:
            index.setdefault(x, []).append(key)

entries, mapping = {}, {}
for h in enc:
    quotes = re.findall(r'«([^»]+)»', h['hadeeth']) or [h['hadeeth']]
    g = grams(norm(' '.join(quotes)))
    if len(g) < 3:
        continue
    counts = {}
    for x in g:
        lst = index.get(x, ())
        if len(lst) > 400:  # very common phrase: no signal
            continue
        for key in lst:
            counts[key] = counts.get(key, 0) + 1
    hits = [k for k, c in counts.items() if c / len(g) >= 0.6]
    if not hits:
        continue
    eid = str(h['id'])
    entries[eid] = {k: h[k] for k in ('title', 'attribution', 'grade', 'explanation', 'hints')}
    for k in hits:
        prev = mapping.get(k)
        if prev is None or counts[k] / len(g) > prev[1]:
            mapping[k] = (eid, counts[k] / len(g))

json.dump({'version': 1, 'entries': entries, 'map': {k: v[0] for k, v in sorted(mapping.items())}},
          open(out, 'w'), ensure_ascii=False, separators=(',', ':'))
by = {}
for k in mapping:
    by[k.split(':')[0]] = by.get(k.split(':')[0], 0) + 1
print('encyclopedia', len(enc), 'matched', len(entries), 'linked hadiths', len(mapping), by, os.path.getsize(out) // 1024, 'KB')
