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
  type ReactNode,
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
import { shareAyahImage } from "@/lib/ayah-image";
import { TafsirPanel } from "./TafsirPanel";
import { ReaderPlayer } from "./ReaderPlayer";
import { ReaderIcon } from "./ReaderIcon";
import { KhatmaSheet } from "./KhatmaSheet";
import { PageAyahList, PageButtons, PageTafsirList, SurahFlow, usePageSwipe } from "./ReaderViews";
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
  /** A 15-line Madinah line is about this many em wide in the KFGQPC HAFS v18 font (median of the 1441H lines; pages 1–2 and the cap use it). */
  lineEms: 15.6,
  /** Upper bound relative to lineEms, so a page with unusually short lines is not enlarged. */
  capRatio: 0.86,
  lines: 15,
  lineHeight: 1.92,
  /** Height kept below the page (besides the measured dock) when fitting it on a screen. */
  bottomGap: 12,
  minHeight: 360,
  /** Height of the selected ayah's actions row in the wide strip (reader.css .rd-actions, wide). */
  actionsRow: 72,
  /** Wide listen-with-tafsir: the page may be this much taller than its column (it scrolls there)… */
  duoScroll: 1.4,
  /** …and take at most this share of the reader's width. */
  duoShare: 0.55,
  defaultProbe: 20,
  /** Sub-pixel rounding margin so the widest line never overflows. */
  safetyPx: 2,
} as const;
/**
 * Wide screens (laptops, tablets sideways): the page takes the full width and the player, page slider and
 * tools sit in one low band under it. Same query as reader.css.
 */
export const SIDE_PANEL_QUERY = "(min-width: 1024px) and (min-height: 560px) and (orientation: landscape)";
/** True on wide screens (SIDE_PANEL_QUERY); follows window resizes. */
function useWide(): boolean {
  const [wide, setWide] = useState(false);
  useEffect(() => {
    if (typeof window.matchMedia !== "function") return;
    const mq = window.matchMedia(SIDE_PANEL_QUERY);
    const on = (): void => setWide(mq.matches);
    on();
    mq.addEventListener?.("change", on);
    return () => mq.removeEventListener?.("change", on);
  }, []);
  return wide;
}
/** How many times the full-screen hint (how to turn pages, how to show the controls) is shown. */
const HINT_SHOWS = 3;
const HINT_KEY = "rattil.readerHint";
/** Set once the first-open guide to the Mushaf's touches was closed. */
const GUIDE_KEY = "rattil.readerGuide";
const HINT_MS = 7000;
const DRAG_START_PX = 8;
const TURN_MS = 220;
/** Pinch zoom of the page: up to 3×; letting go under 108% goes back to 100%. */
const ZOOM_MAX = 3;
const ZOOM_SNAP = 1.08;

