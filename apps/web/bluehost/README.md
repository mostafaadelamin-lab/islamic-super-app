# Website on Bluehost (Apache + PHP)

The site is a static export; only the videos feed/search needs a server. On Netlify that is
`netlify/functions/videos.mjs`; on Bluehost it is `api/videos.php` (a line-for-line PHP port of
`netlify/lib/videos-core.mjs`, same JSON), reached through the same URLs by `.htaccess` rewrites:

- `/api/v1/reels/feed` -> `api/videos.php?route=feed` (cache 3 h in `api/cache/`, last good copy served if YouTube fails)
- `/api/videos/search?q=` -> `api/videos.php?route=search` (cache 1 h)

`.htaccess` also forces https://rattilwasalli.com (no www), serves `/404.html`, adds `/` to page folders,
and sets cache headers (hashed `_next/static` 1 year; pages, `sw.js` and the manifest `no-cache`).
Files are kept as `htaccess.txt` so they are visible; the package script renames them.

Build: `npm run build && node scripts/package-bluehost.mjs`, zip the contents of `out-bluehost/`.

Test (PHP vs the Netlify JS on the same saved YouTube pages; must print EQUAL):
`cd bluehost/test && python3 fx.py && cp ../../netlify/lib/videos-core.mjs ../../netlify/lib/reel-sources.json . && node run.mjs > js.json && php run.php ../api/videos.php > php.json` then compare the two JSON files.
Checked 2026-11-13 on Apache 2.4 + PHP 8.3: pages 200, `/ar/help` -> 301 `/ar/help/`, unknown -> 404 page,
`api/reel-sources.json`, `api/cache/`, `netlify.toml` -> 403, feed 200 JSON.
