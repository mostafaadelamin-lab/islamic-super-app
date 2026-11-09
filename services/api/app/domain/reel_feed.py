"""Automatic reels: the newest Shorts of the trusted channels in content/reels/sources.json.

Owner decision (2026-11-09): the owner approves a channel once; its videos need no per-video review.
YouTube's public Atom feeds need no API key. Browsers cannot read them (no CORS), so the website asks
this endpoint; the mobile app reads the feeds itself.
"""
from __future__ import annotations

import json
import re
import threading
import time
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Callable
from urllib.parse import quote, urlencode

ATOM = "{http://www.w3.org/2005/Atom}"
YT = "{http://www.youtube.com/xml/schemas/2015}"
VIDEO_ID = re.compile(r"^[A-Za-z0-9_-]{11}$")
MAX_AGE = 3 * 3600
PER_SOURCE = 15

Fetcher = Callable[[str], "str | None"]


def http_fetch(url: str) -> str | None:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "rattil-reels/1"})
        with urllib.request.urlopen(req, timeout=10) as res:  # noqa: S310 (fixed youtube.com URLs only)
            if res.status != 200:
                return None
            return res.read(2_000_000).decode("utf-8", "replace")
    except Exception:  # network errors of every kind just mean "no fresh data"
        return None


def shorts_feed(channel_id: str) -> str:
    return "https://www.youtube.com/feeds/videos.xml?" + urlencode({"playlist_id": "UUSH" + channel_id[2:]})


def channel_feed(channel_id: str) -> str:
    return "https://www.youtube.com/feeds/videos.xml?" + urlencode({"channel_id": channel_id})


ID_ON_PAGE = [
    re.compile(r'<link rel="canonical" href="https://www\.youtube\.com/channel/(UC[A-Za-z0-9_-]{22})"'),
    re.compile(r'<meta itemprop="identifier" content="(UC[A-Za-z0-9_-]{22})"'),
    re.compile(r'"externalId":"(UC[A-Za-z0-9_-]{22})"'),
    re.compile(r'"browseId":"(UC[A-Za-z0-9_-]{22})"'),
]


def handle_page(handle: str) -> str:
    return "https://www.youtube.com/@" + quote(handle)


def channel_id_from_page(html: str) -> str | None:
    for rx in ID_ON_PAGE:
        m = rx.search(html)
        if m:
            return m.group(1)
    return None


def parse_feed(xml: str, shorts_only: bool = False) -> list[dict]:
    try:
        root = ET.fromstring(xml)
    except ET.ParseError:
        return []
    out = []
    for e in root.iter(f"{ATOM}entry"):
        vid = (e.findtext(f"{YT}videoId") or "").strip()
        title = (e.findtext(f"{ATOM}title") or "").strip()
        link = e.find(f"{ATOM}link")
        href = link.get("href", "") if link is not None else ""
        if not VIDEO_ID.match(vid) or not title or (shorts_only and "/shorts/" not in href):
            continue
        out.append({"ref": vid, "title": title, "published": (e.findtext(f"{ATOM}published") or "").strip() or None})
    return out


def fetch_source(channel_id: str, fetch: Fetcher) -> list[dict] | None:
    """Shorts playlist first; then the channel feed (Shorts entries, else every upload). None if unreachable."""
    shorts = fetch(shorts_feed(channel_id))
    items = parse_feed(shorts) if shorts else []
    if items:
        return items
    whole = fetch(channel_feed(channel_id))
    if whole is None:
        return None if shorts is None else []
    return parse_feed(whole, shorts_only=True) or parse_feed(whole)


def mix(per_source: list[list[dict]]) -> list[dict]:
    """Each channel newest first, then one per channel in turn; duplicates dropped."""
    queues = [sorted(q, key=lambda r: r.get("published") or "", reverse=True) for q in per_source if q]
    seen: set[str] = set()
    out: list[dict] = []
    for i in range(max((len(q) for q in queues), default=0)):
        for q in queues:
            if i < len(q) and q[i]["id"] not in seen:
                seen.add(q[i]["id"])
                out.append(q[i])
    return out


class ReelFeed:
    def __init__(self, content_dir: Path, fetch: Fetcher = http_fetch, clock: Callable[[], float] = time.time):
        self.sources_path = content_dir / "reels/dist/reel-sources.v1.json"
        self.fetch = fetch
        self.clock = clock
        self._cache: dict[str, tuple[float, list[dict]]] = {}
        self._handles: dict[str, str] = {}
        self._lock = threading.Lock()

    def sources(self) -> list[dict]:
        if not self.sources_path.exists():
            return []
        return json.loads(self.sources_path.read_text(encoding="utf-8")).get("sources", [])

    def _channel_id(self, src: dict) -> str | None:
        if src.get("channelId"):
            return src["channelId"]
        handle = src.get("handle") or ""
        if handle not in self._handles:
            page = self.fetch(handle_page(handle))
            cid = channel_id_from_page(page) if page else None
            if cid is None:
                return None
            self._handles[handle] = cid
        return self._handles[handle]

    def _items(self, src: dict) -> list[dict]:
        cid = self._channel_id(src)
        if cid is None:
            return []
        now = self.clock()
        with self._lock:
            hit = self._cache.get(cid)
        if hit and now - hit[0] < MAX_AGE:
            raw = hit[1]
        else:
            fresh = fetch_source(cid, self.fetch)
            if fresh is None:
                raw = hit[1] if hit else []  # keep stale data rather than nothing
            else:
                raw = fresh[:PER_SOURCE]
                with self._lock:
                    self._cache[cid] = (now, raw)
        return [
            {
                "id": "yt-" + r["ref"],
                "platform": "youtube",
                "ref": r["ref"],
                "url": "https://www.youtube.com/watch?v=" + r["ref"],
                "title": {"ar": r["title"], "en": r["title"]},
                "speaker": src["name"],
                "category": src["category"],
                "sourceId": src["id"],
                "status": "auto",
                "published": r["published"],
            }
            for r in raw
        ]

    def build(self) -> dict:
        srcs = self.sources()
        return {
            "schema": "reels-feed.v1",
            "sources": [{k: s[k] for k in ("id", "channelId", "handle", "name", "category") if k in s} for s in srcs],
            "items": mix([self._items(s) for s in srcs]),
        }
