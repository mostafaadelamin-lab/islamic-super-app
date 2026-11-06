# Quran integrity report — Milestone 1

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
