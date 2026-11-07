import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { HISN } from "@/lib/hisn";
import { HisnIndex } from "@/components/HisnIndex";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "hisn.title") };
}

export default async function HisnPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "hisn.title")}</h1>
      <p className="muted">{t(locale, "hisn.intro")}</p>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      <HisnIndex locale={locale} chapters={HISN.map(({ id, title }) => ({ id, title }))} />
      <p className="muted small">{t(locale, "adhkar.source")}</p>
    </>
  );
}
