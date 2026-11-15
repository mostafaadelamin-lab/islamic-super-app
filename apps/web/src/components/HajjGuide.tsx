import guideJson from "@/generated/hajj-guide.json";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahMeta } from "@/lib/pages";
import { ayahEndMark, renderQuranText } from "@/lib/quran-render";
import type { RoundTool } from "@/lib/rounds";
import { RoundCounter } from "./RoundCounter";
import { HajjScene } from "./HajjScene";

/*
 * The Hajj and Umrah guide (owner 2026-11-16): every word comes from content/pilgrimage/dist/hajj-guide.v2.json,
 * where content/pilgrimage/build-guide.mjs cut it out of its published source (Ibn Baz «التحقيق والإيضاح»
 * with page numbers, the official «دليل الحاج والمعتمر», the hadith books, Hisn al-Muslim, and the KFGQPC
 * Quran). Nothing religious is written here: this file only lays the texts out, each with its reference.
 */

export type Seg =
  | { t: "text"; v: string }
  | { t: "quran"; s: number; from: number; to: number; part?: string; texts: string[] };

interface QuranRef {
  s: number;
  from: number;
  to: number;
  /** Only these words of the ayah are quoted (the source quotes a part); texts still hold the whole ayah. */
  part?: string;
  texts: string[];
}

export type GuideItem =
  | { k: "text" | "hadith"; segs: Seg[]; src: string; notes?: string[] }
  | { k: "say"; segs: Seg[]; src: string; times?: number; notes?: string[] }
  | (QuranRef & { k: "quran"; say?: boolean; cite?: { text: string; src: string } })
  | { k: "table"; head: string[]; rows: string[][]; src: string };

export interface GuideSub {
  title: string;
  tags?: string[];
  scene?: string;
  items: GuideItem[];
}
export interface GuideStep {
  title: string;
  scene: string | null;
  subs: string[];
}
export interface FlowStep {
  title: string;
  step: string;
  dalil: string | null;
}
export interface Guide {
  sources: {
    id: string;
    short: string;
    title: string;
    author?: string;
    publisher?: string;
    edition?: string;
  }[];
  corrections: string[];
  subs: Record<string, GuideSub>;
  steps: Record<string, GuideStep>;
  flows: Record<PilgrimageKind, FlowStep[]>;
  hub: { umrahIntro: string; days: string[]; ihram: string[]; madinah: string };
  official: {
    title: string;
    types: { name: string; segs: Seg[] }[];
    typesNote: Seg[];
    umrah: Seg[][];
    hajj: Seg[][];
  };
}

export const GUIDE = guideJson as unknown as Guide;

/** One page per kind of pilgrimage (owner 2026-11-15): Umrah and the three kinds of Hajj. */
export const PILGRIMAGE_KINDS = ["umrah", "tamattu", "qiran", "ifrad"] as const;
export type PilgrimageKind = (typeof PILGRIMAGE_KINDS)[number];
export const isPilgrimageKind = (x: string): x is PilgrimageKind =>
  (PILGRIMAGE_KINDS as readonly string[]).includes(x);

/** Menu title and short line of each kind's page. */
export const KIND_TITLE: Record<PilgrimageKind, string> = {
  umrah: "nav.hajjUmrah",
  tamattu: "nav.hajjTamattu",
  qiran: "nav.hajjQiran",
  ifrad: "nav.hajjIfrad",
};

/** The name each kind has in the official guide's list of kinds. */
const KIND_IN_OFFICIAL: Record<PilgrimageKind, string> = {
  umrah: "",
  tamattu: "التمتع",
  qiran: "القِرَان",
  ifrad: "الإفراد",
};

/** Seven rounds of tawaf or sa'i, or seven stones: the counters a step gets. */
const STEP_TOOLS: Readonly<Record<string, readonly RoundTool[]>> = {
  "tawaf-first": ["tawaf"],
  ifadah: ["tawaf"],
  "ifadah-tamattu": ["tawaf", "sai"],
  farewell: ["tawaf"],
  sai: ["sai"],
  "sai-qudum": ["sai"],
  aqaba: ["jamarat"],
  "tashriq-rami": ["jamarat"],
};

