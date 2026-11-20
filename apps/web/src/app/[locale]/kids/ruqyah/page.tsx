import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { RuqyahView } from "@/components/RuqyahView";
import { KIDS } from "@/lib/kids";
import { ruqyahPassages } from "@/lib/server/ruqyah";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "ruqyah.kidsTitle") };
}

export default async function KidsRuqyahPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const items = KIDS.ruqyahKids.items;
  return (
    <>
      <PreloadQuranFont />
      <nav className="crumbs">
        <Link href={href(locale, "kids")}>{t(locale, "kids.back")}</Link>
      </nav>
      <h1>{t(locale, "ruqyah.kidsTitle")}</h1>
      <RuqyahView locale={locale} kids items={items} passages={ruqyahPassages(items)} />
    </>
  );
}
