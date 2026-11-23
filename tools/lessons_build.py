"""Builds content/lessons/dist/lessons.v1.json: the «سلاسل الدروس» audio lesson series
(owner-approved list in content/lessons/sources.json). Each series is one or more archive.org
items; their file lists are cached in content/lessons/raw/<item>.json (--fetch refreshes them).
Audio is streamed or downloaded per lesson by the app and the website, never bundled.
Sources are recorded in docs/CONTENT_SOURCES.md only, never shown in the app.

usage: python3 tools/lessons_build.py [--fetch]
"""
import json, re, sys, urllib.request
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'content/lessons/sources.json'
RAW = ROOT / 'content/lessons/raw'
DST = ROOT / 'content/lessons/dist/lessons.v1.json'


def fetch(item):
    d = json.load(urllib.request.urlopen(f'https://archive.org/metadata/{item}', timeout=60))
    keep = ('name', 'source', 'format', 'size', 'length', 'title', 'original')
    files = [{k: f[k] for k in keep if k in f} for f in d.get('files', []) if f['name'].lower().endswith('.mp3')]
    return {'item': item, 'files': files}


def natkey(s):
    return [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', s)]


def seconds(v):
    if v is None:
        return 0
    v = str(v)
    if ':' in v:
        t = 0
        for p in v.split(':'):
            t = t * 60 + float(p)
        return round(t)
    try:
        return round(float(v))
    except ValueError:
        return 0


def pick(files):
    orig = [f for f in files if f.get('source') == 'original']
    if orig:
        return orig
    # Only derivatives: one per original, best quality first.
    best = {}
    for f in files:
        k = f.get('original', f['name'])
        rank = 0 if 'VBR' in f.get('format', '') else 1
        if k not in best or rank < best[k][0]:
            best[k] = (rank, f)
    return [f for _, f in best.values()]


def norm(s):
    return re.sub('[أإآ]', 'ا', s)


LATIN = re.compile(r'[A-Za-z][A-Za-z0-9_.\-]*')


def clean(name, words):
    s = name.rsplit('/', 1)[-1]
    s = re.sub(r'\.mp3$', '', s, flags=re.I)
    s = LATIN.sub(' ', s)
    s = re.sub(r'ح\s*\d{2,}|\sح\d$', ' ', s)
    s = s.replace('ـ', '')
    for w in words:
        s = s.replace(w, ' ')
    s = re.sub(r'^[\s\d\-_.()]+', '', s)
    s = re.sub(r'^الحلقة\s*\d+\s*', '', s)
    s = re.sub(r'[\s_\-]+$', '', s)
    s = re.sub(r'\s+', ' ', s).strip(' -_.')
    return s or None


def build(src, refetch=False):
    sheikhs = {s['id']: s for s in src['sheikhs']}
    topics = {t['id'] for t in src['topics']}
    out = []
    for se in src['series']:
        assert se['topic'] in topics and se['sheikh'] in sheikhs, se['id']
        eps = []
        for item in se['items']:
            p = RAW / f'{item}.json'
            if refetch or not p.exists():
                p.write_text(json.dumps(fetch(item), ensure_ascii=False, indent=0))
            files = pick(json.loads(p.read_text())['files'])
            if se.get('sort') == 'lex':
                # Two runs of numbers ("001a".."014b" = part 1, "01a".."26b" = part 2): plain text order.
                files.sort(key=lambda f: f['name'])
            else:
                files.sort(key=lambda f: natkey(f['name']))
            if 'order' in se:
                # Listed order (e.g. prophets in their historical order); file order within each entry.
                def rank(f):
                    t = norm(f.get('title') or f['name'])
                    for i, k in enumerate(se['order']):
                        if norm(k) in t:
                            return i
                    raise SystemExit(f'{se["id"]}: no order entry for {f["name"]}')
                files.sort(key=rank)
            base = f'https://archive.org/download/{quote(item)}/'
            words = [sheikhs[se['sheikh']]['ar'].replace('الشيخ ', ''), se['ar'], 'برنامج', 'للشيخ', 'مع الشيخ', 'الشيخ', 'سلسلة']
            for f in files:
                ep = {'u': base + '/'.join(quote(x) for x in f['name'].split('/')), 's': seconds(f.get('length')), 'b': int(f.get('size') or 0)}
                mode = se.get('titles')
                t = None
                if mode == 'name':
                    t = clean(f['name'], words)
                elif mode == 'title':
                    t = clean(f.get('title') or '', [])
                if t:
                    ep['t'] = t
                eps.append(ep)
        if not eps:
            raise SystemExit(f'no audio in {se["id"]}')
        out.append({k: se[k] for k in ('id', 'topic', 'sheikh', 'ar', 'en')} | {'episodes': eps})
    return {
        'version': 1,
        'topics': src['topics'],
        'groups': src['groups'],
        'sheikhs': src['sheikhs'],
        'series': out,
    }


if __name__ == '__main__':
    src = json.loads(SRC.read_text())
    data = build(src, '--fetch' in sys.argv)
    DST.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')))
    n = sum(len(s['episodes']) for s in data['series'])
    h = sum(e['s'] for s in data['series'] for e in s['episodes']) / 3600
    print('series', len(data['series']), 'lessons', n, 'hours', round(h), 'bytes', DST.stat().st_size)
