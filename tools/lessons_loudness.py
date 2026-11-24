"""Measure how loud and how clear each lesson series is, so the players can even it out.

Owner 2026-11-24: some series are very quiet and some are old, muffled tapes («صوتها ضعيف جدا وقديم»);
keep them and improve the sound. The recordings stay as published; content/lessons/audio-fx.json gives each
series that needs it:
  g  gain in dB toward TARGET_LUFS (more than MIN_GAIN_DB away; capped at MAX_BOOST_DB / MAX_CUT_DB)
  c  1 = clarity: muffled or narrow-band tape (little energy above 4 kHz) -> cut the rumble, lift the voice
tools/lessons_build.py copies it into each series as "fx"; the website (Web Audio) and Android
(LoudnessEnhancer + Equalizer) apply it while playing.

Usage: python3 tools/lessons_loudness.py            (measures 3 episodes per series with ffmpeg; ~5 min)
       python3 tools/lessons_loudness.py --new      (measures only series not measured yet, keeps the rest)
       python3 tools/lessons_loudness.py --rules    (re-applies the rules to content/lessons/raw/loudness-raw.json)
"""
import json
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / 'content/lessons/dist/lessons.v1.json'
RAW = ROOT / 'content/lessons/raw/loudness-raw.json'
OUT = ROOT / 'content/lessons/audio-fx.json'
TARGET_LUFS = -16.0
MIN_GAIN_DB = 3.0
MAX_BOOST_DB = 12.0
MAX_CUT_DB = -10.0
# Energy above 4 kHz this far under the whole (dB), or a sample rate this low: an old, muffled recording.
MUFFLED_HIGHS_DB = -29.0
NARROW_RATE = 16000


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, errors='replace', stdin=subprocess.DEVNULL)


def measure(job):
    sid, idx, url = job
    f = Path(tempfile.mkdtemp()) / 'a.mp3'
    # A few minutes from 2 MB in (past any intro).
    run(['curl', '-sL', '-m', '120', '-r', '2000000-6000000', '-o', str(f), url])
    if not f.exists() or f.stat().st_size < 100000:
        run(['curl', '-sL', '-m', '120', '-r', '0-4000000', '-o', str(f), url])
    st = (json.loads(run(['ffprobe', '-v', 'quiet', '-select_streams', 'a:0', '-show_entries', 'stream=sample_rate',
                          '-of', 'json', str(f)]).stdout or '{}').get('streams') or [{}])[0]
    r = run(['ffmpeg', '-nostdin', '-hide_banner', '-t', '240', '-i', str(f), '-af',
             'ebur128=framelog=quiet,volumedetect', '-f', 'null', '-']).stderr
    h = run(['ffmpeg', '-nostdin', '-hide_banner', '-t', '240', '-i', str(f), '-af',
             'highpass=f=4000,volumedetect', '-f', 'null', '-']).stderr
    f.unlink(missing_ok=True)
    lufs = re.findall(r'I:\s+(-?[\d.]+) LUFS', r)
    am = re.findall(r'mean_volume: (-?[\d.]+) dB', r)
    hm = re.findall(r'mean_volume: (-?[\d.]+) dB', h)
    return {'series': sid, 'ep': idx, 'lufs': float(lufs[-1]) if lufs else None,
            'hi': float(hm[0]) - float(am[0]) if hm and am else None, 'sr': int(st.get('sample_rate') or 0)}


def rules(raw):
    by = {}
    for x in raw:
        by.setdefault(x['series'], []).append(x)
    out = {}
    for sid, xs in sorted(by.items()):
        lufs = [x['lufs'] for x in xs if x['lufs'] is not None and x['lufs'] > -70]
        his = [x['hi'] for x in xs if x['hi'] is not None]
        fx = {}
        if lufs:
            g = max(MAX_CUT_DB, min(MAX_BOOST_DB, TARGET_LUFS - sum(lufs) / len(lufs)))
            if abs(g) >= MIN_GAIN_DB:
                fx['g'] = round(g)
        if (his and min(his) < MUFFLED_HIGHS_DB) or any(0 < x['sr'] <= NARROW_RATE for x in xs):
            fx['c'] = 1
        if fx:
            out[sid] = fx
    OUT.write_text(json.dumps(out, indent=1, ensure_ascii=False) + '\n')
    print(f'{OUT.relative_to(ROOT)}: {len(out)} of {len(by)} series adjusted')


if __name__ == '__main__':
    if sys.argv[1:] == ['--rules']:
        rules(json.loads(RAW.read_text()))
        sys.exit()
    cat = json.loads(DIST.read_text())
    listed = cat['series'] + cat.get('sharawi', [])
    ids = {s['id'] for s in listed}
    # Series no longer in the list are dropped from the measurements.
    old = [x for x in json.loads(RAW.read_text()) if x['series'] in ids] if '--new' in sys.argv else []
    done = {x['series'] for x in old}
    jobs = []
    for s in listed:
        if s['id'] in done:
            continue
        eps = s['episodes']
        for i in sorted({0, len(eps) // 2, len(eps) - 1}):
            jobs.append((s['id'], i + 1, eps[i]['u']))
    with ThreadPoolExecutor(6) as ex:
        res = old + list(ex.map(measure, jobs))
    RAW.write_text(json.dumps(res, indent=0))
    rules(res)
