import importlib.util
import json
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("reels_tool", REPO / "tools/reels.py")
reels = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reels)


@pytest.mark.parametrize(
    "url,expected",
    [
        ("https://www.youtube.com/shorts/hTtlD-u4_HI", ("youtube", "hTtlD-u4_HI")),
        ("https://youtube.com/shorts/hTtlD-u4_HI?feature=share", ("youtube", "hTtlD-u4_HI")),
        ("https://youtu.be/26dRG7OeL6Q?si=abc", ("youtube", "26dRG7OeL6Q")),
        ("https://www.youtube.com/watch?v=26dRG7OeL6Q&t=10s", ("youtube", "26dRG7OeL6Q")),
        ("https://m.youtube.com/embed/26dRG7OeL6Q", ("youtube", "26dRG7OeL6Q")),
    ],
)
def test_parse_url(url, expected):
    assert reels.parse_url(url) == expected


@pytest.mark.parametrize(
    "url",
    [
        "https://www.tiktok.com/@x/video/1",
        "javascript:alert(1)",
        "https://www.youtube.com/watch?v=short",
        "https://www.youtube.com/@channel",
        "https://www.instagram.com/reel/C1a2B3c4D5e/",  # Instagram not enabled yet
        "https://evil.example/youtube.com/shorts/hTtlD-u4_HI",
        "https://www.youtube.com/shorts/<script>xx",
    ],
)
def test_parse_url_rejects(url):
    with pytest.raises(reels.ReelError):
        reels.parse_url(url)


def _item(**kw):
    base = {
        "id": "yt-hTtlD-u4_HI", "platform": "youtube", "ref": "hTtlD-u4_HI",
        "url": "https://www.youtube.com/watch?v=hTtlD-u4_HI", "title": {"ar": "عنوان", "en": ""},
        "speaker": None, "category": "recitation", "source": None, "addedAt": "2026-11-08",
        "review": {"status": "pending", "reviewer": None, "reviewedAt": None, "notes": ""},
    }
    base.update(kw)
    return base


def test_validate_requires_reviewer_for_approval():
    cat = {"schema": "reels-catalogue.v1", "items": [_item(review={"status": "approved", "reviewer": "", "reviewedAt": None})]}
    probs = reels.validate(cat)
    assert any("reviewer" in p for p in probs) and any("reviewedAt" in p for p in probs)


def test_validate_rejects_bad_ids_and_duplicates():
    cat = {"schema": "reels-catalogue.v1", "items": [_item(), _item(), _item(id="yt-x", ref="bad")]}
    probs = reels.validate(cat)
    assert any("duplicate" in p for p in probs)
    assert any(": ref" in p for p in probs)


def test_validate_only_allows_recitation_and_lessons():
    assert reels.CATEGORIES == ("recitation", "lesson")
    cat = {"schema": "reels-catalogue.v1", "items": [_item(category="music")]}
    assert any("category" in p for p in reels.validate(cat))
    ig = _item(id="ig-C1a2B3c4D5e", platform="instagram", ref="C1a2B3c4D5e", url="https://www.instagram.com/reel/C1a2B3c4D5e/")
    assert any("platform" in p for p in reels.validate({"schema": "reels-catalogue.v1", "items": [ig]}))


def test_bundle_drops_rejected_and_orders_approved_first():
    ok = {"status": "approved", "reviewer": "الشيخ", "reviewedAt": "2026-11-09", "notes": ""}
    bad = {"status": "rejected", "reviewer": "الشيخ", "reviewedAt": "2026-11-09", "notes": "خطأ"}
    a = _item()
    b = _item(id="yt-26dRG7OeL6Q", ref="26dRG7OeL6Q", url="https://www.youtube.com/watch?v=26dRG7OeL6Q", review=ok)
    c = _item(id="yt-dQw4w9WgXcQ", ref="dQw4w9WgXcQ", url="https://www.youtube.com/watch?v=dQw4w9WgXcQ", review=bad)
    cat = {"schema": "reels-catalogue.v1", "items": [a, b, c]}
    assert reels.validate(cat) == []
    out = reels.build_bundle(cat)
    assert [r["id"] for r in out["items"]] == ["yt-26dRG7OeL6Q", "yt-hTtlD-u4_HI"]
    assert out["items"][0]["reviewer"] == "الشيخ"
    assert out["items"][1]["status"] == "pending" and out["items"][1]["reviewer"] is None
    assert out["items"][1]["title"]["en"] == "عنوان"  # falls back to Arabic


def test_repo_catalogue_is_valid_and_built():
    cat = json.loads((REPO / "content/reels/reels.json").read_text(encoding="utf-8"))
    assert reels.validate(cat) == []
    built = json.loads((REPO / "content/reels/dist/reels.v1.json").read_text(encoding="utf-8"))
    assert built == reels.build_bundle(cat)


def test_api_returns_only_approved_by_default(client, settings, tmp_path, monkeypatch):
    from app.config import Settings
    from app.main import create_app
    from fastapi.testclient import TestClient

    content = tmp_path / "content"
    (content / "reels/dist").mkdir(parents=True)
    for rel in ("quran/dist", ):
        (content / rel).mkdir(parents=True)
    items = [
        {"id": "yt-a", "status": "approved", "platform": "youtube"},
        {"id": "yt-b", "status": "pending", "platform": "youtube"},
    ]
    (content / "reels/dist/reels.v1.json").write_text(json.dumps({"schema": "reels.v1", "version": 3, "items": items}), encoding="utf-8")
    s = Settings(database_url="sqlite://", jwt_secret="t" * 48, general_rate_per_minute=10000)
    object.__setattr__(s, "content_dir", content)
    c = TestClient(create_app(s))
    assert [r["id"] for r in c.get("/v1/reels").json()["items"]] == ["yt-a"]
    assert [r["id"] for r in c.get("/v1/reels?include_pending=true").json()["items"]] == ["yt-a", "yt-b"]


def test_api_reels_repo_bundle(client):
    r = client.get("/v1/reels")
    assert r.status_code == 200
    assert all(x["status"] == "approved" for x in r.json()["items"])
