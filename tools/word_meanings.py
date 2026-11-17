#!/usr/bin/env python3
"""Word meanings (غريب القرآن) for the Mushaf: «السراج في بيان غريب القرآن» by Muhammad al-Khudairi.

Source: Quranpedia.net data dump `meanings.json.gz` (version 2026-11-14, sha256 below), book id 491.
Licence (content/word-meanings/upstream/QURANPEDIA-LICENSE.md): free to use inside apps and websites.
The words and meanings are copied verbatim; only surrounding whitespace is trimmed. Nothing is written by us.

Output: content/word-meanings/dist/siraj.v1.json
  surahs[s-1][a-1] = [[word, meaning], ...]   (empty list when the book has no entry for that ayah)
"""
from __future__ import annotations

import gzip
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
C = ROOT / "content"
UP = C / "word-meanings/upstream/quranpedia-meanings-2026-11-14.json.gz"
UP_SHA = "b46ca5ae7baa5287dc08816d5c6037e8ad9282e49cf870357e6bb6184b8d0699"
BOOK_ID = 491
OUT = C / "word-meanings/dist/siraj.v1.json"


def build() -> tuple[dict, list[str]]:
    raw = UP.read_bytes()
    problems: list[str] = []
    if hashlib.sha256(raw).hexdigest() != UP_SHA:
        problems.append("upstream file hash changed")
    data = json.loads(gzip.decompress(raw))
    counts = json.loads((C / "quran/dist/quran.v1.json").read_text(encoding="utf-8"))
    counts = [len(s["ayahs"]) for s in counts["surahs"]]
    surahs: list[list[list[list[str]]]] = [[[] for _ in range(n)] for n in counts]
    book = None
    for row in data["data"]:
        s, a = row["surah"], row["ayah"]
        for m in row["meanings"]:
            if m["book_info"]["id"] != BOOK_ID:
                continue
            book = m["book_info"]
            if not (1 <= s <= 114 and 1 <= a <= counts[s - 1]):
                problems.append(f"bad ref {s}:{a}")
                continue
            for w in m["words"]:
                word, meaning = w["text"].strip(), w["meaning"].strip()
                if not word or not meaning:
                    problems.append(f"empty entry at {s}:{a}")
                    continue
                if "<" in word + meaning:
                    problems.append(f"markup at {s}:{a}")
                surahs[s - 1][a - 1].append([word, meaning])
    if book is None:
        problems.append("book not found")
    total = sum(len(x) for s in surahs for x in s)
    if total < 6000:
        problems.append(f"only {total} words")
    out = {
        "schema": "word-meanings.v1",
        "id": "siraj",
        "nameAr": "السراج في بيان غريب القرآن",
        "authorAr": "محمد بن عبد العزيز الخضيري",
        "edition": (book or {}).get("edition"),
        "publisher": (book or {}).get("nasher"),
        "source": "Quranpedia.net data dump meanings.json.gz (version 2026-11-14), book 491; text copied unmodified",
        "upstreamSha256": UP_SHA,
        "wordCount": total,
        "surahs": surahs,
    }
    return out, problems


def main() -> int:
    out, problems = build()
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    for p in problems:
        print("word-meanings:", p, file=sys.stderr)
    print(f"word-meanings: {out['wordCount']} words -> {OUT.relative_to(ROOT)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
