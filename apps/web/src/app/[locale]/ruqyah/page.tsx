import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { PreloadQuranFont } from "@/components/PreloadQuranFont";
import { RuqyahView } from "@/components/RuqyahView";
import { KIDS } from "@/lib/kids";
import { ruqyahPassages } from "@/lib/server/ruqyah";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "ruqyah.title") };
}

export default async function RuqyahPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const items = KIDS.ruqyah.items;
  return (
    <>
      <PreloadQuranFont />
      <h1>{t(locale, "ruqyah.title")}</h1>
      <RuqyahView
        locale={locale}
        kids={false}
        items={items}
        passages={ruqyahPassages(items)}
        full={KIDS.ruqyah.full}
      />
    </>
  );
}
