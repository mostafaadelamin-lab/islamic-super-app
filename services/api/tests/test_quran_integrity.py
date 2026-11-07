"""Quran text integrity: the served text must equal the pinned upstream source byte-for-byte."""

import hashlib
import json

from .conftest import REPO

DIST = REPO / "content/quran/dist"
BUNDLE = json.loads((DIST / "quran.v1.json").read_text(encoding="utf-8"))
INTEG = json.loads((DIST / "integrity.v1.json").read_text(encoding="utf-8"))
PAGES = json.loads((DIST / "pages.v1.json").read_text(encoding="utf-8"))["pages"]
REF = json.loads((REPO / "tests/vectors/quran-reference.json").read_text(encoding="utf-8"))
UPSTREAM = REPO / "content/quran/upstream/quran-json-3.1.2.quran.json"


def test_upstream_file_hash_is_pinned():
    assert hashlib.sha256(UPSTREAM.read_bytes()).hexdigest() == REF["upstreamFileSha256"]


def test_114_surahs_and_6236_ayahs():
    assert len(BUNDLE["surahs"]) == 114
    assert sum(len(s["ayahs"]) for s in BUNDLE["surahs"]) == 6236


def test_ayah_counts_match_independent_reference():
    assert [len(s["ayahs"]) for s in BUNDLE["surahs"]] == REF["ayahCounts"]
    assert [s["ayahCount"] for s in BUNDLE["surahs"]] == REF["ayahCounts"]


def test_surah_order():
    assert [s["n"] for s in BUNDLE["surahs"]] == list(range(1, 115))


def test_text_identical_to_upstream_every_ayah():
    up = json.loads(UPSTREAM.read_text(encoding="utf-8"))
    for s, u in zip(BUNDLE["surahs"], up, strict=True):
        assert s["ayahs"] == [v["text"] for v in u["verses"]], s["n"]


def test_hashes():
    lines = "".join(f"{s['n']}|{i + 1}|{t}\n" for s in BUNDLE["surahs"] for i, t in enumerate(s["ayahs"]))
    assert hashlib.sha256(lines.encode()).hexdigest() == INTEG["allAyahsSha256"]
    for s in BUNDLE["surahs"]:
        assert hashlib.sha256("\n".join(s["ayahs"]).encode()).hexdigest() == INTEG["surahSha256"][s["n"] - 1]


def test_no_display_glyph_substitution_in_stored_text():
    render = json.loads((REPO / "packages/shared-schemas/quran-render.json").read_text(encoding="utf-8"))
    joined = "".join(t for s in BUNDLE["surahs"] for t in s["ayahs"])
    for target in render["map"].values():
        assert target not in joined  # U+08F0..08F2 must never appear in canonical text
    assert any(src in joined for src in render["map"])


def test_spot_check_ayah_skeletons():
    # Compared on the letter skeleton (diacritics removed) so the expected values can be
    # typed independently of mark ordering; exact code points are covered by the hashes above.
    from app.domain.quran import QuranStore

    norm = QuranStore(REPO / "content").normalize
    s = BUNDLE["surahs"]
    assert norm(s[0]["ayahs"][0]) == "بسم الله الرحمن الرحيم"
    assert norm(s[111]["ayahs"][0]) == "قل هو الله احد"
    assert norm(s[113]["ayahs"][5]) == "من الجنه والناس"
    assert norm(s[1]["ayahs"][254]).startswith("الله لا اله الا هو الحي القيوم")


def test_604_madinah_pages_contiguous_and_complete():
    assert len(PAGES) == 604
    counts = REF["ayahCounts"]
    covered = 0
    for i, p in enumerate(PAGES):
        assert p["page"] == i + 1
        (s0, a0), (s1, a1) = p["start"], p["end"]
        assert (s0, a0) <= (s1, a1)
        covered += sum((a1 if s == s1 else counts[s - 1]) - (a0 if s == s0 else 1) + 1 for s in range(s0, s1 + 1))
    assert covered == 6236


def test_page_spot_checks_match_printed_mushaf():
    for sc in REF["madinahPageSpotChecks"]:
        p = PAGES[sc["page"] - 1]
        assert p["start"] == sc["start"] and p["end"] == sc["end"], sc


# --- 15-line Madinah layout (content/quran/dist/mushaf-lines.v1.json) ---------
LINES = json.loads((DIST / "mushaf-lines.v1.json").read_text(encoding="utf-8"))
QMH = REPO / "content/quran/upstream/quran-madina-html-2.2.2"


def test_mushaf_lines_upstream_files_pinned():
    for row in (QMH / "SHA256SUMS").read_text(encoding="utf-8").splitlines():
        digest, name = row.split()
        assert hashlib.sha256((QMH / name).read_bytes()).hexdigest() == digest, name


def test_mushaf_lines_hash_recorded():
    blob = json.dumps(LINES["pages"], ensure_ascii=False, separators=(",", ":"), sort_keys=True)
    assert hashlib.sha256(blob.encode("utf-8")).hexdigest() == INTEG["mushafLinesSha256"]


def test_mushaf_lines_604_pages_15_lines():
    pages = LINES["pages"]
    assert [p["page"] for p in pages] == list(range(1, 605))
    assert [len(p["lines"]) for p in pages[:2]] == [8, 8]
    assert all(len(p["lines"]) == 15 for p in pages[2:])


def test_mushaf_lines_cover_every_canonical_word_once_in_order():
    surahs = BUNDLE["surahs"]
    flat = [(g[0], g[1], w) for p in LINES["pages"] for line in p["lines"] if line["k"] == "text" for g in line["g"] for w in range(g[2], g[3])]
    expected = [(s["n"], a, w) for s in surahs for a, t in enumerate(s["ayahs"], start=1) for w in range(len(t.split(" ")))]
    assert flat == expected
    ends = [(g[0], g[1]) for p in LINES["pages"] for line in p["lines"] if line["k"] == "text" for g in line["g"] if g[4]]
    assert len(ends) == 6236


def test_mushaf_lines_page_ends_agree_with_page_map():
    for p, meta in zip(LINES["pages"], PAGES, strict=True):
        ends = [[g[0], g[1]] for line in p["lines"] if line["k"] == "text" for g in line["g"] if g[4]]
        assert ends[-1] == meta["end"], p["page"]


def test_mushaf_lines_surah_bands_and_basmala():
    bands = [line["s"] for p in LINES["pages"] for line in p["lines"] if line["k"] == "sura"]
    assert bands == list(range(1, 115))
    basmala = [line["s"] for p in LINES["pages"] for line in p["lines"] if line["k"] == "basmala"]
    # Al-Fatihah's basmala is ayah 1 (a text line); at-Tawbah has none.
    assert basmala == [s for s in range(2, 115) if s != 9]


def test_mushaf_lines_printed_page_spot_checks():
    first = {p["page"]: next(g for line in p["lines"] if line["k"] == "text" for g in line["g"]) for p in LINES["pages"]}
    assert first[3][:2] == [2, 6]  # p3 begins "إن الذين كفروا سواء عليهم"
    assert first[50][:2] == [3, 1]
    assert first[604][:2] == [112, 1]
