#!/usr/bin/env python3
"""Build versioned, platform-neutral content bundles from pinned upstream sources.

The Quran text is copied byte-for-byte from the upstream file. Nothing in this
script edits, normalises or re-encodes ayah text. Any glyph substitution needed
for a particular font happens at render time in the client, never in content.

Outputs (all deterministic, sorted keys, UTF-8):
  content/quran/dist/quran.v1.json       surahs + ayah text (+ English translation)
  content/quran/dist/pages.v1.json       Madinah Mushaf 1405H page boundaries (604)
  content/quran/dist/integrity.v1.json   SHA-256 hashes used by every platform's tests
  content/adhkar/dist/adhkar.v1.json     morning/evening adhkar
  content/VERSIONS.json                  content version registry
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
C = ROOT / "content"
QURAN_SRC = C / "quran/upstream/quran-json-3.1.2.quran.json"
EN_SRC = C / "translations/upstream/quran-json-3.1.2.quran_en.json"
MADINA = C / "quran/madina-1405h-manifest.json"
REF = ROOT / "tests/vectors/quran-reference.json"

QURAN_VERSION = "1.0.0"


def sha(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def dump(path: pathlib.Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n", encoding="utf-8")


def ayah_hash(surahs) -> str:
    # Canonical line format: "<surah>|<ayah>|<text>\n" over all ayahs in order.
    return sha("".join(f"{s['n']}|{i + 1}|{t}\n" for s in surahs for i, t in enumerate(s["ayahs"])))


def main() -> int:
    src = json.loads(QURAN_SRC.read_text(encoding="utf-8"))
    en = json.loads(EN_SRC.read_text(encoding="utf-8"))
    ref = json.loads(REF.read_text(encoding="utf-8"))
    surahs = []
    for s, e in zip(src, en, strict=True):
        assert s["id"] == e["id"]
        surahs.append({
            "n": s["id"],
            "nameAr": s["name"],
            "translit": s["transliteration"],
            "nameEn": e["translation"],
            "revelation": s["type"],
            "ayahCount": len(s["verses"]),
            "ayahs": [v["text"] for v in s["verses"]],
            "en": [v["translation"] for v in e["verses"]],
        })
        assert [v["id"] for v in s["verses"]] == list(range(1, len(s["verses"]) + 1))

    # --- Madinah Mushaf (KFGQPC 1405H) page boundaries ---------------------
    # Manifest rows are [surahIdx0, lineIdx, surahIdx0, lineIdx] where lineIdx 0/1
    # are the surah header and basmala and lineIdx k>=2 is ayah k-1.
    m = json.loads(MADINA.read_text(encoding="utf-8"))
    counts = [s["ayahCount"] for s in surahs]
    pages = []
    for i, (s0, i0, s1, i1) in enumerate(m["pages"]):
        start = (s0 + 1, max(1, i0 - 1))
        if i1 >= 2:
            end = (s1 + 1, i1 - 1)
        else:  # page ends on the next surah's header: last ayah is in previous surah
            end = (s1, counts[s1 - 1])
        pages.append({"page": i + 1, "start": list(start), "end": list(end)})
    juz = [{"juz": k + 1, "page": row[2], "start": [row[0] + 1, max(1, row[1] - 1)]} for k, row in enumerate(m["juz"])]

    bundle = {
        "schema": "quran.v1",
        "version": QURAN_VERSION,
        "riwayah": "Hafs an Asim",
        "numbering": "Kufi (6236)",
        "source": {
            "text": "The Noble Qur'an Encyclopedia (quranenc.com) Uthmani text, via npm quran-json@3.1.2 (CC BY 4.0)",
            "translationEn": "Saheeh International via quran-json@3.1.2 (licence review pending, see docs/CONTENT_SOURCES.md)",
            "upstreamSha256": hashlib.sha256(QURAN_SRC.read_bytes()).hexdigest(),
        },
        "surahs": surahs,
    }
    dump(C / "quran/dist/quran.v1.json", bundle)
    dump(C / "quran/dist/pages.v1.json", {"schema": "pages.v1", "layout": "Madinah Mushaf KFGQPC 1405H", "pages": pages, "juz": juz})

    integrity = {
        "schema": "integrity.v1",
        "version": QURAN_VERSION,
        "surahCount": len(surahs),
        "ayahCount": sum(counts),
        "ayahCounts": counts,
        "allAyahsSha256": ayah_hash(surahs),
        "surahSha256": [sha("\n".join(s["ayahs"])) for s in surahs],
        "upstreamFileSha256": bundle["source"]["upstreamSha256"],
        "pageCount": len(pages),
    }
    dump(C / "quran/dist/integrity.v1.json", integrity)

    # --- Adhkar ---------------------------------------------------------------
    adhkar_src = json.loads((C / "adhkar/adhkar.json").read_text(encoding="utf-8"))
    dump(C / "adhkar/dist/adhkar.v1.json", {"schema": "adhkar.v1", "source": "Kazi Shariar adhkar dataset (CC BY 4.0)", "items": adhkar_src})

    dump(C / "VERSIONS.json", {"quran": QURAN_VERSION, "pages": "1405H-1", "adhkar": "1.0.0"})

    # Independent cross-checks against reference data (not derived from the source).
    problems = []
    if counts != ref["ayahCounts"]:
        problems.append("ayah counts differ from reference")
    if sum(counts) != 6236 or len(surahs) != 114:
        problems.append("totals wrong")
    if integrity["upstreamFileSha256"] != ref["upstreamFileSha256"]:
        problems.append("upstream file hash changed")
    if len(pages) != 604:
        problems.append("page count")
    for p, q in zip(pages, pages[1:]):
        a, b = p["end"], q["start"]
        nxt = [a[0], a[1] + 1] if a[1] < counts[a[0] - 1] else [a[0] + 1, 1]
        if b != nxt:
            problems.append(f"page gap/overlap between {p['page']} and {q['page']}: {a} -> {b}")
    if pages[0]["start"] != [1, 1] or pages[-1]["end"] != [114, 6]:
        problems.append("page range ends")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 1
    print(f"ok: {len(surahs)} surahs, {sum(counts)} ayahs, {len(pages)} pages, sha256={integrity['allAyahsSha256'][:16]}…")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
