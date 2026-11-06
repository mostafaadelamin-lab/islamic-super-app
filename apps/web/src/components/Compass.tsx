/** Static compass rose (north up) with a needle at `bearing` degrees clockwise from north. */
export function Compass({ bearing, label }: { bearing: number; label: string }) {
  const ticks = Array.from({ length: 36 }, (_, i) => i * 10);
  return (
    <svg className="compass" viewBox="0 0 200 200" role="img" aria-label={label} data-testid="compass">
      <circle
        cx="100"
        cy="100"
        r="92"
        fill="var(--color-surface-2)"
        stroke="var(--color-line)"
        strokeWidth="3"
      />
      {ticks.map((d) => (
        <line
          key={d}
          x1="100"
          y1="12"
          x2="100"
          y2={d % 90 === 0 ? 26 : 19}
          stroke="var(--color-muted)"
          strokeWidth={d % 90 === 0 ? 3 : 1}
          transform={`rotate(${d} 100 100)`}
        />
      ))}
      <text x="100" y="42" textAnchor="middle" fontSize="16" fontWeight="600" fill="var(--color-danger)">
        N
      </text>
      <text x="164" y="106" textAnchor="middle" fontSize="13" fill="var(--color-muted)">
        E
      </text>
      <text x="100" y="172" textAnchor="middle" fontSize="13" fill="var(--color-muted)">
        S
      </text>
      <text x="36" y="106" textAnchor="middle" fontSize="13" fill="var(--color-muted)">
        W
      </text>
      <g transform={`rotate(${bearing.toFixed(2)} 100 100)`} data-testid="qibla-needle">
        <polygon points="100,30 110,100 100,92 90,100" fill="var(--color-accent)" />
        <polygon points="100,170 108,100 100,108 92,100" fill="var(--color-muted)" opacity="0.5" />
        <rect x="93" y="22" width="14" height="12" rx="2" fill="var(--color-ink)" />
      </g>
      <circle cx="100" cy="100" r="6" fill="var(--color-ink)" />
    </svg>
  );
}
