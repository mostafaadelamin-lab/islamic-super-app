import { describe, expect, it } from "vitest";
import dalil from "@/generated/dalil-hajj.json";
import hajj from "@/generated/hajj.json";
import { HAJJ_FLOWS, HAJJ_TYPES } from "@/lib/hajj-flows";

const anchors = new Set([
  "#dalil-types",
  ...dalil.umrah.map((_, i) => `#dalil-u${i + 1}`),
  ...dalil.hajj.map((_, i) => `#dalil-h${i + 1}`),
  ...hajj.hajj.days.map((_, i) => `#hajj-stage-${i + 1}`),
]);

describe("Hajj steps per type", () => {
  it("every step links to an explanation on the page", () => {
    for (const k of HAJJ_TYPES)
      for (const s of HAJJ_FLOWS[k]) expect(anchors, `${k}: ${s.title}`).toContain(s.href);
  });

  it("goes Mina, Arafah, then Muzdalifah, then the Jamrat al-Aqaba in every type", () => {
    for (const k of HAJJ_TYPES) {
      const titles = HAJJ_FLOWS[k].map((s) => s.title);
      const at = (x: string): number => titles.indexOf(x);
      expect(at("منى يوم التروية")).toBeGreaterThan(0);
      expect(at("الوقوف بعرفة")).toBe(at("منى يوم التروية") + 1);
      expect(at("المبيت بمزدلفة")).toBe(at("الوقوف بعرفة") + 1);
      expect(at("رمي جمرة العقبة")).toBe(at("المبيت بمزدلفة") + 1);
      expect(titles.at(-1)).toBe("طواف الوداع");
    }
  });

  it("tamattu' starts with a full Umrah; qiran and ifrad start with tawaf al-qudum", () => {
    expect(HAJJ_FLOWS.tamattu.slice(0, 4).map((s) => s.href)).toEqual([
      "#dalil-u1",
      "#dalil-u2",
      "#dalil-u3",
      "#dalil-u4",
    ]);
    expect(HAJJ_FLOWS.qiran[1]!.title).toBe("طواف القدوم");
    expect(HAJJ_FLOWS.ifrad[1]!.title).toBe("طواف القدوم");
  });

  it("only tamattu' and qiran have the sacrifice (hady)", () => {
    const has = (k: (typeof HAJJ_TYPES)[number]): boolean =>
      HAJJ_FLOWS[k].some((s) => s.title === "ذبح الهدي");
    expect([has("tamattu"), has("qiran"), has("ifrad")]).toEqual([true, true, false]);
  });

  it("keeps the official guide's paragraphs with their source", () => {
    expect(dalil.source.url).toMatch(/^https:\/\//);
    expect(dalil.hajj[3]).toContain("مزدلفة");
    expect(dalil.types.map((x) => x.name)).toEqual(["التمتع", "القِرَان", "الإفراد"]);
  });
});
