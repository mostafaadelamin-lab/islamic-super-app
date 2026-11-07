"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { Icon, type IconName } from "./Icon";

/** Top navigation on wide screens, bottom tab bar on phone widths (same element, CSS decides). */
export const NAV_ITEMS: readonly { path: string; key: string; icon: IconName; also: readonly string[] }[] = [
  { path: "", key: "nav.home", icon: "home", also: [] },
  { path: "quran", key: "nav.quran", icon: "quran", also: ["surah", "page"] },
  { path: "prayer", key: "nav.prayer", icon: "prayer", also: ["qibla"] },
  { path: "adhkar", key: "nav.adhkar", icon: "adhkar", also: ["hisn", "tasbih"] },
  {
    path: "more",
    key: "nav.more",
    icon: "more",
    also: ["search", "bookmarks", "settings", "about", "hajj"],
  },
];

export function isActive(pathname: string, locale: Locale, item: (typeof NAV_ITEMS)[number]): boolean {
  const p = pathname.endsWith("/") ? pathname : `${pathname}/`;
  if (item.path === "") return p === href(locale);
  return [item.path, ...item.also].some((seg) => p.startsWith(href(locale, seg)));
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
              aria-current={isActive(pathname, locale, item) ? "page" : undefined}
            >
              <Icon name={item.icon} />
              <span>{t(locale, item.key)}</span>
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}
