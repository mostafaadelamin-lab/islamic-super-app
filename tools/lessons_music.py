"""Find the music in lesson recordings (intro, bumpers between parts, outro) so the players jump over it.

Owner 2026-11-23: the Grand Imam's podcast episodes open (and some close) with music; lessons must have none.
The recordings stay as published; content/lessons/music.json lists, per audio URL, the stretches to skip
in whole seconds [from, to). tools/lessons_build.py copies them into each episode as "m".

Needs inaSpeechSegmenter (speech / music classifier, CNN) and ffmpeg:
    python3 -m venv /tmp/v && /tmp/v/bin/pip install inaSpeechSegmenter tensorflow-cpu
    /tmp/v/bin/python tools/lessons_music.py asma-tayeb hayat-tayeb ...   (series ids; resumable)
    python3 tools/lessons_music.py --clean   (only re-applies the rules below to the raw results)
Raw results are kept in content/lessons/raw/music-raw.json.
"""
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / 'content/lessons/dist/lessons.v1.json'
RAW = ROOT / 'content/lessons/raw/music-raw.json'
OUT = ROOT / 'content/lessons/music.json'
# Shorter music runs are left alone (a note or a breath the classifier misread).
MIN_RUN_SEC = 2.0
# Two runs this close are one bumper.
JOIN_GAP_SEC = 5.0
# Music this close to the start runs to the start; this close to the end (outro, then silence), to the end.
EDGE_SEC = 6.0
END_EDGE_SEC = 15.0


def clean(dur, runs):
    """[[a, b], ...] seconds from the classifier -> whole-second stretches to skip."""
    runs = sorted([a, b] for a, b in runs if b - a >= MIN_RUN_SEC)
    joined = []
    for a, b in runs:
        if joined and a - joined[-1][1] <= JOIN_GAP_SEC:
            joined[-1][1] = b
        else:
            joined.append([a, b])
    out = []
    for a, b in joined:
        if a <= EDGE_SEC:
            a = 0
        if dur and b >= dur - END_EDGE_SEC:
            b = dur + 1
        out.append([math.floor(a), math.ceil(b)])
    return out


def write_clean(raw):
    music = {u: clean(r['dur'], r['music']) for u, r in sorted(raw.items())}
    OUT.write_text(json.dumps({u: m for u, m in music.items() if m}, indent=1) + '\n')
    print(f'{OUT.relative_to(ROOT)}: {sum(1 for m in music.values() if m)} of {len(music)} recordings have music')


def analyse(series_ids):
    os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
    from inaSpeechSegmenter import Segmenter

    cat = json.loads(DIST.read_text())
    raw = json.loads(RAW.read_text()) if RAW.exists() else {}
    seg = Segmenter(vad_engine='smn', detect_gender=False)
    tmp = Path(tempfile.mkdtemp()) / 'a.mp3'
    for s in cat['series'] + cat.get('sharawi', []):
        if s['id'] not in series_ids:
            continue
        for e in s['episodes']:
            if e['u'] in raw:
                continue
            subprocess.run(['curl', '-sL', '-m', '300', '-o', str(tmp), e['u']], check=True, stdin=subprocess.DEVNULL)
            parts = seg(str(tmp))
            raw[e['u']] = {
                'dur': round(parts[-1][2], 1) if parts else 0,
                'music': [[round(a, 1), round(b, 1)] for lab, a, b in parts if lab == 'music'],
            }
            print(s['id'], e['u'], raw[e['u']]['music'], flush=True)
            RAW.write_text(json.dumps(raw, indent=0))
    return raw


if __name__ == '__main__':
    args = sys.argv[1:]
    if args == ['--clean']:
        write_clean(json.loads(RAW.read_text()))
    else:
        write_clean(analyse(set(args)))
