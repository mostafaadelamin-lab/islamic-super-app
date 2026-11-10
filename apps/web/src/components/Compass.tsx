/**
 * Emerald-and-gold compass with the qibla at `bearing` degrees clockwise from north (same design as the
 * mobile app). Without `heading` the dial is static (north up); with a live device heading the whole dial
 * turns so that N points to real north, and the gold triangle on top marks where the device points.
 */
const GOLD = "#d4af5a";
const TICKS = Array.from({ length: 72 }, (_, i) => i * 5);
/** Eight-pointed star: two squares, the second turned 45°. */
const STAR = [0, 45].map((base) =>
  [0, 90, 180, 270]
    .map((d) => {
      const a = ((base + d) * Math.PI) / 180;
      return `${(100 + 26 * Math.sin(a)).toFixed(2)},${(100 - 26 * Math.cos(a)).toFixed(2)}`;
    })
    .join(" "),
);

export function Compass({
  bearing,
  label,
  heading = null,
  cardinals = ["N", "E", "S", "W"],
}: {
  bearing: number;
  label: string;
  heading?: number | null;
  /** N, E, S, W in the page language. */
  cardinals?: readonly [string, string, string, string];
}) {
  const [n, e, s, w] = cardinals;
  return (
    <svg className="compass" viewBox="0 0 200 200" role="img" aria-label={label} data-testid="compass">
      <defs>
        <radialGradient id="compass-face">
          <stop offset="0" stopColor="#17735e" />
          <stop offset="0.7" stopColor="#0b4538" />
          <stop offset="1" stopColor="#062a22" />
        </radialGradient>
        <linearGradient id="compass-ray" x1="0" y1="1" x2="0" y2="0">
          <stop offset="0" stopColor={GOLD} stopOpacity="0.15" />
          <stop offset="1" stopColor={GOLD} />
        </linearGradient>
      </defs>
      <circle className="compass-glow" cx="100" cy="100" r="90" fill="none" stroke={GOLD} strokeWidth="6" />
      <g
        transform={heading === null ? undefined : `rotate(${(-heading).toFixed(2)} 100 100)`}
        data-testid="compass-dial"
      >
        <circle cx="100" cy="100" r="88" fill="url(#compass-face)" stroke={GOLD} strokeWidth="2" />
        <circle cx="100" cy="100" r="66" fill="none" stroke={GOLD} strokeOpacity="0.35" strokeWidth="0.8" />
        {TICKS.map((d) => {
          const major = d % 30 === 0;
          return (
            <line
              key={d}
              x1="100"
              y1="15"
              x2="100"
              y2={d % 90 === 0 ? 27 : major ? 24 : 19}
              stroke={major ? GOLD : "#ffffff"}
              strokeOpacity={major ? 0.95 : 0.4}
              strokeWidth={major ? 1.8 : 0.8}
              strokeLinecap="round"
              transform={`rotate(${d} 100 100)`}
            />
          );
        })}
        <text x="100" y="45" textAnchor="middle" fontSize="15" fontWeight="700" fill={GOLD}>
          {n}
        </text>
        <text
          x="157"
          y="105"
          textAnchor="middle"
          fontSize="12"
          fontWeight="700"
          fill="#ffffff"
          fillOpacity="0.85"
        >
          {e}
        </text>
        <text
          x="100"
          y="164"
          textAnchor="middle"
          fontSize="12"
          fontWeight="700"
          fill="#ffffff"
          fillOpacity="0.85"
        >
          {s}
        </text>
        <text
          x="43"
          y="105"
          textAnchor="middle"
          fontSize="12"
          fontWeight="700"
          fill="#ffffff"
          fillOpacity="0.85"
        >
          {w}
        </text>
        {STAR.map((points) => (
          <polygon
            key={points}
            points={points}
            fill="none"
            stroke={GOLD}
            strokeOpacity="0.4"
            strokeWidth="0.9"
          />
        ))}
        <g transform={`rotate(${bearing.toFixed(2)} 100 100)`} data-testid="qibla-needle">
          <line
            x1="100"
            y1="100"
            x2="100"
            y2="34"
            stroke="url(#compass-ray)"
            strokeWidth="3"
            strokeLinecap="round"
          />
          {/* The Kaaba mark on the ring. */}
          <rect
            x="92"
            y="13"
            width="16"
            height="16"
            rx="2.5"
            fill="#151515"
            stroke={GOLD}
            strokeWidth="1.2"
          />
          <rect x="92.6" y="17" width="14.8" height="3" fill={GOLD} />
        </g>
      </g>
      <circle cx="100" cy="100" r="6" fill={GOLD} />
      <circle cx="100" cy="100" r="2.6" fill="#073027" />
      {heading !== null ? <polygon points="100,9 94,0 106,0" fill={GOLD} /> : null}
    </svg>
  );
}