/** Every picture a step shows: its own, then those of its parts. */
export function scenesOfStep(stepId: string): string[] {
  const step = GUIDE.steps[stepId];
  if (!step) return [];
  const own = step.scene ? [step.scene] : [];
  return [...new Set([...own, ...step.subs.flatMap((k) => GUIDE.subs[k]?.scene ?? [])])];
}

/**
 * The official guide's own paragraph for a step: "u1".."u4" (Umrah), "h1".."h9" (Hajj), or "types" (the
 * kind itself). Matches "u2" and "h9"; rejects "x1" and "u".
 * https://regex101.com/?regex=%5E%28%5Buh%5D%29%28%5Cd%2B%29%24&testString=u2
 */
export function officialSegs(dalil: string | null, kind: PilgrimageKind): Seg[] | null {
  if (!dalil) return null;
  if (dalil === "types")
    return GUIDE.official.types.find((x) => x.name === KIND_IN_OFFICIAL[kind])?.segs ?? null;
  // "u" or "h" then the paragraph number: matches "u2", "h9"; rejects "x1", "u".
  // https://regex101.com/?regex=%5E%28%5Buh%5D%29%28%5Cd%2B%29%24&testString=u2
  const m = /^([uh])(\d+)$/.exec(dalil);
  if (!m) return null;
  const list = m[1] === "u" ? GUIDE.official.umrah : GUIDE.official.hajj;
  return list[Number(m[2]) - 1] ?? null;
}

/** "[البقرة: ١٢٥]" or "[الفاتحة: ١–٧]". */
function quranRef(q: QuranRef): string {
  const name = surahMeta(q.s)?.nameAr ?? "";
  const a = localizeDigits(q.from, "ar");
  return q.from === q.to ? `[${name}: ${a}]` : `[${name}: ${a}–${localizeDigits(q.to, "ar")}]`;
}

/** Ayahs in the Complex's own text and font, each with its end mark; a quoted part of an ayah has none. */
function QuranWords({ q }: { q: QuranRef }) {
  return (
    <span className="hg-quran" data-testid="hg-quran">
      <span className="hg-quran-text">
        ﴿
        {q.part
          ? renderQuranText(q.part)
          : q.texts.map((x, i) => (
              <span key={i}>
                {renderQuranText(x)} {ayahEndMark(q.from + i)}
                {i < q.texts.length - 1 ? " " : null}
              </span>
            ))}
        ﴾
      </span>{" "}
      <span className="hg-quran-ref">{quranRef(q)}</span>
    </span>
  );
}

export function Segs({ segs }: { segs: readonly Seg[] }) {
  return (
    <>{segs.map((x, i) => (x.t === "text" ? <span key={i}>{x.v}</span> : <QuranWords key={i} q={x} />))}</>
  );
}

function Source({ src, locale }: { src: string; locale: Locale }) {
  return (
    <p className="hg-src">
      {t(locale, "hajj.ref")}: {src}
    </p>
  );
}

function Notes({ notes }: { notes?: string[] }) {
  if (!notes?.length) return null;
  return (
    <ul className="hg-notes">
      {notes.map((n) => (
        <li key={n}>{n}</li>
      ))}
    </ul>
  );
}

type ItemOf<K extends GuideItem["k"]> = Extract<GuideItem, { k: K }>;
type ItemView = { [K in GuideItem["k"]]: (it: ItemOf<K>, locale: Locale) => React.JSX.Element };

function plainItem(it: ItemOf<"text" | "hadith">, locale: Locale): React.JSX.Element {
  return (
    <div className="hg-item">
      {it.k === "hadith" ? (
        <blockquote className="hg-hadith" data-testid="hg-hadith">
          <Segs segs={it.segs} />
        </blockquote>
      ) : (
        <p className="hg-text" data-testid="hg-text">
          <Segs segs={it.segs} />
        </p>
      )}
      <Source src={it.src} locale={locale} />
      <Notes notes={it.notes} />
    </div>
  );
}

