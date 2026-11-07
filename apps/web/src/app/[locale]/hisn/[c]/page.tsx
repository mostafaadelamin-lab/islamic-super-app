import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { HISN, hisnChapter } from "@/lib/hisn";

export const dynamicParams = false;

type Params = Promise<{ locale: string; c: string }>;

export function generateStaticParams(): { c: string }[] {
  return HISN.map((ch) => ({ c: String(ch.id) }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { c } = await params;
  return { title: hisnChapter(Number(c))?.title ?? c };
}

export default async function HisnChapterPage({ params }: { params: Params }) {
  const { locale, c } = await params;
  const id = Number(c);
  const ch = hisnChapter(id);
  if (!isLocale(locale) || !ch || String(id) !== c) notFound();
  return (
    <>
      <p className="crumbs">
        <Link href={href(locale, "hisn")}>{t(locale, "hisn.title")}</Link>
      </p>
      <h1 lang="ar">{ch.title}</h1>
      <ol className="dhikr-list" data-testid="hisn-items">
        {ch.items.map((x, i) => (
          <li key={i} className="dhikr">
            <p className="dhikr-text" lang="ar" dir="rtl">
              {x}
            </p>
          </li>
        ))}
      </ol>
      <nav className="pager" aria-label={t(locale, "hisn.chapterNav")}>
        {id > 1 ? (
          <Link className="btn" href={href(locale, `hisn/${id - 1}`)} data-testid="hisn-prev">
            {t(locale, "hisn.prev")}
          </Link>
        ) : (
          <span />
        )}
        <span className="muted small">
          {localizeDigits(id, locale)} / {localizeDigits(HISN.length, locale)}
        </span>
        {id < HISN.length ? (
          <Link className="btn btn-primary" href={href(locale, `hisn/${id + 1}`)} data-testid="hisn-next">
            {t(locale, "hisn.next")}
          </Link>
        ) : (
          <span />
        )}
      </nav>
    </>
  );
}
