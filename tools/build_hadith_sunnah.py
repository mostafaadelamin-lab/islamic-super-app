#!/usr/bin/env python3
"""Rebuilds Sahih al-Bukhari and Sahih Muslim in content/hadith/dist from sunnah.com copies.

Owner's decision (2026-11-26): the texts of these two books come from sunnah.com only.

Usage:
  python3 tools/build_hadith_sunnah.py --site <dir>      (2026-11-27: text and numbers from sunnah.com itself)
  python3 tools/build_hadith_sunnah.py <hadith-json dir> <hadith-api dir>      (first build, from two copies)

  --site <dir>: bukhari.site.json and muslim.site.json = every book page of sunnah.com/<book>, read in a
      browser (the Arabic box of each hadith, its "Reference" number, chapter titles). The text shipped is the
      site's text with outer spaces trimmed. Also moves old bookmarks (from-alamiyya.json) to the new entries
      and writes <dir>/moves.json (previous entry -> new entry) for the Hajj guide and kids ruqyah references.

  <hadith-json dir>: bukhari.json and muslim.json of github.com/AhmedBaset/hadith-json v1.2.0
      (db/by_book/the_9_books), a copy of sunnah.com. The TEXT shipped is its "arabic" field, byte for byte.
  <hadith-api dir>: ara-bukhari.json and ara-muslim.json of github.com/fawazahmed0/hadith-api
      (cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/), a second copy of sunnah.com. Used ONLY for
      the sunnah.com hadith numbers (Bukhari 1..7563; Muslim "2186a" style) and as the cross-check.

Run it before tools/hadith_explained.py. Each entry of the first copy gets the numbers of the entries of
the second copy whose text it contains (spaces and direction marks ignored); a few entries of Muslim that
the second copy lacks get the number between their neighbours, or "~<number before>" when that is not
certain. Every number of the second copy must land on exactly one entry, or the build stops.

Also writes <book>/refs.json (the sunnah.com number of every entry, in order) and
<book>/from-alamiyya.json (old al-Alamiyya number -> new entry, for saved bookmarks), and replaces the two
books in books.v1.json.
"""
import glob
import hashlib
import json
import os
import re
import sys

CHUNK = 500
EXPECTED_SHA = {  # inputs as reviewed on 2026-11-26
    "hj/bukhari.json": "8b0038db684b9a37efe2f047627c8076496b2a6d05bff576272de17b6da699f7",
    "hj/muslim.json": "530ed720dea65c7eb4d6ebfef86e9be22ed284f3cb2d33e33d1d66c8318fd24f",
    "fz/ara-bukhari.json": "e34a3402889ca378871da3c5984b7875c680920e93f1c8738ac7afe502179562",
    "fz/ara-muslim.json": "194073b24090c5368e4d14a3f55c9e0ef144c7437bd7e5aa83aa4d2bc54a8ea0",
}
BOOKS = [("bukhari", "صحيح البخاري", "Sahih al-Bukhari"), ("muslim", "صحيح مسلم", "Sahih Muslim")]
LETTERS = "abcdefghijklmnopqrstuvwxyz"


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def squash(s):
    """Text without spaces, direction marks, U+FFFD and braces: only for matching, never shipped."""
    return re.sub(r"[\s‌-‏ �{}]+", "", s)


def plain(s):
    """Letters only, no diacritics (for matching the old al-Alamiyya texts)."""
    s = re.sub(r"[ؐ-ًؚ-ٰٟۖ-ۭـ‌-‏]", "", s)
    s = re.sub("[أإآٱ]", "ا", s).replace("ى", "ي").replace("ة", "ه")
    return re.sub(r"[^ء-ي]+", " ", s).split()


def label_of(h, book):
    """sunnah.com number of one hadith-api entry: ("n", base, letter) / ("i", n) for Muslim's introduction."""
    if book == "bukhari":
        return ("n", int(float(h["hadithnumber"])), 0)
    ref = h["reference"]
    if ref["book"] == 0 and ref["hadith"] > 0:
        return ("i", ref["hadith"], 0)
    a = h.get("arabicnumber")
    if a is None:
        return None
    a = str(a)
    if "." in a:
        b, l = a.split(".")
        return ("n", int(b), int(l))
    return ("n", int(float(a)), 0)


