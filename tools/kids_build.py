#!/usr/bin/env python3
"""Builds the kids section + ruqyah list (assets/content/kids.v1.json) from
content/kids/kids.json. Religious text is COPIED from files already in the repo
(Hisn al-Muslim: content/adhkar/hisn.json, HadeethEnc: content/hadith/hadeethenc-ar.json);
Quran passages stay references (the app reads them from the KFGQPC text).
File sizes/lengths come from the archive.org metadata snapshots in content/kids/raw/."""
import json, os, re, sys, urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = json.load(open(f'{ROOT}/content/kids/kids.json', encoding='utf-8'))
hisn = json.load(open(f'{ROOT}/content/adhkar/hisn.json', encoding='utf-8'))
henc = {h['id']: h for h in json.load(open(f'{ROOT}/content/hadith/hadeethenc-ar.json', encoding='utf-8'))}
audio = json.load(open(f'{ROOT}/apps/mobile/assets/content/adhkar-audio.v1.json', encoding='utf-8'))
raw = {}
for f in os.listdir(f'{ROOT}/content/kids/raw'):
    d = json.load(open(f'{ROOT}/content/kids/raw/{f}', encoding='utf-8'))
    raw[d['identifier']] = {x['name']: x for x in d['files']}

def url(item, name):
    return 'https://archive.org/download/' + item + '/' + urllib.parse.quote(name)

def secs(v):
    v = str(v)
    if ':' in v:
        t = 0
        for part in v.split(':'):
            t = t * 60 + float(part)
        return round(t)
    return round(float(v))

def meta(item, name):
    f = raw[item].get(name)
    if f is None:
        sys.exit(f'missing in raw snapshot: {item}/{name}')
    return {'url': url(item, name), 'bytes': int(f['size']), 'seconds': secs(f['length'])}

def item(x):
    if 'quran' in x:
        s, a, b = x['quran']
        return {'t': 'q', 's': s, 'from': a, 'to': b, **({'repeat': x['repeat']} if 'repeat' in x else {})}
    if 'hadeethenc' in x:
        h = henc[x['hadeethenc']]
        m = re.findall(r'«([^»]+)»', h['hadeeth'])
        if len(m) == 0:
            sys.exit(f'no quoted dua in hadeethenc {x["hadeethenc"]}')
        text = m[-1].strip()
        return {'t': 'd', 'text': text, 'src': h['attribution'], 'repeat': x.get('repeat', 1)}
    if 'hisn' in x:
        c, i = x['hisn']
        text = hisn[c][1][i]
        a = audio['hisn'].get(f'{c}:{i}')
        out = {'t': 'd', 'text': text, 'src': x.get('src', ''), 'repeat': x.get('repeat', 1)}
        if a:
            out['audio'] = audio['base'].replace('{id}', str(a))
        return out
    sys.exit(f'bad item {x}')

AR = '٠١٢٣٤٥٦٧٨٩'
def ar(n): return ''.join(AR[int(c)] for c in str(n))

series = []
for s in src['series']:
    eps = []
    for k, e in enumerate(s['episodes']):
        if 'youtube' in e:
            # Published YouTube series (owner 2026-11-20), checked frame by frame: no prophet's face shown.
            eps.append({'id': f'{s["id"]}-{k + 1}', 'title': e['title'], 'youtube': e['youtube'],
                        'url': 'https://www.youtube.com/watch?v=' + e['youtube'], 'seconds': e['seconds']})
            continue
        it = e.get('archive', s.get('archive'))
        if s['id'] == 'kids-prophets':
            title = f'قصة سيدنا {e["prophet"]} عليه السلام ({ar(e["part"])})'
        elif s['id'] == 'kids-rasoul':
            title = f'الحلقة {ar(e["n"])}' + (f': {e["title"]}' if 'title' in e else '')
        else:
            title = e['title']
        eps.append({'id': f'{s["id"]}-{k + 1}', 'title': title, **meta(it, e['file'])})
    series.append({'id': s['id'], 'group': s['group'], 'episodes': eps})

full = src['ruqyah']['full']
out = {
    'schema': 'kids.v1',
    'quranAudio': f'https://everyayah.com/data/{src["quranReciter"]}/{{sss}}{{aaa}}.mp3',
    'ruqyah': {'items': [item(x) for x in src['ruqyah']['items']], 'full': meta(full['archive'], full['file'])},
    'ruqyahKids': {'items': [item(x) for x in src['ruqyahKids']['items']]},
    'teacher': src['teacher'],
    'series': series,
}
txt = json.dumps(out, ensure_ascii=False, separators=(',', ':'))
for p in ('content/kids/dist/kids.v1.json', 'apps/mobile/assets/content/kids.v1.json'):
    os.makedirs(os.path.dirname(f'{ROOT}/{p}'), exist_ok=True)
    open(f'{ROOT}/{p}', 'w', encoding='utf-8').write(txt)
print('kids.v1.json', len(txt), 'bytes;', sum(len(s['episodes']) for s in series), 'episodes')
