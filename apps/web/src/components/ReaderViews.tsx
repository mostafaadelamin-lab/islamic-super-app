"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahMeta, surahName, type Ref } from "@/lib/pages";
import { NO_BASMALA_BEFORE } from "@/lib/audio";
import { ayahEndMark, renderQuranText } from "@/lib/quran-render";
import { loadTafsirSurah } from "@/lib/tafsir";
import type { MushafData } from "@/lib/mushaf-data";

const key = ([s, a]: Ref): string => `${s}:${a}`;

/** Quran text of one ayah (canonical text, display glyph map only), or null before the text is loaded. */
function ayahText(data: MushafData | null, [s, a]: Ref): string | null {
  return data ? renderQuranText(data.text(s, a)) : null;
}

function Basmala({ data }: { data: MushafData | null }) {
  const text = ayahText(data, [1, 1]);
  return text ? (
    <p className="rd-basmala" lang="ar" dir="rtl">
      {text}
    </p>
  ) : null;
}

/** Surah title band (and basmala, except before al-Fatihah and at-Tawbah) before ayah 1 in the lists. */
function SurahStart({ s, data }: { s: number; data: MushafData | null }) {
  return (
    <div className="rd-surah-start">
      <div className="sura-band rd-band" lang="ar" dir="rtl">
        <span>سورة {surahMeta(s)?.nameAr}</span>
      </div>
      {!NO_BASMALA_BEFORE.includes(s) ? <Basmala data={data} /> : null}
    </div>
  );
}

interface ListProps {
  locale: Locale;
  refs: readonly Ref[];
  data: MushafData | null;
  selected: string | null;
  playing: string | null;
  onSelect: (ref: Ref) => void;
}

/** "الآيات": the ayahs of the current page one by one, large; tap one to listen and read its tafsir. */
export function PageAyahList({ locale, refs, data, selected, playing, onSelect }: ListProps) {
  return (
    <ol className="rd-list" data-testid="ayat-list">
      {refs.map((r) => {
        const k = key(r);
        const text = ayahText(data, r);
        const cls = ["rd-ayah", k === selected ? "selected" : "", k === playing ? "playing" : ""]
          .filter(Boolean)
          .join(" ");
        return (
          <li key={k} className={cls} data-ayah={k} data-testid="ayat-item">
            {r[1] === 1 ? <SurahStart s={r[0]} data={data} /> : null}
            <button type="button" className="rd-ayah-btn" onClick={() => onSelect(r)}>
              <span className="rd-quran" lang="ar" dir="rtl">
                {text ?? "…"} <span className="rd-num">{ayahEndMark(r[1])}</span>
              </span>
              <span className="sr-only">
                {t(locale, "quran.ayahRef", {
                  surah: surahName(r[0], locale),
                  ayah: localizeDigits(r[1], locale),
                })}
              </span>
            </button>
          </li>
        );
      })}
    </ol>
  );
}

type TafsirFiles = Record<number, readonly string[] | "error">;

/** "التفسير": every ayah of the page followed by its Tafsir al-Muyassar entry, verbatim. */
export function PageTafsirList({ locale, refs, data, selected, playing, onSelect }: ListProps) {
  const [files, setFiles] = useState<TafsirFiles>({});
  const surahs = [...new Set(refs.map(([s]) => s))];
  const surahKey = surahs.join(",");
  const [retry, setRetry] = useState(0);
  useEffect(() => {
    let alive = true;
    surahKey
      .split(",")
      .map(Number)
      .forEach((s) => {
        void (async () => {
          try {
            const file = await loadTafsirSurah(s);
            if (alive) setFiles((f) => ({ ...f, [s]: file }));
          } catch {
            if (alive) setFiles((f) => ({ ...f, [s]: "error" }));
          }
        })();
      });
    return () => {
      alive = false;
    };
  }, [surahKey, retry]);
  const failed = surahs.some((s) => files[s] === "error");

  return (
    <div className="rd-tafsir-list" data-testid="tafsir-list">
      {locale === "ar" ? null : <p className="muted small">{t(locale, "tafsir.arabicOnly")}</p>}
      {failed ? (
        <div className="alert alert-error" role="alert">
          <p>{t(locale, "tafsir.error")}</p>
          <button
            type="button"
            className="btn btn-sm"
            onClick={() => {
              setFiles({});
              setRetry((n) => n + 1);
            }}
          >
            {t(locale, "tafsir.retry")}
          </button>
        </div>
      ) : null}
      <ol className="rd-list">
        {refs.map((r) => {
          const k = key(r);
          const file = files[r[0]];
          const entry = Array.isArray(file) ? file[r[1] - 1] : undefined;
          const cls = [
            "rd-ayah",
            "rd-with-tafsir",
            k === selected ? "selected" : "",
            k === playing ? "playing" : "",
          ]
            .filter(Boolean)
            .join(" ");
          return (
            <li key={k} className={cls} data-ayah={k} data-testid="tafsir-item">
              {r[1] === 1 ? <SurahStart s={r[0]} data={data} /> : null}
              <button type="button" className="rd-ayah-btn" onClick={() => onSelect(r)}>
                <span className="rd-quran" lang="ar" dir="rtl">
                  {ayahText(data, r) ?? "…"} <span className="rd-num">{ayahEndMark(r[1])}</span>
                </span>
              </button>
              <p className="rd-tafsir-text" lang="ar" dir="rtl" data-testid="tafsir-item-text">
                {entry ?? (file === "error" ? "" : t(locale, "tafsir.loading"))}
              </p>
            </li>
          );
        })}
      </ol>
      <p className="tafsir-source muted small">{t(locale, "tafsir.source")}</p>
    </div>
  );
}
