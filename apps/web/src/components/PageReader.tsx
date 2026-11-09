"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  useSyncExternalStore,
  type PointerEvent as ReactPointerEvent,
  type CSSProperties,
  type RefObject,
} from "react";
import { dirOf, t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { localizeDigits } from "@/lib/digits";
import { withBase } from "@/lib/base-path";
import { PAGE_COUNT, juzForPage, pageForAyah, surahMeta, type Ref } from "@/lib/pages";
import {
  clampPage,
  fitFontSize,
  isCentredPage,
  pageAyahRefs,
  pageSurahs,
  swipeTarget,
  type ResolvedPage,
} from "@/lib/mushaf";
import { loadMushafData, type MushafData } from "@/lib/mushaf-data";
import { FONT_MAX, FONT_MIN, lastReadStore, prefsStore } from "@/lib/settings";
import { bookmarksStore, isBookmarked, toggleBookmark } from "@/lib/bookmarks";
import { audioStore, itemPage } from "@/lib/audio";
import { player } from "@/lib/audio-player";
import { useStore } from "@/hooks/useStore";
import { KHATMA_DWELL_MS, khatmaStore, markRead } from "@/lib/page-khatma";
import { MushafPage } from "./MushafPage";
import { GoToPage } from "./GoToPage";
import { Icon } from "./Icon";
import { TafsirPanel } from "./TafsirPanel";
import { ReaderPlayer } from "./ReaderPlayer";
import { ReaderIcon } from "./ReaderIcon";
import { KhatmaSheet } from "./KhatmaSheet";
import { PageAyahList, PageTafsirList, SplitRecitation } from "./ReaderViews";
import "./reader.css";

export interface PageReaderProps {
  locale: Locale;
  /** The route's page, resolved at build time (the static HTML works before any data is fetched). */
  initial: ResolvedPage;
}

/** Which page a horizontal arrow key leads to. In RTL the left arrow turns forward, like a printed Mushaf. */
export function arrowTarget(key: string, page: number, dir: "rtl" | "ltr"): number | null {
  let delta = 0;
  if (key === "ArrowLeft") delta = dir === "rtl" ? 1 : -1;
  else if (key === "ArrowRight") delta = dir === "rtl" ? -1 : 1;
  else return null;
  const target = page + delta;
  return target >= 1 && target <= PAGE_COUNT ? target : null;
}

/** Layout constants of the page fit (see useFitFont). */
const FIT = {
  /** A 15-line Madinah line is about this many em wide in Amiri Quran (pages 1–2 and the cap use it). */
  lineEms: 16.2,
  /** Upper bound relative to lineEms, so a page with unusually short lines is not enlarged. */
  capRatio: 0.86,
  lines: 15,
  lineHeight: 1.92,
  /** Height kept below the page (besides the measured dock) when fitting it on a screen. */
  bottomGap: 12,
  minHeight: 360,
  defaultProbe: 20,
  /** Sub-pixel rounding margin so the widest line never overflows. */
  safetyPx: 2,
} as const;
const DRAG_START_PX = 8;
const TURN_MS = 220;
const TILT_DIVISOR = 40;
const REBOUND = 0.35;

/** Sizes the Quran font so the widest line of the page exactly fills the frame (no wrapping, no overflow). */
function useFitFont(pageEl: RefObject<HTMLDivElement | null>, page: number): void {
  const fit = useCallback(() => {
    const el = pageEl.current;
    const frame = el?.parentElement;
    if (!el || !frame) return;
    frame.style.removeProperty("--m-width");
    frame.style.removeProperty("--m-min-h");
    const fs = getComputedStyle(frame);
    const available =
      frame.clientWidth - parseFloat(fs.paddingLeft || "0") - parseFloat(fs.paddingRight || "0");
    const chrome = frame.offsetWidth - available; // borders + padding
    const probe = parseFloat(getComputedStyle(el).fontSize) || FIT.defaultProbe;
    el.classList.add("measuring");
    const widths = isCentredPage(page)
      ? []
      : [...el.querySelectorAll<HTMLElement>(".m-text .m-in")].map((x) => x.getBoundingClientRect().width);
    el.classList.remove("measuring");
    const widestEms = widths.length ? Math.max(...widths) / probe : FIT.lineEms;
    const byWidth = widths.length
      ? fitFontSize(widths, probe, available - FIT.safetyPx)
      : available / FIT.lineEms;
    // Fit between the page's top and the floating player / page slider / bottom bar.
    const top = frame.getBoundingClientRect().top + window.scrollY;
    const dock = document.querySelector<HTMLElement>(".rd-dock")?.offsetHeight ?? 0;
    const frameChrome = frame.offsetHeight - el.offsetHeight;
    const room = Math.max(FIT.minHeight, window.innerHeight - top - dock - frameChrome - FIT.bottomGap);
    // The frame fills the room (pages 1–2 are centred in it, like the printed Mushaf).
    frame.style.setProperty("--m-min-h", `${Math.floor(room + frameChrome)}px`);
    const byHeight =
      room / (Math.max(1, el.querySelectorAll(".m-line").length || FIT.lines) * FIT.lineHeight);
    const size = Math.min(byWidth, byHeight, available / (FIT.lineEms * FIT.capRatio));
    el.style.setProperty("--m-size", `${size.toFixed(2)}px`);
    // When the screen height limits the size, narrow the page (border box) so lines are not stretched.
    if (byHeight < byWidth) {
      const ems = Math.max(widestEms, FIT.lineEms * FIT.capRatio);
      frame.style.setProperty("--m-width", `${Math.ceil(size * ems + chrome + FIT.safetyPx)}px`);
    }
  }, [pageEl, page]);

  useLayoutEffect(() => {
    fit();
    let alive = true;
    // Re-measure once the Quran font is really loaded (fonts.ready alone can resolve before it is requested).
    const fonts = typeof document !== "undefined" ? document.fonts : undefined;
    if (fonts?.load) {
      void (async () => {
        try {
          await fonts.load(`${FIT.defaultProbe}px "Amiri Quran"`);
        } catch {
          // keep the fallback measurement
        }
        if (alive) fit();
      })();
    }
    window.addEventListener("resize", fit);
    return () => {
      alive = false;
      window.removeEventListener("resize", fit);
    };
  }, [fit]);
}

/** Font size steps of the verse and tafsir lists ("حجم الخط"): +4 px, back to the smallest after the largest. */
const FONT_STEP = 4;
export function nextFontSize(size: number): number {
  return size + FONT_STEP > FONT_MAX ? FONT_MIN : size + FONT_STEP;
}

/** The (display) text of an ayah from a resolved page, or null when it is not on that page. */
export function ayahTextOnPage(p: ResolvedPage, [s, a]: Ref): string | null {
  const parts = p.lines
    .flatMap((l) => (l.kind === "text" ? l.segments : []))
    .filter((g) => g.s === s && g.a === a);
  return parts.length ? parts.map((g) => g.text).join(" ") : null;
}

export type ReaderTab = "mushaf" | "ayat" | "tafsir";
const TABS: readonly { id: ReaderTab; key: string }[] = [
  { id: "mushaf", key: "reader.tabMushaf" },
  { id: "ayat", key: "reader.tabAyat" },
  { id: "tafsir", key: "reader.tabTafsir" },
];

interface Gesture {
  x: number;
  y: number;
  t: number;
  active: boolean;
}

export function PageReader({ locale, initial }: PageReaderProps) {
  const router = useRouter();
  const dir = dirOf(locale);
  const [data, setData] = useState<MushafData | null>(null);
  const [view, setView] = useState<ResolvedPage>(initial);
  const page = view.page;
  const [selected, setSelected] = useState<string | null>(null);
  const [slider, setSlider] = useState(initial.page);
  const [notice, setNotice] = useState<string | null>(null);
  const [drag, setDrag] = useState<{ dx: number; anim: boolean }>({ dx: 0, anim: false });
  const [tab, setTab] = useState<ReaderTab>("mushaf");
  const [sheet, setSheet] = useState<"help" | "khatma" | null>(null);
  const dockRef = useRef<HTMLDivElement>(null);
  const pageEl = useRef<HTMLDivElement>(null);
  const sliderRef = useRef<HTMLInputElement>(null);
  const gesture = useRef<Gesture | null>(null);
  const suppressClick = useRef(false);
  const bookmarks = useStore(bookmarksStore);
  const audioPrefs = useStore(audioStore);
  const prefs = useStore(prefsStore);
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const active = ps.status !== "idle";
  const current = active ? (ps.queue[ps.cursor.index] ?? null) : null;
  const playingKey = current?.kind === "ayah" ? `${current.s}:${current.a}` : null;
  const playingBasmala = current?.kind === "basmala" ? current.s : null;

  useFitFont(pageEl, page);

  useEffect(() => {
    let alive = true;
    void (async () => {
      try {
        const d = await loadMushafData();
        if (alive) setData(d);
      } catch {
        // Turning pages falls back to route navigation; the static page is already shown.
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  // Remember the reading position.
  useEffect(() => {
    const first = pageAyahRefs(view)[0];
    if (first) lastReadStore.set({ surah: first[0], ayah: first[1], page: view.page, at: Date.now() });
  }, [view]);

  // An ayah in the URL hash (#a-2-255, from search or bookmarks) is selected on arrival.
  useEffect(() => {
    // Accepts "#a-2-255"; rejects "#a-2" and "#top".
    const m = /^#a-(\d+)-(\d+)$/.exec(window.location.hash);
    if (m) setSelected(`${m[1]}:${m[2]}`);
  }, []);

  const goTo = useCallback(
    (target: number) => {
      const n = clampPage(target);
      if (n === page) return;
      const next = data?.page(n);
      setSelected(null);
      setSlider(n);
      if (next) {
        setView(next);
        window.history.replaceState(window.history.state, "", withBase(href(locale, `page/${n}`)));
      } else {
        router.push(href(locale, `page/${n}`));
      }
    },
    [data, page, locale, router],
  );

  // Follow the recitation onto the next page — only when the recited item changes, so the reader can still
  // browse other pages while listening.
  const followed = useRef<string | null>(null);
  const currentKey = current ? `${current.kind}:${current.s}:${current.a}` : null;
  useEffect(() => {
    if (!current || currentKey === followed.current) return;
    followed.current = currentKey;
    if (!audioPrefs.follow) return;
    const p = itemPage(current);
    if (p !== page) goTo(p);
    // eslint-disable-next-line react-hooks/exhaustive-deps -- runs per recited item, not per page turn
  }, [currentKey]);

  // The fixed dock (player, page slider, bottom bar): publish its height for the sheets and the page fit.
  useEffect(() => {
    const el = dockRef.current;
    if (!el) return;
    const root = document.documentElement;
    const publish = (): void => root.style.setProperty("--rd-dock-h", `${Math.ceil(el.offsetHeight)}px`);
    publish();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(publish);
    ro?.observe(el);
    return () => {
      ro?.disconnect();
      root.style.removeProperty("--rd-dock-h");
    };
  }, []);

  // Khatma: a page counts as read after it has stayed open for a few seconds.
  useEffect(() => {
    if (!khatmaStore.get()) return;
    const id = window.setTimeout(() => khatmaStore.set((k) => markRead(k, page)), KHATMA_DWELL_MS);
    return () => window.clearTimeout(id);
  }, [page]);

  // In the verse and tafsir lists, keep the recited ayah in view.
  useEffect(() => {
    if (tab === "mushaf" || !playingKey) return;
    document
      .querySelector<HTMLElement>(`.rd-list [data-ayah="${playingKey}"]`)
      ?.scrollIntoView?.({ block: "nearest", behavior: "smooth" });
  }, [tab, playingKey]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
      const el = e.target as HTMLElement | null;
      if (el && (el.isContentEditable || ["INPUT", "SELECT", "TEXTAREA"].includes(el.tagName))) return;
      if (e.key === "Escape") {
        setSelected(null);
        return;
      }
      const target = arrowTarget(e.key, page, dir);
      if (target !== null) {
        e.preventDefault();
        goTo(target);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [page, dir, goTo]);

  // The slider commits on release (native "change"), not on every step while dragging.
  useEffect(() => {
    const el = sliderRef.current;
    if (!el) return;
    const onChange = (): void => goTo(Number(el.value));
    el.addEventListener("change", onChange);
    return () => el.removeEventListener("change", onChange);
  }, [goTo]);

  // ---- swipe / drag like a book ----
  const onPointerDown = (e: ReactPointerEvent<HTMLDivElement>): void => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    gesture.current = { x: e.clientX, y: e.clientY, t: performance.now(), active: false };
  };
  const onPointerMove = (e: ReactPointerEvent<HTMLDivElement>): void => {
    const g = gesture.current;
    if (!g) return;
    const dx = e.clientX - g.x;
    const dy = e.clientY - g.y;
    if (!g.active) {
      if (Math.abs(dx) < DRAG_START_PX || Math.abs(dx) < Math.abs(dy)) return;
      g.active = true;
      try {
        e.currentTarget.setPointerCapture(e.pointerId);
      } catch {
        // pointer already released
      }
    }
    setDrag({ dx, anim: false });
  };
  const endGesture = (e: ReactPointerEvent<HTMLDivElement>): void => {
    const g = gesture.current;
    gesture.current = null;
    if (!g?.active) return;
    suppressClick.current = true;
    const dx = e.clientX - g.x;
    const width = e.currentTarget.clientWidth;
    const velocity = dx / Math.max(1, performance.now() - g.t);
    const target = swipeTarget(dx, width, page, dir, velocity);
    if (target === null) {
      setDrag({ dx: 0, anim: true });
      return;
    }
    setDrag({ dx: Math.sign(dx) * width, anim: true });
    window.setTimeout(() => {
      goTo(target);
      setDrag({ dx: -Math.sign(dx) * width * REBOUND, anim: false });
      requestAnimationFrame(() => requestAnimationFrame(() => setDrag({ dx: 0, anim: true })));
    }, TURN_MS);
  };

  const onPageClick = (e: React.MouseEvent<HTMLDivElement>): void => {
    if (suppressClick.current) {
      suppressClick.current = false;
      return;
    }
    const hit = (e.target as HTMLElement).closest<HTMLElement>("[data-ayah]");
    const key = hit?.dataset.ayah ?? null;
    setSelected((cur) => (key && key !== cur ? key : null));
  };

  const name = (s: number): string => {
    const m = surahMeta(s);
    if (!m) return String(s);
    return locale === "ar" ? m.nameAr : m.translit;
  };
  const ref = (s: number, a: number): string =>
    t(locale, "quran.ayahRef", { surah: name(s), ayah: localizeDigits(a, locale) });
  const markerLabel = (s: number, a: number): string => t(locale, "mushaf.ayahActions", { ref: ref(s, a) });
  const surahs = pageSurahs(view);
  const first = pageAyahRefs(view)[0];
  const sel = selected ? (selected.split(":").map(Number) as [number, number]) : null;
  const selBookmarked = sel ? isBookmarked(bookmarks, sel[0], sel[1]) : false;

  // Previous/next ayah from the tafsir panel: move the selection, turning the page when the ayah is on another.
  const selectRef = ([s, a]: Ref): void => {
    const p = pageForAyah(s, a);
    if (p !== page && !data?.page(p)) {
      router.push(`${href(locale, `page/${p}`)}#a-${s}-${a}`);
      return;
    }
    if (p !== page) goTo(p);
    setSelected(`${s}:${a}`);
  };

  const copySelected = async (): Promise<void> => {
    if (!sel) return;
    try {
      const d = data ?? (await loadMushafData());
      await navigator.clipboard.writeText(`${d.text(sel[0], sel[1])} — ${ref(sel[0], sel[1])}`);
      setNotice(t(locale, "mushaf.copied"));
    } catch {
      setNotice(t(locale, "mushaf.copyFailed"));
    }
  };

  const tilt = drag.dx / TILT_DIVISOR;
  const refs = pageAyahRefs(view);
  const recitedAyah: Ref | null = current?.kind === "ayah" ? [current.s, current.a] : null;
  // "Listen with tafsir": while reciting, the Mushaf tab shows the recited ayah and its tafsir in two halves
  // (unless the reader has selected an ayah themselves, whose sheet then wins).
  const split = tab === "mushaf" && audioPrefs.tafsir && active && !sel;
  const playWithTafsir = (s: number, a: number): void => {
    audioStore.set((p) => ({ ...p, tafsir: true }));
    setSelected(null);
    setTab("mushaf");
    player.play({ kind: "from", surah: s, ayah: a });
  };
  const onListSelect = ([s, a]: Ref): void =>
    setSelected((cur) => (cur === `${s}:${a}` ? null : `${s}:${a}`));

  return (
    <div
      className="mushaf-reader rd"
      data-tab={tab}
      data-split={split ? "true" : "false"}
      style={{ "--rd-fs": `${prefs.fontSize}px` } as CSSProperties}
    >
      <div className="rd-top">
        <Link
          className="rd-icon-btn rd-back"
          href={`${href(locale, "quran")}?page=${page}`}
          aria-label={t(locale, "reader.back")}
          data-testid="reader-back"
        >
          <ReaderIcon name="back" />
        </Link>
        <div className="rd-tabs" role="tablist" aria-label={t(locale, "reader.tabs")}>
          {TABS.map((x) => (
            <button
              key={x.id}
              type="button"
              role="tab"
              aria-selected={tab === x.id}
              className="rd-tab"
              data-testid={`tab-${x.id}`}
              onClick={() => setTab(x.id)}
            >
              {t(locale, x.key)}
            </button>
          ))}
        </div>
        {tab === "mushaf" ? (
          <button
            type="button"
            className="rd-icon-btn"
            aria-label={t(locale, "reader.help")}
            aria-expanded={sheet === "help"}
            data-testid="reader-help"
            onClick={() => setSheet((v) => (v === "help" ? null : "help"))}
          >
            <ReaderIcon name="help" />
          </button>
        ) : (
          <button
            type="button"
            className="rd-icon-btn rd-font"
            aria-label={t(locale, "reader.fontSize", { size: localizeDigits(prefs.fontSize, locale) })}
            data-testid="reader-font"
            onClick={() => prefsStore.set((p) => ({ ...p, fontSize: nextFontSize(p.fontSize) }))}
          >
            <span aria-hidden="true">ع</span>
            <span aria-hidden="true" className="rd-font-label">
              {t(locale, "reader.font")}
            </span>
          </button>
        )}
      </div>

      <header className="mushaf-head">
        <span className="mh-surah" data-testid="page-surahs">
          <span className="sr-only">{t(locale, "quran.surahsOnPage")}: </span>
          <span lang="ar">{surahs.map((s) => `سورة ${surahMeta(s)?.nameAr ?? s}`).join(" · ")}</span>
        </span>
        <h1 className="mh-page">
          {t(locale, "quran.pageOf", {
            page: localizeDigits(page, locale),
            total: localizeDigits(PAGE_COUNT, locale),
          })}
        </h1>
        <span className="mh-juz" data-testid="juz">
          {t(locale, "quran.juz", { juz: localizeDigits(juzForPage(page), locale) })}
        </span>
      </header>

      {split ? (
        <SplitRecitation
          locale={locale}
          data={data}
          ayah={recitedAyah}
          basmala={current?.kind === "basmala"}
          fallbackText={recitedAyah ? ayahTextOnPage(view, recitedAyah) : null}
          onShowPage={() => audioStore.set((p) => ({ ...p, tafsir: false }))}
        />
      ) : null}

      <div
        className="mushaf-stage"
        data-testid="mushaf-stage"
        data-ready={data ? "true" : "false"}
        hidden={tab !== "mushaf" || split}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endGesture}
        onPointerCancel={endGesture}
        onClick={onPageClick}
      >
        <div
          className="mushaf-frame"
          data-testid="mushaf-frame"
          style={{
            transform: drag.dx ? `translateX(${drag.dx}px) rotateY(${-tilt}deg)` : undefined,
            transition: drag.anim ? `transform ${TURN_MS}ms ease-out` : "none",
          }}
        >
          <MushafPage
            data={view}
            selected={selected}
            playing={playingKey}
            playingBasmala={playingBasmala}
            markerLabel={markerLabel}
            pageRef={pageEl}
          />
          <div className="mushaf-folio" aria-hidden="true">
            {localizeDigits(page, "ar")}
          </div>
        </div>
      </div>

      {tab === "ayat" ? (
        <section aria-label={t(locale, "reader.ayatOfPage", { page: localizeDigits(page, locale) })}>
          <PageAyahList
            locale={locale}
            refs={refs}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={onListSelect}
          />
        </section>
      ) : null}
      {tab === "tafsir" ? (
        <section aria-label={t(locale, "reader.tafsirOfPage", { page: localizeDigits(page, locale) })}>
          <PageTafsirList
            locale={locale}
            refs={refs}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={onListSelect}
          />
        </section>
      ) : null}

      {sheet === "help" ? (
        <div
          className="ayah-sheet rd-help"
          role="dialog"
          aria-labelledby="rd-help-title"
          data-testid="help-sheet"
        >
          <div className="rd-sheet-head">
            <h2 id="rd-help-title">{t(locale, "reader.helpTitle")}</h2>
            <button
              type="button"
              className="btn btn-sm btn-icon"
              aria-label={t(locale, "common.close")}
              onClick={() => setSheet(null)}
            >
              <Icon name="close" size={16} />
            </button>
          </div>
          <ul>
            <li>{t(locale, "reader.help1")}</li>
            <li>{t(locale, "reader.help2")}</li>
            <li>{t(locale, "reader.help3")}</li>
          </ul>
          <GoToPage locale={locale} />
          {first ? (
            <p className="small">
              <Link href={`${href(locale, `surah/${first[0]}`)}#a-${first[1]}`}>
                {t(locale, "mushaf.listView", { ref: ref(first[0], first[1]) })}
              </Link>
            </p>
          ) : null}
        </div>
      ) : null}
      {sheet === "khatma" ? (
        <KhatmaSheet
          locale={locale}
          onClose={() => setSheet(null)}
          onGo={(p) => {
            setSheet(null);
            goTo(p);
          }}
        />
      ) : null}

      {sel ? (
        <div className="ayah-sheet" data-testid="ayah-sheet">
          <div
            className="ayah-actions"
            role="toolbar"
            aria-label={t(locale, "mushaf.actions")}
            data-testid="ayah-actions"
          >
            <strong className="aa-ref">{ref(sel[0], sel[1])}</strong>
            <div className="aa-buttons">
              <button
                type="button"
                className="btn btn-primary btn-sm"
                data-testid="act-play-ayah"
                onClick={() => player.play({ kind: "ayah", surah: sel[0], ayah: sel[1] })}
              >
                <Icon name="play" size={16} /> {t(locale, "reader.playAyah")}
              </button>
              <button
                type="button"
                className="btn btn-sm"
                data-testid="act-play"
                onClick={() => player.play({ kind: "from", surah: sel[0], ayah: sel[1] })}
              >
                <Icon name="play" size={16} /> {t(locale, "audio.playFromHere")}
              </button>
              <button
                type="button"
                className="btn btn-sm"
                data-testid="act-play-tafsir"
                onClick={() => playWithTafsir(sel[0], sel[1])}
              >
                <ReaderIcon name="split" size={16} /> {t(locale, "reader.playWithTafsir")}
              </button>
              <button
                type="button"
                className="btn btn-sm"
                data-testid="play-surah"
                onClick={() => player.play({ kind: "surah", surah: sel[0] })}
              >
                <Icon name="play" size={16} /> {t(locale, "audio.playSurah", { surah: name(sel[0]) })}
              </button>
              <button
                type="button"
                className="btn btn-sm"
                data-testid="act-bookmark"
                data-bookmarked={selBookmarked}
                onClick={() => bookmarksStore.set((s) => toggleBookmark(s, sel[0], sel[1], Date.now()))}
              >
                <Icon name="bookmark" size={16} />{" "}
                {selBookmarked ? t(locale, "quran.removeBookmark") : t(locale, "quran.bookmark")}
              </button>
              <button
                type="button"
                className="btn btn-sm"
                data-testid="act-copy"
                onClick={() => void copySelected()}
              >
                <Icon name="copy" size={16} /> {t(locale, "mushaf.copy")}
              </button>
              <button
                type="button"
                className="btn btn-sm btn-icon"
                data-testid="act-close"
                aria-label={t(locale, "common.close")}
                onClick={() => setSelected(null)}
              >
                <Icon name="close" size={16} />
              </button>
            </div>
            <p className="aa-notice" role="status" data-testid="mushaf-notice">
              {notice}
            </p>
          </div>
          <TafsirPanel locale={locale} surah={sel[0]} ayah={sel[1]} onStep={selectRef} />
        </div>
      ) : null}

      <div className="rd-dock" ref={dockRef}>
        <ReaderPlayer locale={locale} page={page} />
        <nav className="pager rd-pager" aria-label={t(locale, "quran.pageNav")}>
          <button
            type="button"
            className="rd-icon-btn"
            data-testid="prev-page"
            aria-label={t(locale, "quran.prevPage")}
            disabled={page <= 1}
            onClick={() => goTo(page - 1)}
          >
            <Icon name={locale === "ar" ? "next" : "prev"} size={18} />
          </button>
          <label className="page-slider rd-slider">
            <span className="sr-only">{t(locale, "mushaf.slider")}</span>
            <input
              ref={sliderRef}
              type="range"
              min={1}
              max={PAGE_COUNT}
              step={1}
              dir="rtl"
              value={slider}
              data-testid="page-slider"
              aria-valuetext={t(locale, "quran.page", { page: localizeDigits(slider, locale) })}
              onChange={(e) => setSlider(Number(e.target.value))}
            />
            <output data-testid="slider-value">{localizeDigits(slider, locale)}</output>
          </label>
          <button
            type="button"
            className="rd-icon-btn"
            data-testid="next-page"
            aria-label={t(locale, "quran.nextPage")}
            disabled={page >= PAGE_COUNT}
            onClick={() => goTo(page + 1)}
          >
            <Icon name={locale === "ar" ? "prev" : "next"} size={18} />
          </button>
        </nav>
        <nav className="rd-bar" aria-label={t(locale, "reader.bottomNav")}>
          <Link href={`${href(locale, "quran")}?page=${page}`} data-testid="bar-index">
            <ReaderIcon name="list" />
            <span>{t(locale, "reader.index")}</span>
          </Link>
          <Link href={href(locale, "bookmarks")} data-testid="bar-bookmarks">
            <ReaderIcon name="bookmarks" />
            <span>{t(locale, "reader.bookmarks")}</span>
          </Link>
          <button
            type="button"
            data-testid="bar-khatma"
            aria-expanded={sheet === "khatma"}
            onClick={() => setSheet((v) => (v === "khatma" ? null : "khatma"))}
          >
            <ReaderIcon name="khatma" />
            <span>{t(locale, "reader.khatma")}</span>
          </button>
          <Link href={href(locale, "search")} data-testid="bar-search">
            <ReaderIcon name="search" />
            <span>{t(locale, "reader.search")}</span>
          </Link>
        </nav>
      </div>
    </div>
  );
}
