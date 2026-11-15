import { execFileSync } from "node:child_process";
import { join } from "node:path";
import { render, screen, within } from "@testing-library/react";
import {
  GUIDE,
  PILGRIMAGE_KINDS,
  GuideStepCard,
  officialSegs,
  scenesOfStep,
  type Seg,
} from "@/components/HajjGuide";
import { HajjScene, SCENES, roleColour } from "@/components/HajjScene";
import HajjPage from "@/app/[locale]/hajj/page";
import PilgrimagePage from "@/app/[locale]/hajj/[kind]/page";
import { renderQuranText } from "@/lib/quran-render";
import { REPO, readRepoJson } from "../repo";

const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const ayah = (s: number, a: number): string => quran.surahs[s - 1]!.ayahs[a - 1]!;
const HAJJ_ONLY_PLACES = ["mina", "arafah", "muzdalifah", "jamarat"];

/** Every Quran quotation in the guide, wherever it sits. */
type Q = { s: number; from: number; to: number; part?: string; texts: string[] };
function allQuran(): Q[] {
  const fromSegs = (segs: readonly Seg[]): Q[] => segs.flatMap((x) => (x.t === "quran" ? [x] : []));
  const items = Object.values(GUIDE.subs).flatMap((s) => s.items);
  return [
    ...items.flatMap((it): Q[] => (it.k === "quran" ? [it] : "segs" in it ? fromSegs(it.segs) : [])),
    ...GUIDE.official.umrah.flatMap(fromSegs),
    ...GUIDE.official.hajj.flatMap(fromSegs),
    ...GUIDE.official.types.flatMap((x) => fromSegs(x.segs)),
  ];
}

