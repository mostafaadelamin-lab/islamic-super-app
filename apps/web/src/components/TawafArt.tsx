/**
 * Tawaf drawing (same as the app's hajj_art.dart): the walk goes anti-clockwise seen from above,
 * with the Kaaba on the walker's left (owner, 2026-11-14). The oval is the floor seen from the
 * front, so its near (lower) half runs left to right and its far (upper) half right to left.
 */
const CX = 160;
const CY = 74;
const RX = 120;
const RY = 34;
/** Positions of the arrows on the oval (radians, screen coordinates, y down). */
export const TAWAF_ARROW_ANGLES = [0, Math.PI * 0.57, Math.PI * 1.14, Math.PI * 1.71];

/** Screen heading of the arrow at angle `a`: the tangent of decreasing `a` (anti-clockwise from above). */
export function tawafHeading(a: number): number {
  return Math.atan2(-Math.cos(a) * RY, Math.sin(a) * RX);
}

function arrow(a: number): string {
  const x = CX + Math.cos(a) * RX;
  const y = CY + Math.sin(a) * RY;
  const d = tawafHeading(a);
  const len = 13;
  const pt = (ang: number, r: number): string =>
    `${(x + Math.cos(ang) * r).toFixed(1)},${(y + Math.sin(ang) * r).toFixed(1)}`;
  return `${pt(d, 4)} ${pt(d + 2.5, len)} ${pt(d - 2.5, len)}`;
}

export function TawafArt({ label }: { label: string }) {
  const dots = Array.from({ length: 7 }, (_, i) => Math.PI + (i * 2 * Math.PI) / 7);
  return (
    <svg className="tawaf-art" viewBox="0 0 320 130" role="img" aria-label={label} data-testid="tawaf-art">
      <rect x="0" y="0" width="320" height="130" rx="12" className="tawaf-sky" />
      <rect x="0" y="104" width="320" height="26" className="tawaf-ground" />
      <ellipse cx={CX} cy={CY} rx={RX} ry={RY} className="tawaf-path" />
      {dots.map((a, i) => (
        <circle key={i} cx={CX + Math.cos(a) * RX} cy={CY + Math.sin(a) * RY} r="4" className="tawaf-dot" />
      ))}
      <rect x={CX - 23} y={CY - 18} width="46" height="44" rx="2" className="tawaf-kaaba" />
      <rect x={CX - 23} y={CY - 8} width="46" height="6" className="tawaf-band" />
      <rect x={CX + 8} y={CY + 8} width="9" height="18" className="tawaf-band" />
      {TAWAF_ARROW_ANGLES.map((a) => (
        <polygon
          key={a}
          points={arrow(a)}
          className="tawaf-arrow"
          data-heading={tawafHeading(a).toFixed(3)}
        />
      ))}
    </svg>
  );
}
