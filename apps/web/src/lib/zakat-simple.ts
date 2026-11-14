/**
 * The simple zakat calculator the owner asked for (2026-11-11), ported from the app
 * (apps/mobile/lib/domain/zakat_simple.dart) so the website gives the same answers.
 * Gold nisab 85 g of 24-carat gold, silver nisab 595 g of pure silver, 2.5% after a lunar year;
 * money is measured against the gold or the silver nisab (user's choice); crops: nisab 612 kg,
 * 10% when watered without cost, 5% with machines, due at harvest. Livestock: the Prophet's
 * letter narrated by Anas (Sahih al-Bukhari 1454) for camels and sheep, and the hadith of
 * Mu'adh (Sunan al-Tirmidhi 623) for cattle.
 */
import { createStore } from "./store";

export const GOLD_NISAB_GRAMS = 85;
export const SILVER_NISAB_GRAMS = 595;
export const CROPS_NISAB_KG = 612;
export const ZAKAT_RATE = 0.025;

export interface MetalZakat {
  reached: boolean;
  dueGrams: number;
  dueMoney: number | null;
}

export const pureGold = (grams: number, karat: number): number => (grams * karat) / 24;

export function goldZakat(grams: number, karat: number, pricePerGram24: number | null): MetalZakat {
  const pure = pureGold(grams, karat);
  if (pure < GOLD_NISAB_GRAMS) return { reached: false, dueGrams: 0, dueMoney: null };
  return {
    reached: true,
    dueGrams: grams * ZAKAT_RATE,
    dueMoney: pricePerGram24 == null ? null : pure * ZAKAT_RATE * pricePerGram24,
  };
}

export function silverZakat(grams: number, pricePerGram: number | null): MetalZakat {
  if (grams < SILVER_NISAB_GRAMS) return { reached: false, dueGrams: 0, dueMoney: null };
  const due = grams * ZAKAT_RATE;
  return { reached: true, dueGrams: due, dueMoney: pricePerGram == null ? null : due * pricePerGram };
}

export function moneyZakat(amount: number, nisab: number): { reached: boolean; due: number; nisab: number } {
  const reached = nisab > 0 && amount >= nisab;
  return { reached, due: reached ? amount * ZAKAT_RATE : 0, nisab };
}

export function cropsZakat(kg: number, rainFed: boolean): { reached: boolean; dueKg: number } {
  return kg < CROPS_NISAB_KG
    ? { reached: false, dueKg: 0 }
    : { reached: true, dueKg: kg * (rainFed ? 0.1 : 0.05) };
}

export type Livestock = "camels" | "cattle" | "sheep";
export type LivestockUnit = "sheep" | "bintMakhad" | "bintLabun" | "hiqqa" | "jadhaa" | "tabi" | "musinna";

/** Above the fixed table: one aUnit per a and one bUnit per b, covering as many as possible. */
function bestSplit(count: number, a: number, aUnit: LivestockUnit, b: number, bUnit: LivestockUnit) {
  let best: [number, number, number] = [0, 0, -1];
  for (let nb = 0; nb * b <= count; nb++) {
    const na = Math.floor((count - nb * b) / a);
    const covered = na * a + nb * b;
    if (covered > best[2]) best = [na, nb, covered];
  }
  const out: [number, LivestockUnit][] = [];
  if (best[0] > 0) out.push([best[0], aUnit]);
  if (best[1] > 0) out.push([best[1], bUnit]);
  return out;
}

/** What is due on count grazing animals of kind, as [amount, unit] pairs. Empty = below the nisab. */
export function livestockZakat(kind: Livestock, count: number): [number, LivestockUnit][] {
  switch (kind) {
    case "sheep":
      if (count < 40) return [];
      if (count <= 120) return [[1, "sheep"]];
      if (count <= 200) return [[2, "sheep"]];
      if (count <= 300) return [[3, "sheep"]];
      return [[Math.floor(count / 100), "sheep"]];
    case "camels":
      if (count < 5) return [];
      if (count <= 24) return [[Math.floor(count / 5), "sheep"]];
      if (count <= 35) return [[1, "bintMakhad"]];
      if (count <= 45) return [[1, "bintLabun"]];
      if (count <= 60) return [[1, "hiqqa"]];
      if (count <= 75) return [[1, "jadhaa"]];
      if (count <= 90) return [[2, "bintLabun"]];
      if (count <= 120) return [[2, "hiqqa"]];
      return bestSplit(count, 40, "bintLabun", 50, "hiqqa");
    case "cattle":
      if (count < 30) return [];
      if (count < 40) return [[1, "tabi"]];
      if (count < 60) return [[1, "musinna"]];
      return bestSplit(count, 30, "tabi", 40, "musinna");
  }
}

export type ZakatTab = "silver" | "gold" | "money" | "livestock" | "crops";
export const ZAKAT_TABS: readonly ZakatTab[] = ["silver", "gold", "money", "livestock", "crops"];

export interface SimpleZakatState {
  tab: ZakatTab;
  karat: 24 | 21 | 18;
  basis: "gold" | "silver";
  animal: Livestock;
  rain: boolean;
  values: Record<string, number>;
}

export const DEFAULT_SIMPLE_ZAKAT: SimpleZakatState = {
  tab: "money",
  karat: 21,
  basis: "gold",
  animal: "sheep",
  rain: true,
  values: {},
};

export function sanitizeSimpleZakat(raw: unknown): SimpleZakatState {
  const r = (raw ?? {}) as Partial<Record<keyof SimpleZakatState, unknown>>;
  const values: Record<string, number> = {};
  if (r.values && typeof r.values === "object") {
    for (const [k, v] of Object.entries(r.values as Record<string, unknown>)) {
      if (typeof v === "number" && Number.isFinite(v) && v >= 0) values[k] = v;
    }
  }
  return {
    tab: ZAKAT_TABS.includes(r.tab as ZakatTab) ? (r.tab as ZakatTab) : DEFAULT_SIMPLE_ZAKAT.tab,
    karat: r.karat === 24 || r.karat === 18 ? r.karat : 21,
    basis: r.basis === "silver" ? "silver" : "gold",
    animal: r.animal === "camels" || r.animal === "cattle" ? r.animal : "sheep",
    rain: r.rain !== false,
    values,
  };
}

export const simpleZakatStore = createStore<SimpleZakatState>(
  "rattil.zakat.simple",
  DEFAULT_SIMPLE_ZAKAT,
  sanitizeSimpleZakat,
);
