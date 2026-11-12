#!/usr/bin/env python3
"""Completes and corrects the tashkeel of the Hisn al-Muslim texts (content/adhkar/hisn.json)
and the morning/evening list (content/adhkar/adhkar.json) from the fully vowelled text of
Hisn al-Muslim (Sa'id al-Qahtani) in content/adhkar/hisnmuslim-audio-source.json.
Only marks change, never letters or words: for every item that matches a reference item
(at least 70% of its words found in order in it) and every word whose letters are identical in both, each letter
takes the reference's marks (or keeps its own when the reference has none). Then the tanween
is moved off the alif (tools/fix_tanween.py). Writes a report of every changed word.
Usage: hisn_tashkeel.py REPORT.tsv"""
import difflib, json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from fix_tanween import _order, fix

root = Path(__file__).resolve().parents[1]
A = root / 'content/adhkar'
MARK = re.compile('[ً-ْٰـ]')
WORD = re.compile('([ء-ْٰـ]+)')


def skel(w):
    return MARK.sub('', w)


def key(w):
    return skel(w).translate(str.maketrans('أإآىة', 'ااايه'))


def letters(w):
    out = []
    for ch in w:
        if ch == 'ـ': continue
        if MARK.match(ch):
            if out: out[-1][1] += ch
        else: out.append([ch, ''])
    return out


def norm(w):
    return ''.join(x[0] + _order(x[1]) for x in letters(fix(w)))


def merge(ours, ref):
    a, b = letters(fix(ours)), letters(fix(ref))
    if [x[0] for x in a] != [x[0] for x in b]: return ours
    return ''.join(x[0] + _order(y[1] or x[1]) for x, y in zip(a, b))


src = json.loads((A / 'hisnmuslim-audio-source.json').read_text())
REF = [it['text'] for c in src for it in c['items']]
REFK = [' '.join(key(w) for w in WORD.findall(t)) for t in REF]
report = []


def cover(a, b):
    """Share of the words of a found, in order, in b."""
    sm = difflib.SequenceMatcher(None, a, b, autojunk=False)
    return sum(x.size for x in sm.get_matching_blocks()) / max(1, len(a))


REFW = [k.split() for k in REFK]


def fix_text(t, where):
    k = [key(w) for w in WORD.findall(t)]
    j = max(range(len(REF)), key=lambda j: cover(k, REFW[j]))
    if len(k) < 3 or cover(k, REFW[j]) < 0.7: return fix(t), False
    parts = WORD.split(t)
    ours = parts[1::2]
    refw = WORD.findall(REF[j])
    sm = difflib.SequenceMatcher(None, [key(w) for w in ours], [key(w) for w in refw], autojunk=False)
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op != 'equal': continue
        for i, jj in zip(range(i1, i2), range(j1, j2)):
            new = merge(ours[i], refw[jj])
            if norm(new) != norm(ours[i]):
                report.append((where, ours[i], fix(new), refw[jj]))
            ours[i] = new
    parts[1::2] = ours
    return fix(''.join(parts)), True


hisn = json.loads((A / 'hisn.json').read_text())
n = 0
for ci, (title, items) in enumerate(hisn):
    for ii, t in enumerate(items):
        items[ii], ok = fix_text(t, f'hisn {ci + 1}:{ii + 1} {title}')
        n += ok
(A / 'hisn.json').write_text(json.dumps(hisn, ensure_ascii=False, separators=(',', ':')))
adhkar = json.loads((A / 'adhkar.json').read_text())
m = 0
for i, t in enumerate(adhkar):
    adhkar[i], ok = fix_text(t, f'adhkar {i + 1}')
    m += ok
(A / 'adhkar.json').write_text(json.dumps(adhkar, ensure_ascii=False, separators=(',', ':')))
with open(sys.argv[1], 'w', encoding='utf-8') as f:
    f.write('where\tbefore\tafter\treference word\n')
    for r in report: f.write('\t'.join(r) + '\n')
print(f'hisn items matched {n}, adhkar matched {m}/{len(adhkar)}, words changed {len(report)}')
