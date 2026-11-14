"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { filterHisn, type ChapterTitle } from "@/lib/hisn-filter";

export interface SectionChips {
  id: string;
  chapters: readonly number[];
}

export function HisnIndex({
  locale,
  chapters,
  sections = [],
}: {
  locale: Locale;
  chapters: readonly ChapterTitle[];
  sections?: readonly SectionChips[];
}) {
  const [q, setQ] = useState("");
  const [section, setSection] = useState<string | null>(null);
  // /hisn/#sleep opens that section (links from the adhkar page, like the app's adhkar hub).
  useEffect(() => {
    const pick = (): void => {
      const id = decodeURIComponent(window.location.hash.slice(1));
      if (sections.some((x) => x.id === id)) setSection(id);
    };
    pick();
    window.addEventListener("hashchange", pick);
    return () => window.removeEventListener("hashchange", pick);
  }, [sections]);
  const inSection = sections.find((x) => x.id === section)?.chapters;
  const list = filterHisn(q, inSection ? chapters.filter((c) => inSection.includes(c.id)) : chapters);
  return (
    <>
      <div className="field">
        <label htmlFor="hisn-filter">{t(locale, "hisn.filter")}</label>
        <input
          id="hisn-filter"
          type="search"
          dir="rtl"
          lang="ar"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          autoComplete="off"
        />
      </div>
      {sections.length > 0 ? (
        <div
          className="chips"
          role="group"
          aria-label={t(locale, "hisn.sections")}
          data-testid="hisn-sections"
        >
          <button
            type="button"
            className="chip"
            aria-pressed={section === null}
            onClick={() => setSection(null)}
            data-testid="hisn-section-all"
          >
            {t(locale, "hisn.section.all")}
          </button>
          {sections.map((x) => (
            <button
              key={x.id}
              type="button"
              className="chip"
              aria-pressed={section === x.id}
              onClick={() => setSection(x.id)}
              data-testid={`hisn-section-${x.id}`}
            >
              {t(locale, `hisn.section.${x.id}`)}
            </button>
          ))}
        </div>
      ) : null}
      {list.length === 0 ? (
        <p className="muted" role="status">
          {t(locale, "hisn.none")}
        </p>
      ) : null}
      <ol className="list-links" data-testid="hisn-list">
        {list.map((c) => (
          <li key={c.id}>
            <Link href={href(locale, `hisn/${c.id}`)} prefetch={false}>
              <span className="num-badge">{localizeDigits(c.id, locale)}</span>
              <span lang="ar">{c.title}</span>
            </Link>
          </li>
        ))}
      </ol>
    </>
  );
}
