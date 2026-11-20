#!/usr/bin/env python3
"""Builds packages/shared-schemas/audio/ayah-timings.json: where each ayah starts and ends inside the
surah files of the reciters recorded one file per surah (owner 2026-11-20: Idris Abkar, Mustafa Ismail,
Mahmoud Ali al-Banna (mujawwad), Ahmad Eisa al-Masarawi).

Source of the timings: the free ayah-timing API of the same site that hosts the files
(api/v3/ayat_timing?surah=S&read=ID). The published timings were checked against the audio itself:
each ayah boundary should sit in a pause. Usage (from the repo root):

    python3 -I tools/ayah_timings/build.py CACHE_DIR

CACHE_DIR keeps the downloaded timings and loudness envelopes (ffmpeg needed) so a re-run is quick.
For every surah the script
  1. scores the published boundaries (loudness at the boundary vs. around it),
  2. if a constant shift / small stretch makes them clearly better, applies it (files re-edited
     with a different intro length),
  3. if they are still not in pauses, re-places them in the pauses of the recording, choosing the
     pauses whose spacing best matches the ayah lengths (text length) (dynamic programming),
  4. moves each boundary to the quietest moment within 0.4 s, so no syllable is cut.
A report (per surah: method and score) is printed; surahs that still score badly are listed.
Surahs listed in overrides.json (re-aligned with dtw_align.py) replace the computed rows.
"""
import bisect
import concurrent.futures as cf
import json
import os
import subprocess
import sys
import urllib.request

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
API = "https://www.mp3quran.net/api/v3/ayat_timing?surah={s}&read={read}"
RECITERS = {
    # folder in reciters.json: (timing read id, surah file URL, murattal). Mujawwad recordings (long
    # pauses everywhere, repeated phrases, audience) cannot be judged by the pause test: their published
    # timings are kept as they are (only nudged into the quietest moment nearby).
    "mp3q_idrees_abkar": (12, "https://cdn.mp3quran.net/audio/idrees-abkar/r1/{sss}.mp3", True),
    "mp3q_mustafa_ismail_mujawwad": (288, "https://cdn.mp3quran.net/audio/mustafa-ismail/r2/{sss}.mp3", False),
    "mp3q_mahmoud_banna_mujawwad": (122, "https://cdn.mp3quran.net/audio/mahmoud-banna/r2/{sss}.mp3", False),
    "mp3q_ahmad_masarawi": (289, "https://cdn.mp3quran.net/audio/ahmad-masarawi/r1/{sss}.mp3", True),
}
HOP = 0.05  # seconds per envelope frame


def raw_timings(cache, read, s):
    p = os.path.join(cache, f"timing/{read}_{s}.json")
    if not os.path.exists(p):
        os.makedirs(os.path.dirname(p), exist_ok=True)
        data = urllib.request.urlopen(API.format(s=s, read=read), timeout=60).read()
        open(p, "wb").write(data)
    rows = [a for a in json.load(open(p)) if a["ayah"] > 0]
    return [r["start_time"] for r in rows], [r["end_time"] for r in rows]


def envelope(cache, read, url, s):
    p = os.path.join(cache, f"rms/{read}_{s}.npy")
    if os.path.exists(p):
        return np.load(p)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", url.format(sss=f"{s:03d}"), "-ac", "1", "-ar", "8000", "-f", "s16le", "-"],
        capture_output=True, timeout=1800, check=True,
    ).stdout
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
    w = int(8000 * HOP)
    n = len(x) // w
    rms = np.sqrt((x[: n * w].reshape(n, w) ** 2).mean(1) + 1)
    np.save(p, rms)
    return rms


_ratio_cache = {}


def _ratio(rms):
    """Per frame: quietest loudness within +-0.25 s divided by the median loudness within +-2 s."""
    key = id(rms)
    if key not in _ratio_cache:
        from numpy.lib.stride_tricks import sliding_window_view as win

        p1 = np.pad(rms, 5, mode="edge")
        p2 = np.pad(rms, 40, mode="edge")
        mins = win(p1, 11).min(axis=1)
        meds = np.median(win(p2, 81), axis=1)
        _ratio_cache[key] = (rms, mins / (meds + 1))
    return _ratio_cache[key][1]


