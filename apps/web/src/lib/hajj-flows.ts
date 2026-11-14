/**
 * Hajj steps in order for each type (owner, 2026-11-14: show the type, Muzdalifah, and what
 * comes before the day of Tarwiyah). Step names only; the explanation of each step stays in the
 * guide's own text, which each step links to. Same lists as apps/mobile/lib/domain/hajj_flows.dart.
 */
export type HajjType = "tamattu" | "qiran" | "ifrad";
export const HAJJ_TYPES: readonly HajjType[] = ["tamattu", "qiran", "ifrad"];

export interface FlowStep {
  title: string;
  /** Anchor on the Hajj page with the explanation. */
  href: string;
}

/** Paragraphs of the official guide (content/pilgrimage/dalil-hajj.v1.json), rendered by OfficialHajjGuide. */
const U = (n: number): string => `#dalil-u${n}`;
const H = (n: number): string => `#dalil-h${n}`;
const TYPES = "#dalil-types";

const DAYS_AFTER_IHRAM: readonly FlowStep[] = [
  { title: "منى يوم التروية", href: H(2) },
  { title: "الوقوف بعرفة", href: H(3) },
  { title: "المبيت بمزدلفة", href: H(4) },
  { title: "رمي جمرة العقبة", href: H(6) },
];
const END: readonly FlowStep[] = [
  { title: "المبيت بمنى أيام التشريق", href: H(8) },
  { title: "رمي الجمرات الثلاث", href: H(9) },
  { title: "طواف الوداع", href: "#hajj-stage-5" },
];
const QIRAN_IFRAD_START: readonly FlowStep[] = [
  { title: "طواف القدوم", href: U(2) },
  { title: "السعي بعد طواف القدوم", href: H(7) },
  { title: "البقاء على الإحرام", href: TYPES },
];

export const HAJJ_FLOWS: Record<HajjType, readonly FlowStep[]> = {
  tamattu: [
    { title: "الإحرام بالعمرة من الميقات", href: U(1) },
    { title: "طواف العمرة", href: U(2) },
    { title: "سعي العمرة", href: U(3) },
    { title: "الحلق أو التقصير والتحلل", href: U(4) },
    { title: "الإحرام بالحج يوم التروية", href: H(1) },
    ...DAYS_AFTER_IHRAM,
    { title: "ذبح الهدي", href: H(6) },
    { title: "الحلق أو التقصير", href: H(6) },
    { title: "طواف الإفاضة ثم السعي", href: H(7) },
    ...END,
  ],
  qiran: [
    { title: "الإحرام بالعمرة والحج من الميقات", href: H(1) },
    ...QIRAN_IFRAD_START,
    ...DAYS_AFTER_IHRAM,
    { title: "ذبح الهدي", href: H(6) },
    { title: "الحلق أو التقصير", href: H(6) },
    { title: "طواف الإفاضة", href: H(7) },
    ...END,
  ],
  ifrad: [
    { title: "الإحرام بالحج من الميقات", href: H(1) },
    ...QIRAN_IFRAD_START,
    ...DAYS_AFTER_IHRAM,
    { title: "الحلق أو التقصير", href: H(6) },
    { title: "طواف الإفاضة", href: H(7) },
    ...END,
  ],
};
