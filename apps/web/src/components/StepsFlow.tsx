import { localizeDigits } from "@/lib/digits";
import type { Locale } from "@/lib/i18n";
import {
  FLOW_R,
  FLOW_W,
  connectorPath,
  flowHeight,
  flowPosition,
  shortStepTitle,
  twoLines,
} from "@/lib/steps-flow";

/** Numbered steps 1, 2, 3… joined by dotted arrows; each circle jumps to its step. */
export function StepsFlow({
  locale,
  titles,
  idPrefix,
  label,
  hrefs,
}: {
  locale: Locale;
  titles: readonly string[];
  idPrefix: string;
  label: string;
  /** Where each circle jumps (default: #idPrefix-N). */
  hrefs?: readonly string[];
}) {
  const h = flowHeight(titles.length);
  return (
    <svg
      className="steps-flow"
      viewBox={`0 0 ${FLOW_W} ${h}`}
      role="img"
      aria-label={label}
      data-testid={`steps-flow-${idPrefix}`}
    >
      <defs>
        <marker
          id={`sf-arrow-${idPrefix}`}
          viewBox="0 0 10 10"
          refX="7"
          refY="5"
          markerWidth="7"
          markerHeight="7"
          orient="auto-start-reverse"
        >
          <path d="M0,0 L10,5 L0,10 z" className="sf-arrowhead" />
        </marker>
      </defs>
      {titles.slice(0, -1).map((_, i) => (
        <path
          key={`c${i}`}
          d={connectorPath(i)}
          className="sf-link"
          markerEnd={`url(#sf-arrow-${idPrefix})`}
        />
      ))}
      {titles.map((title, i) => {
        const [x, y] = flowPosition(i);
        const lines = twoLines(shortStepTitle(title));
        return (
          <a
            key={i}
            href={hrefs?.[i] ?? `#${idPrefix}-${i + 1}`}
            data-testid={`steps-flow-${idPrefix}-${i + 1}`}
          >
            <circle cx={x} cy={y} r={FLOW_R} className="sf-circle" />
            <text x={x} y={y + 9} textAnchor="middle" className="sf-num">
              {localizeDigits(i + 1, locale)}
            </text>
            {lines.map((line, k) => (
              <text
                key={k}
                x={x}
                y={y + FLOW_R + 18 + k * 16}
                textAnchor="middle"
                className="sf-title"
                lang="ar"
              >
                {line}
              </text>
            ))}
          </a>
        );
      })}
    </svg>
  );
}
