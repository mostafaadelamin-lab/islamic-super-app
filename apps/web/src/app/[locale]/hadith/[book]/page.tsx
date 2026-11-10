import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { bookName, hadithBook, HADITH_BOOKS } from "@/lib/hadith";
import { HadithReader } from "@/components/HadithReader";

export const dynamicParams = false;

type Params = Promise<{ locale: string; book: string }>;

export function generateStaticParams(): { book: string }[] {
  return HADITH_BOOKS.map((b) => ({ book: b.id }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { locale, book } = await params;
  const b = hadithBook(book);
  return { title: b ? bookName(b, isLocale(locale) ? locale : "ar") : book };
}

export default async function HadithBookPage({ params }: { params: Params }) {
  const { locale, book } = await params;
  const b = hadithBook(book);
  if (!isLocale(locale) || !b) notFound();
  return (
    <>
      <p className="crumbs">
        <Link href={href(locale, "hadith")}>{t(locale, "hadith.title")}</Link>
      </p>
      <h1>{bookName(b, locale)}</h1>
      <HadithReader locale={locale} bookId={b.id} />
    </>
  );
}
