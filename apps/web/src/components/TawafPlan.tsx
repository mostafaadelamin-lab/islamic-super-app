import { CORNERS, KAABA, PATH, PLAN_ARROWS, PLAN_H, PLAN_W, planHeading, startPoint } from "@/lib/tawaf-plan";

export interface TawafPlanLabels {
  title: string;
  kaaba: string;
  blackStone: string;
  yemeni: string;
  shami: string;
  iraqi: string;
  door: string;
  hijr: string;
  maqam: string;
  start: string;
  direction: string;
}

function arrow(a: number): string {
  const x = PATH.cx + Math.cos(a) * PATH.rx;
  const y = PATH.cy + Math.sin(a) * PATH.ry;
  const d = planHeading(a);
  const pt = (ang: number, r: number): string =>
    `${(x + Math.cos(ang) * r).toFixed(1)},${(y + Math.sin(ang) * r).toFixed(1)}`;
  return `${pt(d, 6)} ${pt(d + 2.5, 12)} ${pt(d - 2.5, 12)}`;
}

/** Tawaf map from above: corners, door, Hijr, Maqam, start at the Black Stone, anti-clockwise path. */
export function TawafPlan({ l }: { l: TawafPlanLabels }) {
  const { left, top, size } = KAABA;
  const [sx, sy] = startPoint();
  const [bx, by] = CORNERS.blackStone;
  const right = left + size;
  const bottom = top + size;
  return (
    <svg
      className="tawaf-plan"
      viewBox={`0 0 ${PLAN_W} ${PLAN_H}`}
      role="img"
      aria-label={l.title}
      data-testid="tawaf-plan"
    >
      <rect width={PLAN_W} height={PLAN_H} rx="14" className="tp-bg" />
      <ellipse cx={PATH.cx} cy={PATH.cy} rx={PATH.rx} ry={PATH.ry} className="tp-path" />
      {PLAN_ARROWS.map((a) => (
        <polygon key={a} points={arrow(a)} className="tp-arrow" data-heading={planHeading(a).toFixed(3)} />
      ))}
      {/* Hijr Ismail: the low semicircular wall beside the north-west wall. */}
      <path d={`M ${right} ${top + 14} A 40 40 0 0 1 ${right} ${bottom - 14}`} className="tp-hijr" />
      <text x={right + 38} y={top + size / 2 + 4} textAnchor="start" className="tp-label">
        {l.hijr}
      </text>
      {/* Kaaba */}
      <rect x={left} y={top} width={size} height={size} rx="3" className="tp-kaaba" />
      <rect x={left + 5} y={top + 5} width={size - 10} height={size - 10} rx="2" className="tp-band" />
      <text x={left + size / 2} y={top + size / 2 - 2} textAnchor="middle" className="tp-kaaba-label">
        {l.kaaba}
      </text>
      {/* Door on the near wall, close to the Black Stone. */}
      <rect x={left + 26} y={bottom - 7} width="20" height="7" className="tp-door" />
      <text x={left + 36} y={bottom - 12} textAnchor="middle" className="tp-kaaba-small">
        {l.door}
      </text>
      {/* Maqam Ibrahim in front of the door. */}
      <rect x={left + 52} y={bottom + 18} width="12" height="12" rx="3" className="tp-maqam" />
      <text x={left + 58} y={bottom + 44} textAnchor="middle" className="tp-label">
        {l.maqam}
      </text>
      {/* Corners */}
      <text x={CORNERS.yemeni[0] - 6} y={CORNERS.yemeni[1] - 8} textAnchor="end" className="tp-label">
        {l.yemeni}
      </text>
      <text x={CORNERS.shami[0] + 6} y={CORNERS.shami[1] - 8} textAnchor="start" className="tp-label">
        {l.shami}
      </text>
      <text x={CORNERS.iraqi[0] + 8} y={CORNERS.iraqi[1] + 14} textAnchor="start" className="tp-label">
        {l.iraqi}
      </text>
      {Object.values(CORNERS).map(([x, y]) => (
        <circle key={`${x}-${y}`} cx={x} cy={y} r="4" className="tp-corner" />
      ))}
      {/* Black Stone and the start of tawaf */}
      <line x1={bx} y1={by} x2={sx} y2={sy} className="tp-start-line" />
      <ellipse cx={bx} cy={by} rx="6" ry="7" className="tp-stone-frame" />
      <ellipse cx={bx} cy={by} rx="4" ry="5" className="tp-stone" data-testid="tawaf-black-stone" />
      <text x={bx - 10} y={by - 6} textAnchor="end" className="tp-label tp-strong">
        {l.blackStone}
      </text>
      <circle cx={sx} cy={sy} r="11" className="tp-start" data-testid="tawaf-start" />
      <text x={sx} y={sy + 4} textAnchor="middle" className="tp-start-num">
        ١
      </text>
      <text x={sx} y={sy + 30} textAnchor="middle" className="tp-label tp-strong">
        {l.start}
      </text>
      <text x={PATH.cx} y={PATH.cy - PATH.ry - 8} textAnchor="middle" className="tp-label tp-muted">
        {l.direction}
      </text>
    </svg>
  );
}