def fmt(t):
    if t[0] == "i":
        return f"intro{t[1]}"
    return f"{t[1]}{LETTERS[t[2] - 1] if t[2] else ''}"


def align(book, hj, fz):
    """entry index -> list of hadith-api numbers, matched in order."""
    texts = [squash(h["arabic"]) for h in hj]
    starts, big = [], []
    off = 0
    for t in texts:
        starts.append(off)
        big.append(t + "|")
        off += len(t) + 1
    big = "".join(big)

    def entry_at(o):
        lo, hi = 0, len(starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if starts[mid] <= o:
                lo = mid
            else:
                hi = mid - 1
        return lo

    inv, pos, missing = {}, 0, []
    for h in fz:
        t = squash(h["text"])
        if not t:
            continue
        o = big.find(t, pos)
        if o < 0:
            o = big.find(t)
        if o < 0:
            # the second copy has a broken letter (U+FFFD): look for its longest clean piece
            piece = max(re.split("�", re.sub(r"[\s‌-‏ {}]+", "", h["text"])), key=len)
            o = big.find(piece, pos)
        if o < 0:
            missing.append(h["hadithnumber"])
            continue
        inv.setdefault(entry_at(o), []).append(h)
        pos = o
    return inv, missing


def build_labels(book, hj, fz, inv):
    by_num = {h["hadithnumber"]: h for h in fz}
    labels = [None] * len(hj)
    for k, hs in inv.items():
        ts = [label_of(h, book) for h in hs]
        if all(ts):
            seen = []
            for t in ts:
                if fmt(t) not in seen:
                    seen.append(fmt(t))
            labels[k] = seen
    # entries of the second copy with no text: numbers that sunnah.com shows together with the entry before
    if book == "bukhari":
        owner = {h["hadithnumber"]: k for k, hs in inv.items() for h in hs}
        prev = None
        for h in fz:
            n = h["hadithnumber"]
            if n in owner:
                prev = owner[n]
            elif not squash(h["text"]) and prev is not None:
                lab = fmt(label_of(h, book))
                if lab not in labels[prev]:
                    labels[prev].append(lab)
        return labels, 0
    # Muslim: gaps between numbered entries
    gaps = [k for k in range(len(hj)) if labels[k] is None]
    groups = []
    for k in gaps:
        if groups and k == groups[-1][-1] + 1:
            groups[-1].append(k)
        else:
            groups.append([k])
    approx = 0
    for g in groups:
        p, q = g[0] - 1, g[-1] + 1
        pn = max((h["hadithnumber"] for h in inv.get(p, [])), default=None) if p >= 0 and labels[p] else None
        qn = min((h["hadithnumber"] for h in inv.get(q, [])), default=None) if q < len(hj) and labels[q] else None
        P = label_of(by_num[pn], book) if pn else None
        Q = label_of(by_num[qn], book) if qn else None
        cands = []
        if pn and qn:
            cands = [label_of(h, book) for h in fz
                     if pn < h["hadithnumber"] < qn and not squash(h["text"]) and label_of(h, book)]
        if not cands and P and Q and P[0] == Q[0] == "n":
            pb, pl, qb, ql = P[1], P[2], Q[1], Q[2]
            if pb == qb and ql - pl - 1 == len(g):
                cands = [("n", pb, pl + 1 + j) for j in range(len(g))]
            elif qb == pb + 1 and pl > 0 and ql in (0, 1):
                cands = [("n", pb, pl + 1 + j) for j in range(len(g))]
            elif qb == pb + len(g) + 1 and pl == 0 and ql in (0, 1):
                cands = [("n", pb + 1 + j, 0) for j in range(len(g))]
        if not cands and P and Q and P[0] == Q[0] == "i" and Q[1] - P[1] - 1 == len(g):
            cands = [("i", P[1] + 1 + j, 0) for j in range(len(g))]
        if len(cands) == len(g):
            for k, c in zip(g, cands):
                labels[k] = [fmt(c)]
        else:
            before = labels[p][-1] if p >= 0 and labels[p] else ""
            for k in g:
                labels[k] = [f"~{before}"] if before else [""]
                approx += 1
    return labels, approx


def old_texts(dist, book):
    out = {}
    for f in glob.glob(os.path.join(dist, book, "[0-9]*.json")):
        j = json.load(open(f, encoding="utf-8"))
        for i, t in enumerate(j["ahadith"]):
            out[j["from"] + i] = t
    return [out[n] for n in range(1, len(out) + 1)]


def migrate(old, hj):
    """old al-Alamiyya number -> best new entry (1-based), by shared 5-word runs; 0 when nothing is close."""
    N = 5
    index = {}
    for k, h in enumerate(hj):
        w = plain(h["arabic"])
        for i in range(len(w) - N + 1):
            index.setdefault(" ".join(w[i:i + N]), set()).add(k)
    res, guess = [], 0
    expect = 0
    for t in old:
        w = plain(t)
        gs = {" ".join(w[i:i + N]) for i in range(len(w) - N + 1)}
        counts = {}
        for g in gs:
            ks = index.get(g, ())
            if len(ks) > 50:
                continue
            for k in ks:
                counts[k] = counts.get(k, 0) + 1
        if not counts:
            res.append(0)
            continue
        best = max(counts.items(), key=lambda kv: (kv[1], -abs(kv[0] - expect)))
        if best[1] / max(1, len(gs)) < 0.5:
            guess += 1
        res.append(best[0] + 1)
        expect = best[0]
    return res, guess


SITE_SHA = {  # pages of sunnah.com itself, read on 2026-11-26/27 in a browser (owner approved, 2026-11-27)
    "bukhari.site.json": "1c6ff13e17612eea22ed2477b43de4f5170f4f10bb8b225cebc5c5eae0c2985a",
    "muslim.site.json": "01214c6064fbcb1da6c0842bfffb4f7b34d66266e8e6035f9c83be05794a8ecb",
}


def site_label(refs):
    """'Reference : Sahih Muslim 4 a' -> '4a'; '... Introduction 8' -> 'intro8'; '2314, 2315' -> '2314,2315'."""
    r = next((x for x in refs if x.startswith("Reference :")), "")
    m = re.match(r"Reference : Sahih (?:al-Bukhari|Muslim) (.+)$", r)
    if not m:
        return None
    v = m.group(1).strip()
    if v.startswith("Introduction"):
        return "intro" + v.split()[-1]
    return ",".join(re.sub(r"\s+", "", x) for x in v.split(","))


def clean(t):
    """The site's text as shown: outer spaces trimmed, runs of spaces made one, line breaks kept."""
    t = t.strip().replace("\r", "")
    t = re.sub(r"[ \t]+", " ", t)
    return re.sub(r" ?\n[ \n]*", "\n", t)


def main_site(sitedir):
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dist = os.path.join(repo, "content", "hadith", "dist")
    meta_path = os.path.join(dist, "books.v1.json")
    meta = json.load(open(meta_path, encoding="utf-8"))
    report = {}
    for bid, ar, en in BOOKS:
        path = os.path.join(sitedir, f"{bid}.site.json")
        want = SITE_SHA.get(f"{bid}.site.json")
        if want and sha256(path) != want:
            sys.exit(f"{path}: SHA-256 changed; review the new pages, then update SITE_SHA")
        site = json.load(open(path, encoding="utf-8"))
        texts, labels, chapters = [], [], []
        for page in site["pages"]:
            if page.get("error"):
                sys.exit(f"{bid}: page {page['p']} was not read")
            for it in page["items"]:
                t = clean(it["ar"])
                if not t:
                    continue  # one empty box on the site (Bukhari book 62)
                lab = site_label(it["refs"])
                if lab is None:
                    sys.exit(f"{bid}: no sunnah.com number on {page['p']}")
                texts.append(t)
                labels.append(lab)
        if len(set(labels)) != len(labels):
            dup = [l for l in set(labels) if labels.count(l) > 1]
            sys.exit(f"{bid}: numbers used twice: {dup[:10]}")
        # the app's previous build of this book (sunnah.com copy): old entry -> new entry, by number, else by text
        old_refs = json.load(open(os.path.join(dist, bid, "refs.json"), encoding="utf-8"))["refs"]
        old = old_texts(dist, bid)
        by_label = {}
        for k, l in enumerate(labels):
            for part in l.split(","):
                by_label.setdefault(part, k)
        by_text = {}
        for k, t in enumerate(texts):
            by_text.setdefault(squash(t), k)
        move, by_num, by_txt, near = [], 0, 0, 0
        for i, (r, t) in enumerate(zip(old_refs, old)):
            k = by_text.get(squash(t))
            if k is not None:
                by_txt += 1
            else:
                parts = [x for x in r.split(",") if x and not x.startswith("~")]
                k = next((by_label[x] for x in parts if x in by_label), None)
                if k is not None:
                    by_num += 1
                else:
                    k = move[-1] if move else 0
                    near += 1
            move.append(k)
        mig_path = os.path.join(dist, bid, "from-alamiyya.json")
        if os.path.exists(mig_path):
            mig = json.load(open(mig_path, encoding="utf-8"))
            mig["to"] = [move[n - 1] + 1 if n else 0 for n in mig["to"]]
            with open(mig_path, "w", encoding="utf-8") as f:
                json.dump(mig, f, separators=(",", ":"))
        report[bid] = {"old_to_new": [k + 1 for k in move], "by_label": by_label}
        for f in glob.glob(os.path.join(dist, bid, "[0-9]*.json")):
            os.remove(f)
        chunks = (len(texts) + CHUNK - 1) // CHUNK
        for k in range(chunks):
            part = {"book": bid, "from": k * CHUNK + 1, "ahadith": texts[k * CHUNK:(k + 1) * CHUNK]}
            with open(os.path.join(dist, bid, f"{k}.json"), "w", encoding="utf-8") as f:
                json.dump(part, f, ensure_ascii=False, separators=(",", ":"))
        with open(os.path.join(dist, bid, "refs.json"), "w", encoding="utf-8") as f:
            json.dump({"book": bid, "refs": labels}, f, ensure_ascii=False, separators=(",", ":"))
        books = {}
        for page in site["pages"]:
            n = sum(1 for it in page["items"] if clean(it["ar"]))
            if n:
                books[page["p"].rsplit("/", 1)[-1]] = sha256_text("\n".join(
                    bare(clean(it["ar"])) for it in page["items"] if clean(it["ar"])))
        entry = {
            "id": bid, "nameAr": ar, "nameEn": en, "count": len(texts), "chunks": chunks,
            "numbering": "sunnah.com", "refs": True,
            "source": {"name": "sunnah.com", "url": "https://sunnah.com/" + bid, "read": site["fetched"]},
            "sourceFile": f"sunnah.com/{bid}.site.json", "sha256": sha256(path),
            "textSha256": sha256_text("\n".join(texts)),
            "fingerprint": {
                "how": "SHA-256 of each hadith's letters and marks with spaces and direction marks removed, one per line",
                "all": sha256_text("\n".join(bare(t) for t in texts)),
                "books": books,
            },
        }
        meta["books"] = [entry if b["id"] == bid else b for b in meta["books"]]
        print(bid, len(texts), "entries from sunnah.com,", chunks, "parts; old entries moved by text", by_txt,
              "by number", by_num, "nearest", near, "; fingerprint", entry["fingerprint"]["all"])
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        f.write("\n")
    with open(os.path.join(sitedir, "moves.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False)


def bare(s):
    """For the fingerprint: the text without spaces and invisible direction marks (letters, marks, braces kept)."""
    return re.sub(r"[\s\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]+", "", s)


def sha256_text(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def main():
    if sys.argv[1] == "--site":
        return main_site(sys.argv[2])
    hjdir, fzdir = sys.argv[1:3]
    for rel, want in EXPECTED_SHA.items():
        d, name = rel.split("/")
        path = os.path.join(hjdir if d == "hj" else fzdir, name)
        if sha256(path) != want:
            sys.exit(f"{path}: SHA-256 changed; review the new copy, then update EXPECTED_SHA")
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dist = os.path.join(repo, "content", "hadith", "dist")
    meta_path = os.path.join(dist, "books.v1.json")
    meta = json.load(open(meta_path, encoding="utf-8"))
    for bid, ar, en in BOOKS:
        hj_path = os.path.join(hjdir, f"{bid}.json")
        fz_path = os.path.join(fzdir, f"ara-{bid}.json")
        hj = json.load(open(hj_path, encoding="utf-8"))["hadiths"]
        fz = json.load(open(fz_path, encoding="utf-8"))["hadiths"]
        if [h["idInBook"] for h in hj] != list(range(1, len(hj) + 1)):
            sys.exit(f"{bid}: entries are not 1..n")
        if any(not h["arabic"].strip() for h in hj):
            sys.exit(f"{bid}: empty text")
        inv, missing = align(bid, hj, fz)
        labels, approx = build_labels(bid, hj, fz, inv)
        texts = [h["arabic"] for h in hj]
        # cross-check: how many entries are letter-for-letter the same in both copies
        fz_set = {squash(h["text"]) for h in fz if squash(h["text"])}
        same = sum(1 for t in texts if squash(t) in fz_set)
        joined = sum(1 for k, hs in inv.items() if len(hs) > 1 and "".join(squash(h["text"]) for h in hs) == squash(texts[k]))
        old_migration = None
        if os.path.isdir(os.path.join(dist, bid)) and not os.path.exists(os.path.join(dist, bid, "refs.json")):
            old_migration = migrate(old_texts(dist, bid), hj)
        for f in glob.glob(os.path.join(dist, bid, "[0-9]*.json")):
            os.remove(f)
        os.makedirs(os.path.join(dist, bid), exist_ok=True)
        chunks = (len(texts) + CHUNK - 1) // CHUNK
        for k in range(chunks):
            part = {"book": bid, "from": k * CHUNK + 1, "ahadith": texts[k * CHUNK:(k + 1) * CHUNK]}
            with open(os.path.join(dist, bid, f"{k}.json"), "w", encoding="utf-8") as f:
                json.dump(part, f, ensure_ascii=False, separators=(",", ":"))
        with open(os.path.join(dist, bid, "refs.json"), "w", encoding="utf-8") as f:
            json.dump({"book": bid, "refs": [",".join(l) for l in labels]}, f, ensure_ascii=False, separators=(",", ":"))
        if old_migration:
            with open(os.path.join(dist, bid, "from-alamiyya.json"), "w", encoding="utf-8") as f:
                json.dump({"book": bid, "to": old_migration[0]}, f, separators=(",", ":"))
        entry = {
            "id": bid, "nameAr": ar, "nameEn": en, "count": len(texts), "chunks": chunks,
            "numbering": "sunnah.com", "refs": True,
            "source": {
                "name": "sunnah.com (copy: AhmedBaset/hadith-json v1.2.0)",
                "url": "https://sunnah.com/" + bid,
                "copy": "https://github.com/AhmedBaset/hadith-json",
                "numbersFrom": "https://github.com/fawazahmed0/hadith-api",
            },
            "sourceFile": f"hadith-json/{bid}.json", "sha256": sha256(hj_path),
            "numbersSha256": sha256(fz_path),
            "textSha256": hashlib.sha256("\n".join(texts).encode("utf-8")).hexdigest(),
            "crossCheck": {"sameInBoth": same, "joinedInSunnah": joined, "entries": len(texts),
                           "approxNumbers": approx},
        }
        meta["books"] = [entry if b["id"] == bid else b for b in meta["books"]]
        print(bid, len(texts), "entries,", chunks, "parts; same text in both copies:", same, "+ joined:", joined,
              "; numbers not found:", missing, "; approximate numbers:", approx,
              "; old bookmarks moved:", None if not old_migration else (len(old_migration[0]), "weak", old_migration[1]))
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
