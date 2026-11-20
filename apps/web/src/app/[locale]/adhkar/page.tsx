import type { Metadata } from "next";
import Link from "next/link";
import adhkar from "@/generated/adhkar.json";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { AdhkarView } from "@/components/AdhkarView";
import { AdhkarHub } from "@/components/AdhkarHub";
import { adhkarExtras } from "@/lib/dhikr-extras";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "adhkar.title") };
}

export default async function AdhkarPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "adhkar.hubTitle")}</h1>
      <p className="row">
        <Link className="btn btn-sm" href={href(locale, "hisn")}>
          {t(locale, "hisn.title")}
        </Link>
        <Link className="btn btn-sm" href={href(locale, "tasbih")}>
          {t(locale, "tasbih.title")}
        </Link>
        <Link
          className="btn btn-sm"
          href={href(locale, "adhkar/reminders")}
          data-testid="open-dhikr-reminders"
        >
          {t(locale, "dhikrRem.title")}
        </Link>
      </p>
      <AdhkarHub locale={locale} />
      <h2 id="adhkar-sessions">{t(locale, "adhkar.morningEvening")}</h2>
      <AdhkarView
        locale={locale}
        items={(adhkar as { items: string[] }).items}
        extras={adhkarExtras((adhkar as { items: string[] }).items.length)}
      />
    </>
  );
}
