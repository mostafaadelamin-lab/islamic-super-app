#!/usr/bin/env python3
"""Builds the extra tafsir books (al-Sa'di, Ibn Kathir, al-Tabari, al-Baghawi) from the Quranpedia.net
open-data dumps (https://quranpedia.net/dumps, licence: content/tafsir/upstream/QURANPEDIA-LICENSE.md).

Input : content/tafsir/upstream/quranpedia/tafsir-book-<id>.json.gz (downloaded with --fetch)
Output: content/tafsir/dist/<key>.v1.json.gz, schema "tafsir-book.v1":
    {"schema", "id", "nameAr", "authorAr", "upstream": {...},
     "surahs": [ [[from, to, text, notes], ...] per surah ]}
Each surah is a list of sections in Mushaf order; a section covers ayahs from..to (the book explains them
together). Every ayah of the Quran belongs to exactly one section.

The words are kept exactly as published. Only the HTML is removed: line breaks, headings and paragraphs
become new lines, the two halves of a verse of poetry are separated by spaces, and the editor's footnotes
(the "foot-notes" block of each page) are moved to `notes`. Nothing is added, reworded or shortened.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import html
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
C = ROOT / "content"
UP = C / "tafsir/upstream/quranpedia"
DIST = C / "tafsir/dist"

# key -> (Quranpedia book id, Arabic name shown in the app, author)
BOOKS: dict[str, tuple[int, str, str]] = {
    "saadi": (3, "تفسير السعدي", "عبد الرحمن بن ناصر السعدي"),
    "ibn-kathir": (136, "تفسير ابن كثير", "إسماعيل بن عمر بن كثير"),
    "tabari": (4, "تفسير الطبري", "محمد بن جرير الطبري"),
    "baghawi": (2, "تفسير البغوي", "الحسين بن مسعود البغوي"),
    "qurtubi": (0, "تفسير القرطبي", "محمد بن أحمد القرطبي"),
    "jalalayn": (272, "تفسير الجلالين", "جلال الدين المحلي وجلال الدين السيوطي"),
}
DEFAULT_KEYS = ["saadi", "ibn-kathir", "tabari", "baghawi", "qurtubi"]
# al-Qurtubi is not in the Quranpedia dumps: it comes from the public GitHub repository spa5k/tafsir_api
# (MIT; plain text per ayah), saved as one file by --fetch.
QURTUBI_UP = C / "tafsir/upstream/qurtubi/ar-tafseer-al-qurtubi.json.gz"
QURTUBI_REPO = "https://github.com/spa5k/tafsir_api.git"

FOOT = re.compile(r'<div class="foot-notes">(.*?)</div>', re.S)


def clean(fragment: str) -> str:
    s = fragment.replace("\r", "")
    s = re.sub(r"</td>\s*<td[^>]*>", "  ", s)  # two halves of a verse
    s = re.sub(r"<(br|hr)[^>]*/?>", "\n", s)
    s = re.sub(r"</?(p|h\d|tr|table|div)[^>]*>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    s = re.sub(r"[ \t ]+\n", "\n", s)
    s = re.sub(r"\n[ \t ]+", "\n", s)
    s = re.sub(r"\n{2,}", "\n", s)
    return s.strip()


def split_chunk(text: str) -> tuple[str, str]:
    notes = [clean(m) for m in FOOT.findall(text)]
    body = clean(FOOT.sub("\n", text))
    return body, "\n".join(n for n in notes if n)


def build(key: str, ayah_counts: list[int]) -> dict:
    book_id, name, author = BOOKS[key]
    src = QURTUBI_UP if key == "qurtubi" else UP / f"tafsir-book-{book_id}.json.gz"
    raw = src.read_bytes()
    data = json.loads(gzip.decompress(raw))
    by_ref: dict[tuple[int, int], tuple] = {}
    if key == "qurtubi":
        for surah in data["surahs"]:
            for a in surah:
                if a["text"].strip():  # plain text: escape it so clean() keeps every character
                    by_ref[(a["surah"], a["ayah"])] = ((None, html.escape(a["text"], quote=False)),)
        data["book"] = {"name": "الجامع لأحكام القرآن"}
    for a in data.get("ayahs", []):
        chunks = tuple((c.get("page"), c["text"]) for c in a["content"] if c.get("text", "").strip())
        if chunks:
            by_ref[(a["surah"], a["ayah"])] = chunks
    surahs = []
    for si, count in enumerate(ayah_counts, start=1):
        sections: list[list] = []  # [from, to, chunks]
        for ay in range(1, count + 1):
            chunks = by_ref.get((si, ay))
            if chunks is None:
                if not sections:  # nothing yet: joins the next section that has text
                    nxt = next((by_ref[(si, b)] for b in range(ay + 1, count + 1) if (si, b) in by_ref), None)
                    if nxt is None:
                        raise SystemExit(f"{key}: surah {si} has no text")
                    sections.append([ay, ay, nxt])
                else:
                    sections[-1][1] = ay
                continue
            if sections and sections[-1][2] == chunks:
                sections[-1][1] = ay
            else:
                sections.append([ay, ay, chunks])
        out = []
        for f, t, chunks in sections:
            bodies, notes = zip(*(split_chunk(text) for _, text in chunks))
            body = "\n".join(b for b in bodies if b)
            note = "\n".join(n for n in notes if n)
            if not body:
                raise SystemExit(f"{key}: empty section {si}:{f}-{t}")
            out.append([f, t, body, note] if note else [f, t, body])
        # merge adjacent sections whose cleaned text is identical (same page split differently)
        merged: list[list] = []
        for sec in out:
            if merged and merged[-1][2:] == sec[2:]:
                merged[-1][1] = sec[1]
            else:
                merged.append(sec)
        assert merged[0][0] == 1 and merged[-1][1] == count
        assert all(merged[i][1] + 1 == merged[i + 1][0] for i in range(len(merged) - 1))
        surahs.append(merged)
    return {
        "schema": "tafsir-book.v1",
        "id": key,
        "nameAr": name,
        "authorAr": author,
        "upstream": {
            "source": data.get("source", "https://quranpedia.net/dumps"),
            "bookId": book_id,
            "title": data["book"].get("name"),
            "edition": data["book"].get("edition"),
            "publisher": data["book"].get("nasher"),
            "dumpVersion": data.get("license", {}).get("version"),
            "sha256": hashlib.sha256(raw).hexdigest(),
        },
        "surahs": surahs,
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("books", nargs="*", default=DEFAULT_KEYS)
    ap.add_argument("--fetch", action="store_true", help="download the dumps first")
    args = ap.parse_args()
    quran = json.loads((C / "quran/dist/quran.v1.json").read_text(encoding="utf-8"))
    counts = [len(s["ayahs"]) for s in quran["surahs"]]
    UP.mkdir(parents=True, exist_ok=True)
    DIST.mkdir(parents=True, exist_ok=True)
    for key in args.books:
        book_id = BOOKS[key][0]
        if key == "qurtubi":
            if args.fetch or not QURTUBI_UP.exists():
                fetch_qurtubi()
            book = build(key, counts)
            write(key, book)
            continue
        dst = UP / f"tafsir-book-{book_id}.json.gz"
        if args.fetch or not dst.exists():
            url = f"https://quranpedia.net/dumps/tafsir-book-{book_id}.json.gz"
            print("fetch", url, file=sys.stderr)
            dst.write_bytes(urllib.request.urlopen(url, timeout=120).read())
        write(key, build(key, counts))


def write(key: str, book: dict) -> None:
    body = json.dumps(book, ensure_ascii=False, separators=(",", ":")).encode()
    (DIST / f"{key}.v1.json.gz").write_bytes(gzip.compress(body, 9, mtime=0))
    n = sum(len(s) for s in book["surahs"])
    print(f"{key}: {n} sections, {len(body) / 1e6:.1f} MB", file=sys.stderr)


def fetch_qurtubi() -> None:
    import subprocess
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["git", "clone", "-q", "--depth", "1", "--filter=blob:none", "--sparse", QURTUBI_REPO, tmp], check=True)
        subprocess.run(["git", "-C", tmp, "sparse-checkout", "set", "tafsir/ar-tafseer-al-qurtubi"], check=True)
        commit = subprocess.run(["git", "-C", tmp, "rev-parse", "HEAD"], check=True, capture_output=True, text=True).stdout.strip()
        folder = Path(tmp) / "tafsir/ar-tafseer-al-qurtubi"
        out = {
            "source": f"{QURTUBI_REPO} tafsir/ar-tafseer-al-qurtubi @ {commit} (MIT)",
            "surahs": [json.loads((folder / f"{i}.json").read_text(encoding="utf-8")) for i in range(1, 115)],
        }
    QURTUBI_UP.parent.mkdir(parents=True, exist_ok=True)
    QURTUBI_UP.write_bytes(gzip.compress(json.dumps(out, ensure_ascii=False).encode(), 9, mtime=0))


if __name__ == "__main__":
    main()
