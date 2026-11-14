/**
 * Numbered steps graphic of the Hajj/Umrah guide (owner, 2026-11-14): circles 1, 2, 3… in rows of
 * three, read right to left on the first row then back (a snake), joined by dotted arrows.
 * Same layout as apps/mobile/lib/ui/steps_flow.dart.
 */
export const FLOW_W = 360;
export const FLOW_ROW_H = 140;
export const FLOW_R = 30;
const COLS_RTL = [300, 180, 60];

export function flowPosition(i: number): [number, number] {
  const row = Math.floor(i / 3);
  const col = i % 3;
  const x = row % 2 === 0 ? COLS_RTL[col]! : COLS_RTL[2 - col]!;
  return [x, 50 + row * FLOW_ROW_H];
}

export function flowHeight(n: number): number {
  return Math.ceil(n / 3) * FLOW_ROW_H - 20;
}

/** The short name of a step: "٨ ذو الحجة · يوم التروية" -> "يوم التروية". */
export function shortStepTitle(title: string): string {
  const parts = title.split("·");
  return (parts[parts.length - 1] ?? title).trim();
}

/** Splits a title into at most two lines of similar length. */
export function twoLines(title: string): string[] {
  const words = title.split(/\s+/).filter(Boolean);
  if (title.length <= 12 || words.length < 2) return [title];
  let best = 1;
  let bestDiff = Infinity;
  for (let k = 1; k < words.length; k++) {
    const diff = Math.abs(words.slice(0, k).join(" ").length - words.slice(k).join(" ").length);
    if (diff < bestDiff) {
      bestDiff = diff;
      best = k;
    }
  }
  return [words.slice(0, best).join(" "), words.slice(best).join(" ")];
}

/** SVG path of the dotted connector from step i to step i+1. */
export function connectorPath(i: number): string {
  const [x1, y1] = flowPosition(i);
  const [x2, y2] = flowPosition(i + 1);
  const r = FLOW_R + 6;
  if (y1 === y2) {
    const dir = Math.sign(x2 - x1);
    const ax = x1 + dir * r;
    const bx = x2 - dir * r;
    return `M ${ax} ${y1} Q ${(ax + bx) / 2} ${y1 - 26} ${bx} ${y2}`;
  }
  // Row change at the end of a row: around the outside edge.
  const side = x1 < FLOW_W / 2 ? -1 : 1;
  const ax = x1 + side * r;
  const edge = x1 + side * (FLOW_R + 28);
  return `M ${ax} ${y1} C ${edge} ${y1 + 30} ${edge} ${y2 - 30} ${x2 + side * r} ${y2}`;
}
