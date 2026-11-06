"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { switchLocalePath } from "@/lib/locale-path";
import { prefsStore } from "@/lib/settings";

export function LanguageSwitch({ locale }: { locale: Locale }) {
  const pathname = usePathname() ?? `/${locale}/`;
  const other: Locale = locale === "ar" ? "en" : "ar";
  return (
    <Link
      className="lang-switch"
      href={switchLocalePath(pathname, other)}
      hrefLang={other}
      onClick={() => prefsStore.set((p) => ({ ...p, locale: other }))}
      data-testid="lang-switch"
    >
      <span className="sr-only">{t(locale, "lang.switch")} </span>
      <span lang={other}>{t(locale, "lang.other")}</span>
    </Link>
  );
}
