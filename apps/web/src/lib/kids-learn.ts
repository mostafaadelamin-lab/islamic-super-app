/**
 * The kids' learning corner (owner 2026-11-20): book shelf, «احفظ حديث» (600 hadith in four levels), adhkar
 * cards and wudu / salah steps. Data: content/kids/dist/kids-learn.v1.json (tools/kids_learn_build.py). The hadith
 * text is copied unchanged from the published book; cards, steps and book pages are the published pages
 * (pictures). Sources: docs/CONTENT_SOURCES.md (never shown on the site). Server pages read this and pass
 * each client component only what it shows.
 */
import learnJson from "@/generated/kids-learn.json";
import type { CardDhikr, HadithLevel, KidsBook } from "@/lib/kids-learn-store";

interface LearnFile {
  booksBase: string;
  shelves: string[];
  books: KidsBook[];
  hadithLevels: HadithLevel[];
  hadith: string[];
  wudu: number[];
  salah: number[];
  stepsCredit: string;
  cardAdhkar: CardDhikr[];
}

export const LEARN = learnJson as unknown as LearnFile;

export const onShelf = (shelf: string): KidsBook[] => LEARN.books.filter((b) => b.shelf === shelf);
export const bookById = (id: number): KidsBook | undefined => LEARN.books.find((b) => b.id === id);
export const shelfKey = (s: string): string => `kidsLearn.shelf${s.charAt(0).toUpperCase()}${s.slice(1)}`;
