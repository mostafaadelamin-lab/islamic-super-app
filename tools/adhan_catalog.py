"""Builds the muezzin catalogue from a saved copy of the adhan selection page (owner's choice, 2026-11-10).

Usage: python tools/adhan_catalog.py <saved-page.html>
Writes apps/mobile/assets/content/adhan_catalog.json and apps/web/public/data/adhan-catalog.json.

Each entry: id (the site's audio id), muezzin (name shown in the app), place (city / country words of the
title, may be empty), fajr (true for a Fajr adhan, which has "as-salatu khayrun min an-nawm").
The audio itself is downloaded by the app when the user picks a muezzin.
"""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
UNKNOWN = "غير معروف"
BY_VOICE = re.compile(r"(?:بصوت|للشيخ|للقارئ|لفضيله الشيخ|لفضيلة الشيخ)\s*[:\-_.]*\s*(?:الشيخ|القارئ|فضيلة الشيخ|الحاج)?\s*(.+)")


def clean(s: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(s)).strip(" -_.,،")


def main(path: str) -> None:
    page = Path(path).read_text(encoding="utf-8", errors="replace")
    tokens = re.finditer(
        r'<h1><a class="a-inverse" href="#">(.*?)</a></h1>|<li class="sitems[^"]*"[^>]*id="poem-line-(\d+)">(.*?)</li>',
        page,
        re.S,
    )
    muezzin = None
    entries: dict[int, dict] = {}
    for m in tokens:
        if m.group(1) is not None:
            muezzin = clean(m.group(1))
            continue
        aid = int(m.group(2))
        body = m.group(3)
        title = re.search(r"<h2>.*?<a [^>]*>(.*?)</a>", body, re.S)
        full = re.search(r'title_data="(.*?)"', body)
        title_s = clean(title.group(1)) if title else ""
        full_s = clean(full.group(1)) if full else ""
        name = muezzin or UNKNOWN
        if name == UNKNOWN:
            v = BY_VOICE.search(full_s)
            name = clean(v.group(1)) if v else full_s or UNKNOWN
        if aid in entries and entries[aid]["muezzin"] != UNKNOWN and muezzin == UNKNOWN:
            continue
        parts = [clean(p) for p in title_s.split(",")]
        place = "، ".join(p for p in parts[1:] if p)
        fajr = "فجر" in title_s or "فجر" in full_s
        entries[aid] = {"id": aid, "muezzin": name, "place": place, "fajr": fajr}
    out = sorted(entries.values(), key=lambda e: (e["fajr"], e["muezzin"], e["id"]))
    text = json.dumps(out, ensure_ascii=False, indent=1) + "\n"
    for dest in (ROOT / "apps/mobile/assets/content/adhan_catalog.json", ROOT / "apps/web/public/data/adhan-catalog.json"):
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text, encoding="utf-8")
    print(f"{len(out)} recordings, {sum(e['fajr'] for e in out)} Fajr")


if __name__ == "__main__":
    main(sys.argv[1])
