import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { surahName } from "@/lib/pages";
import { SERIES, STORIES, storiesByCategory, type Series, type Story } from "@/lib/stories";
import { Icon } from "./Icon";
import { SeriesPlayer } from "./SeriesPlayer";

/** The stories page: narrated series (audio only), then the stories' verses from the Mushaf. */
export function StoriesIndex({
  locale,
  stories = STORIES,
  series = SERIES,
}: {
  locale: Locale;
  stories?: readonly Story[];
  series?: readonly Series[];
}) {
  return (
    <>
      <p className="muted">{t(locale, "stories.intro")}</p>
      {series.map((se) => (
        <SeriesPlayer key={se.id} locale={locale} series={se} />
      ))}
      <h2>{t(locale, "stories.versesTitle")}</h2>
      <p className="muted small">{t(locale, "stories.versesIntro")}</p>
      {storiesByCategory(stories).map((g) => (
        <section key={g.category} aria-labelledby={`cat-${g.category}`}>
          <h3 className="section-title" id={`cat-${g.category}`}>
            {t(locale, `stories.cat.${g.category}`)}
          </h3>
          <ul className="story-list" data-testid={`stories-${g.category}`}>
            {g.items.map((st) => (
              <li key={st.id}>
                <Link className="story-item" href={href(locale, `stories/${st.id}`)} data-story={st.id}>
                  <span className="tile-icon">
                    <Icon name="book" />
                  </span>
                  <span className="tile-text">
                    <strong>{locale === "ar" ? st.title.ar : st.title.en}</strong>
                    <span className="muted small">
                      {st.segments
                        .map(([s]) => surahName(s, locale))
                        .filter((v, i, a) => a.indexOf(v) === i)
                        .join(locale === "ar" ? "، " : ", ")}{" "}
                      · {t(locale, "stories.ayahs", { count: localizeDigits(st.ayahCount, locale) })}
                    </span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </>
  );
}
