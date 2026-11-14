import type { IconName } from "@/components/Icon";
import { SECTIONS, type Section } from "@/components/SectionTiles";
import { href } from "@/lib/locale-path";
import type { Locale } from "@/lib/i18n";

/**
 * Website navigation (desktop / wide screens): every section of the site grouped into menus, used by the
 * header drop-down menus, the footer site map, the home page and the breadcrumbs. Phones keep the app-style
 * bottom tab bar (MainNav); this is the website-style structure the owner asked for on 2026-11-14.
 */
export interface SiteGroup {
  /** i18n key of the menu / column title */
  title: string;
  /** i18n key of the short description shown in the menu and on the home page */
  sub: string;
  icon: IconName;
  /** first link of the group: where the menu title itself leads */
  path: string;
  /** section paths (from SECTIONS) listed under this menu */
  items: readonly string[];
  /** extra URL segments that belong to this group (for the active state) */
  also?: readonly string[];
}

export const SITE_GROUPS: readonly SiteGroup[] = [
  {
    title: "site.group.quran",
    sub: "site.group.quranSub",
    icon: "quran",
    path: "quran",
    items: ["page/1", "quran", "search", "khatma", "bookmarks", "library"],
    also: ["surah", "page"],
  },
  {
    title: "site.group.prayer",
    sub: "site.group.prayerSub",
    icon: "prayer",
    path: "prayer",
    items: ["prayer", "adhan", "qibla", "mosques", "tracker"],
  },
  {
    title: "site.group.adhkar",
    sub: "site.group.adhkarSub",
    icon: "dua",
    path: "adhkar",
    items: ["adhkar", "hisn", "tasbih", "asma"],
  },
  {
    title: "site.group.library",
    sub: "site.group.librarySub",
    icon: "book",
    path: "hadith",
    items: ["hadith", "sharawi", "stories", "nasheeds", "reels", "zakat"],
  },
  {
    // Its own menu (owner, 2026-11-14): the guide, live crowd levels (official link) and live audio.
    title: "site.group.hajj",
    sub: "site.group.hajjSub",
    icon: "kaaba",
    path: "hajj",
    items: ["hajj", "hajj-crowd", "hajj-live"],
  },
  {
    title: "site.group.about",
    sub: "site.group.aboutSub",
    icon: "info",
    path: "about",
    items: ["about", "help", "settings"],
  },
];

/** Menu entries that are a part of a page rather than a page of their own (owner, 2026-11-14: adhan alerts). */
const EXTRA: Readonly<Record<string, Section & { page: string; hash: string }>> = {
  "hajj-crowd": {
    path: "hajj-crowd",
    page: "hajj",
    hash: "crowd",
    title: "nav.hajjCrowd",
    sub: "nav.hajjCrowdSub",
    icon: "kaaba",
  },
  "hajj-live": {
    path: "hajj-live",
    page: "hajj",
    hash: "live",
    title: "nav.hajjLive",
    sub: "nav.hajjLiveSub",
    icon: "radio",
  },
  adhan: {
    path: "adhan",
    page: "prayer",
    hash: "adhan",
    title: "nav.adhanAlerts",
    sub: "nav.adhanAlertsSub",
    icon: "bell",
  },
};

const BY_PATH: ReadonlyMap<string, Section> = new Map([
  ...SECTIONS.map((s) => [s.path, s] as const),
  ...Object.values(EXTRA).map((s) => [s.path, s] as const),
]);

/** Link of a menu entry (a page, or a page plus an anchor). */
export function itemHref(locale: Locale, path: string): string {
  const x = EXTRA[path];
  return x ? `${href(locale, x.page)}#${x.hash}` : href(locale, path);
}

export function sectionOf(path: string): Section {
  const s = BY_PATH.get(path);
  if (!s) throw new Error(`unknown section ${path}`);
  return s;
}

/** First URL segment(s) of a group, for the active state of its menu. */
export function groupSegments(g: SiteGroup): string[] {
  return [...g.items.map((p) => EXTRA[p]?.page ?? p.split("/")[0]!), ...(g.also ?? [])];
}

/** The group and section a path (without the locale prefix, e.g. "surah/2/") belongs to. */
export function locate(rest: string): { group: SiteGroup; section: Section | null } | null {
  const seg = rest.split("/").filter(Boolean);
  if (seg.length === 0) return null;
  const first = seg[0]!;
  for (const g of SITE_GROUPS) {
    if (!groupSegments(g).includes(first)) continue;
    const exact = g.items.find((p) => p.split("/")[0] === first) ?? null;
    return { group: g, section: exact ? sectionOf(exact) : null };
  }
  return null;
}
