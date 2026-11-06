import json
import math
from datetime import date, datetime

import pytest

from app.domain import prayer as P

from .conftest import REPO

V = json.loads((REPO / "tests/vectors/prayer-times.json").read_text())


@pytest.mark.parametrize("case", V["cases"], ids=[c["id"] for c in V["cases"]])
def test_matches_independent_reference(case):
    day = P.prayer_times(date.fromisoformat(case["date"]), case["lat"], case["lng"], case["method"], case["asr"])
    for k, got in day.as_dict().items():
        ref = datetime.fromisoformat(case["utc"][k].replace("Z", "+00:00"))
        assert abs((got - ref).total_seconds()) / 60 <= V["toleranceMinutes"], (k, got, ref)


@pytest.mark.parametrize("q", V["qibla"], ids=[q["city"] for q in V["qibla"]])
def test_qibla(q):
    assert abs(P.qibla_bearing(q["lat"], q["lng"]) - q["bearing"]) <= V["qiblaToleranceDegrees"]


def test_qibla_at_kaaba_neighbourhood_points_roughly_correct():
    # due west of the Kaaba the qibla is due east (~90 degrees)
    assert abs(P.qibla_bearing(21.4225, 30.0) - 90) < 5


def test_order_of_prayers_is_chronological():
    d = P.prayer_times(date(2026, 3, 20), 30.0444, 31.2357, "egypt").as_dict()
    seq = [d[k] for k in P.PRAYER_KEYS]
    assert seq == sorted(seq)


def test_dst_transition_new_york_shifts_local_clock_not_sun():
    before = P.prayer_times(date(2026, 3, 7), 40.7128, -74.006, "isna")
    after = P.prayer_times(date(2026, 3, 8), 40.7128, -74.006, "isna")
    assert P.local_hhmm(before.dhuhr, "America/New_York") < "12:30"
    assert P.local_hhmm(after.dhuhr, "America/New_York") > "12:30"  # clocks moved forward one hour
    assert abs((after.dhuhr - before.dhuhr).total_seconds() / 3600 - 24) < 0.1  # solar noon nearly unchanged in UTC


def test_hanafi_asr_is_later_than_standard():
    s = P.prayer_times(date(2026, 6, 1), 24.86, 67.0, "karachi", "standard")
    h = P.prayer_times(date(2026, 6, 1), 24.86, 67.0, "karachi", "hanafi")
    assert h.asr > s.asr
    assert h.fajr == s.fajr and h.isha == s.isha


def test_interval_isha_methods():
    d = P.prayer_times(date(2026, 3, 20), 21.3891, 39.8579, "makkah")
    assert (d.isha - d.maghrib).total_seconds() == pytest.approx(90 * 60, abs=60)


def test_high_latitude_rule_is_reported():
    d = P.prayer_times(date(2026, 6, 21), 59.9139, 10.7522, "mwl")
    assert set(d.high_latitude_adjusted) >= {"isha"}
    low = P.prayer_times(date(2026, 6, 21), 30.0, 31.0, "mwl")
    assert low.high_latitude_adjusted == ()


def test_polar_day_raises_clear_error():
    with pytest.raises(P.InvalidInput, match="polar"):
        P.prayer_times(date(2026, 6, 21), 78.22, 15.65, "mwl")  # Longyearbyen, midnight sun


def test_manual_adjustments_apply_per_prayer():
    base = P.prayer_times(date(2026, 1, 1), 30.0, 31.0, "egypt")
    adj = P.prayer_times(date(2026, 1, 1), 30.0, 31.0, "egypt", adjustments={"fajr": 2, "isha": -3})
    assert (adj.fajr - base.fajr).total_seconds() == 120
    assert (adj.isha - base.isha).total_seconds() == -180
    assert adj.dhuhr == base.dhuhr


@pytest.mark.parametrize(
    "kw,msg",
    [
        ({"lat": 91, "lng": 0}, "latitude"),
        ({"lat": 0, "lng": 181}, "longitude"),
        ({"lat": 0, "lng": 0, "method": "nope"}, "unknown method"),
        ({"lat": 0, "lng": 0, "asr": "x"}, "asr"),
    ],
)
def test_invalid_inputs(kw, msg):
    with pytest.raises(P.InvalidInput, match=msg):
        P.prayer_times(date(2026, 1, 1), **kw)


def test_julian_day_known_value():
    assert P.julian_day(2000, 1, 1) == 2451544.5


def test_sun_position_declination_at_june_solstice():
    decl, _ = P.sun_position(P.julian_day(2026, 6, 21) + 0.5)
    assert math.isclose(decl, 23.44, abs_tol=0.1)


def test_methods_file_is_complete():
    m = P.methods()
    for key, cfg in m["methods"].items():
        assert {"nameAr", "nameEn", "fajr"} <= cfg.keys(), key
        assert ("isha" in cfg) != ("ishaMinutes" in cfg), key
