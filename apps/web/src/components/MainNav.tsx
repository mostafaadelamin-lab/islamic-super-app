"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";

export const NAV_ITEMS = [
  { path: "", key: "nav.home" },
  { path: "quran", key: "nav.quran" },
  { path: "search", key: "nav.search" },
  { path: "prayer", key: "nav.prayer" },
  { path: "bookmarks", key: "nav.bookmarks" },
  { path: "settings", key: "nav.settings" },
] as const;

function isActive(pathname: string, locale: Locale, path: string): boolean {
  const base = href(locale, path);
  const p = pathname.endsWith("/") ? pathname : `${pathname}/`;
  if (path === "") return p === base;
  if (path === "quran")
    return p.startsWith(base) || p.startsWith(`/${locale}/surah/`) || p.startsWith(`/${locale}/page/`);
  return p.startsWith(base);
}

export function MainNav({ locale }: { locale: Locale }) {
  const pathname = usePathname() ?? "/";
  return (
    <nav className="main-nav" aria-label={t(locale, "nav.main")}>
      <ul>
        {NAV_ITEMS.map((item) => (
          <li key={item.key}>
            <Link
              href={href(locale, item.path)}
              aria-current={isActive(pathname, locale, item.path) ? "page" : undefined}
            >
              {t(locale, item.key)}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
