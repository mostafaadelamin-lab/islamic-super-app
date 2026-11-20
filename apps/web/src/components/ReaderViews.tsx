"use client";
import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent, type RefObject } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { JUZ, PAGE_COUNT, ayahsOnPage, juzRefs, surahMeta, surahName, type Ref } from "@/lib/pages";
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

/** "الصفحة السابقة / التالية" under the ayah lists, so the reader never has to go back to the Mushaf page. */
export function PageButtons({
  locale,
  page,
  onPage,
}: {
  locale: Locale;
  page: number;
  onPage: (p: number) => void;
}) {
  return (
    <div className="rd-page-btns" data-testid="list-page-buttons">
      <button
        type="button"
        className="btn"
        data-testid="list-prev-page"
        disabled={page <= 1}
        onClick={() => onPage(page - 1)}
      >
        {t(locale, "reader.prevPage")}
      </button>
      <button
        type="button"
        className="btn btn-primary"
        data-testid="list-next-page"
        disabled={page >= PAGE_COUNT}
        onClick={() => onPage(page + 1)}
      >
        {t(locale, "reader.nextPage")}
      </button>
    </div>
  );
}

/**
 * A horizontal swipe on the lists turns the page like the Mushaf: in Arabic a swipe from left to right goes to
 * the next page. Vertical scrolling is left alone.
 */
export function usePageSwipe(page: number, dir: "rtl" | "ltr", onPage: (p: number) => void) {
  const start = useRef<{ x: number; y: number; t: number } | null>(null);
  return {
    onPointerDown: (e: ReactPointerEvent<HTMLElement>) => {
      if (e.pointerType === "mouse") return;
      start.current = { x: e.clientX, y: e.clientY, t: performance.now() };
    },
    onPointerUp: (e: ReactPointerEvent<HTMLElement>) => {
      const g = start.current;
      start.current = null;
      if (!g) return;
      const dx = e.clientX - g.x;
      const dy = e.clientY - g.y;
      if (Math.abs(dx) < 70 || Math.abs(dx) < Math.abs(dy) * 1.5) return;
      const forward = dir === "rtl" ? dx > 0 : dx < 0;
      const target = page + (forward ? 1 : -1);
      if (target >= 1 && target <= PAGE_COUNT) onPage(target);
    },
    onPointerCancel: () => {
      start.current = null;
    },
  };
}

/** Scrolls [el] to the top of its own scrolling half (the surah / juz beside the tafsir), else the window. */
function scrollFlowTo(el: Element): void {
  const pane = el.closest<HTMLElement>(".rd-flow-pane");
  if (pane && pane.scrollHeight > pane.clientHeight) {
    const y = el.getBoundingClientRect().top - pane.getBoundingClientRect().top + pane.scrollTop;
    pane.scrollTo?.({ top: Math.max(0, y - 40) });
    return;
  }
  window.scrollBy({ top: el.getBoundingClientRect().top - 140 });
}

/** The ayahs [refs] as one flowing text on the Mushaf paper (a surah band before every ayah 1). */
function FlowText({
  refs,
  data,
  selected,
  playing,
  onSelect,
  bands,
}: {
  refs: readonly Ref[];
  data: MushafData | null;
  selected: string | null;
  playing: string | null;
  onSelect: (ref: Ref) => void;
  /** Surah bands inside the text (the juz view); the surah view draws its own band above. */
  bands: boolean;
}) {
  // Split into runs, one per surah, so a surah band can sit between them.
  const runs: Ref[][] = [];
  for (const r of refs) {
    const last = runs[runs.length - 1];
    if (last && last[0]![0] === r[0]) last.push(r);
    else runs.push([r]);
  }
  return (
    <>
      {runs.map((run) => (
        <div key={key(run[0]!)} className="rd-flow-run">
          {bands && run[0]![1] === 1 ? <SurahStart s={run[0]![0]} data={data} /> : null}
          <p className="rd-flow" lang="ar" dir="rtl">
            {run.map((r) => {
              const k = key(r);
              const cls = ["seg", k === selected ? "selected" : "", k === playing ? "playing" : ""]
                .filter(Boolean)
                .join(" ");
              return (
                <span key={k}>
                  <span
                    className={cls}
                    data-ayah={k}
                    data-testid="flow-ayah"
                    role="button"
                    tabIndex={0}
                    onClick={() => onSelect(r)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") onSelect(r);
                    }}
                  >
                    {ayahText(data, r) ?? "…"}
                  </span>{" "}
                  <span className="rd-num">{ayahEndMark(r[1])}</span>{" "}
                </span>
              );
            })}
          </p>
        </div>
      ))}
    </>
  );
}

