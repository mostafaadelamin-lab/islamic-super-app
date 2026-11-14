"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { locate } from "@/lib/site-map";

/** "Home › Group › Section" trail above inner pages (wide screens only; hidden on phones). */
export function Breadcrumbs({ locale }: { locale: Locale }) {
  const pathname = usePathname() ?? "/";
  const m = /^\/(?:ar|en)(\/.*)?$/.exec(pathname);
  const rest = m?.[1] ?? "/";
  const where = locate(rest);
  if (!where) return null;
  const { group, section } = where;
  const sectionHref = section ? href(locale, section.path) : null;
  const atSection = sectionHref !== null && (pathname.endsWith("/") ? pathname : `${pathname}/`) === sectionHref;
  return (
    <nav className="site-crumbs" aria-label={t(locale, "site.breadcrumbs")}>
      <ol>
        <li>
          <Link href={href(locale)}>{t(locale, "nav.home")}</Link>
        </li>
        <li>
          <span>{t(locale, group.title)}</span>
        </li>
        {section ? (
          <li>
            {atSection ? (
              <span aria-current="page">{t(locale, section.title)}</span>
            ) : (
              <Link href={sectionHref!}>{t(locale, section.title)}</Link>
            )}
          </li>
        ) : null}
      </ol>
    </nav>
  );
}
