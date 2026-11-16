"""Builds content/shabib/dist/shabib.v1.json: Sheikh Mohamed Ahmed Shabib's recitations
(owner 2026-11-16). No complete 114-surah recording of the sheikh exists, so the app and
the website get his own section in the recitation library: the murattal surahs that exist
(Hafs, several are partial) and his mujawwad recitations (live, Quran al-Fajr, radio).

Input content/shabib/shabib.src.json = the hand-checked track list (surahs per file read
from each file name). Audio is streamed or saved per track, never bundled. Sources are
recorded in docs/CONTENT_SOURCES.md only, never shown in the app or on the site.

usage: python3 tools/shabib_build.py   (then apps/mobile/tool/sync_assets.sh)
"""
import hashlib
import json
from urllib.parse import quote

SRC = 'content/shabib/shabib.src.json'
DST = 'content/shabib/dist/shabib.v1.json'
TAGS = {'', 'fajr', 'radio', 'oct73', 'short'}


def build(src):
    m, j = src['murattal'], src['mujawwad']
    murattal = []
    for t in m['tracks']:
        murattal.append({
            'id': 'm%d' % t['surahs'][0],
            'surahs': t['surahs'],
            'part': t['part'],
            'url': m['base'] + t['p'],
            's': round(t['b'] * 8 / m['bitrate']),
        })
    mujawwad = []
    for t in sorted(j['tracks'], key=lambda t: (t['surahs'] or [200], t['s'])):
        assert t['tag'] in TAGS, t
        assert t['surahs'] or t['tag'] == 'short', t
        assert all(1 <= n <= 114 for n in t['surahs']), t
        x = {'id': 'j' + hashlib.sha1(t['file'].encode()).hexdigest()[:8], 'surahs': t['surahs'], 'url': j['base'] + quote(t['file']), 's': t['s']}
        if t['tag']:
            x['tag'] = t['tag']
        if t.get('year') and t['tag'] != 'oct73':
            x['year'] = t['year']
        mujawwad.append(x)
    assert len({x['id'] for x in mujawwad}) == len(mujawwad)
    return {'version': 1, 'murattal': murattal, 'mujawwad': mujawwad}


if __name__ == '__main__':
    data = build(json.load(open(SRC)))
    json.dump(data, open(DST, 'w'), ensure_ascii=False, separators=(',', ':'))
    h = sum(x['s'] for k in ('murattal', 'mujawwad') for x in data[k]) / 3600
    print('murattal', len(data['murattal']), 'mujawwad', len(data['mujawwad']), 'hours', round(h, 1))
