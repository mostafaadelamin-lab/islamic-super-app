#!/usr/bin/env python3
"""Audio Quranic stories (قصص قرآنية مسموعة): catalogue validation, build and a small editor CLI.

A story is a list of Quranic verse ranges. The apps play those verses with the app's reciters
(everyayah.com, the same per-ayah audio as the Mushaf), show the canonical Quran text and offer
Tafsir al-Muyassar per ayah. Owner rule: no story text is written by us; only trusted sources.

Narrated series (owner request, 2026-11-08): audio-only series by a named narrator, e.g. Sheikh Nabil
al-Awadi's "Stories of the Prophets". Episodes are streamed from their https URL (never re-hosted), and a
series must name its source and the licence or permission that allows the app to play it.

Review states:
  story    -> records the check of its verse ranges (the verses, being the Quran, are always shown)
  episode  -> pending: heard only in reviewer mode, with a "not reviewed" banner;
              approved: heard by everyone (reviewer name + date); rejected: never shipped (+ reason)

Catalogue: content/stories/stories.json   Output: content/stories/dist/stories.v1.json

CLI:
  python tools/stories.py list
  python tools/stories.py approve <story-id> --reviewer "name" [--notes "…"]
  python tools/stories.py approve <series-id> --episode <episode-id|all> --reviewer "name"
  python tools/stories.py reject  <id> --reviewer "name" --notes "reason"
  python tools/stories.py build
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import sys
from urllib.parse import urlparse

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / "content/stories/stories.json"
DIST = ROOT / "content/stories/dist/stories.v1.json"
QURAN = ROOT / "content/quran/dist/quran.v1.json"

CATEGORIES = ("prophets", "others")
STATUSES = ("pending", "approved", "rejected")
ID = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
AUDIO_EXT = (".mp3", ".m4a", ".aac", ".ogg", ".opus")


class StoryError(ValueError):
    pass


def ayah_counts() -> list[int]:
    q = json.loads(QURAN.read_text(encoding="utf-8"))
    return [s["ayahCount"] for s in q["surahs"]]


def _date(s: object) -> bool:
    try:
        dt.date.fromisoformat(str(s))
        return True
    except ValueError:
        return False


def _review_problems(where: str, rv: dict) -> list[str]:
    problems: list[str] = []
    status = rv.get("status")
    if status not in STATUSES:
        return [f"{where}: review.status"]
    if status != "pending":
        if not str(rv.get("reviewer") or "").strip():
            problems.append(f"{where}: {status} needs review.reviewer")
        if not _date(rv.get("reviewedAt")):
            problems.append(f"{where}: {status} needs review.reviewedAt")
        if status == "rejected" and not str(rv.get("notes") or "").strip():
            problems.append(f"{where}: rejected needs review.notes (the reason)")
    return problems


def _audio_url_ok(url: object) -> bool:
    u = urlparse(str(url or ""))
    return u.scheme == "https" and bool(u.hostname) and u.path.lower().endswith(AUDIO_EXT)


def series_problems(cat: dict, story_ids: set[str]) -> list[str]:
    problems: list[str] = []
    seen: set[str] = set()
    for i, se in enumerate(cat.get("series", [])):
        where = f"series {i} ({se.get('id', '?')})"
        if not isinstance(se.get("id"), str) or not ID.match(se["id"]) or se["id"] in seen or se["id"] in story_ids:
            problems.append(f"{where}: id must be unique lower-case-kebab")
        seen.add(se.get("id"))
        for field in ("title", "narrator"):
            if not str((se.get(field) or {}).get("ar", "")).strip():
                problems.append(f"{where}: {field}.ar required")
        for field in ("source", "licence"):
            if not str(se.get(field) or "").strip():
                problems.append(f"{where}: {field} required (who published it, and the licence or written permission)")
        eps = se.get("episodes")
        if not isinstance(eps, list) or not eps:
            problems.append(f"{where}: at least one episode")
            eps = []
        eids: set[str] = set()
        for k, e in enumerate(eps):
            ew = f"{where} episode {k} ({e.get('id', '?')})"
            if not isinstance(e.get("id"), str) or not ID.match(e["id"]) or e["id"] in eids:
                problems.append(f"{ew}: id must be unique lower-case-kebab")
            eids.add(e.get("id"))
            if not str((e.get("title") or {}).get("ar", "")).strip():
                problems.append(f"{ew}: title.ar required")
            if not _audio_url_ok(e.get("url")):
                problems.append(f"{ew}: url must be an https link to an audio file ({', '.join(AUDIO_EXT)})")
            d = e.get("durationSec")
            if d is not None and (not isinstance(d, int) or d <= 0):
                problems.append(f"{ew}: durationSec must be a positive integer or null")
            if e.get("story") is not None and e["story"] not in story_ids:
                problems.append(f"{ew}: story {e['story']} does not exist")
            if not _date(e.get("addedAt")):
                problems.append(f"{ew}: addedAt date")
            problems += _review_problems(ew, e.get("review") or {})
    return problems


def validate(cat: dict, counts: list[int]) -> list[str]:
    problems: list[str] = []
    if cat.get("schema") != "stories-catalogue.v1":
        problems.append("schema must be stories-catalogue.v1")
    seen: set[str] = set()
    for i, st in enumerate(cat.get("items", [])):
        sid = st.get("id")
        where = f"item {i} ({sid or '?'})"
        if not isinstance(sid, str) or not ID.match(sid):
            problems.append(f"{where}: id must be lower-case-kebab")
        if sid in seen:
            problems.append(f"{where}: duplicate id")
        seen.add(sid)
        if st.get("category") not in CATEGORIES:
            problems.append(f"{where}: category must be one of {CATEGORIES}")
        v = st.get("title") or {}
        if not str(v.get("ar", "")).strip() or not str(v.get("en", "")).strip():
            problems.append(f"{where}: title needs ar and en")
        if "summary" in st:
            problems.append(f"{where}: no summary: story text comes only from the Quran and its tafsir")
        segs = st.get("segments")
        if not isinstance(segs, list) or not segs:
            problems.append(f"{where}: at least one segment")
            segs = []
        covered: set[tuple[int, int]] = set()
        for j, g in enumerate(segs):
            s, a, b = g.get("surah"), g.get("from"), g.get("to")
            if not all(isinstance(x, int) for x in (s, a, b)) or not 1 <= s <= len(counts):
                problems.append(f"{where}: segment {j} surah")
                continue
            if not 1 <= a <= b <= counts[s - 1]:
                problems.append(f"{where}: segment {j} {s}:{a}-{b} outside 1..{counts[s - 1]}")
                continue
            ayahs = {(s, x) for x in range(a, b + 1)}
            if covered & ayahs:
                problems.append(f"{where}: segment {j} overlaps an earlier segment")
            covered |= ayahs
        if not _date(st.get("addedAt")):
            problems.append(f"{where}: addedAt date")
        problems += _review_problems(where, st.get("review") or {})
    return problems + series_problems(cat, seen)


def build_bundle(cat: dict) -> dict:
    """Catalogue order is kept (roughly chronological). Rejected stories are dropped."""
    out = []
    for st in cat["items"]:
        rv = st["review"]
        if rv["status"] == "rejected":
            continue
        approved = rv["status"] == "approved"
        out.append({
            "id": st["id"],
            "category": st["category"],
            "title": st["title"],
            "segments": [[g["surah"], g["from"], g["to"]] for g in st["segments"]],
            "ayahCount": sum(g["to"] - g["from"] + 1 for g in st["segments"]),
            "status": rv["status"],
            "reviewer": rv.get("reviewer") if approved else None,
            "reviewedAt": rv.get("reviewedAt") if approved else None,
        })
    series = []
    for se in cat.get("series", []):
        eps = []
        for e in se["episodes"]:
            st = e["review"]["status"]
            if st == "rejected":
                continue
            eps.append({
                "id": e["id"],
                "title": {"ar": e["title"]["ar"], "en": e["title"].get("en") or e["title"]["ar"]},
                "url": e["url"],
                "durationSec": e.get("durationSec"),
                "story": e.get("story"),
                "status": st,
                "reviewer": e["review"].get("reviewer") if st == "approved" else None,
            })
        if eps:
            series.append({
                "id": se["id"],
                "title": {"ar": se["title"]["ar"], "en": se["title"].get("en") or se["title"]["ar"]},
                "narrator": {"ar": se["narrator"]["ar"], "en": se["narrator"].get("en") or se["narrator"]["ar"]},
                "source": se["source"],
                "sourceUrl": se.get("sourceUrl"),
                "licence": se["licence"],
                "episodes": eps,
            })
    return {"schema": "stories.v1", "version": cat.get("version", 1), "items": out, "series": series}


def load() -> dict:
    return json.loads(CATALOGUE.read_text(encoding="utf-8"))


def save(cat: dict) -> None:
    CATALOGUE.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build(write: bool = True) -> tuple[dict, list[str]]:
    cat = load()
    problems = validate(cat, ayah_counts())
    bundle = build_bundle(cat) if not problems else {}
    if write and not problems:
        DIST.parent.mkdir(parents=True, exist_ok=True)
        DIST.write_text(json.dumps(bundle, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n", encoding="utf-8")
    return bundle, problems


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("build")
    for name in ("approve", "reject"):
        s = sub.add_parser(name)
        s.add_argument("id")
        s.add_argument("--episode", help="with a series id: review this episode ('all' for every pending one)")
        s.add_argument("--reviewer", required=True)
        s.add_argument("--notes", default="")
    args = ap.parse_args(argv)
    try:
        cat = load()
        if args.cmd == "list":
            for st in cat["items"]:
                segs = ", ".join(f"{g['surah']}:{g['from']}-{g['to']}" for g in st["segments"])
                print(f"{st['review']['status']:9} {st['id']:16} {segs:22} {st['title']['ar']}")
            for se in cat.get("series", []):
                print(f"\nseries {se['id']}: {se['title']['ar']} — {se['narrator']['ar']}")
                for e in se["episodes"]:
                    print(f"  {e['review']['status']:9} {e['id']:16} {e['title']['ar']}")
            return 0
        today = dt.date.today().isoformat()
        if args.cmd in ("approve", "reject"):
            if args.cmd == "reject" and not args.notes.strip():
                raise StoryError("reject needs --notes with the reason")
            review = {
                "status": "approved" if args.cmd == "approve" else "rejected",
                "reviewer": args.reviewer,
                "reviewedAt": today,
                "notes": args.notes,
            }
            if args.episode:
                se = next((x for x in cat.get("series", []) if x["id"] == args.id), None)
                if se is None:
                    raise StoryError(f"no series with id {args.id}")
                targets = [e for e in se["episodes"] if args.episode == "all" and e["review"]["status"] == "pending" or e["id"] == args.episode]
                if not targets:
                    raise StoryError(f"{args.id} has no episode {args.episode}")
            else:
                st = next((x for x in cat["items"] if x["id"] == args.id), None)
                if st is None:
                    raise StoryError(f"no story with id {args.id}")
                targets = [st]
            for t in targets:
                t["review"] = dict(review)
            problems = validate(cat, ayah_counts())
            if problems:
                raise StoryError("; ".join(problems))
            save(cat)
            for t in targets:
                print(f"{args.id}/{t['id']}: {review['status']}")
        _, problems = build()
        if problems:
            raise StoryError("; ".join(problems))
        rel = DIST.relative_to(ROOT) if DIST.is_relative_to(ROOT) else DIST
        print(f"wrote {rel} — now run apps/mobile/tool/sync_assets.sh")
        return 0
    except StoryError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
