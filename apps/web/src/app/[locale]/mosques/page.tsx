import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { MosquesView } from "@/components/MosquesView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "mosques.title") };
}

export default async function MosquesPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "mosques.title")}</h1>
      <MosquesView locale={locale} />
      <p>
        <Link href={href(locale, "prayer")}>{t(locale, "qibla.changeCity")}</Link>
      </p>
    </>
  );
}
