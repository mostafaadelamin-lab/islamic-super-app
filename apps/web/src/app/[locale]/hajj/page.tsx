import type { Metadata } from "next";
import Link from "next/link";
import hajj from "@/generated/hajj.json";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { Icon } from "@/components/Icon";
import { OfficialHajjGuide } from "@/components/OfficialHajjGuide";
import { HajjServices } from "@/components/HajjServices";
import { DuaText } from "@/components/DuaText";
import { KIND_TITLE, PILGRIMAGE_KINDS } from "@/components/HajjGuide";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "hajj.title") };
}

/** Hajj & Umrah guide from content/pilgrimage/source-hajj.js (Arabic). Religious review is pending. */
export default async function HajjPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const tawaf = hajj.umrah.steps.findIndex((s) => s.tool === "tawaf");
  return (
    <>
      <h1>{t(locale, "hajj.title")}</h1>
      {locale !== "ar" ? <p className="alert">{t(locale, "common.arabicOnly")}</p> : null}
      {/* One page per kind (owner 2026-11-15): pick Umrah or a kind of Hajj, then go step by step. */}
      <nav className="hajj-kinds" aria-label={t(locale, "hajj.contents")} data-testid="hajj-kinds">
        {PILGRIMAGE_KINDS.map((k) => (
          <Link
            key={k}
            className="card hajj-kind"
            href={href(locale, `hajj/${k}`)}
            data-testid={`hajj-kind-${k}`}
          >
            <span className="hajj-kind-icon">
              <Icon name="kaaba" size={28} />
            </span>
            <span>
              <strong>{t(locale, KIND_TITLE[k])}</strong>
              <span className="muted small">
                {t(locale, k === "umrah" ? "nav.hajjUmrahSub" : "nav.hajjTypeSub")}
              </span>
            </span>
            <span className="home-more-chevron">
              <Icon name="chevron" size={20} />
            </span>
          </Link>
        ))}
      </nav>
      <HajjServices
        locale={locale}
        tawafHref={tawaf < 0 ? null : `${href(locale, "hajj/umrah")}#umrah-step-${tawaf + 1}`}
      />
      <section className="card">
        <h3 lang="ar">{hajj.hajj.typesTitle}</h3>
        <dl lang="ar">
          {hajj.hajj.types.map((x) => (
            <div key={x.name}>
              <dt>{x.name}</dt>
              <dd>
                <DuaText text={x.body} />
              </dd>
            </div>
          ))}
        </dl>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.hajj.pillars.title}</h3>
        <p lang="ar">{hajj.hajj.pillars.body}</p>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.madinah.title}</h3>
        <ul lang="ar">
          {hajj.madinah.points.map((p, i) => (
            <li key={i}>
              <DuaText text={p} />
            </li>
          ))}
        </ul>
      </section>
      <OfficialHajjGuide locale={locale} />

      <h2 id="ihram">{t(locale, "hajj.ihram")}</h2>
      <section className="card">
        <h3 lang="ar">{hajj.ihram.miqatTitle}</h3>
        <dl lang="ar">
          {hajj.ihram.miqat.map((x) => (
            <div key={x.name}>
              <dt>{x.name}</dt>
              <dd>
                <DuaText text={x.body} />
              </dd>
            </div>
          ))}
        </dl>
        <p className="muted" lang="ar">
          {hajj.ihram.miqatNote}
        </p>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.ihram.prohibitionsTitle}</h3>
        <ul lang="ar">
          {hajj.ihram.prohibitions.map((p, i) => (
            <li key={i}>
              <DuaText text={p} />
            </li>
          ))}
        </ul>
        <p className="muted" lang="ar">
          {hajj.ihram.prohibitionsNote}
        </p>
      </section>
      <section className="card">
        <h3 lang="ar">{hajj.talbiya.title}</h3>
        <p className="dua" lang="ar">
          {hajj.talbiya.text}
        </p>
      </section>
      <p className="muted small">{t(locale, "hajj.source")}</p>
    </>
  );
}
