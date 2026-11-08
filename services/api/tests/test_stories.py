import importlib.util
import json
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("stories_tool", REPO / "tools/stories.py")
stories = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stories)

COUNTS = stories.ayah_counts()


def _story(**kw):
    base = {
        "id": "yusuf", "category": "prophets",
        "title": {"ar": "يوسف", "en": "Joseph"},
        "segments": [{"surah": 12, "from": 4, "to": 101}], "addedAt": "2026-11-08",
        "review": {"status": "pending", "reviewer": None, "reviewedAt": None, "notes": ""},
    }
    base.update(kw)
    return base


def _cat(*items):
    return {"schema": "stories-catalogue.v1", "version": 1, "items": list(items)}


def test_shipped_catalogue_is_valid_and_all_pending():
    cat = stories.load()
    assert stories.validate(cat, COUNTS) == []
    assert len(cat["items"]) >= 20
    # Nothing is approved without a named human reviewer.
    assert all(s["review"]["status"] == "pending" for s in cat["items"])


def test_shipped_bundle_matches_catalogue():
    bundle, problems = stories.build(write=False)
    assert problems == []
    on_disk = json.loads((REPO / "content/stories/dist/stories.v1.json").read_text(encoding="utf-8"))
    assert on_disk == bundle
    mobile = json.loads((REPO / "apps/mobile/assets/content/stories.v1.json").read_text(encoding="utf-8"))
    assert mobile == bundle


@pytest.mark.parametrize(
    "seg,msg",
    [
        ({"surah": 12, "from": 4, "to": 112}, "outside"),  # Yusuf has 111 ayahs
        ({"surah": 12, "from": 0, "to": 3}, "outside"),
        ({"surah": 12, "from": 9, "to": 3}, "outside"),
        ({"surah": 115, "from": 1, "to": 1}, "surah"),
        ({"surah": "12", "from": 1, "to": 2}, "surah"),
    ],
)
def test_rejects_bad_ranges(seg, msg):
    problems = stories.validate(_cat(_story(segments=[seg])), COUNTS)
    assert any(msg in p for p in problems), problems


def test_rejects_overlap_duplicates_and_unreviewed_approval():
    overlap = _story(segments=[{"surah": 18, "from": 9, "to": 20}, {"surah": 18, "from": 20, "to": 26}])
    assert any("overlaps" in p for p in stories.validate(_cat(overlap), COUNTS))
    assert any("duplicate" in p for p in stories.validate(_cat(_story(), _story()), COUNTS))
    no_reviewer = _story(review={"status": "approved", "reviewer": " ", "reviewedAt": "2026-11-08", "notes": ""})
    assert any("reviewer" in p for p in stories.validate(_cat(no_reviewer), COUNTS))
    no_reason = _story(review={"status": "rejected", "reviewer": "x", "reviewedAt": "2026-11-08", "notes": ""})
    assert any("reason" in p for p in stories.validate(_cat(no_reason), COUNTS))
    authored = _story(summary={"ar": "ملخص", "en": "x"})
    assert any("no summary" in p for p in stories.validate(_cat(authored), COUNTS))


def test_bundle_drops_rejected_and_hides_reviewer_of_pending():
    ok = _story(id="a", review={"status": "approved", "reviewer": "الشيخ س", "reviewedAt": "2026-11-09", "notes": ""})
    pend = _story(id="b", review={"status": "pending", "reviewer": "draft", "reviewedAt": None, "notes": ""})
    rej = _story(id="c", review={"status": "rejected", "reviewer": "x", "reviewedAt": "2026-11-09", "notes": "خطأ"})
    b = stories.build_bundle(_cat(ok, pend, rej))
    assert [s["id"] for s in b["items"]] == ["a", "b"]
    assert b["items"][0]["reviewer"] == "الشيخ س"
    assert b["items"][1]["reviewer"] is None
    assert b["items"][0]["segments"] == [[12, 4, 101]] and b["items"][0]["ayahCount"] == 98


def test_cli_approve_and_reject(tmp_path, monkeypatch):
    cat_file = tmp_path / "stories.json"
    cat_file.write_text(json.dumps(_cat(_story(id="a"), _story(id="b"))), encoding="utf-8")
    monkeypatch.setattr(stories, "CATALOGUE", cat_file)
    monkeypatch.setattr(stories, "DIST", tmp_path / "dist.json")
    assert stories.main(["reject", "a", "--reviewer", "x"]) == 1  # reason required
    assert stories.main(["approve", "a", "--reviewer", "الشيخ س"]) == 0
    assert stories.main(["reject", "b", "--reviewer", "x", "--notes", "range"]) == 0
    built = json.loads((tmp_path / "dist.json").read_text(encoding="utf-8"))
    assert [(s["id"], s["status"]) for s in built["items"]] == [("a", "approved")]


