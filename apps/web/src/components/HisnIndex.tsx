"use client";
import Link from "next/link";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { filterHisn, type ChapterTitle } from "@/lib/hisn-filter";

export function HisnIndex({ locale, chapters }: { locale: Locale; chapters: readonly ChapterTitle[] }) {
  const [q, setQ] = useState("");
  const list = filterHisn(q, chapters);
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
