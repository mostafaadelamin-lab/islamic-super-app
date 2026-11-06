import sharedAr from "@/generated/i18n-ar.json";
import sharedEn from "@/generated/i18n-en.json";
import webAr from "@/i18n/web.ar.json";
import webEn from "@/i18n/web.en.json";

export const LOCALES = ["ar", "en"] as const;
export type Locale = (typeof LOCALES)[number];
export const DEFAULT_LOCALE: Locale = "ar";

export type Dict = Record<string, string>;

export const dictionaries: Record<Locale, Dict> = {
  ar: { ...(sharedAr as Dict), ...(webAr as Dict) },
  en: { ...(sharedEn as Dict), ...(webEn as Dict) },
};

export function isLocale(v: unknown): v is Locale {
  return v === "ar" || v === "en";
}

export function dirOf(locale: Locale): "rtl" | "ltr" {
  return locale === "ar" ? "rtl" : "ltr";
}

export function translate(dict: Dict, key: string, vars: Record<string, string | number> = {}): string {
  const template = dict[key] ?? key;
  return template.replace(/\{(\w+)\}/g, (m, name: string) => (name in vars ? String(vars[name]) : m));
}

export function t(locale: Locale, key: string, vars?: Record<string, string | number>): string {
  return translate(dictionaries[locale], key, vars);
}
