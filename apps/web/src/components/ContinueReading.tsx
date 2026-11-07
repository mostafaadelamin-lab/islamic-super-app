"use client";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { surahMeta } from "@/lib/pages";
import { lastReadStore } from "@/lib/settings";
import { useStore } from "@/hooks/useStore";
import { Icon } from "./Icon";

export function ContinueReading({ locale }: { locale: Locale }) {
  const last = useStore(lastReadStore);
  const meta = last ? surahMeta(last.surah) : undefined;
  return (
    <section className="card continue" aria-labelledby="continue-h">
      <h2 id="continue-h" className="card-title">
        <Icon name="book" /> {t(locale, "quran.continueReading")}
      </h2>
      {last && meta ? (
        <div className="row">
          {last.page ? (
            <Link
              className="btn btn-primary"
              href={href(locale, `page/${last.page}`)}
              data-testid="continue-page"
            >
              {t(locale, "quran.page", { page: localizeDigits(last.page, locale) })}
            </Link>
          ) : null}
          <Link
            className="btn"
            href={`${href(locale, `surah/${last.surah}`)}#a-${last.ayah}`}
            data-testid="continue-surah"
          >
            {t(locale, "quran.lastRead", {
              surah: locale === "ar" ? meta.nameAr : meta.translit,
              ayah: localizeDigits(last.ayah, locale),
            })}
          </Link>
        </div>
      ) : (
        <p className="muted">{t(locale, "quran.noLastRead")}</p>
      )}
    </section>
  );
}
