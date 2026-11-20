import type { Metadata } from "next";
import Link from "next/link";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { withBase } from "@/lib/base-path";
import { localizeDigits } from "@/lib/digits";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { LEARN, onShelf, shelfKey } from "@/lib/kids-learn";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "kidsLearn.books") };
}

/** «مكتبة كتب الأطفال»: shelves of covers; a book opens page by page. */
export default async function KidsBooksPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <nav className="crumbs">
        <Link href={href(locale, "kids")}>{t(locale, "kids.back")}</Link>
      </nav>
      <h1>{t(locale, "kidsLearn.books")}</h1>
      <p className="muted">{t(locale, "kidsLearn.booksNote")}</p>
      <div data-testid="kids-books">
        {LEARN.shelves.map((s) => (
          <section key={s} data-testid={`kids-shelf-${s}`}>
            <h2 className="section-title">{t(locale, shelfKey(s))}</h2>
            <ul className="kl-shelf">
              {onShelf(s).map((b) => (
                <li key={b.id}>
                  <Link
                    className="kl-book"
                    href={href(locale, `kids/books/${b.id}`)}
                    data-testid={`kids-book-${b.id}`}
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element -- static export: no image optimiser */}
                    <img src={withBase(`/kids/covers/${b.id}.webp`)} alt="" loading="lazy" />
                    <span>{b.title}</span>
                    <span className="muted small">
                      {t(locale, "kidsLearn.pages", { n: localizeDigits(b.pages, locale) })}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
    </>
  );
}
