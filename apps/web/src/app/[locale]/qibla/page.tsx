import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { QiblaView } from "@/components/QiblaView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "qibla.title") };
}

export default async function QiblaPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "qibla.title")}</h1>
      <QiblaView locale={locale} />
      <p>
        <Link href={href(locale, "prayer")}>{t(locale, "qibla.changeCity")}</Link>
      </p>
    </>
  );
}
