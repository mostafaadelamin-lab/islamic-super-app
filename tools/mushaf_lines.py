"""Madinah Mushaf 1405H line layout (15 lines per page) bound to the canonical text.

The line layout (which words sit on which line of which page) comes from the
pinned upstream package quran-madina-html@2.2.2 (Madina-1405H database, KFGQPC
1405H layout, Waqf GPL 2.0). Its own text is used ONLY to locate line breaks;
it is never copied into the output. Each output segment references a word range
of the canonical ayah text (content/quran/dist/quran.v1.json), so every platform
renders exactly the canonical code points.

Output content/quran/dist/mushaf-lines.v1.json:
  {"schema": "mushaf-lines.v1", "pages": [{"page": n, "lines": [Line, ...]}, ...]}
  Line = {"k": "sura", "s": 2}                      surah title band
       | {"k": "basmala", "s": 2}                    basmala line (not an ayah, except 1:1)
       | {"k": "text", "g": [[s, a, w0, w1, end], ...]}
         a segment shows canonical words w0..w1-1 of ayah s:a; end=1 when the ayah
         ends on this line (render the ayah-number marker after it).
Pages 1 and 2 have 8 lines and are centred; every other page has 15 lines.
"""
from __future__ import annotations

import collections
import json
import pathlib
import unicodedata

UPSTREAM = "quran/upstream/quran-madina-html-2.2.2/Madina-1405H"
AYAH_MARK = "۝"


def _skeleton(word: str) -> str:
    """Base letters only, so that differently encoded words can be aligned."""
    out = []
    for ch in word:
        if ch == "ٱ":  # alef wasla
            ch = "ا"
        if "ء" <= ch <= "ي" and unicodedata.category(ch) == "Lo":
            out.append(ch)
    return "".join(out)


def _load_upstream(content: pathlib.Path):
    segs = collections.defaultdict(list)
    for f in sorted((content / UPSTREAM).glob("juz-*.json")):
        for si, ai, pg, lines in json.loads(f.read_text(encoding="utf-8"))["d"]:
            segs[(si, ai)].append((pg, lines))
    return segs


def _assign_lines(canon_words: list[str], up_words: list[tuple[int, int, str]]) -> list[tuple[int, int]]:
    """Return (page, line) for each canonical word."""
    if len(canon_words) == len(up_words):
        return [(p, ln) for p, ln, _ in up_words]
    # Different word splitting (e.g. "مَالِيَ" vs "مَا لِيَ"): align by letter skeleton.
    ends, pos = [], 0
    for p, ln, w in up_words:
        pos += len(_skeleton(w))
        ends.append((pos, p, ln))
    out, pos = [], 0
    for w in canon_words:
        pos += len(_skeleton(w))
        target = max(pos, 1)
        for e, p, ln in ends:
            if e >= target:
                out.append((p, ln))
                break
        else:
            out.append((ends[-1][1], ends[-1][2]))
    return out


def build(content: pathlib.Path, surahs: list[dict], pages: list[dict]):
    segs = _load_upstream(content)
    problems: list[str] = []
    # page -> line -> list of items
    layout: dict[int, dict[int, list]] = collections.defaultdict(lambda: collections.defaultdict(list))
    for s in surahs:
        si = s["n"] - 1
        for ai in (0, 1):
            for pg, lines in segs.get((si, ai), []):
                for ln in lines:
                    t = ln["t"].strip()
                    if not t:
                        continue
                    if t.startswith("سُورَةُ"):
                        layout[pg][ln["l"]].append({"k": "sura", "s": s["n"]})
                    elif _skeleton(t) == _skeleton("بسم الله الرحمن الرحيم"):
                        layout[pg][ln["l"]].append({"k": "basmala", "s": s["n"]})
                    else:
                        problems.append(f"unexpected header text {s['n']}/{ai}: {t}")
        for a, text in enumerate(s["ayahs"], start=1):
            up = [(pg, ln["l"], w) for pg, lines in segs.get((si, a + 1), []) for ln in lines
                  for w in ln["t"].split() if not w.startswith(AYAH_MARK)]
            if not up:
                problems.append(f"no layout for {s['n']}:{a}")
                continue
            words = text.split(" ")
            where = _assign_lines(words, up)
            run_start = 0
            for i in range(1, len(words) + 1):
                if i == len(words) or where[i] != where[run_start]:
                    pg, ln = where[run_start]
                    layout[pg][ln].append([s["n"], a, run_start, i, 1 if i == len(words) else 0])
                    run_start = i

    out_pages = []
    for pg in range(1, 605):
        lines_map = layout.get(pg, {})
        n_lines = 8 if pg <= 2 else 15
        if sorted(lines_map) != list(range(1, n_lines + 1)):
            problems.append(f"page {pg}: lines {sorted(lines_map)}")
        lines = []
        for ln in sorted(lines_map):
            items = lines_map[ln]
            heads = [x for x in items if isinstance(x, dict)]
            text = [x for x in items if isinstance(x, list)]
            if heads and text or len(heads) > 1:
                problems.append(f"page {pg} line {ln}: mixed line")
            lines.append(heads[0] if heads else {"k": "text", "g": text})
        out_pages.append({"page": pg, "lines": lines})

    # Coverage: every canonical word appears exactly once, in reading order, and
    # each page holds exactly the ayahs that pages.v1.json assigns to it.
    flat = [(g[0], g[1], w) for p in out_pages for ln_ in p["lines"] if ln_["k"] == "text" for g in ln_["g"] for w in range(g[2], g[3])]
    expected = [(s["n"], a, w) for s in surahs for a, t in enumerate(s["ayahs"], start=1) for w in range(len(t.split(" ")))]
    if flat != expected:
        problems.append("mushaf lines do not cover the canonical words exactly once in order")
    for p, meta in zip(out_pages, pages, strict=True):
        ayahs = [(g[0], g[1]) for ln_ in p["lines"] if ln_["k"] == "text" for g in ln_["g"]]
        if ayahs and (list(ayahs[0]) != meta["start"] and ayahs[0][0] == meta["start"][0] and ayahs[0][1] < meta["start"][1]):
            problems.append(f"page {p['page']} starts before {meta['start']}")
        ends = [(g[0], g[1]) for ln_ in p["lines"] if ln_["k"] == "text" for g in ln_["g"] if g[4]]
        if ends and list(ends[-1]) != meta["end"]:
            problems.append(f"page {p['page']}: last ayah ending {ends[-1]} != pages.v1 end {meta['end']}")
    return {"schema": "mushaf-lines.v1", "layout": "Madinah Mushaf KFGQPC 1405H (15 lines)",
            "source": "line breaks from npm quran-madina-html@2.2.2 (Waqf GPL 2.0); words reference quran.v1.json",
            "pages": out_pages}, problems
