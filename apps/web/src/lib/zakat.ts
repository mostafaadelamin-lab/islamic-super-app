/**
 * Zakat on money, following the published fatwas of Dar al-Ifta al-Misriyya
 * (content/zakat/dar-alifta.v1.json, held for a shar'i review). The rules (85 g of 21-karat gold, 2.5%,
 * a full lunar year) and every quote shown come from that file; this module only does the arithmetic.
 */
import data from "@/generated/zakat.json";
import { createStore } from "./store";

export interface ZakatSource {
  id: string;
  number: number;
  date: string;
  url: string;
  titleAr: string;
  quotes: string[];
}
export interface ZakatField {
  id: string;
  karat?: number;
  subtract?: boolean;
  sources: string[];
}

export const ZAKAT = data as {
  reviewStatus: string;
  reference: { nameAr: string; nameEn: string; url: string };
  rules: { nisabGoldGrams: number; nisabKarat: number; rate: number; year: string };
  sources: ZakatSource[];
  fields: ZakatField[];
};

export const zakatSource = (id: string): ZakatSource | undefined => ZAKAT.sources.find((s) => s.id === id);

/** Amounts typed by the user, in their currency (gold fields in grams); missing means 0. */
export type ZakatInput = Readonly<Record<string, number>>;

export type ZakatResult =
  | { status: "needPrice" }
  | { status: "belowNisab"; net: number; nisab: number }
  | { status: "yearNotPassed"; net: number; nisab: number }
  | { status: "due"; net: number; nisab: number; zakat: number };

const amount = (v: number | undefined): number =>
  typeof v === "number" && Number.isFinite(v) && v > 0 ? v : 0;

/** Money value of one field: gold grams are turned into 21-karat grams by purity and priced. */
function fieldValue(f: ZakatField, input: ZakatInput, gramPrice: number): number {
  const v = amount(input[f.id]);
  if (f.karat === undefined) return v;
  return (v * f.karat * gramPrice) / ZAKAT.rules.nisabKarat;
}

/**
 * `gramPrice`: today's price of one gram of 21-karat gold. `yearPassed`: a full lunar year has passed
 * since the wealth reached the nisab.
 */
export function computeZakat(input: ZakatInput, gramPrice: number, yearPassed: boolean): ZakatResult {
  const price = amount(gramPrice);
  if (price === 0) return { status: "needPrice" };
  const net = ZAKAT.fields.reduce((sum, f) => {
    const v = fieldValue(f, input, price);
    return f.subtract ? sum - v : sum + v;
  }, 0);
  const nisab = ZAKAT.rules.nisabGoldGrams * price;
  if (net < nisab) return { status: "belowNisab", net, nisab };
  if (!yearPassed) return { status: "yearNotPassed", net, nisab };
  return { status: "due", net, nisab, zakat: net * ZAKAT.rules.rate };
}

export interface ZakatState {
  price: number;
  yearPassed: boolean;
  values: Record<string, number>;
}
export const DEFAULT_ZAKAT: ZakatState = { price: 0, yearPassed: false, values: {} };

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null;

/** Keeps only known fields with non-negative finite numbers. */
export function sanitizeZakat(raw: unknown): ZakatState {
  if (!isObj(raw)) return DEFAULT_ZAKAT;
  const vals = isObj(raw.values) ? raw.values : {};
  const values = Object.fromEntries(
    ZAKAT.fields.flatMap((f) => {
      const v = vals[f.id];
      return typeof v === "number" && v > 0 && Number.isFinite(v) ? [[f.id, v]] : [];
    }),
  );
  return { price: amount(raw.price as number), yearPassed: raw.yearPassed === true, values };
}

/** What the user typed stays on this device only, so the numbers are not retyped every visit. */
export const zakatStore = createStore<ZakatState>("rattil.zakat", DEFAULT_ZAKAT, sanitizeZakat);
