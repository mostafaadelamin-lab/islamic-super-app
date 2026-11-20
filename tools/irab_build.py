#!/usr/bin/env python3
"""Builds the i'rab, sarf, balagha and fawa'id of every ayah from «الجدول في إعراب القرآن وصرفه وبيانه»
(Mahmud Safi), as published in the public GitHub repository spa5k/tafsir_api (folder
tafsir/al-jadwal-fi-i-rab-al-quran, MIT; one plain-text entry per ayah).

Output: content/irab/dist/jadwal.v1.json.gz, schema "irab.v1":
    {"schema", "id", "nameAr", "authorAr", "upstream", "surahs": [[[from, to, irab, sarf, balagha, fawaid], ...]]}
A section covers ayahs from..to when the book gives them the same entry. Each part is the book's text under
its heading («الإعراب» / «الصرف» / «البلاغة» / «الفوائد»), verbatim, or "" when the book has no such part
for these ayahs. Only blank lines are collapsed; no word is added, removed or changed.
"""
from __future__ import annotations

import gzip
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
C = ROOT / "content"
UP = C / "irab/upstream/al-jadwal.json.gz"
DIST = C / "irab/dist/jadwal.v1.json.gz"
REPO = "https://github.com/spa5k/tafsir_api.git"
FOLDER = "tafsir/al-jadwal-fi-i-rab-al-quran"

# A heading line, e.g. "* الإعراب:" or "الإعراب:" (not "- القلب:" or a sentence ending in a colon).
HEADING = re.compile(r"^\*?\s*(الإعراب|الصرف|البلاغة|الفوائد|فوائد)\s*:\s*$", re.M)
PART = {"الإعراب": 0, "الصرف": 1, "البلاغة": 2, "الفوائد": 3, "فوائد": 3}


def fetch() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["git", "clone", "-q", "--depth", "1", "--filter=blob:none", "--sparse", REPO, tmp], check=True)
        subprocess.run(["git", "-C", tmp, "sparse-checkout", "set", FOLDER], check=True)
        commit = subprocess.run(["git", "-C", tmp, "rev-parse", "HEAD"], check=True, capture_output=True, text=True).stdout.strip()
        folder = Path(tmp) / FOLDER
        out = {
            "source": f"{REPO} {FOLDER} @ {commit} (MIT)",
            "surahs": [json.loads((folder / f"{i}.json").read_text(encoding="utf-8")) for i in range(1, 115)],
        }
    UP.parent.mkdir(parents=True, exist_ok=True)
    UP.write_bytes(gzip.compress(json.dumps(out, ensure_ascii=False).encode(), 9, mtime=0))


def tidy(s: str) -> str:
    return re.sub(r"\n[ \t]*\n+", "\n", s.replace("\r", "")).strip()


def split(text: str) -> list[str]:
    parts = ["", "", "", ""]
    marks = list(HEADING.finditer(text))
    # An entry without headings (e.g. «انظر إعرابها في الآية (1) من سورة البقرة.») and any text before the first
    # heading belong to the i'rab.
    lead = tidy(text[: marks[0].start()] if marks else text)
    if lead:
        parts[0] = lead
    for i, m in enumerate(marks):
        end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
        k = PART[m.group(1)]
        body = tidy(text[m.end() : end])
        parts[k] = f"{parts[k]}\n{body}".strip() if parts[k] else body
    return parts


def main() -> None:
    if "--fetch" in sys.argv or not UP.exists():
        fetch()
    raw = UP.read_bytes()
    data = json.loads(gzip.decompress(raw))
    quran = json.loads((C / "quran/dist/quran.v1.json").read_text(encoding="utf-8"))
    counts = [len(s["ayahs"]) for s in quran["surahs"]]
    surahs = []
    for si, (entries, count) in enumerate(zip(data["surahs"], counts), start=1):
        if [e["ayah"] for e in entries] != list(range(1, count + 1)) or any(e["surah"] != si for e in entries):
            raise SystemExit(f"surah {si}: ayah numbering differs from the Quran")
        secs: list[list] = []
        for e in entries:
            parts = split(e["text"])
            if secs and secs[-1][2:] == parts:
                secs[-1][1] = e["ayah"]
            else:
                secs.append([e["ayah"], e["ayah"], *parts])
        surahs.append(secs)
    book = {
        "schema": "irab.v1",
        "id": "jadwal",
        "nameAr": "الجدول في إعراب القرآن وصرفه وبيانه",
        "authorAr": "محمود صافي",
        "upstream": {"source": data["source"], "sha256": hashlib.sha256(raw).hexdigest()},
        "surahs": surahs,
    }
    body = json.dumps(book, ensure_ascii=False, separators=(",", ":")).encode()
    DIST.parent.mkdir(parents=True, exist_ok=True)
    DIST.write_bytes(gzip.compress(body, 9, mtime=0))
    n = sum(len(s) for s in surahs)
    filled = [sum(1 for s in surahs for x in s if x[2 + k]) for k in range(4)]
    print(f"jadwal: {n} sections, {len(body) / 1e6:.1f} MB, parts filled (irab, sarf, balagha, fawaid): {filled}", file=sys.stderr)


if __name__ == "__main__":
    main()
