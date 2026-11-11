# Quran integrity report

## Update 2026-11-10 — Quran content 2.0.0: King Fahd Complex text v18 (owner's request)
- **Source now:** KFGQPC "Hafs Uthmanic Data" v18, `hafsData_v18.json` (2021-10-25, the Complex's latest published release), file SHA-256 `5d8bb91726e482839d0057633cb1973031e4d706fa9604eea5e08892f20ba140`.
- **Text:** every one of the 6236 ayahs is the Complex's `aya_text` byte-for-byte; only the trailing no-break space + ayah number that the file appends is removed (the build and tests check that number equals the ayah). Overall SHA-256 of the bundled ayahs: `debc5c29cc6116809f4778dbbcb7abbe01e8f845fb924081d8b67d97b757b48b`.
- **Compared with the previous text (quranenc via quran-json 3.1.2):** no letter, dot or haraka differs; the differences were Unicode encoding only (code point order and the no-break space after ۞ and some signs).
- **Pages and lines:** KFGQPC new edition (1441H). Every ayah's page equals the v18 `page` column (6236/6236); every ayah's first and last line in the 15-line layout equals v18 `line_start`/`line_end`. Juz starts follow the printed margin marks: juz 4 starts at ۞ 3:93 and juz 11 at ۞ 9:93 ("الجزء ٤ / الحزب ٧", "الجزء ١١ / الحزب ٢١"), while the page headers follow v18 `jozz` (page 62 = juz 4, page 201 = juz 10, page 202 = juz 11). Checked against the owner's printed copy on 2026-11-11.
- **Font:** KFGQPC HAFS Uthmanic Script v18, unmodified; the display glyph map is now empty; the ayah ornament is drawn by the font.
- **Tafsir al-Muyassar:** 114 surahs, one entry per ayah (6236), positions equal the upstream numbering 1..6236; spot-checked 2:255, 2:282, 9:129, 18:1, 36:82, 112:1.
- **Recitation:** audio is addressed by surah and ayah number (everyayah `SSSAAA.mp3`), independent of the text; page playlists come from the new pages (checked above). everyayah.com is not reachable from the build machine, so the files were not fetched here.
- Human comparison with a printed Mushaf and official approval (KFGQPC / al-Azhar) remain **pending**.

---

# Milestone 1 (historical)

**Result: PASS on Backend, Web, and the Flutter suite (run on Linux and on macOS CI).** Human religious verification: **PENDING**.

## Approved source
- The Noble Qur'an Encyclopedia (QuranEnc) Uthmani text, Hafs, Kufi numbering, via npm `quran-json@3.1.2` `dist/quran.json`.
- npm tarball shasum `6cfe0249dc0db413cf582358925717a74a934d7d`, matched against registry metadata on 2026-11-06.
- File SHA-256 `d8a8adff387f60ce3ff7dbe3238dd9b27120bfe29d8fcb07ad2e89cad37cefd4` (pinned in `tests/vectors/quran-reference.json`).
- No AI-generated text is used anywhere; expected values in tests are either hashes of the source or letter skeletons of well-known ayahs.

## Checks (identical intent on every platform)
| Check | Backend (pytest) | Web (vitest) | Flutter (flutter_test) |
|---|---|---|---|
| Upstream file hash pinned | PASS | – | PASS (every ayah equals upstream) |
| 114 surahs, 6236 ayahs | PASS | PASS | PASS |
| Per-surah counts = independent reference list | PASS | PASS | PASS |
| Surah order 1..114 | PASS | PASS | PASS |
| Every ayah byte-identical to upstream | PASS | PASS (via hashes) | PASS |
| SHA-256 all ayahs `7b2b0712466673…` | PASS | PASS | PASS |
| SHA-256 per surah (114) | PASS | PASS | PASS |
| Display glyph map never present in stored/hashed text | PASS | PASS | PASS |
| 604 Madinah pages contiguous, cover 6236 ayahs exactly | PASS | PASS | PASS |
| Printed-page spot checks (p1, p2, p3, p50, p604) | PASS | PASS | PASS |
| Basmala shown before surahs 2–114 except 9 (display) | n/a | PASS | PASS (after DEF-001) |

Content build (`tools/build_content.py`) refuses to emit output if any count, hash or page boundary check fails; CI re-runs it and fails if regenerated files differ from the committed ones.

## Finding carried over from the prototype
The earlier Rattil prototype had replaced three tanween code points (U+0657/U+065E/U+0656 → U+08F0/U+08F1/U+08F2) **in its stored text** so the Amiri Quran font would draw them. Milestone 1 restores the pristine upstream text; the replacement now happens only in the string handed to the text renderer. Tests on all platforms assert U+08F0–U+08F2 never occur in stored text.

## Not yet verified
- Audio-to-verse mapping, downloaded-content checks: no audio or downloads in M1.
- Human comparison with a printed Madinah Mushaf by a qualified reviewer: **PENDING (owner to arrange)**.
