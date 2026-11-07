import type { Metadata } from "next";
import Link from "next/link";
import adhkar from "@/generated/adhkar.json";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { AdhkarView } from "@/components/AdhkarView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "adhkar.title") };
}

export default async function AdhkarPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "adhkar.title")}</h1>
      <p className="row">
        <Link className="btn btn-sm" href={href(locale, "hisn")}>
          {t(locale, "hisn.title")}
        </Link>
        <Link className="btn btn-sm" href={href(locale, "tasbih")}>
          {t(locale, "tasbih.title")}
        </Link>
      </p>
      <AdhkarView locale={locale} items={(adhkar as { items: string[] }).items} />
    </>
  );
}
