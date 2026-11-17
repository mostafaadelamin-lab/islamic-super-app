/**
 * "Share as image": draws one ayah (text unchanged) on a card in the Rattil colours and hands it to the
 * system share sheet, or downloads it where sharing files is not supported.
 */

export const CARD_WIDTH = 1080;
const PADDING = 96;
const FRAME_INSET = 36;
const FRAME_WIDTH = 4;
const INNER_FRAME_GAP = 12;
const AYAH_FONT_PX = 56;
const LINE_HEIGHT = 1.9;
const REF_FONT_PX = 34;
const BRAND_FONT_PX = 28;
const HEADER_SPACE = 140;
const FOOTER_SPACE = 190;
const MIN_HEIGHT = 1080;
/** Mushaf cream paper; reference and brand line use the chosen colour style (packages/design-tokens). */
const PAPER = "#FBF6EA";
const INK = "#141414";
const FALLBACK_PRIMARY = "#0F6B50";
const GOLD = "#A8773E";
/** The current colour style's deep brand colour (style 1 emerald, style 2 navy). */
export function brandColour(): string {
  if (typeof document === "undefined") return FALLBACK_PRIMARY;
  const v = getComputedStyle(document.documentElement).getPropertyValue("--brand-hero-top").trim();
  return v || FALLBACK_PRIMARY;
}
const QURAN_FONT = "'KFGQPC HAFS Uthmanic Script', serif";
const UI_FONT = "'IBM Plex Sans Arabic', system-ui, sans-serif";

export interface AyahCard {
  /** The ayah exactly as in the Mushaf data. */
  text: string;
  /** Reference line, e.g. "al-Baqarah 2:255". */
  reference: string;
  /** App name in the reader's language. */
  brand: string;
}

/** Splits on runs of whitespace: "a  b" → ["a", "b"]; never splits inside "ٱلۡحَمۡدُ". https://regex101.com/?regex=%5Cs%2B&testString=a%20%20b */
const SPACES_RE = /\s+/;

/** Greedy word wrap: no line wider than `max` unless a single word is. */
export function wrapLines(text: string, max: number, measure: (s: string) => number): string[] {
  const words = text.split(SPACES_RE).filter(Boolean);
  return words.reduce<string[]>((lines, w) => {
    const last = lines[lines.length - 1];
    if (last !== undefined && measure(`${last} ${w}`) <= max) return [...lines.slice(0, -1), `${last} ${w}`];
    return [...lines, w];
  }, []);
}

const SIDES = 2;
const HALF = 0.5;
const CENTER_X = CARD_WIDTH * HALF;
const TEXT_WIDTH = CARD_WIDTH - SIDES * PADDING;

/** Height the card needs for the wrapped ayah. */
export function cardHeight(lines: number): number {
  return Math.ceil(
    Math.max(MIN_HEIGHT, HEADER_SPACE + lines * AYAH_FONT_PX * LINE_HEIGHT + FOOTER_SPACE + PADDING),
  );
}

/** Draws the card on a new canvas sized to the wrapped ayah. */
function drawCard(card: AyahCard): HTMLCanvasElement {
  const canvas = document.createElement("canvas");
  const measureCtx = canvas.getContext("2d");
  if (!measureCtx) throw new Error("no 2d canvas");
  measureCtx.font = `${AYAH_FONT_PX}px ${QURAN_FONT}`;
  const lines = wrapLines(card.text, TEXT_WIDTH, (t) => measureCtx.measureText(t).width);
  const height = cardHeight(lines.length);
  canvas.width = CARD_WIDTH;
  canvas.height = height;
  // Resizing resets the context state, so everything is set again below.
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("no 2d canvas");
  ctx.fillStyle = PAPER;
  ctx.fillRect(0, 0, CARD_WIDTH, height);
  ctx.strokeStyle = GOLD;
  ctx.lineWidth = FRAME_WIDTH;
  ctx.strokeRect(FRAME_INSET, FRAME_INSET, CARD_WIDTH - SIDES * FRAME_INSET, height - SIDES * FRAME_INSET);
  ctx.lineWidth = 1;
  const inner = FRAME_INSET + INNER_FRAME_GAP;
  ctx.strokeRect(inner, inner, CARD_WIDTH - SIDES * inner, height - SIDES * inner);

  ctx.direction = "rtl";
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillStyle = INK;
  ctx.font = `${AYAH_FONT_PX}px ${QURAN_FONT}`;
  const step = AYAH_FONT_PX * LINE_HEIGHT;
  const top = HEADER_SPACE + (height - HEADER_SPACE - FOOTER_SPACE - lines.length * step) * HALF;
  lines.forEach((line, i) => ctx.fillText(line, CENTER_X, top + step * (i + HALF)));

  ctx.fillStyle = brandColour();
  ctx.font = `600 ${REF_FONT_PX}px ${UI_FONT}`;
  ctx.fillText(card.reference, CENTER_X, height - FOOTER_SPACE + REF_FONT_PX);
  ctx.fillStyle = GOLD;
  ctx.font = `${BRAND_FONT_PX}px ${UI_FONT}`;
  ctx.fillText(card.brand, CENTER_X, height - FOOTER_SPACE * HALF + BRAND_FONT_PX);
  return canvas;
}

/** Renders the card to a PNG (after the Quran font has loaded, so the text is not drawn in a fallback). */
export async function renderAyahPng(card: AyahCard): Promise<Blob> {
  if (document.fonts) await document.fonts.load(`${AYAH_FONT_PX}px "KFGQPC HAFS Uthmanic Script"`);
  const canvas = drawCard(card);
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("toBlob failed"))), "image/png"),
  );
}

export type ShareOutcome = "shared" | "downloaded" | "cancelled";

/** Opens the share sheet with the image (and the text), or downloads the PNG where that is unsupported. */
export async function shareAyahImage(card: AyahCard, fileName: string): Promise<ShareOutcome> {
  const blob = await renderAyahPng(card);
  const file = new File([blob], fileName, { type: "image/png" });
  const data: ShareData = { files: [file], text: `${card.text} — ${card.reference}` };
  if (typeof navigator.canShare === "function" && navigator.canShare(data)) {
    try {
      await navigator.share(data);
      return "shared";
    } catch (e) {
      if (e instanceof DOMException && e.name === "AbortError") return "cancelled";
      throw e;
    }
  }
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
  return "downloaded";
}
