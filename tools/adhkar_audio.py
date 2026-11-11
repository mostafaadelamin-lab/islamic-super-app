"""Maps every dhikr in the app (morning/evening list and Hisn al-Muslim chapters) to the
per-dhikr recording of Hisn al-Muslim (hisnmuslim.com API, fetched into
content/adhkar/hisnmuslim-audio-source.json). Output: apps/mobile/assets/content/adhkar-audio.v1.json
  {"base": "...{id}.mp3", "adhkar": {"<index>": id}, "hisn": {"<chapter>:<item>": id}}
Matching is by text similarity after removing diacritics/punctuation; weak matches are left out.
Usage: python3 tools/adhkar_audio.py"""
import json, re, difflib, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = json.loads((root/'content/adhkar/hisnmuslim-audio-source.json').read_text())
DIAC = re.compile(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]')
def norm(t):
    t = DIAC.sub('', t)
    t = re.sub('[إأآٱ]', 'ا', t).replace('ى', 'ي').replace('ة', 'ه')
    t = re.sub(r'[^ء-ي ]', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()
cands = [(i['id'], norm(i['text'])) for c in src for i in c['items']]
def best(text, pool=cands):
    n = norm(text)[:220]
    if len(n) < 6: return None, 0
    scored = []
    for cid, ct in pool:
        r = difflib.SequenceMatcher(None, n, ct[:max(len(n)+40, 60)], autojunk=False).ratio()
        if n and n in ct: r = max(r, 0.9)
        scored.append((r, cid))
    r, cid = max(scored)
    return cid, r
out = {'base': 'https://www.hisnmuslim.com/audio/ar/{id}.mp3', 'adhkar': {}, 'hisn': {}}
adhkar = json.loads((root/'apps/mobile/assets/content/adhkar.v1.json').read_text())['items']
morning = [(i['id'], norm(i['text'])) for i in src[0]['items']]  # chapter 27 = morning & evening
for k, t in enumerate(adhkar):
    cid, r = best(t, morning)
    if r < 0.45: cid, r = best(t)
    if r >= 0.45: out['adhkar'][str(k)] = cid
    print('adhkar', k, round(r, 2), cid, norm(t)[:40])
# Manual fixes after checking the matches (app index -> recording id; None = no recording).
for k, v in {0: None, 4: 76, 5: 76, 27: 92, 31: 93, 33: 91}.items():
    if v is None: out['adhkar'].pop(str(k), None)
    else: out['adhkar'][str(k)] = v
hisn = json.loads((root/'apps/mobile/assets/content/hisn.json').read_text())
weak = 0
for ci, (title, items) in enumerate(hisn):
    for ii, t in enumerate(items):
        cid, r = best(t)
        if r >= 0.55: out['hisn'][f'{ci}:{ii}'] = cid
        else: weak += 1
for k in ['0:0', '2:2', '14:1', '17:5', '32:2', '32:3', '58:1']:  # wrong matches (checked by hand)
    out['hisn'].pop(k, None)
print('hisn mapped', len(out['hisn']), 'unmapped', weak)
(root/'apps/mobile/assets/content/adhkar-audio.v1.json').write_text(json.dumps(out, ensure_ascii=False, separators=(',', ':')))
