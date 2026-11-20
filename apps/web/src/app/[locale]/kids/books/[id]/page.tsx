import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale, t } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { LEARN, bookById } from "@/lib/kids-learn";
import { KidsBookReader } from "@/components/KidsLearn";

export const dynamicParams = false;

type Params = Promise<{ locale: string; id: string }>;

export function generateStaticParams(): { id: string }[] {
  return LEARN.books.map((b) => ({ id: String(b.id) }));
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const { id } = await params;
  return { title: bookById(Number(id))?.title ?? "" };
}

/** One kids' book, page by page (pictures of the published pages). */
export default async function KidsBookPage({ params }: { params: Params }) {
  const { locale, id } = await params;
  const book = bookById(Number(id));
  if (!isLocale(locale) || !book) notFound();
  return (
    <>
      <nav className="crumbs">
        <Link href={href(locale, "kids/books")}>{t(locale, "kidsLearn.back")}</Link>
      </nav>
      <h1>{book.title}</h1>
      <KidsBookReader locale={locale} book={book} base={LEARN.booksBase} />
    </>
  );
}
