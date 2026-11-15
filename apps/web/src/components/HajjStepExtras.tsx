import duas from "@/generated/hajj-duas.json";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { surahMeta } from "@/lib/pages";
import { ayahEndMark, renderQuranText } from "@/lib/quran-render";
import { TawafPlan, type TawafPlanLabels } from "./TawafPlan";

/*
 * Each step of Umrah and Hajj (owner 2026-11-15): a picture of where it happens, and everything said
 * there written in full at its place. The words come only from Hisn al-Muslim and the Quran
 * (content/pilgrimage/step-duas.v1.json, resolved at build time); nothing here is new religious text.
 */

type Say = { kind: string; text: string; quran?: number[] };
type Group = { title: string; say: Say[] };
const PLACES = duas.places as Record<string, Group[]>;
const RULES = duas.rules as { contains: string; places: string[]; stop?: boolean }[];

/** The places of a step, from the words of its title (same rules as the app). */
export function placesFor(title: string): string[] {
  const matching = RULES.filter((r) => title.includes(r.contains));
  const stopAt = matching.findIndex((r) => r.stop);
  const used = stopAt < 0 ? matching : matching.slice(0, stopAt + 1);
  return [...new Set(used.flatMap((r) => r.places))];
}

export type Picture =
  | { kind: "tawaf" }
  | { kind: "sai" }
  | { kind: "jamarat"; aqabaOnly: boolean }
  | { kind: "route"; at: RoutePlace };
export type RoutePlace = "miqat" | "makkah" | "mina" | "muzdalifah" | "arafah";

/** The picture of a step. [umrah]: the step is part of an Umrah (its shaving is in Makkah). */
export function pictureFor(title: string, umrah: boolean): Picture | null {
  if (title.includes("طواف")) return { kind: "tawaf" };
  if (title.includes("سعي")) return { kind: "sai" };
  if (title.includes("رمي")) return { kind: "jamarat", aqabaOnly: title.includes("العقبة") };
  if (title.includes("عرفة")) return { kind: "route", at: "arafah" };
  if (title.includes("مزدلفة")) return { kind: "route", at: "muzdalifah" };
  if (title.includes("منى")) return { kind: "route", at: "mina" };
  if (title.includes("الميقات")) return { kind: "route", at: "miqat" };
  if (title.includes("الإحرام")) return { kind: "route", at: "makkah" };
  if (title.includes("ذبح")) return { kind: "route", at: "mina" };
  if (title.includes("الحلق"))
    return { kind: "route", at: umrah || title.includes("التحلل") ? "makkah" : "mina" };
  return null;
}

function planLabels(locale: Locale): TawafPlanLabels {
  const k = [
    "title",
    "kaaba",
    "blackStone",
    "yemeni",
    "shami",
    "iraqi",
    "door",
    "hijr",
    "maqam",
    "start",
    "direction",
  ] as const;
  return Object.fromEntries(k.map((x) => [x, t(locale, `hajj.plan.${x}`)])) as unknown as TawafPlanLabels;
}

/** Route map geometry (viewBox 350 × 130), Makkah to the west. */
const RT = {
  y: 70,
  dotOn: 13,
  dotOff: 8,
  labelOn: 34,
  labelOff: 28,
  miqat: { x: 14, y: 28, on: 9, off: 5 },
} as const;
/** The stations sit evenly along the road from Makkah (west) to Arafah. */
const ROUTE_START_X = 50;
const STATION_GAP = 85;
const ROUTE: readonly { id: RoutePlace; name: string; x: number }[] = (
  [
    ["makkah", "مكة المكرمة"],
    ["mina", "منى"],
    ["muzdalifah", "مزدلفة"],
    ["arafah", "عرفات"],
  ] as const
).map(([id, name], i) => ({ id, name, x: ROUTE_START_X + i * STATION_GAP }));
const nameOf = (p: RoutePlace): string => ROUTE.find((r) => r.id === p)?.name ?? "الميقات";

