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
    if item.startswith('spreaker:'):
        return fetch_feed(item)
    d = json.load(urllib.request.urlopen(f'https://archive.org/metadata/{item}', timeout=60))
    keep = ('name', 'source', 'format', 'size', 'length', 'title', 'original')
    files = [{k: f[k] for k in keep if k in f} for f in d.get('files', []) if f['name'].lower().endswith('.mp3')]
    return {'item': item, 'title': d.get('metadata', {}).get('title'), 'files': files}


ITUNES = '{http://www.itunes.com/dtds/podcast-1.0.dtd}'


def fetch_feed(item):
    """An official podcast feed (e.g. the Grand Imam's Ramadan programmes): episodes in feed order."""
    import xml.etree.ElementTree as ET
    show = item.split(':', 1)[1]
    root = ET.fromstring(urllib.request.urlopen(f'https://www.spreaker.com/show/{show}/episodes/feed', timeout=60).read())
    files = []
    for it in root.find('channel').findall('item'):
        enc = it.find('enclosure')
        if enc is None:
            continue
        desc = re.sub(r'<[^>]+>', ' ', it.findtext('description') or '')
        files.append({'url': enc.get('url'), 'name': it.findtext('title') or '', 'source': 'original',
                      'size': enc.get('length'), 'length': it.findtext(ITUNES + 'duration'),
                      'desc': re.sub(r'\s+', ' ', desc).strip()})
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


MIN_EPISODE_SEC = 120
MAX_DESC_TITLE = 40
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
    # Music stretches the players jump over (tools/lessons_music.py), by audio URL.
    music_file = RAW.parent / 'music.json'
    music = json.loads(music_file.read_text()) if music_file.exists() else {}
    # Gain / clarity per series (tools/lessons_loudness.py).
    fx_file = RAW.parent / 'audio-fx.json'
    audio_fx = json.loads(fx_file.read_text()) if fx_file.exists() else {}
    sheikhs = {s['id']: s for s in src['sheikhs']}
    topics = {t['id'] for t in src['topics']}
    def series_list(entries):
        return [one(se) for se in entries]

    def one(se):
        assert se['topic'] in topics and se['sheikh'] in sheikhs, se['id']
        eps = []
        for item in se['items']:
            p = RAW / f"{item.replace(':', '-')}.json"
            if refetch or not p.exists():
                p.write_text(json.dumps(fetch(item), ensure_ascii=False, indent=0))
            raw = json.loads(p.read_text())
            files = pick(raw['files'])
            # Feeds keep their own order (reversed when newest comes first); trailers are dropped.
            if item.startswith('spreaker:'):
                files = [f for f in files if seconds(f.get('length')) >= MIN_EPISODE_SEC]
                if se.get('reverse'):
                    files.reverse()
            elif se.get('sort') == 'lex':
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
                url = f.get('url') or base + '/'.join(quote(x) for x in f['name'].split('/'))
                ep = {'u': url, 's': seconds(f.get('length')), 'b': int(f.get('size') or 0)}
                mode = se.get('titles')
                t = None
                if mode == 'name':
                    t = clean(f['name'], words)
                elif mode == 'title':
                    t = clean(f.get('title') or '', [])
                elif mode == 'desc':
                    # Short topic lines only ("الابتلاء"); long summaries are left out.
                    d = f.get('desc') or ''
                    t = d if 0 < len(d) <= MAX_DESC_TITLE else None
                elif mode == 'item':
                    # "001_ مقدمة وتعريف الطهارة _دورة شرح (...) _ م علاء حامد" -> "مقدمة وتعريف الطهارة"
                    t = clean(re.split(r'\s_|_\s', re.sub(r'^[\d\s\-_.]+', '', raw.get('title') or ''))[0], words)
                if t:
                    ep['t'] = t
                if url in music:
                    ep['m'] = music[url]
                eps.append(ep)
        if not eps:
            raise SystemExit(f'no audio in {se["id"]}')
        out = {k: se[k] for k in ('id', 'topic', 'sheikh', 'ar', 'en')}
        if se['id'] in audio_fx:
            out['fx'] = audio_fx[se['id']]
        return out | {'episodes': eps}

    out = series_list(src['series'])
    return {
        'version': 1,
        'topics': src['topics'],
        'groups': src['groups'],
        'sheikhs': src['sheikhs'],
        'series': out,
        # Shown inside the Sha'rawi section (seerah, prophets' stories), not in the lesson list.
        'sharawi': series_list(src.get('sharawi', [])),
        # His Quran tafsir (content/sharawi), summed for its card in the lesson list and his section.
        'sharawiTafsir': tafsir_summary(),
    }


def tafsir_summary():
    d = json.loads((ROOT / 'content/sharawi/dist/sharawi.v1.json').read_text())
    lessons = [x for s in d['surahs'] for x in s['lessons']]
    return {'id': 'sharawi-tafsir', 'topic': 'quran', 'sheikh': 'shaarawi', 'ar': 'تفسير القرآن الكريم',
            'en': 'Quran tafsir', 'n': len(lessons), 's': sum(x.get('s') or 0 for x in lessons)}


if __name__ == '__main__':
    src = json.loads(SRC.read_text())
    data = build(src, '--fetch' in sys.argv)
    DST.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')))
    n = sum(len(s['episodes']) for s in data['series'])
    h = sum(e['s'] for s in data['series'] for e in s['episodes']) / 3600
    print('series', len(data['series']), 'lessons', n, 'hours', round(h), 'bytes', DST.stat().st_size)