const ITEM_VIEW: ItemView = {
  text: plainItem,
  hadith: plainItem,
  say: (it, locale) => (
    <div className="hg-item hg-say" data-testid="hg-say">
      <p className="hg-say-text">
        <Segs segs={it.segs} />
        {it.times ? (
          <span className="hg-times">{t(locale, "hajj.times", { n: localizeDigits(it.times, locale) })}</span>
        ) : null}
      </p>
      <Source src={it.src} locale={locale} />
      <Notes notes={it.notes} />
    </div>
  ),
  quran: (it, locale) => (
    <div className={it.say ? "hg-item hg-say" : "hg-item"} data-testid={it.say ? "hg-say" : undefined}>
      {it.cite ? (
        <>
          <blockquote className="hg-hadith">{it.cite.text}</blockquote>
          <Source src={it.cite.src} locale={locale} />
        </>
      ) : null}
      <p className="hg-quran-block">
        <QuranWords q={it} />
      </p>
    </div>
  ),
  table: (it, locale) => (
    <div className="hg-table-wrap">
      <table className="hg-table" data-testid="hg-table">
        <thead>
          <tr>
            {it.head.map((h) => (
              <th key={h}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {it.rows.map((r) => (
            <tr key={r[0]}>
              {r.map((c, i) => (
                <td key={i}>{c}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      <Source src={it.src} locale={locale} />
    </div>
  ),
};

function Item({ it, locale }: { it: GuideItem; locale: Locale }) {
  const view = ITEM_VIEW[it.k] as (it: GuideItem, locale: Locale) => React.JSX.Element;
  return view(it, locale);
}

/** One part of a step (a sunnah, a dhikr, a place), with its own picture when it has one. */
export function GuideSubView({ id, locale, shown }: { id: string; locale: Locale; shown?: string | null }) {
  const sub = GUIDE.subs[id];
  if (!sub) return null;
  return (
    <section className="hg-sub" data-testid={`hg-sub-${id}`} id={`hg-${id}`}>
      <h4>{sub.title}</h4>
      {sub.tags?.length ? (
        <p className="hg-tags">
          {sub.tags.map((x) => (
            <span key={x} className="hg-tag">
              {t(locale, `hajj.tag.${x}`)}
            </span>
          ))}
        </p>
      ) : null}
      {sub.scene && sub.scene !== shown ? <HajjScene id={sub.scene} /> : null}
      {sub.items.map((it, i) => (
        <Item key={i} it={it} locale={locale} />
      ))}
    </section>
  );
}

/** A whole step: its picture, the official guide's words for it (when given), then each part in full. */
export function GuideStepCard({
  locale,
  id,
  label,
  stepId,
  title,
  dalil = null,
  kind = "umrah",
}: {
  locale: Locale;
  id: string;
  label: string;
  stepId: string;
  title?: string;
  dalil?: string | null;
  kind?: PilgrimageKind;
}) {
  const step = GUIDE.steps[stepId];
  if (!step) return null;
  const official = officialSegs(dalil, kind);
  const tools = STEP_TOOLS[stepId] ?? [];
  return (
    <section className="card step hajj-step" id={id} data-step={stepId}>
      <span className="step-label">{label}</span>
      <h3 lang="ar" data-testid="hajj-step-title">
        {title ?? step.title}
      </h3>
      <div lang="ar" dir="rtl">
        {step.scene ? <HajjScene id={step.scene} /> : null}
        {official ? (
          <div className="hg-official" data-testid="hg-official">
            <h4>{t(locale, "hajj.guide.title")}</h4>
            <p>
              <Segs segs={official} />
            </p>
            <p className="hg-src">
              {t(locale, "hajj.ref")}: {GUIDE.official.title}
            </p>
          </div>
        ) : null}
        {step.subs.map((k) => (
          <GuideSubView key={k} id={k} locale={locale} shown={step.scene} />
        ))}
      </div>
      {tools.map((x) => (
        <RoundCounter key={x} locale={locale} tool={x} />
      ))}
    </section>
  );
}

/** The sources the guide quotes, with the typing errors of the digital copy that were corrected. */
export function GuideSources({ locale }: { locale: Locale }) {
  return (
    <section className="card hg-sources" data-testid="hg-sources">
      <h3>{t(locale, "hajj.sources")}</h3>
      <ul lang="ar">
        {GUIDE.sources.map((s) => (
          <li key={s.id}>
            <strong>{s.title}</strong>
            {[s.author, s.publisher, s.edition]
              .filter(Boolean)
              .map((x) => ` — ${x}`)
              .join("")}
          </li>
        ))}
      </ul>
      <details className="muted small">
        <summary>{t(locale, "hajj.guide.corrections")}</summary>
        <ul lang="ar">
          {GUIDE.corrections.map((c) => (
            <li key={c}>{c}</li>
          ))}
        </ul>
      </details>
    </section>
  );
}