/** Makkah, Mina, Muzdalifah and Arafah on one line (Makkah to the west), the step's place marked. */
export function RouteMap({ at }: { at: RoutePlace }) {
  const first = ROUTE[0]!;
  const last = ROUTE[ROUTE.length - 1]!;
  const onMiqat = at === "miqat";
  return (
    <svg className="hajj-pic" viewBox="0 0 350 130" role="img" aria-label={`خريطة المشاعر: ${nameOf(at)}`}>
      <rect className="hp-bg" x="0" y="0" width="350" height="130" rx="14" />
      <path className="hp-road" d={`M${first.x} ${RT.y} L${last.x} ${RT.y}`} />
      <g className={onMiqat ? "hp-on" : "hp-off"}>
        <path className="hp-miqat-line" d={`M${RT.miqat.x} ${RT.miqat.y} L${first.x} ${RT.y}`} />
        <circle cx={RT.miqat.x} cy={RT.miqat.y} r={onMiqat ? RT.miqat.on : RT.miqat.off} className="hp-dot" />
        <text x="24" y="22" className="hp-label" textAnchor="start">
          الميقات
        </text>
      </g>
      {ROUTE.map((p) => {
        const on = p.id === at;
        return (
          <g key={p.id} className={on ? "hp-on" : "hp-off"}>
            <circle cx={p.x} cy={RT.y} r={on ? RT.dotOn : RT.dotOff} className="hp-dot" />
            <text x={p.x} y={RT.y + (on ? RT.labelOn : RT.labelOff)} className="hp-label" textAnchor="middle">
              {p.name}
            </text>
          </g>
        );
      })}
      <text x="340" y="20" className="hp-hint" textAnchor="end">
        {onMiqat ? "تُحرم من الميقات قبل دخول مكة" : `أنت هنا: ${nameOf(at)}`}
      </text>
    </svg>
  );
}

/** Sa'i from above: Safa (start) to Marwa, the green markers between, seven laps ending at Marwa. */
export function SaiPlan() {
  return (
    <svg className="hajj-pic" viewBox="0 0 350 150" role="img" aria-label="مخطط السعي بين الصفا والمروة">
      <rect className="hp-bg" x="0" y="0" width="350" height="150" rx="14" />
      <rect className="hp-lane" x="62" y="52" width="226" height="46" rx="6" />
      <rect className="hp-green" x="150" y="52" width="50" height="46" />
      <text x="175" y="118" className="hp-small" textAnchor="middle">
        العلمان الأخضران: يسرع الرجل بينهما
      </text>
      <path className="hp-hill" d="M290 100 Q312 40 334 100 Z" />
      <path className="hp-hill" d="M16 100 Q38 40 60 100 Z" />
      <text x="312" y="34" className="hp-label hp-strong" textAnchor="middle">
        الصفا
      </text>
      <text x="312" y="134" className="hp-small" textAnchor="middle">
        البداية
      </text>
      <text x="38" y="34" className="hp-label hp-strong" textAnchor="middle">
        المروة
      </text>
      <text x="38" y="134" className="hp-small" textAnchor="middle">
        النهاية
      </text>
      <path className="hp-way" d="M280 64 L72 64" markerEnd="url(#hp-arrow)" />
      <path className="hp-way" d="M72 86 L280 86" markerEnd="url(#hp-arrow)" />
      <text x="232" y="60" className="hp-small" textAnchor="middle">
        ١ ، ٣ ، ٥ ، ٧
      </text>
      <text x="118" y="96" className="hp-small" textAnchor="middle">
        ٢ ، ٤ ، ٦
      </text>
      <defs>
        <marker
          id="hp-arrow"
          viewBox="0 0 10 10"
          refX="8"
          refY="5"
          markerWidth="6"
          markerHeight="6"
          orient="auto"
        >
          <path d="M0,0 L10,5 L0,10 z" className="hp-arrowhead" />
        </marker>
      </defs>
    </svg>
  );
}

const PILLARS: readonly { name: string; order: string; x: string }[] = [
  { name: "الصغرى", order: "١", x: "285" },
  { name: "الوسطى", order: "٢", x: "175" },
  { name: "الكبرى (العقبة)", order: "٣", x: "65" },
];
const AQABA = PILLARS[PILLARS.length - 1]!.name;

