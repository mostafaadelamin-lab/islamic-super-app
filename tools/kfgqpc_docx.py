"""Reads the Quran text out of the King Fahd Complex's official font package.

Since its new website (qurancomplex.gov.sa/fonts/hafs) the Complex publishes the Hafs text as a Word
document inside the font package, e.g. hafs-2.2.zip -> "UthmanicHafs v22.docx", with the package's
SHA-256 printed on the download page. This module takes every ayah out of that document exactly as
written: no character is changed, added or removed. Each ayah in the document ends with a no-break
space and its number in Arabic-Indic digits; that suffix is split off (the apps draw the number with
the Complex's font, as before).
"""
from __future__ import annotations

import hashlib
import re
import zipfile
from pathlib import Path

SURAH_TITLE = "سُورَةُ"
AYAH_END = re.compile(" ([٠-٩]+)")
DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")


def paragraphs(docx_xml: str) -> list[str]:
    out = []
    for p in re.findall(r"<w:p[ >].*?</w:p>", docx_xml, re.S):
        t = "".join(re.findall(r"<w:t(?: [^>]*)?>(.*?)</w:t>", p, re.S))
        if t.strip():
            out.append(t)
    return out


def read_package(zip_path: Path, docx_name: str, expected_sha256: str) -> list[list[str]]:
    """Returns the 114 surahs, each a list of ayah texts (without the ayah-number suffix)."""
    raw = zip_path.read_bytes()
    got = hashlib.sha256(raw).hexdigest()
    if got != expected_sha256.lower():
        raise SystemExit(f"{zip_path.name}: SHA-256 {got} is not the one published by the Complex ({expected_sha256})")
    with zipfile.ZipFile(zip_path) as z:
        with zipfile.ZipFile(z.open(docx_name)) as d:
            xml = d.read("word/document.xml").decode("utf-8")
    if "&" in re.sub(r"&(amp|lt|gt|quot|apos);", "", xml):
        raise SystemExit("unexpected XML entity in the Word document")
    surahs: list[list[str]] = []
    for para in paragraphs(xml):
        if para.startswith(SURAH_TITLE) and " " not in para:
            surahs.append([])
            continue
        if not surahs:
            raise SystemExit("text before the first surah title")
        surahs[-1].append(para)
    if len(surahs) != 114:
        raise SystemExit(f"{len(surahs)} surah titles, expected 114")
    result = []
    for n, paras in enumerate(surahs, start=1):
        if paras and " " not in paras[0]:  # the basmala line above a surah (not an ayah except in al-Fatiha)
            paras = paras[1:]
        body = " ".join(paras)
        parts = AYAH_END.split(body)
        if parts[-1].strip():
            raise SystemExit(f"surah {n}: text after the last ayah number")
        ayahs = []
        for i in range(0, len(parts) - 1, 2):
            number = int(parts[i + 1].translate(DIGITS))
            if number != len(ayahs) + 1:
                raise SystemExit(f"surah {n}: ayah {number} out of order")
            text = parts[i][1:] if i else parts[i]  # the space that follows the previous ayah number
            if text != text.strip(" ") or not text:
                raise SystemExit(f"surah {n} ayah {number}: unexpected spacing")
            ayahs.append(text)
        result.append(ayahs)
    return result
