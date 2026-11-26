#!/usr/bin/env python3
"""Build versioned, platform-neutral content bundles from pinned upstream sources.

The Quran text is the King Fahd Glorious Quran Printing Complex's own digital
text, version 2.2 (v22, 2024): the Word document inside the official package
hafs-2.2.zip from qurancomplex.gov.sa/fonts/hafs, whose SHA-256 the Complex
prints on that page (read by tools/kfgqpc_docx.py). Every ayah is copied
byte-for-byte; only the ayah number after the no-break space is split off (the
apps draw that number themselves, in the Complex's font). The page, line and
juz columns still come from the Complex's hafsData_v18.json (same 1441H
edition); the build checks that the v22 text equals the v18 text except the
33 places where v22 dropped the kashida in «كَلَّا» (owner's choice 2026-11-26). Nothing in this script edits, normalises or
re-encodes ayah text. Any glyph substitution needed
for a particular font happens at render time in the client, never in content.

Outputs (all deterministic, sorted keys, UTF-8):
  content/quran/dist/quran.v1.json       surahs + ayah text (+ English translation)
  content/quran/dist/pages.v1.json       Madinah Mushaf (KFGQPC, new edition 1441H, the pages of hafsData_v18) page boundaries (604), juz starts and
                                         the 240 hizb quarters (rub' al-hizb) with their start ayah and page
  content/quran/dist/integrity.v1.json   SHA-256 hashes used by every platform's tests
  content/quran/dist/mushaf-lines.v1.json  15-line Madinah page layout as word ranges of the canonical text
  content/adhkar/dist/adhkar.v1.json     morning/evening adhkar
  content/reels/dist/reels.v1.json       curated reels that passed validation (see tools/reels.py)
  content/stories/dist/stories.v1.json   audio Quranic stories: verse ranges + reviewed summaries (see tools/stories.py)
  content/VERSIONS.json                  content version registry
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import kfgqpc_docx  # noqa: E402
import mushaf_lines  # noqa: E402
import reels  # noqa: E402
import stories  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[1]
C = ROOT / "content"
QURAN_SRC = C / "quran/upstream/kfgqpc-hafs-v18.json"  # page/line/juz columns (and the v18 text the v22 text is checked against)
QURAN_PKG = C / "quran/upstream/kfgqpc-hafs-2.2.zip"  # official package, SHA-256 as printed on qurancomplex.gov.sa/fonts/hafs
QURAN_PKG_DOCX = "UthmanicHafs v22.docx"
QURAN_PKG_SHA256 = "B5CF0666441AABD5FF2BE4993934E6F2A57D00B6B89AFCDF708CD70288671B23"
KALLA_KASHIDA = "\u0643\u0640"  # «كـ»: v18 wrote كَلَّا with a kashida after the kaf; v22 does not (33 places)
META_SRC = C / "quran/upstream/quran-json-3.1.2.quran.json"  # surah names/transliteration only, never ayah text
EN_SRC = C / "translations/upstream/quran-json-3.1.2.quran_en.json"
MADINA = C / "quran/madina-1441h-manifest.json"
AYAH_NUMBER_SUFFIX = re.compile("\u00a0[\u0660-\u0669]+$")  # " ١" appended by the Complex to aya_text
REF = ROOT / "tests/vectors/quran-reference.json"
QUARTERS_SRC = C / "quran/upstream/quran-meta-7.0.0-hizb-quarters.json"
RUB_SIGN = "\u06de"  # ۞ printed in the Mushaf at the start of each hizb quarter

QURAN_VERSION = "3.0.0"  # 3.0.0: text = KFGQPC Hafs v22 (2.2); 2.0.0: v18, pages = new edition (1441H)


def sha(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def dump(path: pathlib.Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n", encoding="utf-8")


def ayah_hash(surahs) -> str:
    # Canonical line format: "<surah>|<ayah>|<text>\n" over all ayahs in order.
    return sha("".join(f"{s['n']}|{i + 1}|{t}\n" for s in surahs for i, t in enumerate(s["ayahs"])))


def page_of(pages, ref) -> int:
    r = list(ref)
    best = 1
    for p in pages:
        if p["start"] <= r:
            best = p["page"]
    return best


def build_quarters(surahs, pages, juz):
    """240 hizb quarters. Starts come from quran-meta (Tanzil) and are checked
    against the ۞ sign in the canonical text; no text is stored here, apps read
    the opening words from quran.v1.json."""
    problems = []
    src = json.loads(QUARTERS_SRC.read_text(encoding="utf-8"))["hizbQuarterList"]
    flat = [(s["n"], a) for s in surahs for a in range(1, s["ayahCount"] + 1)]
    marked = {(s["n"], a) for s in surahs for a, t in enumerate(s["ayahs"], 1) if RUB_SIGN in t}
    starts = []
    for x in src:
        if not 1 <= x <= len(flat):
            continue
        ref = flat[x - 1]
        if ref not in marked and ref[1] != 1 and flat[x - 2] in marked:
            ref = flat[x - 2]  # the Mushaf prints the sign one ayah earlier (only 15:49 vs Tanzil 15:50)
        starts.append(ref)
    if len(starts) != 240:
        problems.append(f"quarters: {len(starts)} starts, expected 240")
    if sorted(set(starts)) != starts:
        problems.append("quarters: starts not strictly increasing")
    if missing := marked - set(starts):
        problems.append(f"quarters: rub' al-hizb sign without a quarter start at {sorted(missing)}")
    if odd := [r for r in starts if r not in marked and r[1] != 1]:
        problems.append(f"quarters: start without the sign and not at a surah start: {odd}")
    # A juz starts at its rub' al-hizb sign (every 8th quarter), as the printed Madinah Mushaf marks it in
    # the margin ("الجزء ٤ / الحزب ٧" beside 3:93, "الجزء ١١ / الحزب ٢١" beside 9:93). The `page` of a juz is
    # the first page whose header carries its name (hafsData_v18 `jozz`): pages 62 and 202 for juz 4 and 11,
    # whose ۞ fall on the previous page's last line(s). Checked against the owner's printed copy 2026-11-11.
    for j in juz:
        k = (j["juz"] - 1) * 8
        if k >= len(starts):
            continue
        q = list(starts[k])
        if q != j["start"]:
            if page_of(pages, tuple(q)) not in (j["page"], j["page"] - 1):
                problems.append(f"quarters: juz {j['juz']} sign {q} far from its header page {j['page']}")
            j["start"] = q
    out = [{
        "n": i + 1,
        "hizb": i // 4 + 1,
        "quarter": i % 4,  # 0 = start of the hizb, 1..3 = 1/4, 2/4, 3/4
        "juz": i // 8 + 1,
        "start": list(r),
        "page": page_of(pages, r),
    } for i, r in enumerate(starts)]
    return out, problems


def main() -> int:
    kf = json.loads(QURAN_SRC.read_text(encoding="utf-8"))
    meta = json.loads(META_SRC.read_text(encoding="utf-8"))
    en = json.loads(EN_SRC.read_text(encoding="utf-8"))
    ref = json.loads(REF.read_text(encoding="utf-8"))
    assert [r["id"] for r in kf] == list(range(1, 6237)), "hafsData_v18 rows out of order"
    by_surah: dict[int, list[dict]] = {}
    for r in kf:
        by_surah.setdefault(r["sora"], []).append(r)
    v22 = kfgqpc_docx.read_package(QURAN_PKG, QURAN_PKG_DOCX, QURAN_PKG_SHA256)
    kalla_changes = 0
    surahs = []
    for s, e in zip(meta, en, strict=True):
        assert s["id"] == e["id"]
        rows = by_surah[s["id"]]
        assert [r["aya_no"] for r in rows] == list(range(1, len(rows) + 1)), s["id"]
        ayahs = []
        for r in rows:
            m = AYAH_NUMBER_SUFFIX.search(r["aya_text"])
            assert m and int(m.group(0)[1:].translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))) == r["aya_no"], (s["id"], r["aya_no"])
            v18_text = r["aya_text"][: m.start()]
            text = v22[s["id"] - 1][r["aya_no"] - 1]
            if text != v18_text:
                # the only allowed difference: one kashida dropped from «كـَلَّا»
                assert v18_text.count(KALLA_KASHIDA) == 1 and v18_text.replace(KALLA_KASHIDA, "\u0643") == text, (s["id"], r["aya_no"])
                kalla_changes += 1
            ayahs.append(text)
        surahs.append({
            "n": s["id"],
            "nameAr": s["name"],
            "translit": s["transliteration"],
            "nameEn": e["translation"],
            "revelation": s["type"],
            "ayahCount": len(rows),
            "ayahs": ayahs,
            "en": [v["translation"] for v in e["verses"]],
        })
        assert len(e["verses"]) == len(rows)
    assert [len(a) for a in v22] == [s["ayahCount"] for s in surahs]
    assert kalla_changes == 33, kalla_changes

    # --- Madinah Mushaf (KFGQPC new edition, 1441H) page boundaries ----------
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
    # Juz starts and the page of every ayah come from the Complex's own data (jozz, page columns).
    first = {}
    for r in kf:
        first.setdefault(r["jozz"], r)
    juz = [{"juz": j, "page": first[j]["page"], "start": [first[j]["sora"], first[j]["aya_no"]]} for j in range(1, 31)]
    juz_problems = []
    kf_page_start = {}
    for r in kf:
        kf_page_start.setdefault(r["page"], [r["sora"], r["aya_no"]])
    for p in pages:
        if kf_page_start.get(p["page"]) != p["start"]:
            juz_problems.append(f"page {p['page']} starts at {p['start']} but hafsData_v18 says {kf_page_start.get(p['page'])}")
    quarters, quarter_problems = build_quarters(surahs, pages, juz)

    bundle = {
        "schema": "quran.v1",
        "version": QURAN_VERSION,
        "riwayah": "Hafs an Asim",
        "numbering": "Kufi (6236)",
        "source": {
            "text": "King Fahd Glorious Quran Printing Complex, Hafs text version 2.2 (v22), \"UthmanicHafs v22.docx\" in the official package hafs-2.2.zip (qurancomplex.gov.sa/fonts/hafs), byte-for-byte; ayah-number suffix removed",
            "font": "KFGQPC HAFS Uthmanic Script version 2.2 (the Complex's font for this text, distributed unmodified)",
            "pages": "hafsData_v18.json page/line_start/line_end/jozz (KFGQPC new edition 1441H)",
            "translationEn": "Saheeh International via quran-json@3.1.2 (licence review pending, see docs/CONTENT_SOURCES.md)",
            "upstreamSha256": hashlib.sha256(QURAN_PKG.read_bytes()).hexdigest(),
            "pagesSha256": hashlib.sha256(QURAN_SRC.read_bytes()).hexdigest(),
        },
        "surahs": surahs,
    }
    dump(C / "quran/dist/quran.v1.json", bundle)
    dump(C / "quran/dist/pages.v1.json", {"schema": "pages.v1", "layout": "Madinah Mushaf KFGQPC new edition (1441H)", "pages": pages, "juz": juz, "quarters": quarters,
         "quartersSource": "starts from npm quran-meta@7.0.0 (Tanzil data), checked against the rub' al-hizb sign in the canonical KFGQPC text; where the two differ the Mushaf text wins (15:49)"})

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
    lines_bundle, line_problems = mushaf_lines.build(C, surahs, pages, kf)
    dump(C / "quran/dist/mushaf-lines.v1.json", lines_bundle)
    integrity["mushafLinesSha256"] = sha(json.dumps(lines_bundle["pages"], ensure_ascii=False, separators=(",", ":"), sort_keys=True))
    dump(C / "quran/dist/integrity.v1.json", integrity)

    # --- Adhkar ---------------------------------------------------------------
    adhkar_src = json.loads((C / "adhkar/adhkar.json").read_text(encoding="utf-8"))
    dump(C / "adhkar/dist/adhkar.v1.json", {"schema": "adhkar.v1", "source": "Kazi Shariar adhkar dataset (CC BY 4.0)", "items": adhkar_src})

    # --- Tafsir al-Muyassar (King Fahd Complex), Arabic, one entry per ayah -------
    muy_src = json.loads((C / "tafsir/upstream/muslimjs-ar.muyassar-1.0.0.json").read_text(encoding="utf-8"))
    muy = [[a["text"] for a in s["ayahs"]] for s in muy_src["surahs"]]
    if [s["number"] for s in muy_src["surahs"]] != list(range(1, 115)):
        print("tafsir: surah order", file=sys.stderr)
        return 1
    for s in muy_src["surahs"]:
        if [a["numberInSurah"] for a in s["ayahs"]] != list(range(1, len(s["ayahs"]) + 1)):
            print(f"tafsir: ayah numbering in surah {s['number']}", file=sys.stderr)
            return 1
    dump(C / "tafsir/dist/muyassar.v1.json", {
        "schema": "tafsir.v1",
        "id": "muyassar",
        "nameAr": "التفسير الميسر",
        "nameEn": "Al-Tafsir al-Muyassar",
        "author": "King Fahd Glorious Quran Printing Complex (Madinah)",
        "source": "npm @muslimjs/ar.muyassar@1.0.0 Data/ar.muyassar.json (alquran.cloud / Tanzil edition ar.muyassar); text copied unmodified",
        "upstreamSha256": hashlib.sha256((C / "tafsir/upstream/muslimjs-ar.muyassar-1.0.0.json").read_bytes()).hexdigest(),
        "surahs": muy,
    })

    dump(C / "VERSIONS.json", {"quran": QURAN_VERSION, "pages": "1441H-1", "adhkar": "1.0.0", "tafsir": "muyassar-1"})

    # Independent cross-checks against reference data (not derived from the source).
    problems = list(line_problems) + quarter_problems + juz_problems
    # --- Curated reels (YouTube/Instagram embeds, religious review status) -------
    _, reel_problems = reels.build()
    problems += [f"reels: {x}" for x in reel_problems]
    # --- Audio Quranic stories (verse ranges checked against the ayah counts) ----
    _, story_problems = stories.build()
    problems += [f"stories: {x}" for x in story_problems]
    if counts != ref["ayahCounts"]:
        problems.append("ayah counts differ from reference")
    if sum(counts) != 6236 or len(surahs) != 114:
        problems.append("totals wrong")
    if integrity["upstreamFileSha256"] != ref["upstreamFileSha256"]:
        problems.append("upstream file hash changed")
    if [len(x) for x in muy] != counts:
        problems.append("tafsir ayah counts differ from the Quran")
    if any(not t.strip() for x in muy for t in x):
        problems.append("empty tafsir entry")
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
