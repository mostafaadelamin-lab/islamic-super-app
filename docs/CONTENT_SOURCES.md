# Content sources and licences

| Content | Source | Licence | Integrity control | Review status |
|---|---|---|---|---|
| Quran Arabic text (Uthmani, Hafs, 6236 ayahs) | The Noble Qur'an Encyclopedia (quranenc.com), distributed as npm `quran-json@3.1.2` `dist/quran.json` | CC BY 4.0 (package) | npm shasum `6cfe0249dc0db413cf582358925717a74a934d7d` matched against the npm registry; file SHA-256 `d8a8adff387f60ce3ff7dbe3238dd9b27120bfe29d8fcb07ad2e89cad37cefd4` pinned in `tests/vectors/quran-reference.json`; per-surah and overall hashes in `content/quran/dist/integrity.v1.json` | Text verified mechanically. **Human verification against a printed Madinah Mushaf by a qualified reviewer: pending.** |
| Madinah Mushaf page boundaries (1405H, 604 pages) | `quran-madina-html` manifest (KFGQPC 1405H layout, DigitalKhatt) | Waqf Public License 2.0 / GPL (see `content/quran/QMH_LICENSE.md`) | contiguity + coverage tests, 5 printed-page spot checks | pending human spot check of more pages |
| English meaning translation | Saheeh International via `quran-json@3.1.2` | **Licence review pending** — the translation's own copyright terms must be confirmed before public release | shown only as an optional aid; never used as Quran text | pending |
| Prayer method parameters | Published parameters of each authority (MWL, Egyptian Survey, Umm al-Qura, Karachi, ISNA, Dubai, Kuwait, Qatar, UOIF) | facts | cross-checked against adhan-js 4.4.6 (MIT) | Official timetable comparison for Cairo/Makkah: pending |
| Morning/evening adhkar, Hisn al-Muslim, Nawawi 40 | Kazi Shariar datasets | CC BY 4.0 | stored, not yet shown in M1 apps | religious review pending |
| Hajj/Umrah guide | Rattil prototype text | project-owned | not yet shown in M1 apps | religious review required |
| Fonts | Amiri Quran, IBM Plex Sans Arabic (Google Fonts repository) | SIL OFL 1.1 | files committed with licence | — |

## Display glyph map
The QuranEnc/KFGQPC text encodes open (idgham) tanween as U+0657, U+065E, U+0656. Amiri Quran draws those shapes at U+08F0–U+08F2.
Clients substitute these three characters **only in the string given to the renderer** (`packages/shared-schemas/quran-render.json`). Stored, searched, synced and hashed text is never changed, and tests on every platform assert this.
The earlier Rattil prototype had applied this substitution to its stored copy; Milestone 1 returns to the pristine upstream file.
