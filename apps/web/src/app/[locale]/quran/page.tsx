import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { SurahIndex } from "@/components/SurahIndex";
import { GoToPage } from "@/components/GoToPage";
import { ContinueReading } from "@/components/ContinueReading";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "quran.surahs") };
}

export default async function QuranIndexPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "quran.surahs")}</h1>
      <ContinueReading locale={locale} />
      <section className="card" aria-label={t(locale, "quran.pages")}>
        <div className="row" style={{ justifyContent: "space-between" }}>
          <Link className="btn" href={href(locale, "page/1")}>
            {t(locale, "quran.openMushaf")}
          </Link>
          <GoToPage locale={locale} />
        </div>
      </section>
      <SurahIndex locale={locale} />
    </>
  );
}
