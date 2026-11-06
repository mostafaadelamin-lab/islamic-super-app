const ARABIC_INDIC = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];

/** Converts ASCII digits in a number/string to Arabic-Indic digits. */
export function toArabicIndic(value: number | string): string {
  return String(value).replace(/[0-9]/g, (d) => ARABIC_INDIC[Number(d)] as string);
}

export function localizeDigits(value: number | string, locale: string): string {
  return locale === "ar" ? toArabicIndic(value) : String(value);
}
