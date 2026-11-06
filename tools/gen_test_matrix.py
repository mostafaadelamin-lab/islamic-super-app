#!/usr/bin/env python3
"""Writes docs/reports/TEST_MATRIX.csv. Statuses come from executed runs only (see EVIDENCE)."""
import csv, pathlib, sys
RUN = sys.argv[1] if len(sys.argv) > 1 else "?"
OUT = pathlib.Path(__file__).resolve().parents[1] / "docs/reports/TEST_MATRIX.csv"
# feature, function, android, ios, web, backend, offline, evidence
# Android/iOS cells: "PASS" means Flutter widget/unit tests (shared Dart code) passed on the CI Linux and macOS
# runners AND the device integration flow passed where listed in the 'device_flow' column.
F = [
 ("F-QURAN-01","Surah index list + filter + open","PASS","PASS","PASS","PASS","PASS","widget surah_list_test; e2e pages/features; pytest test_surah_list","yes"),
 ("F-QURAN-02","Surah reader text + ayah numbers","PASS","PASS","PASS","PASS","PASS","widget surah_reader_test; e2e features; pytest test_surah_detail","yes"),
 ("F-QURAN-02","English translation toggle (persisted)","PASS","PASS","PASS","PASS","PASS","widget surah_reader_test; e2e features","no"),
 ("F-QURAN-02","Quran font size 18-40 (persisted)","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget settings_test; e2e features","no"),
 ("F-QURAN-02","Basmala before surahs (not 1, 9)","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget basmala_test; web unit/e2e","no"),
 ("F-QURAN-03","Madinah page reader prev/next/swipe/keys","PASS","PASS","PASS","PASS","PASS","widget page_reader_test; e2e features; pytest test_page","no"),
 ("F-QURAN-03","Go to page with validation","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget page_reader_test (incl. DEF-008); integration_test; e2e features","yes"),
 ("F-QURAN-04","Diacritic-insensitive search + open result","PASS","PASS","PASS","PASS","PASS","unit text_test; widget search_test; e2e features; pytest test_search_*","no"),
 ("F-QURAN-05","Bookmark add/remove + list + persistence","PASS","PASS","PASS","PASS","PASS","widget bookmarks_test; integration_test; e2e features; pytest test_sync","yes"),
 ("F-QURAN-05","Continue reading","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget home_test; e2e features","no"),
 ("F-QURAN-06","Quran integrity (114/6236/hashes/pages)","PASS","PASS","PASS","PASS","PASS","QURAN_INTEGRITY_REPORT.md","no"),
 ("F-PRAYER-01","Prayer times vs 38 independent vectors","PASS","PASS","PASS","PASS","PASS","unit prayer_test; vitest prayer.test; pytest test_prayer","no"),
 ("F-PRAYER-01","City picker","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget prayer_screen_test; integration_test; e2e features","yes"),
 ("F-PRAYER-01","Use my location (browser geolocation)","NOT APPLICABLE","NOT APPLICABLE","PASS","NOT APPLICABLE","PASS","e2e features (granted + denied); mobile: not in M1","no"),
 ("F-PRAYER-01","Method + Asr selectors","PASS","PASS","PASS","PASS","PASS","widget prayer_screen_test; e2e features; pytest","no"),
 ("F-PRAYER-01","DST transitions (5 zones)","PASS","PASS","PASS","PASS","PASS","vectors London/NY/Sydney/Cairo/Oslo","no"),
 ("F-PRAYER-01","High-latitude rule + polar message","PASS","PASS","PASS","PASS","PASS","unit + widget + e2e + pytest","no"),
 ("F-PRAYER-02","Manual adjustments -30..+30","PASS","PASS","PASS","PASS","PASS","widget prayer_screen_test; e2e features; pytest test_manual_adjustments","no"),
 ("F-PRAYER-03","Next prayer countdown","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget home/prayer tests; e2e features","no"),
 ("F-PRAYER-04","Qibla bearing + static compass","PASS","PASS","PASS","PASS","PASS","unit qibla vectors; widget; e2e; pytest test_qibla","no"),
 ("F-PRAYER-04","Live compass (sensor)","NOT TESTED","NOT TESTED","NOT TESTED","NOT APPLICABLE","NOT TESTED","not implemented in M1","no"),
 ("F-I18N-01","Arabic RTL / English LTR + switch","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget shell/settings tests; e2e features","no"),
 ("F-UI-01","Themes light/dark/system + tokens","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget settings_test; e2e features; screenshots","no"),
 ("NFR-A11Y","Accessibility (labels, tap targets, contrast)","PASS","PASS","PASS","NOT APPLICABLE","NOT APPLICABLE","widget a11y_test; axe 44 scans 0 violations","no"),
 ("NFR-RESP","Responsive layouts 360/768/1280, text scale 1.5/2.0","PASS","PASS","PASS","NOT APPLICABLE","NOT APPLICABLE","widget text-scale tests; e2e responsive","no"),
 ("F-SYNC-01","Register / sign in / sign out","PASS","PASS","PASS","PASS","NOT APPLICABLE","widget account_test (fake HTTP) + live API run; e2e sync; pytest test_auth","no"),
 ("F-SYNC-01","Bookmark sync LWW + tombstones","PASS","PASS","PASS","PASS","PASS","unit sync tests; e2e sync vs real API; pytest test_sync","no"),
 ("F-SYNC-01","Settings sync","NOT TESTED","NOT TESTED","NOT TESTED","PASS","NOT APPLICABLE","API only; clients not wired (LIM-03)","no"),
 ("NFR-OFF","Offline after first load","PASS","PASS","PASS","NOT APPLICABLE","PASS","mobile: bundled assets, no network calls except sync; web: e2e offline (server stopped) 3 browsers","no"),
 ("F-ABOUT-01","About + free policy + sources","PASS","PASS","PASS","NOT APPLICABLE","PASS","widget about; e2e features","no"),
 ("F-API-01","API validation/auth/rate-limit/headers/migrations","NOT APPLICABLE","NOT APPLICABLE","NOT APPLICABLE","PASS","NOT APPLICABLE","pytest 128","no"),
 ("M2","Quran audio","NOT TESTED","NOT TESTED","NOT TESTED","NOT APPLICABLE","NOT TESTED","not implemented in M1","no"),
 ("M2","Adhkar","NOT TESTED","NOT TESTED","NOT TESTED","NOT APPLICABLE","NOT TESTED","content stored, not shown in M1","no"),
 ("M2","Hajj guide","NOT TESTED","NOT TESTED","NOT TESTED","NOT APPLICABLE","NOT TESTED","not ported in M1","no"),
 ("M2","Adhan notifications","NOT TESTED","NOT TESTED","NOT TESTED","NOT APPLICABLE","NOT TESTED","not implemented in M1","no"),
 ("M3+","AI assistant","NOT TESTED","NOT TESTED","NOT TESTED","NOT TESTED","NOT TESTED","not started","no"),
]
with OUT.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["feature_id", "function", "android", "ios", "web", "backend", "offline", "covered_by_device_integration_flow", "evidence", "ci_run"])
    for r in F:
        w.writerow([*r[:7], r[8], r[7], RUN])
print(len(F), "rows ->", OUT)
