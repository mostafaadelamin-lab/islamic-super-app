import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { LEARN } from "@/lib/kids-learn";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { KidsSteps } from "@/components/KidsLearn";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "kidsLearn.iman") };
}

export default async function KidsImanPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <nav className="crumbs">
        <Link href={href(locale, "kids")}>{t(locale, "kids.back")}</Link>
      </nav>
      <h1>{t(locale, "kidsLearn.iman")}</h1>
      <KidsSteps locale={locale} salah={false} section="iman" steps={LEARN.iman} credit={LEARN.stepsCredit} />
    </>
  );
}
