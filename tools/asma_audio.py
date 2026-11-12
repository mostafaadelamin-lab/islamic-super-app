#!/usr/bin/env python3
"""Links each name in asma.v1.json to Sheikh Muhammad Ratib al-Nabulsi's lessons on that name
(series أسماء الله الحسنى 2008, two parts per name; catalogue content/asma/nabulsi-2008.json; names it
lacks come from his 1996 series, one lesson each, content/asma/nabulsi-1996.json;
fetched from the sheikh's site). Names with no lesson in the series get no audio.
Usage: asma_audio.py  -> content/asma/dist/asma-audio.v1.json"""
import json, re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
cat = json.loads((root / 'content/asma/nabulsi-2008.json').read_text(encoding='utf-8'))
names = json.loads((root / 'apps/mobile/assets/content/asma.v1.json').read_text(encoding='utf-8'))['names']


def norm(s):
    s = re.sub('[ً-ْـ]', '', s)
    return s.translate(str.maketrans('أإآىة', 'ااايه')).strip()


lessons = {}
for r in cat['lessons']:
    m = re.match(r'اسم الله\s+(\S+)', r['title'])
    if not m: continue
    lessons.setdefault(norm(m[1]), {})[r['part']] = r['mp3']
for r in json.loads((root / 'content/asma/nabulsi-1996.json').read_text(encoding='utf-8'))['lessons']:
    lessons.setdefault(norm(r.get('for') or r['title'].removeprefix('اسم الله ')), {1: r['mp3']})  # 2008 series first
out, missing = {}, []
for i, n in enumerate(names):
    parts = lessons.get(norm(n['name']))
    if parts: out[str(i)] = [parts[p] for p in sorted(parts)]
    else: missing.append(n['name'])
dist = root / 'content/asma/dist'
dist.mkdir(exist_ok=True)
(dist / 'asma-audio.v1.json').write_text(json.dumps({'version': 1, 'sheikh': 'محمد راتب النابلسي', 'names': out},
                                                    ensure_ascii=False, separators=(',', ':')))
print(f'{len(out)}/{len(names)} names have lessons; without: {"، ".join(missing)}')