def test_api_serves_verse_only_stories(client):
    r = client.get("/v1/stories")
    assert r.status_code == 200
    body = r.json()
    assert body["schema"] == "stories.v1" and len(body["items"]) >= 20
    assert all("summary" not in s and s["segments"] for s in body["items"])


def _series(*episodes, **kw):
    base = {
        "id": "s1", "title": {"ar": "قصص الأنبياء"}, "narrator": {"ar": "الشيخ"}, "source": "Publisher",
        "licence": "non-commercial", "episodes": list(episodes),
    }
    base.update(kw)
    return base


EP = {
    "id": "e1", "title": {"ar": "قصة يوسف"}, "url": "https://example.org/a/yusuf.mp3", "durationSec": 60,
    "story": "yusuf", "addedAt": "2026-11-08",
    "review": {"status": "pending", "reviewer": None, "reviewedAt": None, "notes": ""},
}


def _with_series(*series):
    cat = _cat(_story())
    cat["series"] = list(series)
    return cat


def test_shipped_series_all_pending_and_licensed():
    cat = stories.load()
    assert cat["series"], "the narrated series requested by the owner"
    for se in cat["series"]:
        assert se["licence"].strip() and se["source"].strip()
        assert all(e["review"]["status"] == "pending" for e in se["episodes"])
        assert all(e["url"].startswith("https://archive.org/download/") for e in se["episodes"])


@pytest.mark.parametrize(
    "patch,msg",
    [
        ({"url": "http://example.org/a.mp3"}, "https"),
        ({"url": "https://example.org/page.html"}, "audio"),
        ({"url": "javascript:alert(1)//a.mp3"}, "https"),
        ({"durationSec": -3}, "durationSec"),
        ({"story": "nope"}, "does not exist"),
        ({"title": {"ar": ""}}, "title"),
        ({"review": {"status": "approved", "reviewer": None, "reviewedAt": "2026-11-08"}}, "reviewer"),
    ],
)
def test_episode_validation(patch, msg):
    problems = stories.validate(_with_series(_series({**EP, **patch})), COUNTS)
    assert any(msg in p for p in problems), problems


@pytest.mark.parametrize(
    "patch,msg",
    [({"licence": " "}, "licence"), ({"source": ""}, "source"), ({"narrator": {}}, "narrator"), ({"episodes": []}, "episode")],
)
def test_series_validation(patch, msg):
    problems = stories.validate(_with_series(_series(EP, **patch)), COUNTS)
    assert any(msg in p for p in problems), problems


def test_bundle_drops_rejected_episodes_and_empty_series():
    ok = {**EP, "id": "ok", "review": {"status": "approved", "reviewer": "الشيخ س", "reviewedAt": "2026-11-09", "notes": ""}}
    rej = {**EP, "id": "rej", "review": {"status": "rejected", "reviewer": "x", "reviewedAt": "2026-11-09", "notes": "خطأ"}}
    cat = _with_series(_series(ok, EP, rej), _series(rej, id="s2"))
    assert stories.validate(cat, COUNTS) == []
    b = stories.build_bundle(cat)
    assert [s["id"] for s in b["series"]] == ["s1"]
    assert [(e["id"], e["status"], e["reviewer"]) for e in b["series"][0]["episodes"]] == [("ok", "approved", "الشيخ س"), ("e1", "pending", None)]


def test_cli_review_episodes(tmp_path, monkeypatch):
    cat_file = tmp_path / "stories.json"
    cat_file.write_text(json.dumps(_with_series(_series(EP, {**EP, "id": "e2"}))), encoding="utf-8")
    monkeypatch.setattr(stories, "CATALOGUE", cat_file)
    monkeypatch.setattr(stories, "DIST", tmp_path / "dist.json")
    assert stories.main(["approve", "s1", "--episode", "nope", "--reviewer", "x"]) == 1
    assert stories.main(["approve", "s1", "--episode", "e1", "--reviewer", "الشيخ س"]) == 0
    assert stories.main(["approve", "s1", "--episode", "all", "--reviewer", "الشيخ ص"]) == 0
    eps = json.loads((tmp_path / "dist.json").read_text(encoding="utf-8"))["series"][0]["episodes"]
    assert [(e["id"], e["reviewer"]) for e in eps] == [("e1", "الشيخ س"), ("e2", "الشيخ ص")]


def test_api_hides_unreviewed_episodes(client, tmp_path):
    import dataclasses

    bundle = stories.build_bundle(_with_series(_series(EP)))
    (tmp_path / "stories/dist").mkdir(parents=True)
    (tmp_path / "stories/dist/stories.v1.json").write_text(json.dumps(bundle), encoding="utf-8")
    client.app.state.settings = dataclasses.replace(client.app.state.settings, content_dir=tmp_path)
    assert client.get("/v1/stories").json()["series"] == []
    assert len(client.get("/v1/stories?include_pending=true").json()["series"][0]["episodes"]) == 1
