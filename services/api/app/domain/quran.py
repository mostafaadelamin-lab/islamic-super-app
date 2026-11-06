"""Read-only access to the versioned Quran bundle. Text is returned exactly as stored."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from functools import cached_property
from pathlib import Path


@dataclass
class QuranStore:
    content_dir: Path

    @cached_property
    def bundle(self) -> dict:
        return json.loads((self.content_dir / "quran/dist/quran.v1.json").read_text(encoding="utf-8"))

    @cached_property
    def pages(self) -> dict:
        return json.loads((self.content_dir / "quran/dist/pages.v1.json").read_text(encoding="utf-8"))

    @cached_property
    def integrity(self) -> dict:
        return json.loads((self.content_dir / "quran/dist/integrity.v1.json").read_text(encoding="utf-8"))

    @cached_property
    def versions(self) -> dict:
        return json.loads((self.content_dir / "VERSIONS.json").read_text(encoding="utf-8"))

    @property
    def surahs(self) -> list[dict]:
        return self.bundle["surahs"]

    def surah(self, n: int) -> dict | None:
        return self.surahs[n - 1] if 1 <= n <= len(self.surahs) else None

    def ayah_count(self, s: int) -> int:
        su = self.surah(s)
        return su["ayahCount"] if su else 0

    def page_of(self, s: int, a: int) -> int:
        key = (s, a)
        for p in self.pages["pages"]:
            if tuple(p["start"]) <= key <= tuple(p["end"]):
                return p["page"]
        raise ValueError("ayah not on any page")

    def page(self, p: int) -> dict | None:
        if not 1 <= p <= len(self.pages["pages"]):
            return None
        pg = self.pages["pages"][p - 1]
        (s0, a0), (s1, a1) = pg["start"], pg["end"]
        ayahs = []
        for s in range(s0, s1 + 1):
            first = a0 if s == s0 else 1
            last = a1 if s == s1 else self.ayah_count(s)
            ayahs += [{"s": s, "a": a, "text": self.surahs[s - 1]["ayahs"][a - 1]} for a in range(first, last + 1)]
        return {**pg, "ayahs": ayahs}

    @cached_property
    def _norm(self):
        cfg = json.loads((self.content_dir.parent / "packages/shared-schemas/search-normalization.json").read_text(encoding="utf-8"))
        rx = re.compile("[" + "".join(f"\\u{a}-\\u{b}" for a, b in cfg["removeRanges"]) + "]")
        table = str.maketrans(cfg["map"])
        return lambda s: " ".join(rx.sub("", s).translate(table).split())

    def normalize(self, s: str) -> str:
        return self._norm(s)

    @cached_property
    def _index(self) -> list[tuple[int, int, str]]:
        return [(su["n"], i + 1, self._norm(t)) for su in self.surahs for i, t in enumerate(su["ayahs"])]

    def search(self, q: str, limit: int) -> tuple[int, list[dict]]:
        nq = self._norm(q)
        hits = [(s, a) for s, a, t in self._index if nq in t]
        return len(hits), [{"s": s, "a": a, "text": self.surahs[s - 1]["ayahs"][a - 1]} for s, a in hits[:limit]]
