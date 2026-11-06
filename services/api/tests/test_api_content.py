import pytest


def test_health(client):
    assert client.get("/health").json() == {"status": "ok", "version": "0.1.0"}


def test_versions_include_quran_hash(client):
    v = client.get("/v1/content/versions").json()
    assert v["quran"] == "1.0.0" and len(v["quranSha256"]) == 64


def test_surah_list(client):
    r = client.get("/v1/quran/surahs").json()
    assert len(r) == 114 and r[0]["nameAr"] == "الفاتحة" and r[1]["ayahCount"] == 286
    assert "ayahs" not in r[0]


def test_surah_detail_with_and_without_translation(client):
    r = client.get("/v1/quran/surahs/112").json()
    assert r["ayahCount"] == 4 and "en" not in r["ayahs"][0]
    r = client.get("/v1/quran/surahs/112?translation=en").json()
    assert r["ayahs"][0]["en"]


@pytest.mark.parametrize("n", [0, 115, -1])
def test_surah_out_of_range(client, n):
    assert client.get(f"/v1/quran/surahs/{n}").status_code == 404


def test_surah_bad_translation_param(client):
    assert client.get("/v1/quran/surahs/1?translation=fr").status_code == 422


def test_ayah(client):
    r = client.get("/v1/quran/ayahs/2/255").json()
    assert r["page"] == 42 and client.app.state.quran.normalize(r["text"]).startswith("الله لا اله الا هو")
    assert client.get("/v1/quran/ayahs/1/8").status_code == 404


def test_page(client):
    r = client.get("/v1/quran/pages/1").json()
    assert [a["a"] for a in r["ayahs"]] == list(range(1, 8))
    r = client.get("/v1/quran/pages/604").json()
    assert [(a["s"], a["a"]) for a in r["ayahs"]][0] == (112, 1) and len(r["ayahs"]) == 15
    for p in (0, 605):
        assert client.get(f"/v1/quran/pages/{p}").status_code == 404


def test_search_is_diacritic_insensitive_and_returns_original_text(client):
    r = client.get("/v1/quran/search", params={"q": "الرحمن الرحيم"}).json()
    assert r["total"] == 6
    first = r["results"][0]
    assert (first["s"], first["a"]) == (1, 1)
    assert first["text"] == client.app.state.quran.surah(1)["ayahs"][0]  # original, unnormalised text


def test_search_limit_and_validation(client):
    r = client.get("/v1/quran/search", params={"q": "الله", "limit": 3}).json()
    assert len(r["results"]) == 3 and r["total"] > 1000
    assert client.get("/v1/quran/search", params={"q": "ا"}).status_code == 422
    assert client.get("/v1/quran/search", params={"q": "ًٌ"}).status_code == 422
    assert client.get("/v1/quran/search", params={"q": "x" * 101}).status_code == 422
    assert client.get("/v1/quran/search", params={"q": "zzqq"}).json()["total"] == 0


def test_prayer_times_endpoint(client):
    r = client.get("/v1/prayer/times", params=dict(lat=30.0444, lng=31.2357, date="2026-01-15", tz="Africa/Cairo", method="egypt"))
    assert r.status_code == 200
    j = r.json()
    assert set(j["local"]) == {"fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"}
    assert j["local"]["dhuhr"] in ("12:04", "12:05", "12:06")


@pytest.mark.parametrize(
    "params",
    [
        dict(lat=95, lng=0, date="2026-01-01", tz="UTC"),
        dict(lat=0, lng=0, date="2026-13-01", tz="UTC"),
        dict(lat=0, lng=0, date="2026-01-01", tz="Mars/Base"),
        dict(lat=0, lng=0, date="2026-01-01", tz="UTC", method="bogus"),
        dict(lat=0, lng=0, date="2026-01-01", tz="UTC", asr="shafi"),
        dict(lat=78.22, lng=15.65, date="2026-06-21", tz="Arctic/Longyearbyen"),
    ],
)
def test_prayer_times_validation(client, params):
    assert client.get("/v1/prayer/times", params=params).status_code == 422


def test_methods_and_qibla(client):
    assert "egypt" in client.get("/v1/prayer/methods").json()["methods"]
    assert abs(client.get("/v1/qibla", params={"lat": 30.0444, "lng": 31.2357}).json()["bearing"] - 136.14) < 0.5
    assert client.get("/v1/qibla", params={"lat": 100, "lng": 0}).status_code == 422


def test_security_headers_and_cors(client):
    r = client.get("/health", headers={"Origin": "http://localhost:3000"})
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.headers["access-control-allow-origin"] == "http://localhost:3000"
    r = client.get("/health", headers={"Origin": "https://evil.example"})
    assert "access-control-allow-origin" not in r.headers


def test_unknown_route_404(client):
    assert client.get("/v1/nope").status_code == 404
