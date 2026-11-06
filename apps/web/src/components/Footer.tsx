import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";

export function Footer({ locale }: { locale: Locale }) {
  return (
    <footer className="app-footer">
      <p>{t(locale, "settings.free")}</p>
      <Link href={href(locale, "about")}>{t(locale, "nav.about")}</Link>
      <Link href={href(locale, "page/1")}>{t(locale, "quran.pages")}</Link>
    </footer>
  );
}
