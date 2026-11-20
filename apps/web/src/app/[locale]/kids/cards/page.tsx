import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { LEARN } from "@/lib/kids-learn";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { KidsCards } from "@/components/KidsLearn";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "kidsLearn.cards") };
}

export default async function KidsCardsPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <nav className="crumbs">
        <Link href={href(locale, "kids")}>{t(locale, "kids.back")}</Link>
      </nav>
      <h1>{t(locale, "kidsLearn.cards")}</h1>
      <KidsCards locale={locale} cards={LEARN.cards} />
    </>
  );
}
