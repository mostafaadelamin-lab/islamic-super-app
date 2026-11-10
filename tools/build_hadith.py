#!/usr/bin/env python3
"""Builds content/hadith/dist from Open-Hadith-Data (ODbL 1.0).

Usage: python3 tools/build_hadith.py <path to a clone of github.com/mhashim6/Open-Hadith-Data>

Only the hadith text WITH diacritics (column 2 of the *_mushakkala*.csv files) is used, copied
byte for byte; the commentary column (tafseel) is left out. Each book is split into chunks of
CHUNK hadiths so the apps can load a part at a time. books.v1.json records the upstream commit and
the SHA-256 of every source file, so the build can be checked again.
"""
import csv
import hashlib
import json
import os
import subprocess
import sys

CHUNK = 500
EXPECTED_COMMIT = "1515f6cba21efed20d8916bf55acef1dffa0d2d5"

# id, upstream folder, Arabic name, English name, expected count (al-Alamiyya numbering).
BOOKS = [
    ("bukhari", "Sahih_Al-Bukhari", "صحيح البخاري", "Sahih al-Bukhari", 7008),
    ("muslim", "Sahih_Muslim", "صحيح مسلم", "Sahih Muslim", 5362),
    ("abudawud", "Sunan_Abu-Dawud", "سنن أبي داود", "Sunan Abi Dawud", 4590),
    ("tirmidhi", "Sunan_Al-Tirmidhi", "جامع الترمذي", "Jami' at-Tirmidhi", 3891),
    ("nasai", "Sunan_Al-Nasai", "سنن النسائي", "Sunan an-Nasa'i", 5662),
    ("ibnmajah", "Sunan_Ibn-Maja", "سنن ابن ماجه", "Sunan Ibn Majah", 4332),
    ("malik", "Maliks_Muwataa", "موطأ مالك", "Muwatta Malik", 1594),
    ("ahmad", "Musnad_Ahmad_Ibn-Hanbal", "مسند أحمد", "Musnad Ahmad", 26363),
    ("darimi", "Sunan_Al-Darimi", "سنن الدارمي", "Sunan ad-Darimi", 3367),
]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def main():
    src = sys.argv[1]
    commit = subprocess.check_output(["git", "-C", src, "rev-parse", "HEAD"], text=True).strip()
    if commit != EXPECTED_COMMIT:
        sys.exit(f"upstream commit {commit} != pinned {EXPECTED_COMMIT}; review the change, then update the pin")
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(repo, "content", "hadith", "dist")
    os.makedirs(out, exist_ok=True)
    csv.field_size_limit(1 << 30)
    books = []
    for bid, folder, ar, en, expected in BOOKS:
        files = [f for f in os.listdir(os.path.join(src, folder)) if "mushakkala" in f]
        if len(files) != 1:
            sys.exit(f"{folder}: expected one *mushakkala* file, got {files}")
        path = os.path.join(src, folder, files[0])
        with open(path, encoding="utf-8", newline="") as f:
            rows = list(csv.reader(f))
        if [r[0] for r in rows] != [str(i + 1) for i in range(len(rows))]:
            sys.exit(f"{bid}: hadith numbers are not 1..n")
        if len(rows) != expected:
            sys.exit(f"{bid}: {len(rows)} hadiths, expected {expected}")
        texts = [r[1] for r in rows]
        if any(not t.strip() for t in texts):
            sys.exit(f"{bid}: empty hadith text")
        os.makedirs(os.path.join(out, bid), exist_ok=True)
        chunks = (len(texts) + CHUNK - 1) // CHUNK
        for k in range(chunks):
            part = {"book": bid, "from": k * CHUNK + 1, "ahadith": texts[k * CHUNK:(k + 1) * CHUNK]}
            with open(os.path.join(out, bid, f"{k}.json"), "w", encoding="utf-8") as f:
                json.dump(part, f, ensure_ascii=False, separators=(",", ":"))
        books.append({
            "id": bid, "nameAr": ar, "nameEn": en, "count": len(texts), "chunks": chunks,
            "sourceFile": f"{folder}/{files[0]}", "sha256": sha256(path),
            # SHA-256 of the hadith texts joined with "\n": the apps' tests recompute it from the chunks.
            "textSha256": hashlib.sha256("\n".join(texts).encode("utf-8")).hexdigest(),
        })
        print(bid, len(texts), chunks)
    meta = {
        "version": 1,
        "reviewStatus": "pending",
        "numbering": "al-Alamiyya (Sakhr/Harf)",
        "chunkSize": CHUNK,
        "source": {
            "name": "Open-Hadith-Data",
            "url": "https://github.com/mhashim6/Open-Hadith-Data",
            "commit": commit,
            "licence": "ODbL 1.0 (database), DbCL 1.0 (contents)",
            "origin": "hadith-islamware (Islam Ware, 2006-2014)",
        },
        "books": books,
    }
    with open(os.path.join(out, "books.v1.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
