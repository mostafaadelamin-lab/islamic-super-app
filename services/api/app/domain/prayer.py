"""Prayer-time calculation (reference implementation for all platforms).

Algorithm: standard spherical-astronomy formulas (Jean Meeus, "Astronomical
Algorithms", low-precision solar coordinates as published by the U.S. Naval
Observatory). The same algorithm is ported to Dart (apps/mobile) and TypeScript
(apps/web); all three are tested against tests/vectors/prayer-times.json, which
is produced by the independent adhan-js library.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from datetime import UTC, date, datetime, timedelta
from functools import lru_cache
from pathlib import Path
from zoneinfo import ZoneInfo

METHODS_FILE = Path(__file__).resolve().parents[4] / "packages/shared-schemas/prayer/methods.json"
PRAYER_KEYS = ("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")


@lru_cache
def methods() -> dict:
    return json.loads(METHODS_FILE.read_text(encoding="utf-8"))


def _d2r(d: float) -> float:
    return d * math.pi / 180


def _r2d(r: float) -> float:
    return r * 180 / math.pi


def _fix(a: float, b: float) -> float:
    a = a - b * math.floor(a / b)
    return a + b if a < 0 else a


def julian_day(y: int, m: int, d: int) -> float:
    if m <= 2:
        y -= 1
        m += 12
    a = y // 100
    b = 2 - a + a // 4
    return math.floor(365.25 * (y + 4716)) + math.floor(30.6001 * (m + 1)) + d + b - 1524.5


def sun_position(jd: float) -> tuple[float, float]:
    """Return (declination in degrees, equation of time in hours)."""
    dd = jd - 2451545.0
    g = _fix(357.529 + 0.98560028 * dd, 360)
    q = _fix(280.459 + 0.98564736 * dd, 360)
    lam = _fix(q + 1.915 * math.sin(_d2r(g)) + 0.020 * math.sin(_d2r(2 * g)), 360)
    e = 23.439 - 0.00000036 * dd
    ra = _fix(_r2d(math.atan2(math.cos(_d2r(e)) * math.sin(_d2r(lam)), math.cos(_d2r(lam)))) / 15, 24)
    decl = _r2d(math.asin(math.sin(_d2r(e)) * math.sin(_d2r(lam))))
    return decl, q / 15 - ra


@dataclass(frozen=True)
class PrayerDay:
    """UTC datetimes for one local calendar date."""

    fajr: datetime
    sunrise: datetime
    dhuhr: datetime
    asr: datetime
    maghrib: datetime
    isha: datetime
    high_latitude_adjusted: tuple[str, ...] = ()

    def as_dict(self) -> dict[str, datetime]:
        return {k: getattr(self, k) for k in PRAYER_KEYS}


class InvalidInput(ValueError):
    pass


def in_ramadan(y: int, m: int, d: int) -> bool:
    """True if the Gregorian date falls in Ramadan by the Umm al-Qura calendar (table in methods.json)."""
    iso = f"{y:04d}-{m:02d}-{d:02d}"
    return any(a <= iso <= b for a, b in methods().get("ramadanUmmAlQura", {}).values())


def isha_minutes(mt: dict, y: int, m: int, d: int) -> float:
    """Fixed Isha interval after Maghrib; Umm al-Qura uses 120 minutes instead of 90 during Ramadan."""
    if "ishaMinutesRamadan" in mt and in_ramadan(y, m, d):
        return mt["ishaMinutesRamadan"]
    return mt["ishaMinutes"]


def compute_hours(y: int, m: int, d: int, lat: float, lng: float, method: str, asr_factor: int) -> tuple[dict[str, float], list[str]]:
    """Return UTC fractional hours (may be <0 or >=24) for the local date y-m-d."""
    if not (-90 < lat < 90) or not (-180 <= lng <= 180):
        raise InvalidInput("latitude must be in (-90, 90) and longitude in [-180, 180]")
    cfg = methods()
    if method not in cfg["methods"]:
        raise InvalidInput(f"unknown method {method!r}")
    if asr_factor not in (1, 2):
        raise InvalidInput("asr factor must be 1 (standard) or 2 (hanafi)")
    mt = cfg["methods"][method]
    jd = julian_day(y, m, d) - lng / (15 * 24)

    def noon(t: float) -> float:
        return _fix(12 - sun_position(jd + t)[1], 24)

    def angle_time(angle: float, t: float, before_noon: bool) -> float:
        decl = sun_position(jd + t)[0]
        cos_h = (-math.sin(_d2r(angle)) - math.sin(_d2r(decl)) * math.sin(_d2r(lat))) / (math.cos(_d2r(decl)) * math.cos(_d2r(lat)))
        if cos_h < -1 or cos_h > 1:
            return math.nan
        h = _r2d(math.acos(cos_h)) / 15
        n = noon(t)
        return n - h if before_noon else n + h

    def asr_time(factor: int, t: float) -> float:
        decl = sun_position(jd + t)[0]
        angle = -_r2d(math.atan(1 / (factor + math.tan(_d2r(abs(lat - decl))))))
        return angle_time(angle, t, False)

    sr = -cfg["sunAltitudeForSunriseSunset"]
    t = {"fajr": 5.0, "sunrise": 6.0, "dhuhr": 12.0, "asr": 13.0, "maghrib": 18.0, "isha": 18.0}
    for _ in range(2):
        p = {k: (v if not math.isnan(v) else 12.0) / 24 for k, v in t.items()}
        t = {
            "fajr": angle_time(mt["fajr"], p["fajr"], True),
            "sunrise": angle_time(sr, p["sunrise"], True),
            "dhuhr": noon(p["dhuhr"]),
            "asr": asr_time(asr_factor, p["asr"]),
            "maghrib": angle_time(sr, p["maghrib"], False),
            "isha": math.nan if "ishaMinutes" in mt else angle_time(mt["isha"], p["isha"], False),
        }
    if math.isnan(t["sunrise"]) or math.isnan(t["maghrib"]):
        raise InvalidInput("the sun does not rise or set at this location on this date (polar day/night)")
    adjusted: list[str] = []
    if "ishaMinutes" in mt:
        t["isha"] = t["maghrib"] + isha_minutes(mt, y, m, d) / 60
    night = _fix(t["sunrise"] - t["maghrib"], 24)
    portion = mt["fajr"] / 60 * night
    if math.isnan(t["fajr"]) or _fix(t["sunrise"] - t["fajr"], 24) > portion:
        t["fajr"] = t["sunrise"] - portion
        adjusted.append("fajr")
    if "ishaMinutes" not in mt:
        portion = mt["isha"] / 60 * night
        if math.isnan(t["isha"]) or _fix(t["isha"] - t["maghrib"], 24) > portion:
            t["isha"] = t["maghrib"] + portion
            adjusted.append("isha")
    t["dhuhr"] += cfg["dhuhrOffsetMinutes"] / 60
    return {k: v - lng / 15 for k, v in t.items()}, adjusted


def prayer_times(day: date, lat: float, lng: float, method: str = "mwl", asr: str = "standard", adjustments: dict[str, int] | None = None) -> PrayerDay:
    """Prayer times for a local calendar day, rounded to the nearest minute (UTC)."""
    factor = methods()["asr"].get(asr)
    if factor is None:
        raise InvalidInput("asr must be 'standard' or 'hanafi'")
    hours, adjusted = compute_hours(day.year, day.month, day.day, lat, lng, method, factor)
    base = datetime(day.year, day.month, day.day, tzinfo=UTC)
    adjustments = adjustments or {}
    out = {}
    for k in PRAYER_KEYS:
        minutes = round(hours[k] * 60) + int(adjustments.get(k, 0))
        out[k] = base + timedelta(minutes=minutes)
    return PrayerDay(**out, high_latitude_adjusted=tuple(adjusted))


def local_hhmm(dt: datetime, tz: str) -> str:
    return dt.astimezone(ZoneInfo(tz)).strftime("%H:%M")


def qibla_bearing(lat: float, lng: float) -> float:
    k = methods()["kaaba"]
    dl = _d2r(k["lng"] - lng)
    x = math.sin(dl)
    y = math.cos(_d2r(lat)) * math.tan(_d2r(k["lat"])) - math.sin(_d2r(lat)) * math.cos(dl)
    return _fix(_r2d(math.atan2(x, y)), 360)
