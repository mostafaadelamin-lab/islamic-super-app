"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { loadLessons, type LessonCatalog } from "@/lib/lessons";
import { loadSharawi, type SharawiSurah } from "@/lib/sharawi";
import { LessonsView } from "./LessonsView";
import { SharawiView } from "./SharawiView";

type Part = "tafsir" | "seerah" | "anbiya";

const PARTS: readonly { id: Part; label: string; series?: string }[] = [
  { id: "tafsir", label: "sharawi.partTafsir" },
  { id: "seerah", label: "sharawi.partSeerah", series: "seerah-shaarawi" },
  { id: "anbiya", label: "sharawi.partAnbiya", series: "anbiya-shaarawi" },
];

/**
 * The Sha'rawi section in three parts (owner 2026-11-23): Quran tafsir, the Prophet's life and prophets'
 * stories. The last two are his lesson series, with the same download / resume / ✓ as «سلاسل الدروس».
 */
export function SharawiSection({
  locale,
  loader = loadSharawi,
  lessonsLoader = loadLessons,
}: {
  locale: Locale;
  loader?: () => Promise<SharawiSurah[]>;
  lessonsLoader?: () => Promise<LessonCatalog>;
}) {
  const [part, setPart] = useState<Part>("tafsir");
  const current = PARTS.find((p) => p.id === part);
  const content = current?.series ? (
    <LessonsView key={current.series} locale={locale} loader={lessonsLoader} only={current.series} />
  ) : (
    <SharawiView locale={locale} loader={loader} />
  );
  return (
    <>
      <div className="row lessons-chips" role="group" aria-label={t(locale, "sharawi.section")}>
        {PARTS.map((p) => (
          <button
            key={p.id}
            type="button"
            className={part === p.id ? "btn btn-sm btn-primary" : "btn btn-sm"}
            aria-pressed={part === p.id}
            data-testid={`sharawi-part-${p.id}`}
            onClick={() => setPart(p.id)}
          >
            {t(locale, p.label)}
          </button>
        ))}
      </div>
      {content}
    </>
  );
}
