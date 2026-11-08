#!/usr/bin/env python3
"""Curated Islamic reels: catalogue validation, build and a small editor CLI.

Videos stay on YouTube and are shown with YouTube's official embed player, so
nothing is downloaded, re-hosted or stored by us. (Instagram is not enabled yet.)

Only two kinds of reels are accepted, per the owner's content policy:
  recitation -> a humble, moving Quran recitation (تلاوة قرآنية خاشعة)
  lesson     -> a short religious lesson in line with the Quran and the Sunnah (درس ديني مختصر)

Every reel goes through a religious-accuracy review before any app shows it:
  pending  -> visible only in the apps' reviewer mode, with a "not reviewed" banner
  approved -> visible to everyone (needs the reviewer's name and the review date)
  rejected -> kept in the catalogue (so it is not re-added) but never shipped

Catalogue: content/reels/reels.json   Output: content/reels/dist/reels.v1.json

CLI (run from anywhere):
  python tools/reels.py list
  python tools/reels.py add <youtube-url> --title-ar "…" [--title-en "…"]
                            [--speaker-ar "…"] [--category recitation|lesson] [--source "channel"]
  python tools/reels.py approve <id> --reviewer "name" [--notes "…"]
  python tools/reels.py reject <id> --reviewer "name" --notes "reason"
  python tools/reels.py build
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import re
import sys
from urllib.parse import parse_qs, urlparse

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / "content/reels/reels.json"
DIST = ROOT / "content/reels/dist/reels.v1.json"

PLATFORMS = ("youtube",)  # Instagram is not enabled yet
CATEGORIES = ("recitation", "lesson")
STATUSES = ("pending", "approved", "rejected")
YT_ID = re.compile(r"^[A-Za-z0-9_-]{11}$")
YT_HOSTS = {"youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"}


class ReelError(ValueError):
    pass


def parse_url(url: str) -> tuple[str, str]:
    """Return ("youtube", video id) for a YouTube video or Short link."""
    u = urlparse(url.strip())
    if u.scheme not in ("http", "https"):
        raise ReelError("link must start with https://")
    host = (u.hostname or "").lower()
    parts = [p for p in u.path.split("/") if p]
    ref = None
    if host in ("youtu.be", "www.youtu.be"):
        ref = parts[0] if parts else None
        platform = "youtube"
    elif host in YT_HOSTS:
        platform = "youtube"
        if parts[:1] == ["watch"]:
            ref = (parse_qs(u.query).get("v") or [None])[0]
        elif len(parts) >= 2 and parts[0] in ("shorts", "embed", "live", "v"):
            ref = parts[1]
    elif "instagram.com" in host:
        raise ReelError("Instagram is not enabled yet: only YouTube links for now")
    else:
        raise ReelError(f"only YouTube links are supported, got {host or 'nothing'}")
    if not ref:
        raise ReelError("could not find the video in this link")
    if not YT_ID.match(ref):
        raise ReelError(f"not a YouTube video id: {ref}")
    return platform, ref


def canonical_url(platform: str, ref: str) -> str:
    return f"https://www.youtube.com/watch?v={ref}"


def reel_id(platform: str, ref: str) -> str:
    return "yt-" + ref


def _date(s: object) -> bool:
    try:
        dt.date.fromisoformat(str(s))
        return True
    except ValueError:
        return False


def validate(cat: dict) -> list[str]:
    problems: list[str] = []
    if cat.get("schema") != "reels-catalogue.v1":
        problems.append("schema must be reels-catalogue.v1")
    seen: set[str] = set()
    for i, r in enumerate(cat.get("items", [])):
        where = f"item {i} ({r.get('id', '?')})"
        p, ref = r.get("platform"), r.get("ref", "")
        if p not in PLATFORMS:
            problems.append(f"{where}: platform"); continue
        if not YT_ID.match(ref):
            problems.append(f"{where}: ref")
        if r.get("id") != reel_id(p, ref):
            problems.append(f"{where}: id must be {reel_id(p, ref)}")
        if r.get("url") != canonical_url(p, ref):
            problems.append(f"{where}: url must be {canonical_url(p, ref)}")
        if r.get("id") in seen:
            problems.append(f"{where}: duplicate")
        seen.add(r.get("id"))
        title = r.get("title") or {}
        if not str(title.get("ar", "")).strip():
            problems.append(f"{where}: Arabic title required")
        if r.get("category") not in CATEGORIES:
            problems.append(f"{where}: category must be one of {CATEGORIES}")
        if not _date(r.get("addedAt")):
            problems.append(f"{where}: addedAt date")
        rv = r.get("review") or {}
        st = rv.get("status")
        if st not in STATUSES:
            problems.append(f"{where}: review.status")
        elif st != "pending":
            if not str(rv.get("reviewer") or "").strip():
                problems.append(f"{where}: {st} needs review.reviewer")
            if not _date(rv.get("reviewedAt")):
                problems.append(f"{where}: {st} needs review.reviewedAt")
            if st == "rejected" and not str(rv.get("notes") or "").strip():
                problems.append(f"{where}: rejected needs review.notes (the reason)")
    return problems


def build_bundle(cat: dict) -> dict:
    """Approved reels first (newest review first), then pending ones (newest added first). Rejected are dropped."""
    def item(r: dict) -> dict:
        rv = r["review"]
        return {
            "id": r["id"],
            "platform": r["platform"],
            "ref": r["ref"],
            "url": r["url"],
            "title": {"ar": r["title"]["ar"], "en": r["title"].get("en") or r["title"]["ar"]},
            "speaker": r.get("speaker") or None,
            "category": r["category"],
            "source": r.get("source") or None,
            "status": rv["status"],
            "reviewer": rv.get("reviewer") if rv["status"] == "approved" else None,
            "reviewedAt": rv.get("reviewedAt") if rv["status"] == "approved" else None,
        }

    items = cat["items"]
    approved = sorted((r for r in items if r["review"]["status"] == "approved"), key=lambda r: (r["review"]["reviewedAt"], r["id"]), reverse=True)
    pending = sorted((r for r in items if r["review"]["status"] == "pending"), key=lambda r: (r["addedAt"], r["id"]), reverse=True)
    return {"schema": "reels.v1", "version": cat.get("version", 1), "items": [item(r) for r in approved + pending]}


def load() -> dict:
    return json.loads(CATALOGUE.read_text(encoding="utf-8"))


def save(cat: dict) -> None:
    CATALOGUE.write_text(json.dumps(cat, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build(write: bool = True) -> tuple[dict, list[str]]:
    cat = load()
    problems = validate(cat)
    bundle = build_bundle(cat) if not problems else {}
    if write and not problems:
        DIST.parent.mkdir(parents=True, exist_ok=True)
        DIST.write_text(json.dumps(bundle, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n", encoding="utf-8")
    return bundle, problems


def _find(cat: dict, rid: str) -> dict:
    for r in cat["items"]:
        if r["id"] == rid:
            return r
    raise ReelError(f"no reel with id {rid}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("build")
    a = sub.add_parser("add")
    a.add_argument("url")
    a.add_argument("--title-ar", required=True)
    a.add_argument("--title-en")
    a.add_argument("--speaker-ar")
    a.add_argument("--speaker-en")
    a.add_argument("--category", required=True, choices=CATEGORIES)
    a.add_argument("--source")
    for name in ("approve", "reject"):
        s = sub.add_parser(name)
        s.add_argument("id")
        s.add_argument("--reviewer", required=True)
        s.add_argument("--notes", default="")
    args = ap.parse_args(argv)

    try:
        cat = load()
        today = dt.date.today().isoformat()
        if args.cmd == "list":
            for r in cat["items"]:
                print(f"{r['review']['status']:9} {r['id']:20} {r['title']['ar']}")
            return 0
        if args.cmd == "add":
            platform, ref = parse_url(args.url)
            rid = reel_id(platform, ref)
            if any(r["id"] == rid for r in cat["items"]):
                raise ReelError(f"{rid} is already in the catalogue")
            speaker = {"ar": args.speaker_ar, "en": args.speaker_en or args.speaker_ar} if args.speaker_ar else None
            cat["items"].insert(0, {
                "id": rid, "platform": platform, "ref": ref, "url": canonical_url(platform, ref),
                "title": {"ar": args.title_ar, "en": args.title_en or ""}, "speaker": speaker,
                "category": args.category, "source": args.source, "addedAt": today,
                "review": {"status": "pending", "reviewer": None, "reviewedAt": None, "notes": ""},
            })
            print(f"added {rid} as pending review")
        elif args.cmd in ("approve", "reject"):
            if args.cmd == "reject" and not args.notes.strip():
                raise ReelError("reject needs --notes with the reason")
            r = _find(cat, args.id)
            r["review"] = {"status": "approved" if args.cmd == "approve" else "rejected", "reviewer": args.reviewer, "reviewedAt": today, "notes": args.notes}
            print(f"{args.id}: {r['review']['status']}")
        problems = validate(cat)
        if problems:
            raise ReelError("; ".join(problems))
        if args.cmd != "build":
            save(cat)
        _, problems = build()
        if problems:
            raise ReelError("; ".join(problems))
        print(f"wrote {DIST.relative_to(ROOT)} — now run apps/mobile/tool/sync_assets.sh")
        return 0
    except ReelError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
