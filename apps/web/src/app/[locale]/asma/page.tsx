import type { Metadata } from "next";
import asma from "@/generated/asma.json";
import asmaAudio from "@/generated/asma-audio.json";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { AsmaView, type AsmaName } from "@/components/AsmaView";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "asma.title") };
}

interface RawName {
  name: string;
  group?: string | null;
  text?: string | null;
  seeAlso?: string | null;
}

export default async function AsmaPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const raw = (asma as { names: RawName[] }).names;
  const lessons = (asmaAudio as { names: Record<string, string[]> }).names;
  const byName = new Map(raw.map((n) => [n.name, n]));
  const names: AsmaName[] = raw.map((n, i) => {
    const target = !n.text && n.seeAlso ? byName.get(n.seeAlso) : undefined;
    return {
      name: n.name,
      group: n.group && n.group !== n.name ? n.group : null,
      text: n.text ?? target?.text ?? "",
      seeAlso: target ? target.name : null,
      lessons: lessons[String(i)] ?? [],
    };
  });
  return (
    <>
      <h1>{t(locale, "asma.title")}</h1>
      <AsmaView locale={locale} names={names} />
    </>
  );
}
