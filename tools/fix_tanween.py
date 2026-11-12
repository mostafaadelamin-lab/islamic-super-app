#!/usr/bin/env python3
"""Moves tanween al-fath from the alif to the letter before it (رَبّاً -> رَبًّا),
the Madinah-mushaf spelling the owner asked for (2026-11-12). Only the mark's
position changes; letters and other marks are kept. Usage: fix_tanween.py FILE.json..."""
import json, re, sys, unicodedata

MARKS = 'ً-ْٰ'
PAT = re.compile(f'([ء-ي])([{MARKS}]*)ا([{MARKS}]*)ً')


def _order(marks):
    return ''.join(sorted(marks, key=unicodedata.combining))


def fix(s):
    s = re.sub('\u0627\u064b+', '\u0627\u064b', s)  # a doubled tanween in the source (ثَوْباًً)
    while True:
        t = PAT.sub(lambda m: m[1] + _order(m[2].replace('\u064e', '') + '\u064b') + 'ا' + m[3], s)
        if t == s: return s
        s = t


def walk(v):
    if isinstance(v, str): return fix(v)
    if isinstance(v, list): return [walk(x) for x in v]
    if isinstance(v, dict): return {k: walk(x) for k, x in v.items()}
    return v


if __name__ == '__main__':
    for f in sys.argv[1:]:
        raw = open(f, encoding='utf-8').read()
        data = json.loads(raw)
        out = walk(data)
        compact = '\n' not in raw.strip()
        text = json.dumps(out, ensure_ascii=False, separators=(',', ':')) if compact else json.dumps(out, ensure_ascii=False, indent=2)
        open(f, 'w', encoding='utf-8').write(text + ('' if compact else '\n'))
        print(f, raw.count('اً'), '->', text.count('اً'))
