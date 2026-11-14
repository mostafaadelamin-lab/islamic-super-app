import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { bookName, HADITH, HADITH_BOOKS } from "@/lib/hadith";
import { HadithFavourites } from "@/components/HadithReader";
import { Icon } from "@/components/Icon";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "hadith.title") };
}

export default async function HadithPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "hadith.title")}</h1>
      <ul className="tiles" data-testid="hadith-books">
        {HADITH_BOOKS.map((b) => (
          <li key={b.id}>
            <Link className="tile" href={href(locale, `hadith/${b.id}`)} data-testid={`hadith-book-${b.id}`}>
              <span className="tile-icon">
                <Icon name="book" />
              </span>
              <span className="tile-text">
                <strong>{bookName(b, locale)}</strong>
                <span className="muted small">
                  {t(locale, "hadith.count", { count: localizeDigits(b.count, locale) })}
                </span>
              </span>
            </Link>
          </li>
        ))}
      </ul>
      <section className="card" aria-labelledby="hadith-fav-h">
        <h2 id="hadith-fav-h" className="card-title">
          {t(locale, "hadith.favourites")}
        </h2>
        <HadithFavourites locale={locale} />
      </section>
      <p className="small muted" data-testid="hadith-attribution">
        {t(locale, "hadith.attribution", { numbering: t(locale, "hadith.numbering") })}{" "}
        <a href={HADITH.source.url} rel="noopener" target="_blank">
          {HADITH.source.name}
        </a>{" "}
        ({HADITH.source.licence})
      </p>
    </>
  );
}
