#!/usr/bin/env python3
"""Builds content/kids/dist/teacher-timings.v1.json for the interactive «المصحف المعلّم» (owner 2026-11-20):
for the two teaching recitations (al-Husary al-Mu'allim, al-Minshawi with children repeating), where every
ayah and every word starts and ends inside the one-file-per-surah recording, so the kids' Mushaf can light up
the word being read and play a single ayah.

Source: Quran.com API (api.quran.com/api/qdc/audio/reciters/{id}/audio_files?chapter=S&segments=true),
recordings on download.quranicaudio.com/qdc (the files that API points to). Word positions are Quran.com's;
they match the KFGQPC v18 words split on spaces (checked here) except a rub el-hizb mark «۞», which KFGQPC
writes as its own space-separated token and Quran.com glues to the next word — the script maps it.
Usage (repo root): python3 -I tools/kids_teacher_timings.py CACHE_DIR
"""
import json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = sys.argv[1] if len(sys.argv) > 1 else '/tmp/teacher-timings'
os.makedirs(CACHE, exist_ok=True)
kids = json.load(open(f'{ROOT}/content/kids/kids.json', encoding='utf-8'))
quran = json.load(open(f'{ROOT}/content/quran/upstream/kfgqpc-hafs-v18.json', encoding='utf-8'))
DIGITS = re.compile(r'^[٠-٩]+$')

def words(s, a):
    t = next(x['aya_text'] for x in quran if x['sora'] == s and x['aya_no'] == a)
    return [w for w in t.replace('\xa0', ' ').split() if not DIGITS.match(w)]

# kids.json reciter folder -> Quran.com qdc reciter id
QDC = {'Husary_Muallim_128kbps': 12, 'Minshawy_Teacher_128kbps': 168}

def fetch(rid, s):
    p = f'{CACHE}/{rid}-{s}.json'
    if not os.path.exists(p):
        u = f'https://api.quran.com/api/qdc/audio/reciters/{rid}/audio_files?chapter={s}&segments=true'
        open(p, 'wb').write(subprocess.check_output(['curl', '-sf', u]))
    return json.load(open(p))['audio_files'][0]

out = {'_doc': __doc__.strip().split('\n')[0], 'word': 'https://audio.qurancdn.com/wbw/{sss}_{aaa}_{www}.mp3', 'reciters': {}}
problems = []
for folder in kids['teacher']['reciters']:
    rid = QDC[folder]
    rec = {'url': None, 'surahs': {}}
    for s in kids['teacher']['surahs']:
        f = fetch(rid, s)
        url = f['audio_url']
        num = re.search(r'/(\d+)\.mp3$', url).group(1)
        if int(num) != s:
            sys.exit(f'{folder} {s}: file {url}')
        tmpl = url[: -len(num) - 4] + ('{sss}' if len(num) == 3 and s < 100 else '{s}') + '.mp3'
        if s >= 100:
            tmpl = rec['url'] or tmpl
        if rec['url'] is None:
            rec['url'] = tmpl
        elif rec['url'] != tmpl:
            sys.exit(f'{folder} {s}: different url pattern {url}')
        ayahs = []
        vt = f['verse_timings']
        for i, v in enumerate(vt):
            a = int(v['verse_key'].split(':')[1])
            if a != i + 1:
                sys.exit(f'{folder} {s}: verse order {v["verse_key"]}')
            ws = words(s, a)
            # KFGQPC token index for each Quran.com word position («۞» token is skipped -> next word)
            pos = [k for k, w in enumerate(ws) if w != '۞']
            lo, hi = v['timestamp_from'], v['timestamp_to']
            if lo is None:  # one gap in the published data (Minshawi 101:3): fill from the neighbours
                lo = vt[i - 1]['timestamp_to'] if i else 0
            if hi is None:
                hi = vt[i + 1]['timestamp_from'] if i + 1 < len(vt) else f.get('duration') or lo
                problems.append(f'{folder} {s}:{a} ayah bounds filled from neighbours')
            segs = []
            raw = [x for x in (v.get('segments') or []) if len(x) >= 2]
            for j, x in enumerate(raw):
                w = int(x[0])
                if w < 1 or w > len(pos):
                    continue  # the ayah-number «word» some recitations carry
                st = float(x[1])
                en = float(x[2]) if len(x) > 2 else (float(raw[j + 1][1]) if j + 1 < len(raw) else hi)
                if en < lo - 50:  # a segment list relative to the ayah, not the file
                    st += lo; en += lo
                elif st < lo - 50:  # a first word published as starting at 0
                    st = lo
                st, en = max(st, lo), min(en, hi)
                if en <= st:
                    continue
                if segs and st < segs[-1][1]:
                    st = segs[-1][1]
                    if en <= st:
                        continue
                segs.append([pos[w - 1], round(st), round(en)])
            if not segs:
                problems.append(f'{folder} {s}:{a} no word timings')
            ayahs.append([lo, hi, segs])
        if len(ayahs) != sum(1 for x in quran if x['sora'] == s):
            sys.exit(f'{folder} {s}: ayah count')
        rec['surahs'][str(s)] = ayahs
    out['reciters'][folder] = rec

os.makedirs(f'{ROOT}/content/kids/dist', exist_ok=True)
for p in (f'{ROOT}/content/kids/dist/teacher-timings.v1.json', f'{ROOT}/apps/mobile/assets/content/teacher-timings.v1.json'):
    with open(p, 'w', encoding='utf-8') as fh:
        json.dump(out, fh, ensure_ascii=False, separators=(',', ':'))
print('ok', {k: len(v['surahs']) for k, v in out['reciters'].items()}, 'problems', len(problems))
for p in problems[:30]:
    print(' ', p)
