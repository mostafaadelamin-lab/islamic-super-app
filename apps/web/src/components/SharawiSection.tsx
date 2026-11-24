"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { loadLessons, type LessonCatalog, type LessonSeries } from "@/lib/lessons";
import { loadSharawi, type SharawiSurah } from "@/lib/sharawi";
import { Icon } from "./Icon";
import { LessonsHeroCard, LessonsView } from "./LessonsView";
import { SharawiView } from "./SharawiView";
import { closeHashLayer, pushLayer, setRootBack } from "@/lib/back-nav";

type Part = "tafsir" | "seerah" | "anbiya";

const PARTS: readonly { id: Part; label: string; series?: string }[] = [
  { id: "tafsir", label: "sharawi.partTafsir" },
  { id: "seerah", label: "sharawi.partSeerah", series: "seerah-shaarawi" },
  { id: "anbiya", label: "sharawi.partAnbiya", series: "anbiya-shaarawi" },
];

const partOf = (hash: string): Part | null => PARTS.find((p) => `#${p.id}` === hash)?.id ?? null;

/**
 * «دروس الشيخ الشعراوي» (owner 2026-11-24): a front page of three series cards (Quran tafsir, the Prophet's
 * life, prophets' stories); each opens its part (#tafsir / #seerah / #anbiya, so the back button works).
 * The seerah and stories are his lesson series, with the same download / resume / ✓ as «سلاسل الدروس»,
 * where they are listed under their topics too.
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
  const [part, setPart] = useState<Part | null>(null);
  const [data, setData] = useState<LessonCatalog | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    const read = (): void => setPart(partOf(window.location.hash));
    read();
    window.addEventListener("hashchange", read);
    window.addEventListener("popstate", read);
    // A part opened from a link: «رجوع» shows the three cards first (owner 2026-11-24).
    setRootBack(() => closeHashLayer("sharawi"));
    return () => {
      window.removeEventListener("hashchange", read);
      window.removeEventListener("popstate", read);
      setRootBack(null);
    };
  }, []);
  useEffect(() => {
    const load = async (): Promise<void> => {
      try {
        setData(await lessonsLoader());
      } catch {
        setFailed(true);
      }
    };
    void load();
  }, [lessonsLoader]);

  const go = (p: Part | null): void => {
    if (p) pushLayer("sharawi", `#${p}`);
    else closeHashLayer("sharawi");
    setPart(p);
    window.scrollTo?.({ top: 0 });
  };

  if (part) {
    const current = PARTS.find((p) => p.id === part)!;
    return (
      <>
        <button type="button" className="btn btn-sm" data-testid="sharawi-back" onClick={() => go(null)}>
          <Icon name="back" /> {t(locale, "sharawi.section")}
        </button>
        <h2>{t(locale, current.label)}</h2>
        {current.series ? (
          <LessonsView key={current.series} locale={locale} loader={lessonsLoader} only={current.series} />
        ) : (
          <SharawiView locale={locale} loader={loader} />
        )}
      </>
    );
  }
  if (failed) return <p className="alert alert-error">{t(locale, "sharawi.loadError")}</p>;
  if (!data) return <p className="muted">{t(locale, "common.loading")}</p>;
  const cards: { part: Part; series: LessonSeries }[] = PARTS.flatMap((p) => {
    const s = p.series ? data.sharawi.find((x) => x.id === p.series) : data.sharawiTafsir;
    return s ? [{ part: p.id, series: s }] : [];
  });
  return (
    <div className="lessons-hero-cards" data-testid="sharawi-parts">
      {cards.map((c) => (
        <LessonsHeroCard
          key={c.part}
          locale={locale}
          series={c.series}
          openLabel={t(locale, c.part === "tafsir" ? "sharawi.chooseSurah" : "lessons.allEpisodes")}
          onOpen={() => go(c.part)}
        />
      ))}
    </div>
  );
}