describe("Hajj and Umrah guide from its sources (owner 2026-11-16)", () => {
  it("the generated guide and pictures are up to date with their source files", () => {
    for (const f of ["build-guide.mjs", "build-scenes.mjs"])
      execFileSync("node", [join(REPO, "content/pilgrimage", f), "--check"], { cwd: REPO, stdio: "pipe" });
  });

  it("every ayah is the KFGQPC text unchanged; a part of an ayah is an exact part of it", () => {
    const qs = allQuran();
    expect(qs.length).toBeGreaterThan(10);
    for (const q of qs) {
      q.texts.forEach((x, i) => expect(x).toBe(ayah(q.s, q.from + i)));
      if (q.part) expect(ayah(q.s, q.from).includes(q.part), `${q.s}:${q.from}`).toBe(true);
    }
  });

  it("Maqam Ibrahim: the hadith quotes part of al-Baqarah 125, then the full ayah follows (owner 2026-11-16)", () => {
    render(<GuideStepCard locale="ar" id="x" label="x" stepId="tawaf-first" />);
    const [inHadith, full] = within(screen.getByTestId("hg-sub-to-maqam")).getAllByTestId("hg-quran");
    const it = GUIDE.subs["to-maqam"]!.items[0]!;
    const seg = "segs" in it ? it.segs.find((x) => x.t === "quran") : undefined;
    const part = seg?.t === "quran" ? seg.part : undefined;
    expect(part).toBeTruthy();
    expect(inHadith!.textContent).toContain(renderQuranText(part!));
    expect(inHadith!.textContent).not.toContain(renderQuranText("وَإِذۡ جَعَلۡنَا"));
    expect(full!.textContent).toContain(renderQuranText(ayah(2, 125)));
  });

  it("the two rak'ahs have al-Fatiha, al-Kafirun and al-Ikhlas written in full", () => {
    const full = (s: number, n: number) => Array.from({ length: n }, (_, i) => ayah(s, i + 1));
    const q = (sub: string) => GUIDE.subs[sub]!.items.flatMap((x) => (x.k === "quran" ? [x.texts] : []));
    expect(q("rakah-1")).toEqual([full(1, 7), full(109, 6)]);
    expect(q("rakah-2")).toEqual([full(1, 7), full(112, 4)]);
  });

  it("Umrah shows no picture of Mina, Arafah, Muzdalifah or the Jamarat (owner's bug report)", () => {
    for (const f of [...GUIDE.flows.umrah.map((x) => x.step), GUIDE.hub.umrahIntro])
      for (const sc of scenesOfStep(f))
        for (const p of SCENES[sc]!.places) expect(HAJJ_ONLY_PLACES, `${f} → ${sc}`).not.toContain(p);
  });

  it("the Umrah page draws only pictures of Umrah places", async () => {
    render(await PilgrimagePage({ params: Promise.resolve({ locale: "ar", kind: "umrah" }) }));
    const figs = document.querySelectorAll("[data-places]");
    expect(figs.length).toBeGreaterThan(3);
    figs.forEach((f) =>
      f
        .getAttribute("data-places")!
        .split(" ")
        .forEach((p) => expect(HAJJ_ONLY_PLACES).not.toContain(p)),
    );
  });

  it("every picture draws with colours of the chosen style", () => {
    for (const [id, s] of Object.entries(SCENES)) {
      for (const x of s.shapes)
        for (const r of ["f" in x ? x.f : null, "s" in x ? x.s : null])
          if (r) expect(() => roleColour(r)).not.toThrow();
      const { unmount } = render(<HajjScene id={id} />);
      expect(screen.getByTestId(`hajj-scene-${id}`)).toBeInTheDocument();
      unmount();
    }
  });

  it("leaves out the sentence on women visiting graves (owner chose to remove it)", () => {
    const all = JSON.stringify(GUIDE);
    expect(all).not.toContain("زوارات");
    expect(all).not.toContain("في حق الرجال خاصة");
    // The rest of the Madinah chapter is still there.
    expect(GUIDE.steps.madinah!.subs.length).toBeGreaterThan(3);
  });

  it("every step of every kind exists and has its official paragraph when one is named", () => {
    for (const k of PILGRIMAGE_KINDS)
      for (const s of GUIDE.flows[k]) {
        expect(GUIDE.steps[s.step], `${k}: ${s.step}`).toBeDefined();
        if (s.dalil) expect(officialSegs(s.dalil, k), `${k}: ${s.dalil}`).not.toBeNull();
        for (const sub of GUIDE.steps[s.step]!.subs) expect(GUIDE.subs[sub], sub).toBeDefined();
      }
    const titles = (k: (typeof PILGRIMAGE_KINDS)[number]) => GUIDE.flows[k].map((s) => s.step);
    for (const k of ["tamattu", "qiran", "ifrad"] as const) {
      const at = (x: string) => titles(k).indexOf(x);
      expect(at("arafah")).toBe(at("tarwiyah-mina") + 1);
      expect(at("muzdalifah")).toBe(at("arafah") + 1);
      expect(at("aqaba")).toBe(at("muzdalifah") + 1);
      expect(titles(k).at(-1)).toBe("farewell");
    }
    expect(titles("tamattu").slice(0, 4)).toEqual(titles("umrah"));
  });

  it("a step shows its picture, the official words, and each part with its reference", () => {
    render(<GuideStepCard locale="ar" id="x" label="x" stepId="sai" dalil="u3" />);
    expect(screen.getByTestId("hajj-scene-sai")).toBeInTheDocument();
    expect(screen.getByTestId("hg-official")).toBeInTheDocument();
    for (const k of GUIDE.steps.sai!.subs) expect(screen.getByTestId(`hg-sub-${k}`)).toBeInTheDocument();
    // The Safa dhikr, in the wording of Sahih Muslim, said three times.
    const say = screen.getAllByTestId("hg-say");
    expect(
      say.some((x) => x.textContent!.includes("أَنْجَزَ وَعْدَهُ") && x.textContent!.includes("٣")),
    ).toBe(true);
    expect(screen.getByTestId("rounds-sai")).toBeInTheDocument();
  });

  it("the hub shows the miqat of each country, the days of Hajj in full, and Madinah", async () => {
    render(await HajjPage({ params: Promise.resolve({ locale: "ar" }) }));
    const table = screen.getByTestId("hg-table");
    expect(within(table).getAllByRole("row")).toHaveLength(6);
    GUIDE.hub.days.forEach((d, i) => {
      const card = document.getElementById(`hajj-stage-${i + 1}`)!;
      expect(card.getAttribute("data-step")).toBe(d);
    });
    expect(document.getElementById("hajj-madinah")).not.toBeNull();
    // The pillars of Hajj, in Ibn Baz's words (owner 2026-11-16: from a reference, not our own text).
    expect(document.getElementById("hajj-pillars")!.textContent).toContain("وأركان الحج أربعة");
    expect(document.body.textContent).toContain("لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ");
    expect(screen.getByTestId("hg-sources")).toBeInTheDocument();
  });
});
