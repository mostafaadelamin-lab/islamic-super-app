import pytest


def bm(surah=2, ayah=255, t=1000, deleted=False, note=None):
    return {"surah": surah, "ayah": ayah, "updatedAt": t, "deleted": deleted, "note": note}


def test_bookmark_upsert_and_list(client, auth):
    h = auth()
    r = client.put("/v1/bookmarks/b1", json=bm(note="آية الكرسي"), headers=h)
    assert r.status_code == 200 and r.json()["id"] == "b1"
    items = client.get("/v1/bookmarks", headers=h).json()["items"]
    assert [i["id"] for i in items] == ["b1"] and items[0]["note"] == "آية الكرسي"


def test_last_write_wins(client, auth):
    h = auth()
    client.put("/v1/bookmarks/b1", json=bm(ayah=1, t=2000), headers=h)
    stale = client.put("/v1/bookmarks/b1", json=bm(ayah=2, t=1500), headers=h).json()
    assert stale["ayah"] == 1 and stale["updatedAt"] == 2000
    newer = client.put("/v1/bookmarks/b1", json=bm(ayah=3, t=2500), headers=h).json()
    assert newer["ayah"] == 3


def test_tombstone_and_since(client, auth):
    h = auth()
    client.put("/v1/bookmarks/b1", json=bm(t=1), headers=h)
    first = client.get("/v1/bookmarks", headers=h).json()
    assert client.get(f"/v1/bookmarks?since={first['serverTime']}", headers=h).json()["items"] == []
    import time

    time.sleep(0.005)
    client.put("/v1/bookmarks/b1", json=bm(t=2, deleted=True), headers=h)
    delta = client.get(f"/v1/bookmarks?since={first['serverTime']}", headers=h).json()["items"]
    assert len(delta) == 1 and delta[0]["deleted"] is True


def test_users_cannot_see_or_overwrite_each_others_bookmarks(client, auth):
    a, b = auth("a@example.com"), auth("b@example.com")
    client.put("/v1/bookmarks/same-id", json=bm(ayah=7, t=10), headers=a)
    client.put("/v1/bookmarks/same-id", json=bm(ayah=9, t=20), headers=b)
    assert client.get("/v1/bookmarks", headers=a).json()["items"][0]["ayah"] == 7
    assert client.get("/v1/bookmarks", headers=b).json()["items"][0]["ayah"] == 9


def test_bookmarks_require_auth(client):
    assert client.get("/v1/bookmarks").status_code == 401
    assert client.put("/v1/bookmarks/x", json=bm()).status_code == 401


@pytest.mark.parametrize(
    "bid,body",
    [
        ("ok", bm(surah=0)),
        ("ok", bm(surah=115)),
        ("ok", bm(surah=1, ayah=8)),
        ("ok", bm(ayah=0)),
        ("ok", bm(note="x" * 501)),
        ("bad id!", bm()),
        ("x" * 65, bm()),
        ("ok", {**bm(), "extra": 1}),
        ("ok", bm(t=-1)),
    ],
)
def test_bookmark_validation(client, auth, bid, body):
    h = auth()
    assert client.put(f"/v1/bookmarks/{bid}", json=body, headers=h).status_code in (404, 422)


def test_settings_lww(client, auth):
    h = auth()
    assert client.get("/v1/me/settings", headers=h).json() == {"settings": {}, "updatedAt": 0}
    client.put("/v1/me/settings", json={"settings": {"lang": "ar", "method": "egypt"}, "updatedAt": 100}, headers=h)
    r = client.put("/v1/me/settings", json={"settings": {"lang": "en"}, "updatedAt": 50}, headers=h).json()
    assert r["settings"]["lang"] == "ar"
    r = client.put("/v1/me/settings", json={"settings": {"lang": "en"}, "updatedAt": 200}, headers=h).json()
    assert r == {"settings": {"lang": "en"}, "updatedAt": 200}


def test_settings_size_limit(client, auth):
    h = auth()
    assert client.put("/v1/me/settings", json={"settings": {"k": "x" * 9000}, "updatedAt": 1}, headers=h).status_code == 413
