# API contract v1 (Milestone 1)

Base URL in development: `http://127.0.0.1:8000`. All bodies are JSON (UTF-8).
`openapi.json` in this folder is generated from the FastAPI app (`python services/api/scripts/export_openapi.py`)
and CI fails if it drifts from the code. Errors use `{"detail": "<message>"}` with 4xx codes.

Clients are **offline-first**: the Quran, pages and prayer calculation ship inside each app.
The API is used for account sync (bookmarks, settings) and as a cross-check for content versions.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | – | `{"status":"ok","version":"0.1.0"}` |
| GET | `/v1/content/versions` | – | `{"quran":"1.0.0","pages":"1405H-1","adhkar":"1.0.0","quranSha256":"…"}` |
| GET | `/v1/quran/surahs` | – | list of `{n,nameAr,nameEn,translit,revelation,ayahCount}` (114) |
| GET | `/v1/quran/surahs/{n}?translation=en` | – | `{n,nameAr,…,ayahs:[{a,text,en?}]}`; 404 if n∉1..114 |
| GET | `/v1/quran/ayahs/{s}/{a}` | – | `{s,a,text,page,en}` |
| GET | `/v1/quran/pages/{p}` | – | Madinah 1405H page: `{page,start:[s,a],end:[s,a],ayahs:[{s,a,text}]}`; 404 if p∉1..604 |
| GET | `/v1/quran/search?q=…&limit=20` | – | diacritic-insensitive Arabic search: `{q,total,results:[{s,a,text}]}`; 422 if q shorter than 2 letters |
| GET | `/v1/prayer/methods` | – | contents of `packages/shared-schemas/prayer/methods.json` |
| GET | `/v1/prayer/times?lat&lng&date=YYYY-MM-DD&tz=Area/City&method=mwl&asr=standard` | – | `{date,tz,method,asr,local:{fajr:"HH:MM",…},utc:{fajr:"…Z",…},highLatitudeAdjusted:[…]}` |
| GET | `/v1/qibla?lat&lng` | – | `{bearing}` degrees clockwise from true north |
| POST | `/v1/auth/register` | – | `{email,password(≥10 chars)}` → 201 `{id,email}`; 409 if taken |
| POST | `/v1/auth/login` | – | `{email,password}` → `{access_token,token_type:"bearer",expires_in}`; 401 on bad credentials |
| GET | `/v1/me` | bearer | `{id,email}` |
| GET | `/v1/me/settings` | bearer | `{settings:{…},updatedAt}` |
| PUT | `/v1/me/settings` | bearer | `{settings,updatedAt}`; last-write-wins on `updatedAt` (ms epoch) |
| GET | `/v1/bookmarks?since=<ms>` | bearer | `{serverTime,items:[Bookmark]}` incl. tombstones (`deleted:true`) |
| PUT | `/v1/bookmarks/{id}` | bearer | upsert; body is `Bookmark` **without** `id` (the id is the path segment; extra fields → 422); last-write-wins on `updatedAt`; returns stored item incl. `id` |

`Bookmark` = `{id: client-generated string (1–64 chars [A-Za-z0-9_-]), surah: 1..114, ayah: 1..ayahCount, note?: ≤500 chars, updatedAt: ms epoch, deleted: bool}`.

Rate limit: auth endpoints 10 requests/minute per IP (429). Other endpoints 120/minute per IP.
