from __future__ import annotations

from datetime import date as Date

from fastapi import APIRouter, HTTPException, Query, Request

from ..domain import prayer as P

router = APIRouter(prefix="/v1")


def _q(request: Request):
    return request.app.state.quran


@router.get("/content/versions")
def versions(request: Request):
    q = _q(request)
    return {**q.versions, "quranSha256": q.integrity["allAyahsSha256"]}


@router.get("/quran/surahs")
def surahs(request: Request):
    return [{k: s[k] for k in ("n", "nameAr", "nameEn", "translit", "revelation", "ayahCount")} for s in _q(request).surahs]


@router.get("/quran/surahs/{n}")
def surah(request: Request, n: int, translation: str | None = Query(default=None, pattern="^en$")):
    s = _q(request).surah(n)
    if s is None:
        raise HTTPException(404, "surah must be between 1 and 114")
    ayahs = [{"a": i + 1, "text": t, **({"en": s["en"][i]} if translation else {})} for i, t in enumerate(s["ayahs"])]
    return {**{k: s[k] for k in ("n", "nameAr", "nameEn", "translit", "revelation", "ayahCount")}, "ayahs": ayahs}


@router.get("/quran/ayahs/{s}/{a}")
def ayah(request: Request, s: int, a: int):
    q = _q(request)
    su = q.surah(s)
    if su is None or not 1 <= a <= su["ayahCount"]:
        raise HTTPException(404, "ayah not found")
    return {"s": s, "a": a, "text": su["ayahs"][a - 1], "en": su["en"][a - 1], "page": q.page_of(s, a)}


@router.get("/quran/pages/{p}")
def page(request: Request, p: int):
    pg = _q(request).page(p)
    if pg is None:
        raise HTTPException(404, "page must be between 1 and 604")
    return pg


@router.get("/quran/search")
def search(request: Request, q: str = Query(min_length=1, max_length=100), limit: int = Query(default=20, ge=1, le=100)):
    store = _q(request)
    if len(store.normalize(q).replace(" ", "")) < 2:
        raise HTTPException(422, "query must contain at least 2 Arabic letters")
    total, results = store.search(q, limit)
    return {"q": q, "total": total, "results": results}


@router.get("/prayer/methods")
def prayer_methods():
    return P.methods()


@router.get("/prayer/times")
def prayer_times(
    lat: float = Query(gt=-90, lt=90),
    lng: float = Query(ge=-180, le=180),
    date: Date = Query(),
    tz: str = Query(min_length=1, max_length=64),
    method: str = "mwl",
    asr: str = Query(default="standard", pattern="^(standard|hanafi)$"),
):
    from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

    try:
        ZoneInfo(tz)
    except (ZoneInfoNotFoundError, ValueError):
        raise HTTPException(422, "unknown IANA time zone") from None
    try:
        day = P.prayer_times(date, lat, lng, method, asr)
    except P.InvalidInput as e:
        raise HTTPException(422, str(e)) from None
    d = day.as_dict()
    return {
        "date": date.isoformat(),
        "tz": tz,
        "method": method,
        "asr": asr,
        "local": {k: P.local_hhmm(v, tz) for k, v in d.items()},
        "utc": {k: v.strftime("%Y-%m-%dT%H:%MZ") for k, v in d.items()},
        "highLatitudeAdjusted": list(day.high_latitude_adjusted),
    }


@router.get("/qibla")
def qibla(lat: float = Query(ge=-90, le=90), lng: float = Query(ge=-180, le=180)):
    return {"bearing": round(P.qibla_bearing(lat, lng), 2)}
