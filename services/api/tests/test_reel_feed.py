"""Automatic reels from trusted channels (owner decision 2026-11-09: approve channels, not videos)."""
from __future__ import annotations

import sys

import pytest

from app.config import REPO_ROOT
from app.domain import reel_feed as F

sys.path.insert(0, str(REPO_ROOT / "tools"))
import reels as R  # noqa: E402

FIXTURE = (REPO_ROOT / "content/reels/fixtures/youtube-feed.xml").read_text(encoding="utf-8")
YASSER = "UCYuUcfXvsHapABTcPRWCEoQ"


def test_feed_urls():
    assert F.shorts_feed(YASSER) == "https://www.youtube.com/feeds/videos.xml?playlist_id=UUSHYuUcfXvsHapABTcPRWCEoQ"
    assert F.channel_feed(YASSER).endswith("channel_id=" + YASSER)


def test_parse_feed():
    assert [r["ref"] for r in F.parse_feed(FIXTURE)] == ["AAAAAAAAAA1", "BBBBBBBBBB2", "CCCCCCCCCC3"]
    assert [r["ref"] for r in F.parse_feed(FIXTURE, shorts_only=True)] == ["AAAAAAAAAA1", "CCCCCCCCCC3"]
    assert F.parse_feed(FIXTURE)[2]["title"] == "تلاوة من سورة يس & الرحمن"
    assert F.parse_feed("<not xml") == []


def test_fetch_source_fallbacks():
    assert len(F.fetch_source(YASSER, lambda u: FIXTURE)) == 3
    only_channel = lambda u: None if "playlist_id" in u else FIXTURE  # noqa: E731
    assert [r["ref"] for r in F.fetch_source(YASSER, only_channel)] == ["AAAAAAAAAA1", "CCCCCCCCCC3"]
    assert F.fetch_source(YASSER, lambda u: None) is None


def test_mix_alternates_and_dedups():
    a = [{"id": "a1", "published": "2026-11-02"}, {"id": "a2", "published": "2026-11-03"}]
    b = [{"id": "b1", "published": "2026-11-01"}, {"id": "a2", "published": "2026-11-03"}]
    assert [r["id"] for r in F.mix([a, b])] == ["a2", "a1", "b1"]


def test_reel_feed_caches_and_keeps_stale_data(tmp_path):
    (tmp_path / "reels/dist").mkdir(parents=True)
    (tmp_path / "reels/dist/reel-sources.v1.json").write_text(
        '{"schema":"reel-sources.v1","sources":[{"id":"yt-%s","platform":"youtube","channelId":"%s",'
        '"name":{"ar":"ياسر","en":"Yasser"},"category":"recitation"}]}' % (YASSER, YASSER),
        encoding="utf-8",
    )
    calls, now, online = [], [1000.0], [True]

    def fetch(u):
        calls.append(u)
        return FIXTURE if online[0] else None

    feed = F.ReelFeed(tmp_path, fetch=fetch, clock=lambda: now[0])
    out = feed.build()
    assert out["schema"] == "reels-feed.v1"
    assert [i["ref"] for i in out["items"]] == ["BBBBBBBBBB2", "AAAAAAAAAA1", "CCCCCCCCCC3"]
    first = out["items"][0]
    assert first["status"] == "auto" and first["category"] == "recitation" and first["speaker"]["ar"] == "ياسر"
    assert first["sourceId"] == "yt-" + YASSER
    feed.build()
    assert len(calls) == 1, "cached for 3 hours"
    now[0] += F.MAX_AGE + 1
    online[0] = False
    assert len(feed.build()["items"]) == 3, "a failed refresh keeps the last data"


def test_api_reels_feed(client):
    client.app.state.reel_feed.fetch = lambda u: FIXTURE
    r = client.get("/v1/reels/feed")
    assert r.status_code == 200
    body = r.json()
    assert YASSER in [s.get("channelId") for s in body["sources"]]
    assert body["items"][0]["status"] == "auto"


def test_sources_catalogue_rules():
    cat = R.json.loads(R.SOURCES.read_text(encoding="utf-8"))
    assert R.validate_sources(cat) == []
    bad = {"schema": "reel-sources.catalogue.v1", "sources": [{"id": "yt-x", "platform": "youtube", "channelId": "@x", "name": {"ar": ""}, "category": "music", "addedAt": "x"}]}
    probs = " ".join(R.validate_sources(bad))
    for word in ("channelId", "name", "category", "approvedBy", "addedAt"):
        assert word in probs
    assert R.parse_channel("https://www.youtube.com/channel/" + YASSER) == {"channelId": YASSER}
    assert R.parse_channel("https://www.youtube.com/@%D8%A5%D8%B3%D9%84%D8%A7%D9%85%D9%8A%D8%A7%D8%AA123") == {"handle": "إسلاميات123"}
    assert R.parse_channel("@Mazamer.For8an") == {"handle": "Mazamer.For8an"}
    for bad in ("https://www.youtube.com/@x", "https://example.com/@someone", "someone"):
        with pytest.raises(R.ReelError):
            R.parse_channel(bad)
    both = {**cat["sources"][0], "handle": "abc"}
    assert any("exactly one" in p for p in R.validate_sources({**cat, "sources": [both]}))


def test_handle_sources_resolve_once(tmp_path):
    (tmp_path / "reels/dist").mkdir(parents=True)
    (tmp_path / "reels/dist/reel-sources.v1.json").write_text(
        '{"schema":"reel-sources.v1","sources":[{"id":"yt-@samirmoustafa","platform":"youtube","handle":"samirmoustafa",'
        '"name":{"ar":"سمير","en":"Samir"},"category":"lesson"}]}',
        encoding="utf-8",
    )
    calls = []

    def fetch(u):
        calls.append(u)
        if "/@samirmoustafa" in u:
            return '<link rel="canonical" href="https://www.youtube.com/channel/UCch6Y4YgssEzMa4Q5zw4xjw">'
        assert "UUSHch6Y4YgssEzMa4Q5zw4xjw" in u
        return FIXTURE

    feed = F.ReelFeed(tmp_path, fetch=fetch)
    out = feed.build()
    assert len(out["items"]) == 3 and out["sources"][0]["handle"] == "samirmoustafa"
    assert calls[0] == "https://www.youtube.com/@samirmoustafa"
    assert F.channel_id_from_page("nothing") is None
    assert F.ReelFeed(tmp_path, fetch=lambda u: None).build()["items"] == []
