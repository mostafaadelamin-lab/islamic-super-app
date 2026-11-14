/**
 * Tawaf seen from above (owner, 2026-11-14): our own drawing, laid out like a map turned so the
 * Kaaba's door wall faces the reader. Geography (rotation only, never mirrored, so the walk stays
 * anti-clockwise): Black Stone = east corner (near left), Iraqi = north (near right),
 * Shami = west (far right), Yemeni = south (far left), Hijr Ismail on the north-west wall
 * (right), Maqam Ibrahim in front of the door. Same numbers as apps/mobile/lib/ui/tawaf_plan.dart.
 */
export const PLAN_W = 360;
export const PLAN_H = 300;
export const KAABA = { left: 130, top: 100, size: 90 };
export const PATH = { cx: 185, cy: 145, rx: 140, ry: 108 };
/** Kaaba corners [x, y] on the drawing. */
export const CORNERS = {
  blackStone: [130, 190],
  iraqi: [220, 190],
  shami: [220, 100],
  yemeni: [130, 100],
} as const;

/** Where the start line from the Black Stone (outwards, away from the Kaaba) meets the path. */
export function startPoint(): [number, number] {
  const [x0, y0] = CORNERS.blackStone;
  const d = Math.SQRT1_2;
  let t = 0;
  for (; t < 400; t += 0.5) {
    const x = x0 - d * t;
    const y = y0 + d * t;
    if (((x - PATH.cx) / PATH.rx) ** 2 + ((y - PATH.cy) / PATH.ry) ** 2 >= 1) break;
  }
  return [x0 - d * t, y0 + d * t];
}

/** Arrow positions on the path (radians, screen y down) and their anti-clockwise heading. */
export const PLAN_ARROWS = [
  Math.PI * 0.3,
  Math.PI * 0.55,
  Math.PI,
  Math.PI * 1.25,
  Math.PI * 1.5,
  Math.PI * 1.7,
  Math.PI * 1.9,
];
export function planHeading(a: number): number {
  return Math.atan2(-Math.cos(a) * PATH.ry, Math.sin(a) * PATH.rx);
}
