import type { BeadStyle } from "@/lib/tasbih";

/** "#0F5C4A" → [h, s, l] (0..1). */
function hsl(hex: string): [number, number, number] {
  const v = parseInt(hex.slice(1), 16);
  const [r, g, b] = [(v >> 16) & 255, (v >> 8) & 255, v & 255].map((x) => x / 255) as [
    number,
    number,
    number,
  ];
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  const h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
  return [h / 6, s, l];
}

/** The colour with its lightness moved by `d` (as the app's `lift`). */
export function lift(hex: string, d: number): string {
  const [h, s, l] = hsl(hex);
  const nl = Math.min(1, Math.max(0, l + d));
  return `hsl(${Math.round(h * 360)} ${Math.round(s * 100)}% ${Math.round(nl * 100)}%)`;
}

/** The colour mixed with white (`k` = share of the colour). */
const withWhite = (hex: string, k: number): string =>
  `color-mix(in srgb, ${hex} ${Math.round(k * 100)}%, white)`;

/**
 * SVG gradients and textures of the five bead looks of the app's misbaha (glossy, marble, wood, pearl,
 * crystal), in `color`. Beads use `fill="url(#<id>-<style>)"`, then the shine and rim from `BeadOverlay`.
 */
export function BeadDefs({ id, color }: { id: string; color: string }) {
  return (
    <defs>
      <radialGradient id={`${id}-glossy`} cx="0.33" cy="0.28" r="0.6">
        <stop offset="0" stopColor={lift(color, 0.3)} />
        <stop offset="0.55" stopColor={color} />
        <stop offset="1" stopColor={lift(color, -0.2)} />
      </radialGradient>
      <radialGradient id={`${id}-marble`} cx="0.35" cy="0.3" r="0.62">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.5" stopColor={lift(color, 0.42)} />
        <stop offset="1" stopColor={lift(color, 0.25)} />
      </radialGradient>
      <pattern id={`${id}-marble-veins`} patternContentUnits="objectBoundingBox" width="1" height="1">
        <path
          d="M0.05 0.3 Q0.3 0.15 0.5 0.35 T0.95 0.3 M0.1 0.62 Q0.35 0.5 0.55 0.7 T0.98 0.6 M0.2 0.85 Q0.45 0.75 0.7 0.9"
          fill="none"
          stroke={lift(color, -0.1)}
          strokeOpacity="0.4"
          strokeWidth="0.025"
        />
      </pattern>
      <radialGradient id={`${id}-wood`} cx="0.4" cy="0.35" r="0.62">
        <stop offset="0" stopColor={lift(color, 0.12)} />
        <stop offset="0.55" stopColor={color} />
        <stop offset="1" stopColor={lift(color, -0.16)} />
      </radialGradient>
      <pattern id={`${id}-wood-grain`} patternContentUnits="objectBoundingBox" width="1" height="1">
        {[1, 2, 3, 4, 5, 6].map((k) => (
          <ellipse
            key={k}
            cx="0.45"
            cy="1.3"
            rx={0.13 * k}
            ry={0.24 * k}
            fill="none"
            stroke={lift(color, -0.22)}
            strokeOpacity="0.45"
            strokeWidth="0.03"
          />
        ))}
      </pattern>
      <radialGradient id={`${id}-pearl`} cx="0.35" cy="0.3" r="0.6">
        <stop offset="0" stopColor="#ffffff" />
        <stop offset="0.6" stopColor={withWhite(color, 0.18)} />
        <stop offset="1" stopColor={withWhite(color, 0.45)} />
      </radialGradient>
      <linearGradient id={`${id}-pearl-sheen`} x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#ffffff" stopOpacity="0" />
        <stop offset="0.3" stopColor="#ffc0e0" stopOpacity="0.25" />
        <stop offset="0.55" stopColor="#ffffff" stopOpacity="0" />
        <stop offset="0.8" stopColor="#b0e0ff" stopOpacity="0.25" />
        <stop offset="1" stopColor="#ffffff" stopOpacity="0" />
      </linearGradient>
      <radialGradient id={`${id}-crystal`} cx="0.65" cy="0.72" r="0.5">
        <stop offset="0" stopColor={lift(color, 0.35)} stopOpacity="0.95" />
        <stop offset="1" stopColor={color} stopOpacity="0.55" />
      </radialGradient>
      <radialGradient id={`${id}-shine`}>
        <stop offset="0" stopColor="#ffffff" stopOpacity="0.85" />
        <stop offset="1" stopColor="#ffffff" stopOpacity="0" />
      </radialGradient>
      <radialGradient id={`${id}-shine-soft`}>
        <stop offset="0" stopColor="#ffffff" stopOpacity="0.35" />
        <stop offset="1" stopColor="#ffffff" stopOpacity="0" />
      </radialGradient>
    </defs>
  );
}

/** One bead of `look` at (cx, cy), radius r: the body, its texture, the shine and the rim (as the app draws it). */
export function Bead({
  id,
  look,
  cx,
  cy,
  r,
  className,
}: {
  id: string;
  look: BeadStyle;
  cx: number;
  cy: number;
  r: number;
  className?: string;
}) {
  const texture =
    look === "marble"
      ? `${id}-marble-veins`
      : look === "wood"
        ? `${id}-wood-grain`
        : look === "pearl"
          ? `${id}-pearl-sheen`
          : null;
  return (
    <g className={className} data-look={look}>
      <circle cx={cx} cy={cy} r={r} fill={`url(#${id}-${look})`} />
      {texture ? <circle cx={cx} cy={cy} r={r} fill={`url(#${texture})`} /> : null}
      {look === "crystal" ? (
        <circle
          cx={cx}
          cy={cy}
          r={r * 0.96}
          fill="none"
          stroke="#ffffff"
          strokeOpacity="0.45"
          strokeWidth={r * 0.06}
        />
      ) : null}
      <ellipse
        cx={cx - r * 0.34}
        cy={cy - r * 0.42}
        rx={r * 0.31}
        ry={r * 0.18}
        fill={`url(#${id}-${look === "wood" ? "shine-soft" : "shine"})`}
      />
      <circle
        cx={cx}
        cy={cy}
        r={r}
        fill="none"
        stroke="#000000"
        strokeOpacity="0.18"
        strokeWidth={r * 0.06}
      />
    </g>
  );
}
