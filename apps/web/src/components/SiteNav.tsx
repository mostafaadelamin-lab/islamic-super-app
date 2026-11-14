"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { SITE_GROUPS, groupSegments, sectionOf, type SiteGroup } from "@/lib/site-map";
import { Icon } from "./Icon";

function groupActive(pathname: string, locale: Locale, g: SiteGroup): boolean {
  const p = pathname.endsWith("/") ? pathname : `${pathname}/`;
  return groupSegments(g).some((seg) => p.startsWith(href(locale, seg)));
}

/**
 * Website-style header navigation (wide screens): a "Home" link plus one drop-down menu per group of
 * sections. Opens on hover, on keyboard focus and on click; closes on Escape, on leaving and after navigating.
 */
export function SiteNav({ locale }: { locale: Locale }) {
  const pathname = usePathname() ?? "/";
  const [open, setOpen] = useState<number | null>(null);
  useEffect(() => setOpen(null), [pathname]);
  const home = (pathname.endsWith("/") ? pathname : `${pathname}/`) === href(locale);
  return (
    <nav className="site-nav" aria-label={t(locale, "nav.main")} onKeyDown={(e) => e.key === "Escape" && setOpen(null)}>
      <ul className="site-nav-list">
        <li>
          <Link className="site-nav-top" href={href(locale)} aria-current={home ? "page" : undefined}>
            {t(locale, "nav.home")}
          </Link>
        </li>
        {SITE_GROUPS.map((g, i) => {
          const active = groupActive(pathname, locale, g);
          const isOpen = open === i;
          const panelId = `site-menu-${i}`;
          return (
            <li
              key={g.title}
              className={`site-nav-group${isOpen ? " open" : ""}`}
              onMouseEnter={() => setOpen(i)}
              onMouseLeave={() => setOpen((o) => (o === i ? null : o))}
            >
              <button
                type="button"
                className="site-nav-top"
                aria-expanded={isOpen}
                aria-controls={panelId}
                data-active={active || undefined}
                onClick={() => setOpen(isOpen ? null : i)}
              >
                {t(locale, g.title)}
                <span className="site-nav-caret" aria-hidden="true" />
              </button>
              <div className="site-menu" id={panelId} hidden={!isOpen}>
                <div className="site-menu-head">
                  <span className="site-menu-icon">
                    <Icon name={g.icon} size={26} />
                  </span>
                  <span>
                    <strong>{t(locale, g.title)}</strong>
                    <span className="muted small">{t(locale, g.sub)}</span>
                  </span>
                </div>
                <ul className="site-menu-list">
                  {g.items.map((p) => {
                    const s = sectionOf(p);
                    return (
                      <li key={p}>
                        <Link href={href(locale, p)} onFocus={() => setOpen(i)}>
                          <span className="site-menu-item-icon">
                            <Icon name={s.icon} size={20} />
                          </span>
                          <span>
                            <strong>{t(locale, s.title)}</strong>
                            <span className="muted small">{t(locale, s.sub)}</span>
                          </span>
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
