"""Surah cards (owner, 2026-11-11: short "where it was revealed" + reasons for revelation).
Source: Quranpedia.net data dump surahs.json (version in output), "use inside apps needs no
attribution". Kept verbatim; HTML is turned into plain paragraphs. Output:
apps/mobile/assets/content/surah-info.v1.json  [{n, type, order, intro, purposes, asbab}]
Surahs without reasons in the cards get al-Wahidi's "Asbab Nuzul al-Quran" (Quranpedia book 2919),
per ayah, verbatim, as `wahidi: [{ayah, text}]`.
Usage: python3 tools/surah_info.py <surahs.json> [<asbab-book-2919.json>]"""
import json, re, sys, html, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = json.load(open(sys.argv[1]))
def text(v):
    if not isinstance(v, str): return ''
    v = re.sub(r'<br\s*/?>|</p>|\r?\n', '\n', v)
    v = re.sub(r'<[^>]+>', '', v)
    v = html.unescape(v).replace('\xa0', ' ')
    lines = [re.sub(r'[ \t]+', ' ', l).strip() for l in v.split('\n')]
    return '\n'.join(l for l in lines if l)
out = []
for x in src['data']:
    i = x['information']
    g = lambda k: text(i.get(k, {}).get('value', '')) if isinstance(i.get(k), dict) else ''
    out.append({'n': x['surah'], 'type': g('surah_type'), 'order': g('descent'), 'intro': g('introduction'),
                'purposes': g('purposes'), 'asbab': g('revelation')})
if len(sys.argv) > 2:
    w = json.load(open(sys.argv[2]))
    by = {}
    for a in w['ayahs']:
        t = '\n'.join(text(c.get('text', '')) for c in a.get('content', []))
        if t: by.setdefault(a['surah'], []).append({'ayah': a['ayah'], 'text': t})
    for o in out:
        if not o['asbab'] and o['n'] in by: o['wahidi'] = by[o['n']]
dst = root/'apps/mobile/assets/content/surah-info.v1.json'
dst.write_text(json.dumps({'source': 'quranpedia.net surahs.json', 'version': src['license'].get('version'), 'surahs': out}, ensure_ascii=False, separators=(',', ':')))
print(dst, dst.stat().st_size, sum(1 for o in out if o['asbab']), 'with asbab', sum(1 for o in out if o.get('wahidi')), 'wahidi', sum(1 for o in out if not o['asbab'] and not o.get('wahidi')), 'none')
