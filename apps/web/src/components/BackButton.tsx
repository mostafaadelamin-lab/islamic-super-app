"use client";
import { usePathname, useRouter } from "next/navigation";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";

/** Sections that have a page of their own, for going up one level (a deeper page with no history). */
const HAS_PAGE: ReadonlySet<string> = new Set([
  "about",
  "adhkar",
  "adhkar/reminders",
  "asma",
  "bookmarks",
  "hadith",
  "hajj",
  "help",
  "hisn",
  "khatma",
  "kids",
  "kids/books",
  "kids/cards",
  "kids/hadith",
  "kids/ruqyah",
  "kids/salah",
  "kids/wudu",
  "library",
  "more",
  "mosques",
  "nasheeds",
  "prayer",
  "qibla",
  "quran",
  "reels",
  "ruqyah",
  "search",
  "settings",
  "sharawi",
  "stories",
  "tafsir",
  "tasbih",
  "tracker",
  "zakat",
]);

/** «رجوع» above every inner page (owner 2026-11-21: no page had a way back). It goes back in the
 *  browser history when the visitor came from this site, otherwise up one level (or home). Not on the
 *  home page, and not on the Mushaf reader, which has its own back button. */
export function BackButton({ locale }: { locale: Locale }) {
  const pathname = usePathname() ?? "/";
  const router = useRouter();
  const m = /^\/(?:ar|en)(\/.*)?$/.exec(pathname);
  const rest = (m?.[1] ?? "/").replace(/\/+$/, "") || "/";
  if (rest === "/" || /^\/page\//.test(rest)) return null;
  // The nearest level above that has a page (kids/teacher/1 → kids).
  let parent = rest.replace(/^\//, "").split("/").slice(0, -1).join("/");
  while (parent && !HAS_PAGE.has(parent)) parent = parent.split("/").slice(0, -1).join("/");
  const goBack = (): void => {
    let fromHere = false;
    try {
      fromHere = !!document.referrer && new URL(document.referrer).origin === window.location.origin;
    } catch {
      fromHere = false;
    }
    if (fromHere && window.history.length > 1) router.back();
    else router.push(href(locale, parent));
  };
  return (
    <div className="back-bar">
      <button type="button" className="back-btn" onClick={goBack} data-testid="page-back">
        <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
          <path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <span>{t(locale, "nav.back")}</span>
      </button>
    </div>
  );
}