def score(rms, bounds_s):
    """Median loudness at the boundaries relative to the 4 s around them (lower = in a pause)."""
    if len(bounds_s) == 0:
        return 0.0
    r = _ratio(rms)
    idx = (np.asarray(bounds_s) / HOP).astype(int)
    vals = np.where((idx >= 0) & (idx < len(r)), r[np.clip(idx, 0, len(r) - 1)], 1.0)
    return float(np.median(vals))


def control(rms, b):
    return float(np.median([score(rms, b + o) for o in (-9, -6, -4, 4, 6, 9)]))


def pauses(rms):
    """Candidate pauses: (time s, depth 0..1, weight) at the clear dips of loudness (works with reverb too)."""
    from numpy.lib.stride_tricks import sliding_window_view as win

    r = _ratio(rms)
    w = 15  # +-0.75 s
    local_min = win(np.pad(r, w, mode="edge"), 2 * w + 1).min(axis=1)
    out = []
    last = -10.0
    for i in np.where((r <= local_min) & (r < 0.55))[0]:
        t = i * HOP + HOP / 2
        if t - last < 0.8:
            continue
        last = t
        out.append((t, float(1 - r[i]), float(1.5 * (1 - r[i]))))
    return out


def dp_align(rms, lengths, t0, t1):
    """Chooses len(lengths)-1 pauses between t0 and t1 so the ayah durations follow the text lengths."""
    cands = [p for p in pauses(rms) if t0 + 0.5 < p[0] < t1 - 0.5]
    n = len(lengths)
    if len(cands) < n - 1:
        return None
    total = sum(lengths)
    rate = (t1 - t0) / total
    pts = [t0] + [c[0] for c in cands] + [t1]
    bonus = [0.0] + [min(c[2], 1.5) for c in cands] + [0.0]
    m = len(pts)
    inf = float("inf")
    # cost[k][j]: best cost with ayah k ending at point j
    cost = np.full((n + 1, m), inf)
    back = np.zeros((n + 1, m), dtype=int)
    cost[0][0] = 0.0
    for k in range(1, n + 1):
        exp = lengths[k - 1] * rate
        for j in range(1, m):
            if k == n and j != m - 1:
                continue
            if k < n and j == m - 1:
                continue
            best, arg = inf, 0
            # Only ayah lengths between a fifth and three times (+3 s) the expected one.
            lo_i = bisect.bisect_left(pts, pts[j] - (3 * exp + 3), 0, j)
            hi_i = bisect.bisect_right(pts, pts[j] - 0.2 * exp, 0, j)
            for i in range(max(k - 1, lo_i), hi_i):
                if cost[k - 1][i] == inf:
                    continue
                d = pts[j] - pts[i]
                c = cost[k - 1][i] + (d - exp) ** 2 / max(exp, 1.0) - 0.8 * bonus[j]
                if c < best:
                    best, arg = c, i
            cost[k][j], back[k][j] = best, arg
    if cost[n][m - 1] == inf:
        return None
    ends = []
    j = m - 1
    for k in range(n, 0, -1):
        ends.append(pts[j])
        j = back[k][j]
    return ends[::-1]


def snap(rms, b, radius=0.4):
    out = []
    r = int(radius / HOP)
    for e in b:
        i = int(e / HOP)
        lo, hi = max(0, i - r), min(len(rms), i + r + 1)
        if hi <= lo:
            out.append(e)
            continue
        j = lo + int(np.argmin(rms[lo:hi]))
        out.append(j * HOP + HOP / 2)
    return out


