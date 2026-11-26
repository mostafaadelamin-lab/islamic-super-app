"""Quran text integrity: the served text must equal the pinned upstream source byte-for-byte."""

import hashlib
import json
import re
import sys

from .conftest import REPO

DIST = REPO / "content/quran/dist"
BUNDLE = json.loads((DIST / "quran.v1.json").read_text(encoding="utf-8"))
INTEG = json.loads((DIST / "integrity.v1.json").read_text(encoding="utf-8"))
PAGES = json.loads((DIST / "pages.v1.json").read_text(encoding="utf-8"))["pages"]
REF = json.loads((REPO / "tests/vectors/quran-reference.json").read_text(encoding="utf-8"))
UPSTREAM = REPO / "content/quran/upstream/kfgqpc-hafs-v18.json"  # KFGQPC hafsData_v18.json: page/line/juz columns
PACKAGE = REPO / "content/quran/upstream/kfgqpc-hafs-2.2.zip"  # KFGQPC official package v2.2: the text
AYAH_NUMBER_SUFFIX = re.compile("\u00a0[\u0660-\u0669]+$")
# SHA-256 of hafs-2.2.zip exactly as printed by the Complex on qurancomplex.gov.sa/fonts/hafs
PUBLISHED_PACKAGE_SHA256 = "B5CF0666441AABD5FF2BE4993934E6F2A57D00B6B89AFCDF708CD70288671B23"


def test_upstream_file_hash_is_pinned():
    assert hashlib.sha256(PACKAGE.read_bytes()).hexdigest() == REF["upstreamFileSha256"] == PUBLISHED_PACKAGE_SHA256.lower()
    assert hashlib.sha256(UPSTREAM.read_bytes()).hexdigest() == REF["pagesFileSha256"]
    assert INTEG["upstreamFileSha256"] == REF["upstreamFileSha256"]


def test_text_identical_to_the_complex_v22_document_every_ayah():
    sys.path.insert(0, str(REPO / "tools"))
    import kfgqpc_docx

    v22 = kfgqpc_docx.read_package(PACKAGE, "UthmanicHafs v22.docx", PUBLISHED_PACKAGE_SHA256)
    assert [s["ayahs"] for s in BUNDLE["surahs"]] == v22


def test_114_surahs_and_6236_ayahs():
    assert len(BUNDLE["surahs"]) == 114
    assert sum(len(s["ayahs"]) for s in BUNDLE["surahs"]) == 6236


def test_ayah_counts_match_independent_reference():
    assert [len(s["ayahs"]) for s in BUNDLE["surahs"]] == REF["ayahCounts"]
    assert [s["ayahCount"] for s in BUNDLE["surahs"]] == REF["ayahCounts"]


def test_surah_order():
    assert [s["n"] for s in BUNDLE["surahs"]] == list(range(1, 115))


def test_text_equals_v18_except_the_kashida_of_kalla():
    # v22 = v18 aya_text byte-for-byte (minus its trailing NBSP + ayah number), except that v22 dropped
    # the kashida the Complex had put in «كـَلَّا» (33 places)
    rows = json.loads(UPSTREAM.read_text(encoding="utf-8"))
    assert [r["id"] for r in rows] == list(range(1, 6237))
    bundled = [(s["n"], i + 1, t) for s in BUNDLE["surahs"] for i, t in enumerate(s["ayahs"])]
    changed = 0
    for (n, a, text), r in zip(bundled, rows, strict=True):
        assert (n, a) == (r["sora"], r["aya_no"])
        suffix = AYAH_NUMBER_SUFFIX.search(r["aya_text"])
        assert suffix and int(suffix.group()[1:].translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))) == a
        v18 = r["aya_text"][: suffix.start()]
        if text != v18:
            changed += 1
            assert v18.count("\u0643\u0640") == 1 and v18.replace("\u0643\u0640", "\u0643") == text, (n, a)
    assert changed == 33


def test_pages_match_kfgqpc_v18_every_ayah():
    rows = json.loads(UPSTREAM.read_text(encoding="utf-8"))
    page_of = {(r["sora"], r["aya_no"]): r["page"] for r in rows}
    for p in PAGES:
        assert page_of[tuple(p["start"])] == p["page"]
        assert page_of[tuple(p["end"])] == p["page"]


def test_hashes():
    lines = "".join(f"{s['n']}|{i + 1}|{t}\n" for s in BUNDLE["surahs"] for i, t in enumerate(s["ayahs"]))
    assert hashlib.sha256(lines.encode()).hexdigest() == INTEG["allAyahsSha256"]
    for s in BUNDLE["surahs"]:
        assert hashlib.sha256("\n".join(s["ayahs"]).encode()).hexdigest() == INTEG["surahSha256"][s["n"] - 1]


def test_no_display_glyph_substitution_in_stored_text():
    render = json.loads((REPO / "packages/shared-schemas/quran-render.json").read_text(encoding="utf-8"))
    joined = "".join(t for s in BUNDLE["surahs"] for t in s["ayahs"])
    # the Complex's own font draws its text as published: no display substitution at all
    assert render["map"] == {}
    assert render["font"] == "KFGQPC HAFS Uthmanic Script"
    for cp in ("\u08f0", "\u08f1", "\u08f2"):
        assert cp not in joined
    assert "\u0657" in joined  # KFGQPC open tanween code points are kept


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


# --- Tafsir al-Muyassar --------------------------------------------------------
TAFSIR = json.loads((REPO / "content/tafsir/dist/muyassar.v1.json").read_text(encoding="utf-8"))
TAFSIR_UP = REPO / "content/tafsir/upstream/muslimjs-ar.muyassar-1.0.0.json"


def test_tafsir_upstream_pinned():
    digest = hashlib.sha256(TAFSIR_UP.read_bytes()).hexdigest()
    assert digest == "0d0441ae058d5d36cd450d8e9f768a2c5f918e30048316553bc873fb75770da3"
    assert TAFSIR["upstreamSha256"] == digest


def test_tafsir_one_entry_per_ayah_unmodified():
    up = json.loads(TAFSIR_UP.read_text(encoding="utf-8"))["surahs"]
    assert [len(s) for s in TAFSIR["surahs"]] == INTEG["ayahCounts"]
    assert TAFSIR["surahs"] == [[a["text"] for a in s["ayahs"]] for s in up]
    assert all(t.strip() for s in TAFSIR["surahs"] for t in s)


def test_tafsir_spot_checks():
    assert "الكرسي" in TAFSIR["surahs"][1][254]  # 2:255 Ayat al-Kursi
    assert "أحد" in TAFSIR["surahs"][111][0]  # 112:1


def test_juz_starts_follow_the_printed_margin_marks():
    # Owner's printed Madinah Mushaf (photos 2026-11-11): page 62 header "الجزء الرابع" with the margin mark
    # "الجزء ٤ / الحزب ٧" at ۞ 3:93; page 201 header "الجزء العاشر" with "الجزء ١١ / الحزب ٢١" at ۞ 9:93;
    # page 202 header "الجزء الحادي عشر".
    juz = {j["juz"]: j for j in json.loads((DIST / "pages.v1.json").read_text(encoding="utf-8"))["juz"]}
    assert juz[4] == {"juz": 4, "page": 62, "start": [3, 93]}
    assert juz[11] == {"juz": 11, "page": 202, "start": [9, 93]}
    quarters = json.loads((DIST / "pages.v1.json").read_text(encoding="utf-8"))["quarters"]
    for j in juz.values():
        assert quarters[(j["juz"] - 1) * 8]["start"] == j["start"]
