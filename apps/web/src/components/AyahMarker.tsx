import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { ayahEndMark } from "@/lib/quran-render";

/** End-of-ayah marker: the KFGQPC font draws the ornament around Arabic-Indic digits (ar) or a numbered badge (en). */
export function AyahMarker({ n, locale }: { n: number; locale: Locale }) {
  return (
    <>
      {" "}
      {locale === "ar" ? (
        <span className="ayah-marker" aria-hidden="true" data-testid="ayah-marker">
          {ayahEndMark(n)}
        </span>
      ) : (
        <span className="ayah-marker ayah-marker-en" aria-hidden="true" data-testid="ayah-marker">
          ({n})
        </span>
      )}
      <span className="sr-only">{t(locale, "quran.ayah", { n: localizeDigits(n, locale) })}</span>
    </>
  );
}
