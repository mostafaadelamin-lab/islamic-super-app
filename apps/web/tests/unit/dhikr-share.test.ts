import { reportBody, reportFormHref, shareBody, adhkarViewStore } from "@/lib/dhikr-share";
import { HISN, HISN_SECTIONS } from "@/lib/hisn";

const LONG = 200;
const QUOTE = 80;

describe("Hisn sections", () => {
  it("place every chapter in exactly one section and add no text", () => {
    const ids = HISN_SECTIONS.flatMap((s) => s.chapters);
    expect(new Set(ids).size).toBe(ids.length);
    // chapter 1 is the author's introduction, reachable from the full list only
    expect([...ids].sort((a, b) => a - b)).toEqual(HISN.slice(1).map((c) => c.id));
    expect(HISN_SECTIONS.every((s) => Object.keys(s).sort().join() === "chapters,id")).toBe(true);
  });
});

describe("sharing and reporting a dhikr", () => {
  it("shares the text unchanged with its source", () => {
    expect(shareBody("سُبْحَانَ اللَّهِ", "Hisn al-Muslim")).toBe("سُبْحَانَ اللَّهِ\n\n— Hisn al-Muslim");
  });

  it("quotes at most 80 characters in a report and links to the contact form with it filled in", () => {
    const text = "ا".repeat(LONG);
    const body = reportBody("Chapter 3 · 1", text, "Intro");
    expect(body).toContain(`«${"ا".repeat(QUOTE)}…»`);
    expect(body.startsWith("Intro\n\nChapter 3 · 1\n")).toBe(true);
    const url = reportFormHref("/ar/help/", "Subject & more", body);
    expect(url.startsWith("/ar/help/?title=Subject%20%26%20more&message=")).toBe(true);
    expect(url.endsWith("#contact")).toBe(true);
    const q = new URLSearchParams(url.slice(url.indexOf("?"), url.indexOf("#")));
    expect(q.get("message")).toBe(body);
  });

  it("remembers list or cards, defaulting to list", () => {
    localStorage.setItem("rattil.adhkarView", JSON.stringify({ mode: "weird" }));
    adhkarViewStore.reload();
    expect(adhkarViewStore.get().mode).toBe("list");
    adhkarViewStore.set(() => ({ mode: "cards" }));
    expect(JSON.parse(localStorage.getItem("rattil.adhkarView")!)).toEqual({ mode: "cards" });
  });
});
