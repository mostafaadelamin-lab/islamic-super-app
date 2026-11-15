import { render, screen, within } from "@testing-library/react";
import duas from "@/generated/hajj-duas.json";
import hajj from "@/generated/hajj.json";
import { StepSay, placesFor, pictureFor } from "@/components/HajjStepExtras";
import HajjPage from "@/app/[locale]/hajj/page";
import { renderQuranText } from "@/lib/quran-render";
import { readRepoJson } from "../repo";

type Chapter = [string, string[]];
const hisn = readRepoJson<Chapter[]>("content/adhkar/hisn.json");
const quran = readRepoJson<{ surahs: { ayahs: string[] }[] }>("content/quran/dist/quran.v1.json");
const map = readRepoJson<{
  places: Record<string, { hisn: number; say: { hisn?: number; part?: string; quran?: [number, number] }[] }[]>;
}>("content/pilgrimage/step-duas.v1.json");

describe("Hajj and Umrah steps: what is said, verbatim (owner 2026-11-15)", () => {
  it("every text is the Hisn al-Muslim chapter in full, an exact part of it, or the KFGQPC ayah unchanged", () => {
    Object.entries(map.places).forEach(([place, groups]) =>
      groups.forEach((g, gi) => {
        const shown = duas.places[place as keyof typeof duas.places][gi]!;
        expect(shown.title).toBe(hisn[g.hisn - 1]![0]);
        g.say.forEach((x, i) => {
          const text = shown.say[i]!.text;
          if (x.quran) expect(text).toBe(quran.surahs[x.quran[0] - 1]!.ayahs[x.quran[1] - 1]);
          else {
            const full = hisn[x.hisn! - 1]![1].join("\n");
            expect(text).toBe(x.part ?? full);
            expect(full.includes(text)).toBe(true);
          }
        });
        // Nothing shortened: the chapter's whole text is shown at its place.
        expect(shown.say.some((s) => s.text === hisn[g.hisn - 1]![1].join("\n"))).toBe(true);
      }),
    );
  });

  it("puts each place on the right steps", () => {
    expect(placesFor("طواف العمرة")).toEqual(["tawaf"]);
    expect(placesFor("سعي العمرة")).toEqual(["sai"]);
    expect(placesFor("الإحرام بالعمرة من الميقات")).toEqual(["ihram"]);
    expect(placesFor("البقاء على الإحرام")).toEqual([]);
    expect(pictureFor("رمي جمرة العقبة", false)).toEqual({ kind: "jamarat", aqabaOnly: true });
    expect(pictureFor("الوقوف بعرفة", false)).toEqual({ kind: "route", at: "arafah" });
  });

  it("the Yemeni Corner dua and the full ayah are written in the tawaf step", () => {
    render(<StepSay title="طواف العمرة" locale="ar" />);
    const box = screen.getByTestId("step-say");
    expect(within(box).getByText(hisn[118]![1][0]!)).toBeInTheDocument();
    expect(within(box).getByTestId("say-quran").textContent).toContain(renderQuranText(quran.surahs[1]!.ayahs[200]!));
  });

  it("the hub shows the five stages of Hajj by day again, with their points in full", async () => {
    render(await HajjPage({ params: Promise.resolve({ locale: "ar" }) }));
    hajj.hajj.days.forEach((d, i) => {
      const card = document.getElementById(`hajj-stage-${i + 1}`)!;
      expect(card).not.toBeNull();
      expect(within(card).getByText(d.title)).toBeInTheDocument();
      expect(within(card).getAllByRole("listitem")).toHaveLength(d.points.length);
      if (d.dhikr) expect(card.textContent).toContain(d.dhikr);
    });
  });
});
