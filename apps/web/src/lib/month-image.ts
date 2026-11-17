/**
 * The monthly prayer timetable as a picture (as the app shares it): title, place, one row per day with the
 * six times, today's row marked, the app's name at the bottom. Shared through the share sheet, or downloaded
 * where sharing files is not supported.
 */
import { brandColour, type ShareOutcome } from "./ayah-image";

export interface MonthImage {
  title: string;
  place: string;
  /** Column headings: day, the other calendar, then the prayers. */
  head: string[];
  rows: { cells: string[]; today: boolean }[];
  brand: string;
  rtl: boolean;
}

const WIDTH = 1080;
const PAD = 48;
const TITLE_PX = 44;
const PLACE_PX = 28;
const HEAD_PX = 24;
const CELL_PX = 24;
const ROW_H = 46;
const HEAD_H = 58;
const TOP = 170;
const FOOT = 110;
const PAPER = "#FBF6EA";
const INK = "#141414";
const GOLD = "#A8773E";
const STRIPE = "#F3EBD8";
const UI_FONT = "'IBM Plex Sans Arabic', system-ui, sans-serif";
/** The first two columns (day, other calendar) are narrower/wider than the six time columns. */
const COL_WEIGHTS = [0.7, 1.5, 1, 1, 1, 1, 1, 1];

export function monthImageHeight(rows: number): number {
  return TOP + HEAD_H + rows * ROW_H + FOOT;
}

function draw(m: MonthImage): HTMLCanvasElement {
  const canvas = document.createElement("canvas");
  const h = monthImageHeight(m.rows.length);
  canvas.width = WIDTH;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("no 2d canvas");
  const brand = brandColour();
  ctx.fillStyle = PAPER;
  ctx.fillRect(0, 0, WIDTH, h);
  ctx.strokeStyle = GOLD;
  ctx.lineWidth = 4;
  ctx.strokeRect(20, 20, WIDTH - 40, h - 40);

  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.direction = m.rtl ? "rtl" : "ltr";
  ctx.fillStyle = brand;
  ctx.font = `700 ${TITLE_PX}px ${UI_FONT}`;
  ctx.fillText(m.title, WIDTH / 2, 80);
  ctx.fillStyle = INK;
  ctx.font = `${PLACE_PX}px ${UI_FONT}`;
  ctx.fillText(m.place, WIDTH / 2, 132);

  // Column x-ranges, right to left in Arabic.
  const inner = WIDTH - 2 * PAD;
  const weights = COL_WEIGHTS.slice(0, m.head.length);
  const sum = weights.reduce((a, b) => a + b, 0);
  let x = m.rtl ? WIDTH - PAD : PAD;
  const centers = weights.map((w) => {
    const width = (inner * w) / sum;
    const c = m.rtl ? x - width / 2 : x + width / 2;
    x = m.rtl ? x - width : x + width;
    return c;
  });

  ctx.fillStyle = brand;
  ctx.fillRect(PAD, TOP, inner, HEAD_H);
  ctx.fillStyle = "#FFFFFF";
  ctx.font = `700 ${HEAD_PX}px ${UI_FONT}`;
  m.head.forEach((cell, i) => ctx.fillText(cell, centers[i]!, TOP + HEAD_H / 2));

  m.rows.forEach((row, r) => {
    const y = TOP + HEAD_H + r * ROW_H;
    if (row.today) {
      ctx.fillStyle = "#EBD9B5";
      ctx.fillRect(PAD, y, inner, ROW_H);
    } else if (r % 2 === 1) {
      ctx.fillStyle = STRIPE;
      ctx.fillRect(PAD, y, inner, ROW_H);
    }
    ctx.fillStyle = INK;
    ctx.font = `${row.today ? "700 " : ""}${CELL_PX}px ${UI_FONT}`;
    row.cells.forEach((cell, i) => ctx.fillText(cell, centers[i]!, y + ROW_H / 2));
  });
  ctx.strokeStyle = GOLD;
  ctx.lineWidth = 1;
  ctx.strokeRect(PAD, TOP, inner, HEAD_H + m.rows.length * ROW_H);

  ctx.fillStyle = GOLD;
  ctx.font = `600 ${PLACE_PX}px ${UI_FONT}`;
  ctx.fillText(m.brand, WIDTH / 2, h - FOOT / 2);
  return canvas;
}

export async function renderMonthPng(m: MonthImage): Promise<Blob> {
  if (document.fonts) await document.fonts.ready;
  const canvas = draw(m);
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("toBlob failed"))), "image/png"),
  );
}

/** Opens the share sheet with the picture, or downloads the PNG where sharing files is not supported. */
export async function shareMonthImage(m: MonthImage, fileName: string): Promise<ShareOutcome> {
  const blob = await renderMonthPng(m);
  const file = new File([blob], fileName, { type: "image/png" });
  const data: ShareData = { files: [file], title: m.title };
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
