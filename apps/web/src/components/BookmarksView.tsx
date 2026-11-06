"use client";
import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { surahMeta } from "@/lib/pages";
import { activeBookmarks, bookmarksStore, removeBookmark } from "@/lib/bookmarks";
import { useStore } from "@/hooks/useStore";

export function BookmarksView({ locale }: { locale: Locale }) {
  const state = useStore(bookmarksStore);
  const list = activeBookmarks(state);
  if (list.length === 0) {
    return (
      <p className="muted" data-testid="bookmarks-empty">
        {t(locale, "bookmarks.empty")}
      </p>
    );
  }
  return (
    <>
      <p className="muted">{t(locale, "bookmarks.count", { count: localizeDigits(list.length, locale) })}</p>
      <ul className="results" data-testid="bookmark-list">
        {list.map((b) => {
          const m = surahMeta(b.surah);
          const label = t(locale, "quran.ayahRef", {
            surah: m ? (locale === "ar" ? m.nameAr : m.translit) : String(b.surah),
            ayah: localizeDigits(b.ayah, locale),
          });
          return (
            <li key={b.id} className="row" style={{ justifyContent: "space-between" }}>
              <Link href={`${href(locale, `surah/${b.surah}`)}#a-${b.ayah}`}>{label}</Link>
              <button
                type="button"
                className="btn"
                aria-label={`${t(locale, "bookmarks.remove")} — ${label}`}
                onClick={() => bookmarksStore.set((s) => removeBookmark(s, b.id, Date.now()))}
              >
                {t(locale, "bookmarks.remove")}
              </button>
            </li>
          );
        })}
      </ul>
    </>
  );
}
