import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { MainNav } from "./MainNav";
import { LanguageSwitch } from "./LanguageSwitch";

export function Header({ locale }: { locale: Locale }) {
  return (
    <header className="app-header">
      <div className="app-header-inner">
        <Link className="brand" href={href(locale)}>
          {t(locale, "appName")}
        </Link>
        <MainNav locale={locale} />
        <LanguageSwitch locale={locale} />
      </div>
    </header>
  );
}
