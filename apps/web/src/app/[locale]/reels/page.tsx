import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { VideosHub } from "@/components/VideosHub";
import { VideoSearch } from "@/components/VideoSearch";
import { ParentGate } from "@/components/ParentGate";

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "reels.title") };
}

export default async function ReelsPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  return (
    <>
      <h1>{t(locale, "reels.title")}</h1>
      <ParentGate locale={locale}>
        <VideoSearch locale={locale}>
          <VideosHub locale={locale} />
        </VideoSearch>
      </ParentGate>
    </>
  );
}