/** Sizes the Quran font so the widest line of the page exactly fills the frame (no wrapping, no overflow). */
function useFitFont(pageEl: RefObject<HTMLDivElement | null>, page: number, full = false, layout = ""): void {
  const measure = useCallback(() => {
    const el = pageEl.current;
    const frame = el?.parentElement;
    if (!el || !frame) return;
    frame.style.removeProperty("--m-width");
    frame.style.removeProperty("--m-min-h");
    el.style.removeProperty("--m-lh");
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
    // Full screen on a phone turned sideways: the lines take the whole width and the page scrolls down.
    // ... and on a phone listening with tafsir, where the page sits in the top half and scrolls there.
    // Wide "listen with tafsir": the page takes as much of its half as it can, a little taller than the column
    // (it scrolls there and follows the recitation), and the tafsir takes the rest of the width.
    const root = frame.closest<HTMLElement>(".mushaf-reader");
    const stage = frame.closest<HTMLElement>(".mushaf-stage");
    if (layout === "duo-wide" && root && stage) {
      const frameChrome = frame.offsetHeight - el.offsetHeight;
      const lines = Math.max(1, el.querySelectorAll(".m-line").length || FIT.lines);
      const byRoom = ((stage.clientHeight - frameChrome) / (lines * FIT.lineHeight)) * FIT.duoScroll;
      const col = root.clientWidth * FIT.duoShare - chrome - FIT.safetyPx;
      const byCol = widths.length ? fitFontSize(widths, probe, col) : col / FIT.lineEms;
      const size = Math.min(byCol, byRoom, col / (FIT.lineEms * FIT.capRatio));
      const ems = Math.max(widestEms, FIT.lineEms * FIT.capRatio);
      el.style.setProperty("--m-size", `${size.toFixed(2)}px`);
      root.style.setProperty("--duo-w", `${Math.ceil(size * ems + chrome + FIT.safetyPx)}px`);
      return;
    }
    root?.style.removeProperty("--duo-w");
    if ((full && isLandscapePhone()) || layout === "duo") {
      el.style.setProperty(
        "--m-size",
        `${Math.min(byWidth, available / (FIT.lineEms * FIT.capRatio)).toFixed(2)}px`,
      );
      return;
    }
    // Fit between the page's top and the floating player / page slider / bottom bar.
    const top = frame.getBoundingClientRect().top + window.scrollY;
    // The dock floats a little above the bottom edge on wide screens, so measure where it starts.
    const dockEl = document.querySelector<HTMLElement>(".rd-dock");
    // The selected ayah's actions open as the first row of the strip. On wide screens their row is always
    // kept free above the strip, so the page neither shrinks nor gets covered when an ayah is chosen
    // (owner 2026-11-15); elsewhere they open over the strip without resizing the page.
    const actions = dockEl?.querySelector<HTMLElement>(".rd-actions")?.offsetHeight ?? 0;
    const reserve = !full && window.matchMedia?.(SIDE_PANEL_QUERY).matches ? FIT.actionsRow : 0;
    const dockTop =
      dockEl && dockEl.offsetHeight > 0
        ? dockEl.getBoundingClientRect().top + actions - reserve
        : window.innerHeight;
    const frameChrome = frame.offsetHeight - el.offsetHeight;
    const room = Math.max(FIT.minHeight, dockTop + window.scrollY - top - frameChrome - FIT.bottomGap);
    // The frame fills the room (pages 1–2 are centred in it, like the printed Mushaf).
    frame.style.setProperty("--m-min-h", `${Math.floor(room + frameChrome)}px`);
    const byHeight =
      room / (Math.max(1, el.querySelectorAll(".m-line").length || FIT.lines) * FIT.lineHeight);
    let size = Math.min(byWidth, byHeight, available / (FIT.lineEms * FIT.capRatio));
    el.style.setProperty("--m-size", `${size.toFixed(2)}px`);
    // Pages 1–2 (few centred lines under a tall surah band) can still come out taller than the room: shrink to fit.
    const tall = el.offsetHeight;
    if (tall > room + 1) {
      size = (size * room) / tall;
      el.style.setProperty("--m-size", `${size.toFixed(2)}px`);
    }
    // Full screen: when the width limits the size, spread the 15 lines over the whole height (like the printed page).
    const lineCount = el.querySelectorAll(".m-line").length;
    if (full && !isCentredPage(page) && byHeight > size && lineCount) {
      el.style.setProperty("--m-lh", (room / (lineCount * size)).toFixed(3));
    }
    // When the screen height limits the size, narrow the page (border box) so lines are not stretched.
    if (byHeight < byWidth) {
      const ems = Math.max(widestEms, FIT.lineEms * FIT.capRatio);
      frame.style.setProperty("--m-width", `${Math.ceil(size * ems + chrome + FIT.safetyPx)}px`);
    }
    // layout only marks a change of the page's width
  }, [pageEl, page, full, layout]);
  // Measure at 100%: the reader's own pinch zoom (a scale on the frame) is lifted while measuring.
  const fit = useCallback(() => {
    const frame = pageEl.current?.parentElement;
    const scaled = frame?.style.transform.startsWith("scale(") ? frame.style.transform : "";
    if (frame && scaled) frame.style.transform = "";
    try {
      measure();
    } finally {
      if (frame && scaled) frame.style.transform = scaled;
    }
  }, [pageEl, measure]);

  useLayoutEffect(() => {
    fit();
    let alive = true;
    // Re-measure once the Quran font is really loaded (fonts.ready alone can resolve before it is requested).
    const fonts = typeof document !== "undefined" ? document.fonts : undefined;
    if (fonts?.load) {
      void (async () => {
        try {
          await fonts.load(`${FIT.defaultProbe}px "KFGQPC HAFS Uthmanic Script"`);
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

/** A phone held sideways: wider than tall and short (tablets and desktops keep the whole page on screen). */
export const LANDSCAPE_MAX_HEIGHT = 600;
export function isLandscapePhone(w = window.innerWidth, h = window.innerHeight): boolean {
  return w > h && h <= LANDSCAPE_MAX_HEIGHT;
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

export type ReaderTab = "mushaf" | "surah" | "ayat" | "tafsir";
const TABS: readonly { id: ReaderTab; key: string }[] = [
  { id: "mushaf", key: "reader.tabMushaf" },
  { id: "surah", key: "reader.tabSurah" },
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
  // Simple ayah menu: the ways to listen and the tafsir stay folded until asked for.
  const [listenOpen, setListenOpen] = useState(false);
  const [showTafsir, setShowTafsir] = useState(false);
  useEffect(() => {
    setListenOpen(false);
    if (!selected) setShowTafsir(false);
  }, [selected]);
  const [drag, setDrag] = useState<{ dx: number; anim: boolean }>({ dx: 0, anim: false });
  const [tab, setTabState] = useState<ReaderTab>("mushaf");
  // "السورة كاملة": the surah picked with its buttons; otherwise the selected ayah's, else the page's first.
  const [flowSurah, setFlowSurah] = useState<number | null>(null);
  const setTab = (next: ReaderTab): void => {
    setTabState(next);
    setFlowSurah(null);
  };
  const [sheet, setSheet] = useState<"help" | "khatma" | null>(null);
  // Full screen only from its own button, and back with the exit button (owner 2026-11-15: one tap to
  // full screen, another to shrink, a long press for options was confusing). A tap on an ayah opens its row.
  const [chrome, setChrome] = useState(true);
  const [hint, setHint] = useState(false);
  const [guide, setGuide] = useState(false);
  const dockRef = useRef<HTMLDivElement>(null);
  const pageEl = useRef<HTMLDivElement>(null);
  const sliderRef = useRef<HTMLInputElement>(null);
  const gesture = useRef<Gesture | null>(null);
  const suppressClick = useRef(false);
  // Pinch to zoom the page in and out (owner 2026-11-16). Our own zoom, since the page swipe owns the
  // horizontal touch; while zoomed the page scrolls in both directions and the arrows turn pages.
  const [zoom, setZoom] = useState(1);
  // The page's unscaled size; the zoom box takes that size times the zoom so the stage can scroll over it.
  const [zoomBase, setZoomBase] = useState<{ w: number; h: number } | null>(null);
  const zoomRef = useRef(1);
  const stageRef = useRef<HTMLDivElement>(null);
  const pinch = useRef<{ d0: number; z0: number } | null>(null);
  const focus = useRef<{ fx: number; fy: number; mx: number; my: number; rtl: boolean } | null>(null);
  const bookmarks = useStore(bookmarksStore);
  const audioPrefs = useStore(audioStore);
  const prefs = useStore(prefsStore);
  const ps = useSyncExternalStore(player.subscribe, player.get, player.getServer);
  const active = ps.status !== "idle";
  const current = active ? (ps.queue[ps.cursor.index] ?? null) : null;
  const playingKey = current?.kind === "ayah" ? `${current.s}:${current.a}` : null;
  const playingBasmala = current?.kind === "basmala" ? current.s : null;

  const fullScreen =
    tab === "mushaf" && !chrome && !selected && sheet === null && !(audioPrefs.tafsir && active);
  const wide = useWide();
  // "Listen with tafsir": the whole Mushaf page on one half, the page's tafsir on the other (owner 2026-11-15);
  // side by side on wide screens, one above the other on phones.
  const duo = tab === "mushaf" && audioPrefs.tafsir && active && !selected;
  useFitFont(pageEl, page, fullScreen, duo ? `duo${wide ? "-wide" : ""}` : "");

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
    // Recitation paused by another sound (adhkar…): keep its ayah as the place to come back to.
    const held = player.wasInterrupted() ? player.current() : null;
    if (held?.kind === "ayah" && itemPage(held) === view.page) {
      lastReadStore.set({ surah: held.s, ayah: held.a, page: view.page, at: Date.now() });
      return;
    }
    const first = pageAyahRefs(view)[0];
    if (first) lastReadStore.set({ surah: first[0], ayah: first[1], page: view.page, at: Date.now() });
  }, [view]);

  // Full screen: say how to turn pages and how to bring the controls back (the first few times).
  const hinted = useRef(false);
  useEffect(() => {
    if (!fullScreen || hinted.current) return;
    hinted.current = true;
    let shown = 0;
    try {
      shown = Number(window.localStorage.getItem(HINT_KEY) ?? "0") || 0;
      if (shown >= HINT_SHOWS) return;
      window.localStorage.setItem(HINT_KEY, String(shown + 1));
    } catch {
      // storage blocked: still show it this time
    }
    setHint(true);
    const id = window.setTimeout(() => setHint(false), HINT_MS);
    return () => window.clearTimeout(id);
  }, [fullScreen]);

  // The first time the Mushaf opens: a short guide to the touches (owner 2026-11-15).
  useEffect(() => {
    try {
      if (window.localStorage.getItem(GUIDE_KEY)) return;
    } catch {
      return;
    }
    setGuide(true);
  }, []);
  const closeGuide = (): void => {
    setGuide(false);
    try {
      window.localStorage.setItem(GUIDE_KEY, "1");
    } catch {
      // storage blocked: shown again next time
    }
  };

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
    const publish = (): void => {
      const h = Math.ceil(el.offsetHeight);
      const changed = root.style.getPropertyValue("--rd-dock-h") !== `${h}px`;
      root.style.setProperty("--rd-dock-h", `${h}px`);
      root.style.setProperty("--rd-panel-h", `${h}px`);
      // The page is sized to end where the dock starts: size it again when the dock grows or shrinks.
      if (changed) window.dispatchEvent(new Event("resize"));
    };
    publish();
    const ro = typeof ResizeObserver === "undefined" ? null : new ResizeObserver(publish);
    ro?.observe(el);
    return () => {
      ro?.disconnect();
      root.style.removeProperty("--rd-dock-h");
      root.style.removeProperty("--rd-panel-h");
    };
  }, []);

  // Khatma: a page counts as read after it has stayed open for a few seconds.
  useEffect(() => {
    if (!khatmaStore.get()) return;
    const id = window.setTimeout(() => khatmaStore.set((k) => markRead(k, page)), KHATMA_DWELL_MS);
    return () => window.clearTimeout(id);
  }, [page]);

  // One panel at a time: choosing an ayah closes the khatma / help panel.
  useEffect(() => {
    if (selected) setSheet(null);
  }, [selected]);

  // A selected ayah stays in view above its actions (phones: the actions sheet covers the lower part).
  useEffect(() => {
    if (!selected || tab !== "mushaf") return;
    document
      .querySelector<HTMLElement>(`.mushaf-stage [data-ayah="${selected}"]`)
      ?.scrollIntoView?.({ block: "nearest", behavior: "smooth" });
  }, [selected, tab]);

  // In the verse and tafsir lists, keep the recited ayah in view.
  useEffect(() => {
    if (!playingKey) return;
    if (duo) {
      // Scroll only inside each half (the tafsir, and the page on phones), never the whole page.
      const follow = (boxSel: string, gap: number): void => {
        const box = document.querySelector<HTMLElement>(boxSel);
        const item = box?.querySelector<HTMLElement>(`[data-ayah="${playingKey}"]`);
        if (!box || !item || box.scrollHeight <= box.clientHeight) return;
        const y = item.getBoundingClientRect().top - box.getBoundingClientRect().top + box.scrollTop;
        box.scrollTo?.({ top: Math.max(0, y - gap), behavior: "smooth" });
      };
      follow(".rd-duo-tafsir", 56);
      follow(".rd-duo .mushaf-stage", 40);
      return;
    }
    if (tab === "mushaf") return;
    document
      .querySelector<HTMLElement>(`.rd-list [data-ayah="${playingKey}"]`)
      ?.scrollIntoView?.({ block: "nearest", behavior: "smooth" });
  }, [tab, playingKey, duo]);

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

  // ---- pinch zoom (two fingers) ----
  useEffect(() => {
    zoomRef.current = zoom;
  }, [zoom]);
  useEffect(() => {
    const stage = stageRef.current;
    if (!stage) return;
    const two = (t: TouchList): [Touch, Touch] | null => {
      const a = t.item(0);
      const b = t.item(1);
      return a && b ? [a, b] : null;
    };
    const dist = ([a, b]: [Touch, Touch]): number =>
      Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1;
    const onStart = (e: TouchEvent): void => {
      const pts = e.touches.length === 2 ? two(e.touches) : null;
      if (!pts) return;
      pinch.current = { d0: dist(pts), z0: zoomRef.current };
      const frame = pageEl.current?.parentElement;
      if (frame && zoomRef.current === 1) setZoomBase({ w: frame.offsetWidth, h: frame.offsetHeight });
      gesture.current = null;
      setDrag({ dx: 0, anim: false });
    };
    const onMove = (e: TouchEvent): void => {
      const p = pinch.current;
      const pts = e.touches.length === 2 ? two(e.touches) : null;
      if (!p || !pts) return;
      e.preventDefault();
      const z = Math.min(ZOOM_MAX, Math.max(1, (p.z0 * dist(pts)) / p.d0));
      // keep the point between the fingers where it is
      const r = stage.getBoundingClientRect();
      const mx = (pts[0].clientX + pts[1].clientX) / 2 - r.left;
      const my = (pts[0].clientY + pts[1].clientY) / 2 - r.top;
      // Content fractions under the fingers, before the zoom (RTL scrollLeft runs from -max to 0).
      const rtl = getComputedStyle(stage).direction === "rtl";
      const maxX = stage.scrollWidth - stage.clientWidth;
      const left = rtl ? stage.scrollLeft + maxX : stage.scrollLeft;
      const fx = (left + mx) / Math.max(1, stage.scrollWidth);
      const fy = (stage.scrollTop + my) / Math.max(1, stage.scrollHeight);
      focus.current = { fx, fy, mx, my, rtl };
      zoomRef.current = z;
      setZoom(z);
    };
    const onEnd = (e: TouchEvent): void => {
      if (!pinch.current || e.touches.length >= 2) return;
      pinch.current = null;
      suppressClick.current = true;
      if (zoomRef.current < ZOOM_SNAP) setZoom(1);
    };
    stage.addEventListener("touchstart", onStart, { passive: true });
    stage.addEventListener("touchmove", onMove, { passive: false });
    stage.addEventListener("touchend", onEnd);
    stage.addEventListener("touchcancel", onEnd);
    return () => {
      stage.removeEventListener("touchstart", onStart);
      stage.removeEventListener("touchmove", onMove);
      stage.removeEventListener("touchend", onEnd);
      stage.removeEventListener("touchcancel", onEnd);
    };
  }, [tab]);
  // After the zoom is laid out, scroll so the point between the fingers stays under them.
  useLayoutEffect(() => {
    const stage = stageRef.current;
    const f = focus.current;
    focus.current = null;
    if (!stage || !f) return;
    const nx = f.fx * stage.scrollWidth - f.mx;
    const nMax = stage.scrollWidth - stage.clientWidth;
    stage.scrollLeft = f.rtl ? nx - nMax : nx;
    stage.scrollTop = f.fy * stage.scrollHeight - f.my;
  }, [zoom]);
  // A new page starts at its top (and may have a slightly different size).
  useEffect(() => {
    const stage = stageRef.current;
    if (!stage || zoomRef.current <= 1) return;
    const id = requestAnimationFrame(() => {
      const frame = pageEl.current?.parentElement;
      if (frame) setZoomBase({ w: frame.offsetWidth, h: frame.offsetHeight });
      stage.scrollTo({ top: 0, left: 0 });
    });
    return () => cancelAnimationFrame(id);
  }, [page]);

  // ---- swipe / drag like a book ----
  const onPointerDown = (e: ReactPointerEvent<HTMLDivElement>): void => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    // Zoomed in: one finger moves around the page instead of turning it.
    if (zoomRef.current > 1 || pinch.current) return;
    gesture.current = { x: e.clientX, y: e.clientY, t: performance.now(), active: false };
  };
  const onPointerMove = (e: ReactPointerEvent<HTMLDivElement>): void => {
    const g = gesture.current;
    if (!g || pinch.current) return;
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
    // The leaf finishes its turn (forward: it folds over the spine; back: the previous leaf lies down),
    // then the reader shows the new page with nothing moving.
    setDrag({ dx: Math.sign(dx) * width, anim: true });
    window.setTimeout(() => {
      goTo(target);
      setDrag({ dx: 0, anim: false });
    }, TURN_MS);
  };

  const onPageClick = (e: React.MouseEvent<HTMLDivElement>): void => {
    if (suppressClick.current) {
      suppressClick.current = false;
      return;
    }
    // One rule everywhere: a tap on an ayah opens its row of actions; a tap beside the text closes it.
    const hit = (e.target as HTMLElement).closest<HTMLElement>("[data-ayah]");
    const key = hit?.dataset.ayah ?? null;
    if (!key && !selected) return;
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

  const shareImage = async (): Promise<void> => {
    if (!sel) return;
    try {
      const d = data ?? (await loadMushafData());
      const outcome = await shareAyahImage(
        { text: d.text(sel[0], sel[1]), reference: ref(sel[0], sel[1]), brand: t(locale, "appName") },
        `rattil-${sel[0]}-${sel[1]}.png`,
      );
      if (outcome === "downloaded") setNotice(t(locale, "mushaf.imageSaved"));
    } catch {
      setNotice(t(locale, "mushaf.imageFailed"));
    }
  };

  // Turning like a paper Mushaf (owner 2026-11-17): the leaf is hinged on the spine (the right edge in Arabic)
  // and follows the finger. Forward, this page is the leaf and the next one lies still underneath; back, the
  // previous leaf comes down over this page.
  const turn = ((): { forward: boolean; other: ResolvedPage; angle: number; shade: number } | null => {
    if (!drag.dx || zoom > 1 || !data) return null;
    const forward = dir === "rtl" ? drag.dx > 0 : drag.dx < 0;
    const other = data.page(page + (forward ? 1 : -1));
    if (!other) return null;
    const width = stageRef.current?.clientWidth || 400;
    const p = Math.min(1, Math.abs(drag.dx) / width);
    const progress = forward ? p : 1 - p; // how far the leaf has turned away (0 flat, 1 folded over)
    return { forward, other, angle: (dir === "rtl" ? 1 : -1) * progress * 88, shade: 0.18 * (1 - progress) };
  })();
  const spine = dir === "rtl" ? "right center" : "left center";
  /** The other page of a turn, drawn at the same size as this one (the fitted sizes are copied over). */
  const turnLayer = (other: ResolvedPage, role: "under" | "leaf"): ReactNode => {
    const el = pageEl.current;
    const frame = el?.parentElement;
    const vars: Record<string, string> = {};
    for (const [node, names] of [
      [el, ["--m-size", "--m-lh"]],
      [frame, ["--m-width", "--m-min-h"]],
    ] as const) {
      for (const n of names) {
        const v = node?.style.getPropertyValue(n);
        if (v) vars[n] = v;
      }
    }
    return (
      <div className={`mushaf-turn-layer is-${role}`} aria-hidden="true" data-testid={`mushaf-turn-${role}`}>
        <div
          className="mushaf-frame"
          style={
            {
              ...vars,
              transformOrigin: spine,
              transform:
                role === "leaf" && turn ? `perspective(1400px) rotateY(${turn.angle}deg)` : undefined,
              transition: drag.anim ? `transform ${TURN_MS}ms ease-out` : "none",
            } as CSSProperties
          }
        >
          <MushafPage data={other} markerLabel={markerLabel} />
          <div className="mushaf-folio">{localizeDigits(other.page, "ar")}</div>
          {role === "under" && turn ? <div className="mushaf-shade" style={{ opacity: turn.shade }} /> : null}
        </div>
      </div>
    );
  };
  const refs = pageAyahRefs(view);
  const playWithTafsir = (s: number, a: number): void => {
    audioStore.set((p) => ({ ...p, tafsir: true }));
    setSelected(null);
    setTab("mushaf");
    player.play({ kind: "from", surah: s, ayah: a });
  };
  const flowShown = flowSurah ?? (sel ? sel[0] : (refs[0]?.[0] ?? 1));
  /** A list page change starts the new page at its top. */
  const goToTop = (p: number): void => {
    goTo(p);
    window.scrollTo({ top: 0 });
  };
  const listSwipe = usePageSwipe(page, dir, goToTop);
  const onListSelect = ([s, a]: Ref): void =>
    setSelected((cur) => (cur === `${s}:${a}` ? null : `${s}:${a}`));

  return (
    <div
      className={["mushaf-reader rd", fullScreen ? "rd-full" : "", duo ? "rd-duo" : ""]
        .filter(Boolean)
        .join(" ")}
      data-tab={tab}
      data-split={duo ? "true" : "false"}
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
        <div className="rd-tools">
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
          ) : null}
          {tab === "mushaf" ? (
            <button
              type="button"
              className="rd-icon-btn rd-full-btn"
              aria-label={t(locale, "reader.fullScreen")}
              title={t(locale, "reader.fullScreen")}
              data-testid="reader-full"
              onClick={() => {
                setSelected(null);
                setSheet(null);
                setChrome(false);
              }}
            >
              <ReaderIcon name="expand" />
            </button>
          ) : (
            // A− / A+ (owner 2026-11-17): the text size of the whole-surah view and the lists.
            <span className="rd-font-pair">
              <button
                type="button"
                className="rd-icon-btn rd-font"
                aria-label={t(locale, "reader.fontDown")}
                data-testid="reader-font-down"
                disabled={prefs.fontSize <= FONT_MIN}
                onClick={() =>
                  prefsStore.set((p) => ({ ...p, fontSize: Math.max(FONT_MIN, p.fontSize - FONT_STEP) }))
                }
              >
                <span aria-hidden="true">A−</span>
              </button>
              <button
                type="button"
                className="rd-icon-btn rd-font"
                aria-label={t(locale, "reader.fontUp")}
                data-testid="reader-font"
                disabled={prefs.fontSize >= FONT_MAX}
                onClick={() =>
                  prefsStore.set((p) => ({ ...p, fontSize: Math.min(FONT_MAX, p.fontSize + FONT_STEP) }))
                }
              >
                <span aria-hidden="true">A+</span>
              </button>
            </span>
          )}
        </div>
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

      {duo ? (
        <aside
          className="rd-duo-tafsir"
          aria-label={t(locale, "reader.tafsirOfPage", { page: localizeDigits(page, locale) })}
          data-testid="duo-tafsir"
        >
          <div className="rd-duo-head">
            <strong>{t(locale, "reader.listenWithTafsir")}</strong>
            <button
              type="button"
              className="btn btn-sm"
              data-testid="duo-close"
              onClick={() => audioStore.set((p) => ({ ...p, tafsir: false }))}
            >
              {t(locale, "reader.hideTafsir")}
            </button>
          </div>
          <PageTafsirList
            locale={locale}
            refs={refs}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={([s, a]) => playWithTafsir(s, a)}
          />
        </aside>
      ) : null}

      <div
        ref={stageRef}
        className={`mushaf-stage${zoom > 1 ? " is-zoomed" : ""}`}
        data-testid="mushaf-stage"
        data-ready={data ? "true" : "false"}
        hidden={tab !== "mushaf"}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={endGesture}
        onPointerCancel={endGesture}
        onClick={onPageClick}
      >
        <div
          className="mushaf-zoom"
          style={zoom > 1 && zoomBase ? { width: zoomBase.w * zoom, height: zoomBase.h * zoom } : undefined}
        >
          {turn?.forward ? turnLayer(turn.other, "under") : null}
          <div
            className="mushaf-frame"
            data-testid="mushaf-frame"
            style={{
              transformOrigin: turn ? spine : undefined,
              transform:
                zoom > 1
                  ? `scale(${zoom.toFixed(3)})`
                  : turn?.forward
                    ? `perspective(1400px) rotateY(${turn.angle}deg)`
                    : undefined,
              transition: drag.anim && zoom === 1 ? `transform ${TURN_MS}ms ease-out` : "none",
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
            {turn && !turn.forward ? <div className="mushaf-shade" style={{ opacity: turn.shade }} /> : null}
          </div>
          {turn && !turn.forward ? turnLayer(turn.other, "leaf") : null}
        </div>
      </div>
      {zoom > 1 ? (
        <button
          type="button"
          className="rd-zoom-reset"
          data-testid="reader-zoom-reset"
          onClick={() => setZoom(1)}
        >
          <ReaderIcon name="shrink" size={16} />
          <span>
            {t(locale, "reader.zoomReset", { pct: localizeDigits(Math.round(zoom * 100), locale) })}
          </span>
        </button>
      ) : null}

      {fullScreen ? (
        <div className="rd-turn" data-testid="turn-arrows">
          {(["next", "prev"] as const).map((which) => {
            const target = which === "next" ? page + 1 : page - 1;
            // RTL: the next page is on the left, like a printed Mushaf.
            const side = (which === "next") === (dir === "rtl") ? "left" : "right";
            return (
              <button
                key={which}
                type="button"
                className={`rd-turn-btn rd-turn-${side}`}
                data-testid={`turn-${which}`}
                aria-label={t(locale, which === "next" ? "quran.nextPage" : "quran.prevPage")}
                disabled={target < 1 || target > PAGE_COUNT}
                onClick={() => goTo(target)}
              >
                <svg width={26} height={26} viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                  <path
                    d={side === "left" ? "M15 5l-7 7 7 7" : "M9 5l7 7-7 7"}
                    fill="none"
                    stroke="currentColor"
                    strokeWidth={2.2}
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </button>
            );
          })}
        </div>
      ) : null}
      {fullScreen ? (
        <button
          type="button"
          className="rd-exit-full"
          data-testid="reader-exit-full"
          onClick={() => setChrome(true)}
        >
          <ReaderIcon name="shrink" size={18} />
          <span>{t(locale, "reader.exitFull")}</span>
        </button>
      ) : null}
      {guide ? (
        <div className="rd-modal" role="dialog" aria-labelledby="rd-guide-title" data-testid="reader-guide">
          <div className="rd-modal-card rd-guide">
            <h2 id="rd-guide-title">{t(locale, "reader.guideTitle")}</h2>
            <ol>
              {(["guide1", "guide2", "guide3", "guide4"] as const).map((k) => (
                <li key={k}>{t(locale, `reader.${k}`)}</li>
              ))}
            </ol>
            <button
              type="button"
              className="btn btn-primary kh-go"
              data-testid="reader-guide-ok"
              onClick={closeGuide}
            >
              {t(locale, "reader.hintClose")}
            </button>
          </div>
        </div>
      ) : null}
      {fullScreen && hint ? (
        <div className="rd-hint" role="status" data-testid="reader-hint">
          <span>{t(locale, "reader.fullHint")}</span>
          <button type="button" className="btn btn-sm" onClick={() => setHint(false)}>
            {t(locale, "reader.hintClose")}
          </button>
        </div>
      ) : null}

      {tab === "surah" ? (
        <section aria-label={t(locale, "reader.tabSurah")}>
          <SurahFlow
            key={flowShown}
            locale={locale}
            surah={flowShown}
            page={page}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={onListSelect}
            onSurah={(n) => {
              goTo(pageForAyah(n, 1));
              setFlowSurah(n);
            }}
          />
        </section>
      ) : null}
      {tab === "ayat" ? (
        <section
          aria-label={t(locale, "reader.ayatOfPage", { page: localizeDigits(page, locale) })}
          {...listSwipe}
        >
          <PageAyahList
            locale={locale}
            refs={refs}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={onListSelect}
          />
          <PageButtons locale={locale} page={page} onPage={goToTop} />
        </section>
      ) : null}
      {tab === "tafsir" ? (
        <section
          aria-label={t(locale, "reader.tafsirOfPage", { page: localizeDigits(page, locale) })}
          {...listSwipe}
        >
          <PageTafsirList
            locale={locale}
            refs={refs}
            data={data}
            selected={selected}
            playing={playingKey}
            onSelect={onListSelect}
          />
          <PageButtons locale={locale} page={page} onPage={goToTop} />
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
            {(["guide1", "guide2", "guide3", "guide4"] as const).map((k) => (
              <li key={k}>{t(locale, `reader.${k}`)}</li>
            ))}
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

      <div className="rd-dock" ref={dockRef}>
        {/* The selected ayah's actions sit in the bottom strip with the other bars (owner 2026-11-15). */}
        {sel ? (
          <div
            className="ayah-sheet rd-actions"
            data-testid="ayah-sheet"
            data-tafsir={showTafsir ? "open" : "closed"}
          >
            {/* Simple ayah menu (owner, 2026-11-15): one row of five buttons; the ways to listen and the
                tafsir open only when asked for. */}
            <div
              className="ayah-actions aa-simple"
              role="toolbar"
              aria-label={t(locale, "mushaf.actions")}
              data-testid="ayah-actions"
            >
              <div className="aa-head">
                <strong className="aa-ref">{ref(sel[0], sel[1])}</strong>
                <button
                  type="button"
                  className="rd-icon-btn aa-close"
                  data-testid="act-close"
                  aria-label={t(locale, "common.close")}
                  onClick={() => setSelected(null)}
                >
                  <Icon name="close" size={18} />
                </button>
              </div>
              <div className="aa-row">
                <button
                  type="button"
                  className="aa-btn"
                  aria-expanded={listenOpen}
                  data-testid="act-listen"
                  onClick={() => setListenOpen((v) => !v)}
                >
                  <Icon name="play" size={22} />
                  <span>{t(locale, "mushaf.listen")}</span>
                </button>
                <button
                  type="button"
                  className="aa-btn"
                  aria-pressed={showTafsir}
                  data-testid="act-tafsir"
                  onClick={() => setShowTafsir((v) => !v)}
                >
                  <Icon name="openBook" size={22} />
                  <span>{t(locale, "mushaf.tafsir")}</span>
                </button>
                <button
                  type="button"
                  className="aa-btn"
                  data-testid="act-bookmark"
                  data-bookmarked={selBookmarked}
                  aria-pressed={selBookmarked}
                  onClick={() => bookmarksStore.set((s) => toggleBookmark(s, sel[0], sel[1], Date.now()))}
                >
                  <Icon name="bookmark" size={22} />
                  <span>{selBookmarked ? t(locale, "mushaf.unmark") : t(locale, "mushaf.mark")}</span>
                </button>
                <button
                  type="button"
                  className="aa-btn"
                  data-testid="act-copy"
                  onClick={() => void copySelected()}
                >
                  <Icon name="copy" size={22} />
                  <span>{t(locale, "mushaf.copy")}</span>
                </button>
                <button
                  type="button"
                  className="aa-btn"
                  data-testid="act-share-image"
                  onClick={() => void shareImage()}
                >
                  <Icon name="share" size={22} />
                  <span>{t(locale, "mushaf.share")}</span>
                </button>
              </div>
              {listenOpen ? (
                <div className="aa-listen" role="group" aria-label={t(locale, "mushaf.listenOptions")}>
                  <button
                    type="button"
                    className="btn btn-primary btn-sm"
                    data-testid="act-play-ayah"
                    onClick={() => player.play({ kind: "ayah", surah: sel[0], ayah: sel[1] })}
                  >
                    {t(locale, "reader.playAyahOnly")}
                  </button>
                  <button
                    type="button"
                    className="btn btn-sm"
                    data-testid="act-play"
                    onClick={() => player.play({ kind: "from", surah: sel[0], ayah: sel[1] })}
                  >
                    {t(locale, "reader.playFrom")}
                  </button>
                  <button
                    type="button"
                    className="btn btn-sm"
                    data-testid="play-surah"
                    onClick={() => player.play({ kind: "surah", surah: sel[0] })}
                  >
                    {t(locale, "reader.playWholeSurah")}
                  </button>
                  <button
                    type="button"
                    className="btn btn-sm"
                    data-testid="act-play-tafsir"
                    onClick={() => playWithTafsir(sel[0], sel[1])}
                  >
                    {t(locale, "reader.playTafsirShort")}
                  </button>
                </div>
              ) : null}
              <p className="aa-notice" role="status" data-testid="mushaf-notice">
                {notice}
              </p>
            </div>
            {showTafsir ? (
              <TafsirPanel locale={locale} surah={sel[0]} ayah={sel[1]} onStep={selectRef} />
            ) : null}
          </div>
        ) : null}
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
            onClick={() => {
              setSelected(null);
              setSheet((v) => (v === "khatma" ? null : "khatma"));
            }}
          >
            <ReaderIcon name="openBook" />
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