def build_surah(cache, folder, read, url, s, text_len, murattal=True):
    starts, ends = raw_timings(cache, read, s)
    rms = envelope(cache, read, url, s)
    dur = len(rms) * HOP
    b = np.array(ends[:-1]) / 1000
    start1, last_end = starts[0] / 1000, ends[-1] / 1000
    method = "published"
    s0 = score(rms, b) if len(b) else 0.0
    ctrl = control(rms, b) if len(b) else 1.0
    good = lambda sc, ct: sc <= 0.6 * ct or sc <= 0.2
    # Only clearly broken published timings (boundaries no quieter than random points) are re-done;
    # too few boundaries cannot judge a short surah: keep what was published.
    if murattal and len(b) >= 10 and s0 > 0.8 * ctrl:
        best = (s0, 1.0, 0.0)
        for a in np.arange(0.90, 1.0601, 0.0025):
            for o in np.arange(-30, 30.01, 0.25):
                v = score(rms, b * a + o)
                if v < best[0]:
                    best = (v, float(a), float(o))
        if best[0] <= 0.6 * s0 and good(best[0], ctrl) and start1 * best[1] + best[2] >= 0:
            a, o = best[1], best[2]
            b = b * a + o
            start1, last_end = start1 * a + o, last_end * a + o
            method = f"shift x{a:.4f} {o:+.2f}s"
        else:
            # Speech span: from the published start of ayah 1 (opening kept) to the last sound.
            loud = np.where(rms > 0.25 * np.median(rms))[0]
            t1 = min(dur, (loud[-1] + 1) * HOP if len(loud) else dur)
            t0 = min(start1, t1 - 1)
            new = dp_align(rms, text_len, t0, t1)
            if new is not None:
                v = score(rms, np.array(new[:-1]))
                # Only when clearly better than what was published (else keep it and report it).
                if good(v, ctrl) or v <= 0.75 * s0:
                    b = np.array(new[:-1])
                    last_end = new[-1]
                    method = "re-aligned to pauses"
    if len(b):
        b = np.array(snap(rms, b))
    last_end = min(last_end, dur)
    final = [int(round(start1 * 1000))] + [int(round(x * 1000)) for x in b] + [int(round(last_end * 1000))]
    for i in range(1, len(final)):
        if final[i] <= final[i - 1]:
            final[i] = final[i - 1] + 50
    sc = score(rms, np.array(final[1:-1]) / 1000) if len(final) > 2 else 0.0
    return final, method, round(s0, 3), round(sc, 3), round(ctrl, 3)


def main():
    cache = sys.argv[1] if len(sys.argv) > 1 else "/tmp/ayah-timings-cache"
    quran = json.load(open(os.path.join(ROOT, "content/quran/dist/quran.v1.json"), encoding="utf-8"))
    lens = [[max(1, len(a.replace(" ", ""))) for a in su["ayahs"]] for su in quran["surahs"]]
    out = {}
    worst = []
    overrides = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "overrides.json")))
    for folder, (read, url, murattal) in RECITERS.items():
        with cf.ThreadPoolExecutor(8) as ex:
            res = list(
                ex.map(lambda s: build_surah(cache, folder, read, url, s, lens[s - 1], murattal), range(1, 115))
            )
        rows = []
        for s, (final, method, s0, sc, ctrl) in enumerate(res, 1):
            if str(s) in overrides.get(folder, {}):
                final, method = overrides[folder][str(s)], "override (DTW)"
                print(f"{folder} {s:3d}: {method}")
            assert len(final) == len(lens[s - 1]) + 1, (folder, s)
            rows.append(final)
            if method != "published" or (len(final) > 4 and sc > 0.6 * ctrl and sc > 0.2):
                print(f"{folder} {s:3d}: {method:28s} before {s0} after {sc} (control {ctrl})")
            if murattal and len(final) > 4 and sc > 0.6 * ctrl and sc > 0.2:
                worst.append((folder, s, sc, ctrl))
        out[folder] = rows
    doc = {
        "schema": "ayah-timings.v1",
        "note": "Per reciter (folder in reciters.json), per surah: [start of ayah 1, end of ayah 1, end of ayah 2, ...] "
        "in ms inside the surah file. Built by tools/ayah_timings/build.py.",
        "reciters": out,
    }
    path = os.path.join(ROOT, "packages/shared-schemas/audio/ayah-timings.json")
    with open(path, "w", encoding="utf-8") as f:
        f.write("{\n")
        f.write(f'  "schema": {json.dumps(doc["schema"])},\n  "note": {json.dumps(doc["note"])},\n  "reciters": {{\n')
        keys = list(out)
        for ki, k in enumerate(keys):
            f.write(f"    {json.dumps(k)}: [\n")
            for si, row in enumerate(out[k]):
                f.write("      " + json.dumps(row, separators=(",", ":")) + ("," if si < 113 else "") + "\n")
            f.write("    ]" + ("," if ki < len(keys) - 1 else "") + "\n")
        f.write("  }\n}\n")
    print("wrote", path)
    print("still doubtful:", worst)


if __name__ == "__main__":
    main()
