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
