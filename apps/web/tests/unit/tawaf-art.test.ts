import { TAWAF_ARROW_ANGLES, tawafHeading } from "@/components/TawafArt";

/** Owner, 2026-11-14: tawaf is anti-clockwise with the Kaaba on the left (screen y grows downwards). */
describe("tawaf drawing", () => {
  const dir = (a: number): [number, number] => [Math.cos(tawafHeading(a)), Math.sin(tawafHeading(a))];
  it("near side runs left to right, far side right to left", () => {
    expect(dir(Math.PI / 2)[0]).toBeGreaterThan(0.99);
    expect(dir(Math.PI * 1.5)[0]).toBeLessThan(-0.99);
    expect(dir(0)[1]).toBeLessThan(-0.99);
    expect(dir(Math.PI)[1]).toBeGreaterThan(0.99);
  });
  it("every arrow turns anti-clockwise seen from above", () => {
    for (const a of TAWAF_ARROW_ANGLES) {
      const [px, py] = [Math.cos(a) * 120, Math.sin(a) * 34];
      const [dx, dy] = dir(a);
      expect(px * dy - py * dx).toBeLessThan(0);
    }
  });
});
