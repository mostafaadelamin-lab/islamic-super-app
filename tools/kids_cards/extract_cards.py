"""Extract the adhkar card texts from «بطاقات الأذكار للناشئة» (saaid 19621 boys / 19622 girls).

Usage: pdftotext -bbox-layout -f 4 -l 9 <book.pdf> cards.html; python3 -I extract_cards.py cards.html > cards.json
The PDF draws Arabic visually: each word's characters come reversed, and some harakat are separate
"words" sitting over their letter. We put every word back in reading order, hang each loose mark
after the letter it sits on (by x position), and join pieces that touch (gap < 3 pt).
"""
import html, json, re, sys, unicodedata

W = re.compile(r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">(.*?)</word>')
ismark = lambda s: bool(s) and all(unicodedata.category(c) == "Mn" for c in s)


def line_text(words):
    words = sorted(words, key=lambda q: -q[2])  # right to left
    base = [w for w in words if not ismark(w[4])]
    marks = [w for w in words if ismark(w[4])]
    toks = [[w[0], w[2], list(w[4][::-1])] for w in base]  # logical order within word
    for m in marks:
        cx = (m[0] + m[2]) / 2
        host = min(toks, key=lambda t: 0 if t[0] - 0.5 <= cx <= t[1] + 0.5 else min(abs(cx - t[0]), abs(cx - t[1])))
        chars = [i for i, c in enumerate(host[2]) if not ismark(c)]
        frac = (host[1] - cx) / max(host[1] - host[0], 0.01)
        k = chars[min(len(chars) - 1, max(0, int(frac * len(chars))))]
        j = k + 1
        while j < len(host[2]) and ismark(host[2][j]):
            j += 1
        host[2][j:j] = list(m[4][::-1])
    out, prev = "", None
    for t in toks:
        s = "".join(t[2]).replace("\u200c", " ").replace("\uf072", "\ufdfa")  # ZWNJ used as a space; the font's PUA glyph for ﷺ
        s = re.sub(r"[0-9]+", lambda x: x.group(0)[::-1], s)
        if prev is not None and prev[0] - t[1] < 1.8:
            out += s
        else:
            out += (" " if out else "") + s
        prev = t
    out = unicodedata.normalize("NFC", out)
    return re.sub(r"([\u064B-\u0652])\1+", r"\1", out)  # a mark drawn twice


def page_lines(p):
    ws = [(float(a), float(b), float(c), float(d), html.unescape(e)) for a, b, c, d, e in W.findall(p)]
    ws = [w for w in ws if w[0] > 150 and w[1] < 485]  # skip the side banner and the cheer badge at the bottom
    lines = []
    for w in sorted(ws, key=lambda w: (w[1] + w[3]) / 2):
        cy = (w[1] + w[3]) / 2
        for L in lines:
            if abs(L[0] - cy) < 6:
                L[1].append(w)
                break
        else:
            lines.append([cy, [w]])
    return [line_text(L) for _, L in sorted(lines)]


def main(path):
    t = open(path, encoding="utf-8").read()
    items, cur = [], None
    for card, p in enumerate(t.split("<page")[1:], start=1):
        for ln in page_lines(p):
            m = re.match(r"^\s*(\d+)\s*\.\s*(.*)$", ln)
            if m:
                cur = {"n": len(items) + 1, "card": card, "printed": m.group(1), "raw": m.group(2)}
                items.append(cur)
            elif cur and cur["card"] == card:
                cur["raw"] += " " + ln
    for it in items:
        raw = re.sub(r"\s+", " ", it["raw"]).strip()
        # the count note in brackets at the end, e.g. «(مرة واحدة في الصباح ، و مرة واحدة في المساء)»
        m = re.search(r"[()][^()]*(?:مرة|مرات|مائة)[^()]*[()]?.*$", raw)
        it["note"] = re.sub(r"[()].*$", "", raw[m.start() + 1 :]).strip(" .") if m else ""
        it["text"] = (raw[: m.start()] if m else raw).strip(" .«»\"")
        del it["raw"]
    json.dump(items, sys.stdout, ensure_ascii=False, indent=1)


main(sys.argv[1])
