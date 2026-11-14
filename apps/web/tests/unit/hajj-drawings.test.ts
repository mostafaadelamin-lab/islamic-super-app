import { CORNERS, KAABA, PATH, PLAN_ARROWS, planHeading, startPoint } from "@/lib/tawaf-plan";
import { connectorPath, flowPosition, shortStepTitle, twoLines } from "@/lib/steps-flow";

/** Owner, 2026-11-14: tawaf starts at the Black Stone and goes anti-clockwise (screen y down). */
describe("tawaf plan", () => {
  it("every arrow turns anti-clockwise seen from above", () => {
    for (const a of PLAN_ARROWS) {
      const [px, py] = [Math.cos(a) * PATH.rx, Math.sin(a) * PATH.ry];
      const h = planHeading(a);
      expect(px * Math.sin(h) - py * Math.cos(h)).toBeLessThan(0);
    }
  });
  it("puts the corners in tawaf order: Black Stone, Iraqi, Shami, Yemeni going anti-clockwise", () => {
    const ang = (p: readonly [number, number]): number => Math.atan2(-(p[1] - PATH.cy), p[0] - PATH.cx);
    const order = [CORNERS.blackStone, CORNERS.iraqi, CORNERS.shami, CORNERS.yemeni].map(ang);
    // Anti-clockwise on screen = increasing maths angle (y flipped).
    const rel = order.map((a) => (a - order[0]! + 4 * Math.PI) % (2 * Math.PI));
    expect(rel).toEqual([...rel].sort((x, y) => x - y));
  });
  it("starts on the path, outside the Kaaba, next to the Black Stone", () => {
    const [x, y] = startPoint();
    expect(((x - PATH.cx) / PATH.rx) ** 2 + ((y - PATH.cy) / PATH.ry) ** 2).toBeCloseTo(1, 1);
    expect(x).toBeLessThan(KAABA.left);
    expect(y).toBeGreaterThan(KAABA.top + KAABA.size);
  });
});

describe("steps flow", () => {
  it("snakes right to left, then left to right", () => {
    expect(flowPosition(0)[0]).toBeGreaterThan(flowPosition(1)[0]);
    expect(flowPosition(3)[0]).toBeLessThan(flowPosition(4)[0]);
    expect(flowPosition(3)[0]).toBe(flowPosition(2)[0]);
    expect(connectorPath(2)).toMatch(/^M .* C /);
  });
  it("shortens and wraps titles", () => {
    expect(shortStepTitle("٨ ذو الحجة · يوم التروية")).toBe("يوم التروية");
    expect(twoLines("السعي بين الصفا والمروة")).toHaveLength(2);
    expect(twoLines("الطواف")).toEqual(["الطواف"]);
  });
});