/** Opens a flow view at the reader's page (once per surah / juz), so the place being read stays in view. */
function useOpenAtPage(
  box: RefObject<HTMLDivElement | null>,
  id: string,
  page: number,
  data: MushafData | null,
  inView: (r: Ref) => boolean,
): void {
  const opened = useRef<string | null>(null);
  useEffect(() => {
    if (!data || opened.current === id) return;
    opened.current = id;
    const first = ayahsOnPage(page).find(inView);
    if (!first) return;
    const el = box.current?.querySelector(`[data-ayah="${key(first)}"]`);
    if (el && el !== box.current?.querySelector("[data-ayah]")) scrollFlowTo(el);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data, id, page]);
}

interface SurahFlowProps {
  locale: Locale;
  surah: number;
  /** The Mushaf page the reader is on: the view opens at its first ayah of the surah. */
  page: number;
  data: MushafData | null;
  selected: string | null;
  playing: string | null;
  onSelect: (ref: Ref) => void;
  onSurah: (s: number) => void;
}

/**
 * "السورة كاملة" (owner 2026-11-17): the whole surah as one flowing text on the Mushaf paper, read by scrolling.
 * Every ayah is the canonical KFGQPC text (only the display glyph map is applied), closed by its number.
 */
export function SurahFlow({
  locale,
  surah,
  page,
  data,
  selected,
  playing,
  onSelect,
  onSurah,
}: SurahFlowProps) {
  const meta = surahMeta(surah);
  const count = meta?.ayahCount ?? 0;
  const box = useRef<HTMLDivElement>(null);
  const refs: Ref[] = Array.from({ length: count }, (_, i) => [surah, i + 1]);
  useOpenAtPage(box, `s${surah}`, page, data, ([s]) => s === surah);
  return (
    <div className="rd-surah-flow" data-testid="surah-flow" data-surah={surah} ref={box}>
      <SurahStart s={surah} data={data} />
      <FlowText
        refs={refs}
        data={data}
        selected={selected}
        playing={playing}
        onSelect={onSelect}
        bands={false}
      />
      <div className="rd-page-btns">
        <button
          type="button"
          className="btn"
          data-testid="flow-prev-surah"
          disabled={surah <= 1}
          onClick={() => onSurah(surah - 1)}
        >
          {t(locale, "reader.prevSurah")}
        </button>
        <button
          type="button"
          className="btn btn-primary"
          data-testid="flow-next-surah"
          disabled={surah >= 114}
          onClick={() => onSurah(surah + 1)}
        >
          {t(locale, "reader.nextSurah")}
        </button>
      </div>
    </div>
  );
}

interface JuzFlowProps {
  locale: Locale;
  juz: number;
  page: number;
  data: MushafData | null;
  selected: string | null;
  playing: string | null;
  onSelect: (ref: Ref) => void;
  onJuz: (j: number) => void;
}

/**
 * «الجزء كاملاً» (owner 2026-11-20): one juz as one flowing text, surah after surah, read by scrolling, with a
 * juz picker above and the previous / next juz below. Same canonical text as the whole-surah view.
 */
export function JuzFlow({ locale, juz, page, data, selected, playing, onSelect, onJuz }: JuzFlowProps) {
  const box = useRef<HTMLDivElement>(null);
  const refs = juzRefs(juz);
  const inJuz = new Set(refs.map(key));
  useOpenAtPage(box, `j${juz}`, page, data, (r) => inJuz.has(key(r)));
  const ordinals = t(locale, "quran.juzOrdinals").split("|");
  const title = (j: number): string => t(locale, "quran.juzTitle", { ordinal: ordinals[j - 1] ?? String(j) });
  return (
    <div className="rd-surah-flow rd-juz-flow" data-testid="juz-flow" data-juz={juz} ref={box}>
      <div className="rd-juz-head">
        <label className="rd-juz-pick">
          <span className="sr-only">{t(locale, "reader.pickJuz")}</span>
          <select
            value={juz}
            data-testid="juz-pick"
            aria-label={t(locale, "reader.pickJuz")}
            onChange={(e) => onJuz(Number(e.target.value))}
          >
            {JUZ.map((z) => (
              <option key={z.juz} value={z.juz}>
                {title(z.juz)}
              </option>
            ))}
          </select>
        </label>
      </div>
      {refs[0] && refs[0][1] !== 1 ? (
        <p className="rd-juz-from muted small" lang={locale === "ar" ? "ar" : undefined}>
          {t(locale, "quran.surahTitle", { name: surahName(refs[0][0], locale) })}
        </p>
      ) : null}
      <FlowText refs={refs} data={data} selected={selected} playing={playing} onSelect={onSelect} bands />
      <div className="rd-page-btns">
        <button
          type="button"
          className="btn"
          data-testid="flow-prev-juz"
          disabled={juz <= 1}
          onClick={() => onJuz(juz - 1)}
        >
          {t(locale, "reader.prevJuz")}
        </button>
        <button
          type="button"
          className="btn btn-primary"
          data-testid="flow-next-juz"
          disabled={juz >= 30}
          onClick={() => onJuz(juz + 1)}
        >
          {t(locale, "reader.nextJuz")}
        </button>
      </div>
    </div>
  );
}