/** The three Jamarat in order (small, middle, Aqaba), seven pebbles each; on the day of Nahr only Aqaba. */
export function JamaratPlan({ aqabaOnly }: { aqabaOnly: boolean }) {
  return (
    <svg className="hajj-pic" viewBox="0 0 350 140" role="img" aria-label="مخطط رمي الجمرات">
      <rect className="hp-bg" x="0" y="0" width="350" height="140" rx="14" />
      {PILLARS.map((p) => (
        <g
          key={p.name}
          className={!aqabaOnly || p.name === AQABA ? "hp-on" : "hp-off"}
          transform={`translate(${p.x} 0)`}
        >
          <rect x="-9" y="40" width="18" height="50" rx="4" className="hp-pillar" />
          <ellipse cx="0" cy="92" rx="30" ry="9" className="hp-basin" />
          <text x="0" y="122" className="hp-label" textAnchor="middle">
            {p.name}
          </text>
          {aqabaOnly ? null : (
            <text x="0" y="30" className="hp-small hp-strong" textAnchor="middle">
              {p.order}
            </text>
          )}
        </g>
      ))}
      <text x="340" y="20" className="hp-hint" textAnchor="end">
        {aqabaOnly ? "يوم النحر: جمرة العقبة وحدها، سبع حصيات" : "سبع حصيات لكل جمرة، بهذا الترتيب"}
      </text>
    </svg>
  );
}

export function HajjPicture({ pic, locale }: { pic: Picture; locale: Locale }) {
  return (
    <div className="hajj-pic-wrap" data-testid={`hajj-pic-${pic.kind}`}>
      {pic.kind === "tawaf" ? <TawafPlan l={planLabels(locale)} /> : null}
      {pic.kind === "sai" ? <SaiPlan /> : null}
      {pic.kind === "jamarat" ? <JamaratPlan aqabaOnly={pic.aqabaOnly} /> : null}
      {pic.kind === "route" ? <RouteMap at={pic.at} /> : null}
    </div>
  );
}

/** Everything said at the step's places, in full, each under its Hisn al-Muslim heading. */
export function StepSay({ title, locale }: { title: string; locale: Locale }) {
  const groups = placesFor(title).flatMap((p) => PLACES[p] ?? []);
  if (!groups.length) return null;
  return (
    <section className="step-say" lang="ar" dir="rtl" data-testid="step-say">
      <h4 className="step-say-title">{t(locale, "hajj.say.title")}</h4>
      {groups.map((g) => (
        <div key={g.title} className="say-group">
          <h5>{g.title}</h5>
          {g.say.map((x, i) => (
            <SayItem key={i} say={x} />
          ))}
        </div>
      ))}
    </section>
  );
}

function SayQuran({ say }: { say: Say }) {
  const [surah = 1, ayah = 1] = say.quran ?? [];
  return (
    <p className="say-dua say-quran" data-testid="say-quran">
      <span className="say-quran-text">
        ﴿{renderQuranText(say.text)} {ayahEndMark(ayah)}﴾
      </span>
      <span className="say-ref">
        [{surahMeta(surah)?.nameAr}: {localizeDigits(ayah, "ar")}]
      </span>
    </p>
  );
}

const SAY_VIEW: Record<string, (p: { say: Say }) => React.JSX.Element> = {
  dua: ({ say }) => (
    <p className="say-dua" data-testid="say-dua">
      {say.text}
    </p>
  ),
  hadith: ({ say }) => <blockquote className="say-hadith">{say.text}</blockquote>,
  note: ({ say }) => <p className="say-note muted small">{say.text}</p>,
};

/** One line of what is said: an ayah, a dua, the Prophet's practice, or a short note from it. */
function SayItem({ say }: { say: Say }) {
  const View = say.quran ? SayQuran : (SAY_VIEW[say.kind] ?? SAY_VIEW.note!);
  return <View say={say} />;
}
