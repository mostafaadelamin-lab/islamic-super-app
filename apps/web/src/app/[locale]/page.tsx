import Link from "next/link";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { NextPrayerCard } from "@/components/NextPrayerCard";
import { QuranRadio } from "@/components/QuranRadio";
import { SharePrompt } from "@/components/ShareApp";
import { Icon, type IconName } from "@/components/Icon";
import { MosqueArt } from "@/components/MosqueArt";
import { SITE_GROUPS, itemHref, sectionOf } from "@/lib/site-map";

interface HomeTile {
  path: string;
  title: string;
  icon: IconName;
}

/** Big tiles, then the wide pairs, as in the owner's mockup (2026-11-09). */
const BIG: readonly HomeTile[] = [
  { path: "quran", title: "home.big.quran", icon: "quran" },
  { path: "adhkar", title: "home.big.adhkar", icon: "dua" },
  { path: "prayer", title: "home.big.prayer", icon: "clock" },
];
const WIDE: readonly HomeTile[] = [
  { path: "tasbih", title: "home.big.tasbih", icon: "beads" },
  { path: "qibla", title: "home.big.qibla", icon: "compass" },
  { path: "reels", title: "home.big.reels", icon: "reels" },
  { path: "stories", title: "home.big.stories", icon: "headphones" },
];

function Tiles({ locale, list, kind }: { locale: Locale; list: readonly HomeTile[]; kind: string }) {
  return (
    <ul className={`home-tiles home-tiles-${kind}`}>
      {list.map((s) => (
        <li key={s.path}>
          <Link className={`home-tile home-tile-${kind}`} href={href(locale, s.path)} data-section={s.path}>
            <span className="home-tile-icon">
              <Icon name={s.icon} size={kind === "big" ? 40 : 30} />
            </span>
            <strong>{t(locale, s.title)}</strong>
          </Link>
        </li>
      ))}
    </ul>
  );
}

/** Home cards: Quran, Prayer, Adhkar, Library and Hajj & Umrah as the fifth (owner, 2026-11-15). */
const EXPLORE_GROUPS = SITE_GROUPS.filter((g) => g.path !== "about");

/** Website home sections (wide screens): a card per menu group listing its pages. */
function Explore({ locale }: { locale: Locale }) {
  return (
    <section
      className="home-explore desktop-only"
      aria-labelledby="home-explore-h"
      data-testid="home-explore"
    >
      <h2 id="home-explore-h" className="site-section-title">
        {t(locale, "site.explore")}
      </h2>
      <ul className="explore-grid">
        {EXPLORE_GROUPS.map((g) => (
          <li key={g.title} className="explore-card">
            <Link className="explore-card-head" href={href(locale, g.path)}>
              <span className="explore-card-icon">
                <Icon name={g.icon} size={28} />
              </span>
              <span>
                <strong>{t(locale, g.title)}</strong>
                <span className="muted small">{t(locale, g.sub)}</span>
              </span>
            </Link>
            <ul className="explore-links">
              {g.items.map((p) => {
                const s = sectionOf(p);
                return (
                  <li key={p}>
                    <Link href={itemHref(locale, p)} data-section={p}>
                      <Icon name={s.icon} size={18} />
                      <span>{t(locale, s.title)}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default async function HomePage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <div className="home">
      <h1 className="sr-only">{t(locale, "home.title")}</h1>
      <section className="site-hero desktop-only" aria-labelledby="site-hero-h">
        <div className="site-hero-text">
          <p className="site-hero-kicker">{t(locale, "home.title")}</p>
          <h2 id="site-hero-h">{t(locale, "site.hero.title")}</h2>
          <p className="site-hero-lead">{t(locale, "site.hero.lead")}</p>
          <p className="site-hero-actions">
            {/* Only «اقرأ القرآن» here; it opens the surah index (owner, 2026-11-15). Prayer times and the
                radio follow right below the hero. */}
            <Link className="btn btn-hero" href={href(locale, "quran")} data-testid="hero-read">
              <Icon name="quran" size={20} />
              {t(locale, "site.hero.read")}
            </Link>
          </p>
        </div>
        <div className="site-hero-art" aria-hidden="true">
          <MosqueArt />
        </div>
      </section>
      <div className="home-col home-prayer">
        <NextPrayerCard locale={locale} />
      </div>
      <div className="home-col mobile-only" data-testid="home-tiles">
        <Tiles locale={locale} list={BIG} kind="big" />
        <Tiles locale={locale} list={WIDE} kind="wide" />
      </div>
      <div className="home-col">
        {/* Phones: Hajj & Umrah has its own entry. Wide screens: it is the fifth card of the sections below
            (owner, 2026-11-15), so no separate banner there. */}
        <Link className="card home-hajj mobile-only" href={href(locale, "hajj")} data-testid="home-hajj">
          <span className="home-hajj-icon">
            <Icon name="kaaba" size={34} />
          </span>
          <span className="home-hajj-text">
            <strong>{t(locale, "home.hajjBanner")}</strong>
            <span className="muted small">{t(locale, "home.hajjBannerSub")}</span>
          </span>
          <span className="home-more-chevron">
            <Icon name="chevron" size={20} />
          </span>
        </Link>
      </div>
      <section className="home-col home-radio-wrap" id="home-radio" aria-labelledby="home-radio-h">
        <div className="desktop-only home-radio-intro">
          <h2 id="home-radio-h" className="site-section-title">
            {t(locale, "site.radioTitle")}
          </h2>
          <p className="muted">{t(locale, "site.radioLead")}</p>
        </div>
        <QuranRadio locale={locale} />
      </section>
      <Explore locale={locale} />
      <div className="home-col">
        <Link className="card home-more mobile-only" href={href(locale, "more")} data-testid="home-more">
          <Icon name="more" size={26} />
          <strong>{t(locale, "home.mainSections")}</strong>
          <span className="home-more-chevron">
            <Icon name="chevron" size={20} />
          </span>
        </Link>
        <SharePrompt locale={locale} />
      </div>
    </div>
  );
}
