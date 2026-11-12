"""Builds content/sharawi/dist/sharawi.v1.json: Sheikh Muhammad Mutawalli al-Sha'rawi's
audio tafsir (khawatir), 1116 lessons ordered by surah, each with the ayah range
it explains (from the file name). Input = the archive.org item metadata saved in
the owner's browser (content/sharawi/raw/archive-metadata.json); the container
cannot reach archive.org. Audio is streamed or downloaded per lesson by the app,
never bundled. Source is recorded in docs/CONTENT_SOURCES.md only.

usage: python3 tools/sharawi_build.py content/sharawi/raw/archive-metadata.json content/sharawi/dist/sharawi.v1.json
       apps/mobile/tool/sync_assets.sh   (copies it into the app)
"""
import json, re, sys
from urllib.parse import quote

ITEM = '20240104_20240104_0645'
RANGE = re.compile(r'\((\d{3})_(\d{3})(?:-\d)?\)(?:_\d)?\.mp3$')
INDEXED = re.compile(r'_(\d{3})\.mp3$')
SEQ = re.compile(r'^(\d{4})-')


QURAN = 'content/quran/dist/quran.v1.json'


def build(meta, ayah_counts):
    surahs, top = {}, None
    for f in meta['files']:
        parts = f['n'].split('/')
        name = parts[-1]
        surah = int(parts[1][:3])
        seq = int(SEQ.match(name).group(1))
        top = parts[0]
        lesson = {'id': seq, 'p': '/'.join(parts[1:]), 'b': int(f['s']), 's': round(f['l'] or 0)}
        m = RANGE.search(name)
        if m:
            # One file name overruns its surah (Saba "(052_059)", Saba has 54 ayahs): clamp to the surah.
            last = ayah_counts[surah - 1]
            lesson['f'], lesson['t'] = min(int(m.group(1)), last), min(int(m.group(2)), last)
        elif surah != 0 and not INDEXED.search(name):
            raise SystemExit(f'unrecognised lesson name: {name}')
        surahs.setdefault(surah, []).append(lesson)
    out = []
    for n in sorted(surahs):
        # A long passage spans several lessons with the same range ("(054_054-2)").
        out.append({'n': n, 'lessons': sorted(surahs[n], key=lambda x: x['id'])})
    return {
        'version': 1,
        # Lesson URL = base + each segment of p, percent-encoded.
        'base': f'https://archive.org/download/{ITEM}/{quote(top)}/',
        'surahs': out,
    }


if __name__ == '__main__':
    src, dst = sys.argv[1:3]
    meta = json.load(open(src))
    meta = json.loads(meta) if isinstance(meta, str) else meta
    counts = [len(x['ayahs']) for x in json.load(open(QURAN))['surahs']]
    data = build(meta, counts)
    json.dump(data, open(dst, 'w'), ensure_ascii=False, separators=(',', ':'))
    n = sum(len(s['lessons']) for s in data['surahs'])
    hours = sum(l['s'] for s in data['surahs'] for l in s['lessons']) / 3600
    print('surahs', len(data['surahs']) - 1, 'lessons', n, 'hours', round(hours))
