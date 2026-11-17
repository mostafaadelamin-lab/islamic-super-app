"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { useStore } from "@/hooks/useStore";
import {
  cropsZakat,
  GOLD_NISAB_GRAMS,
  goldZakat,
  livestockZakat,
  moneyZakat,
  SILVER_NISAB_GRAMS,
  silverZakat,
  simpleZakatStore,
  type Livestock,
  type SimpleZakatState,
  type ZakatTab,
} from "@/lib/zakat-simple";

const TAB_KEY: Record<ZakatTab, string> = {
  silver: "zakat.s.tabSilver",
  gold: "zakat.s.tabGold",
  money: "zakat.s.tabMoney",
  livestock: "zakat.s.tabLivestock",
  crops: "zakat.s.tabCrops",
};
const ANIMALS: readonly [Livestock, string][] = [
  ["sheep", "zakat.s.sheep"],
  ["cattle", "zakat.s.cattle"],
  ["camels", "zakat.s.camels"],
];

/** "١٢٫٥" or "12,5" → 12.5; anything else → null. */
export function parseAmount(raw: string): number | null {
  const ascii = raw
    .trim()
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x660))
    .replace(/[٫,]/g, ".");
  if (ascii === "") return null;
  const v = Number(ascii);
  return Number.isFinite(v) && v >= 0 ? v : null;
}

/** The app's zakat calculator: money, gold, silver, livestock and crops on one page, then the total. */
export function ZakatSimple({ locale }: { locale: Locale }) {
  const s = useStore(simpleZakatStore);
  const L = (key: string, vars?: Record<string, string | number>): string => t(locale, key, vars);
  const fmt = (v: number, digits = 2): string =>
    localizeDigits(v.toLocaleString("en-US", { maximumFractionDigits: digits, useGrouping: false }), locale);
  const n = (k: string): number | null => (k in s.values ? (s.values[k] as number) : null);
  const patch = (p: Partial<SimpleZakatState>): void => simpleZakatStore.set((prev) => ({ ...prev, ...p }));
  const setValue = (k: string, raw: string): void =>
    simpleZakatStore.set((prev) => {
      const values = { ...prev.values };
      const v = parseAmount(raw);
      if (v == null) delete values[k];
      else values[k] = v;
      return { ...prev, values };
    });

  const field = (k: string, label: string, suffix?: string) => (
    <label className="field" key={k}>
      <span>{label}</span>
      <span className="row">
        <input
          type="text"
          inputMode="decimal"
          dir="ltr"
          defaultValue={n(k) == null ? "" : String(n(k))}
          data-testid={`zakat-in-${k}`}
          onChange={(e) => setValue(k, e.target.value)}
        />
        {suffix ? <span className="muted">{suffix}</span> : null}
      </span>
    </label>
  );
  const seg = <T extends string | number | boolean>(
    label: string,
    id: string,
    options: readonly [T, string][],
    value: T,
    onPick: (v: T) => void,
  ) => (
    <div className="segmented" role="group" aria-label={label} data-testid={`zakat-${id}`}>
      {options.map(([v, text]) => (
        <button key={String(v)} type="button" aria-pressed={value === v} onClick={() => onPick(v)}>
          {text}
        </button>
      ))}
    </div>
  );
  const rule = (key: string) => <p className="muted small">{L(key)}</p>;

  // One page, every kind under the other, the total at the bottom (as the app, owner 2026-11-17).
  const dash = L("zakat.s.dueEmpty");
  const money = (v: number): string => L("zakat.s.shortMoney", { v: fmt(v, 0) });
  const grams = (v: number): string => L("zakat.s.shortGrams", { g: fmt(v) });
  let totalMoney = 0;
  const totalOther: string[] = [];
  let anyEntered = false;
  const add = (m: number | null, other: string | null, entered: boolean): void => {
    if (m != null) totalMoney += m;
    if (other != null) totalOther.push(other);
    anyEntered = anyEntered || entered;
  };
  const section = (id: ZakatTab, due: string, reached: boolean, children: React.ReactNode) => (
    <section
      className="card zakat-section"
      key={id}
      aria-labelledby={`zakat-h-${id}`}
      data-testid={`zakat-section-${id}`}
    >
      <div className="zakat-section-head">
        <h2 id={`zakat-h-${id}`}>{L(TAB_KEY[id])}</h2>
        <span
          className={`zakat-due-badge${reached ? " reached" : ""}`}
          data-testid={`zakat-due-${id}`}
          data-reached={reached}
        >
          {due}
        </span>
      </div>
      {children}
    </section>
  );

  // Money: its nisab from the gold or silver price typed in those cards.
  const byGold = s.basis === "gold";
  const moneyPrice = byGold ? n("goldPrice") : n("silverPrice");
  const amount = n("money") ?? 0;
  const nisab = moneyPrice == null ? 0 : moneyPrice * (byGold ? GOLD_NISAB_GRAMS : SILVER_NISAB_GRAMS);
  const mr = moneyZakat(amount, nisab);
  const moneyReached = amount > 0 && moneyPrice != null && mr.reached;
  add(moneyReached ? mr.due : null, null, amount > 0);
  const moneyCard = section(
    "money",
    amount <= 0 || moneyPrice == null ? dash : moneyReached ? money(mr.due) : L("zakat.s.dueNone"),
    moneyReached,
    <>
      {field("money", L("zakat.s.money"))}
      <p className="field-label">{L("zakat.s.basis")}</p>
      {seg(
        L("zakat.s.basis"),
        "basis",
        [
          ["gold", L("zakat.s.basisGold")],
          ["silver", L("zakat.s.basisSilver")],
        ] as const,
        s.basis,
        (b) => patch({ basis: b }),
      )}
      {amount > 0 && moneyPrice == null ? (
        <p className="alert alert-error small" data-testid="zakat-need-price">
          {L(byGold ? "zakat.s.needGoldPrice" : "zakat.s.needSilverPrice")}
        </p>
      ) : moneyPrice != null ? (
        <p className="muted small">{L("zakat.s.nisabIs", { v: fmt(nisab, 0) })}</p>
      ) : null}
      {rule("zakat.s.moneyRule")}
    </>,
  );

  const goldG = n("gold") ?? 0;
  const gr = goldZakat(goldG, s.karat, n("goldPrice"));
  const goldReached = goldG > 0 && gr.reached;
  add(
    goldReached ? gr.dueMoney : null,
    goldReached && gr.dueMoney == null ? `${grams(gr.dueGrams)} (${L("zakat.s.tabGold")})` : null,
    goldG > 0,
  );
  const goldCard = section(
    "gold",
    goldG <= 0
      ? dash
      : !gr.reached
        ? L("zakat.s.dueNone")
        : gr.dueMoney != null
          ? money(gr.dueMoney)
          : grams(gr.dueGrams),
    goldReached,
    <>
      {field("gold", L("zakat.s.goldGrams"), L("zakat.s.gram"))}
      <p className="field-label">{L("zakat.s.karat")}</p>
      {seg(
        L("zakat.s.karat"),
        "karat",
        ([24, 21, 18] as const).map((k) => [k, localizeDigits(k, locale)] as [24 | 21 | 18, string]),
        s.karat,
        (k) => patch({ karat: k }),
      )}
      {field("goldPrice", L("zakat.s.goldPrice"))}
      {goldReached ? (
        <p data-testid="zakat-result-gold">
          {L("zakat.s.dueGold", { g: fmt(gr.dueGrams), k: localizeDigits(s.karat, locale) })}
        </p>
      ) : null}
      {rule("zakat.s.goldRule")}
    </>,
  );

  const silverG = n("silver") ?? 0;
  const sr = silverZakat(silverG, n("silverPrice"));
  const silverReached = silverG > 0 && sr.reached;
  add(
    silverReached ? sr.dueMoney : null,
    silverReached && sr.dueMoney == null ? `${grams(sr.dueGrams)} (${L("zakat.s.tabSilver")})` : null,
    silverG > 0,
  );
  const silverCard = section(
    "silver",
    silverG <= 0
      ? dash
      : !sr.reached
        ? L("zakat.s.dueNone")
        : sr.dueMoney != null
          ? money(sr.dueMoney)
          : grams(sr.dueGrams),
    silverReached,
    <>
      {field("silver", L("zakat.s.silverGrams"), L("zakat.s.gram"))}
      {field("silverPrice", L("zakat.s.silverPrice"))}
      {silverReached ? (
        <p data-testid="zakat-result-silver">{L("zakat.s.dueSilver", { g: fmt(sr.dueGrams) })}</p>
      ) : null}
      {rule("zakat.s.silverRule")}
    </>,
  );

  const count = Math.floor(n("animals") ?? 0);
  const animals = livestockZakat(s.animal, count);
  const unit = (u: string): string => L(`zakat.s.unit${u[0]!.toUpperCase()}${u.slice(1)}`);
  const animalsText = animals.map(([k, u]) => `${localizeDigits(k, locale)} ${unit(u)}`).join(" + ");
  add(null, animals.length === 0 ? null : animalsText, count > 0);
  const livestockCard = section(
    "livestock",
    count <= 0 ? dash : animals.length === 0 ? L("zakat.s.dueNone") : animalsText,
    animals.length > 0,
    <>
      {seg(
        L("zakat.s.tabLivestock"),
        "animal",
        ANIMALS.map(([a, k]) => [a, L(k)] as [Livestock, string]),
        s.animal,
        (a) => patch({ animal: a }),
      )}
      {field("animals", L("zakat.s.animalCount"))}
      {rule("zakat.s.livestockRule")}
      {count > 0 ? rule("zakat.s.livestockNote") : null}
    </>,
  );

  const kg = n("crops") ?? 0;
  const cr = cropsZakat(kg, s.rain);
  const cropsReached = kg > 0 && cr.reached;
  const cropsShort = L("zakat.s.shortKg", { kg: fmt(cr.dueKg) });
  add(null, cropsReached ? `${cropsShort} (${L("zakat.s.tabCrops")})` : null, kg > 0);
  const cropsCard = section(
    "crops",
    kg <= 0 ? dash : cropsReached ? cropsShort : L("zakat.s.dueNone"),
    cropsReached,
    <>
      {field("crops", L("zakat.s.cropsKg"), L("zakat.s.kg"))}
      {seg(
        L("zakat.s.tabCrops"),
        "rain",
        [
          [true, L("zakat.s.rain")],
          [false, L("zakat.s.irrigated")],
        ] as const,
        s.rain,
        (v) => patch({ rain: v }),
      )}
      {rule("zakat.s.cropsRule")}
      {kg > 0 ? rule("zakat.s.cropsNote") : null}
    </>,
  );

  const hasDue = totalMoney > 0 || totalOther.length > 0;
  return (
    <div className="zakat-simple" data-testid="zakat-simple">
      {moneyCard}
      {goldCard}
      {silverCard}
      {livestockCard}
      {cropsCard}
      <section
        className={`card zakat-total${hasDue ? " reached" : ""}`}
        role="status"
        aria-live="polite"
        data-testid="zakat-total"
        data-reached={hasDue}
      >
        <h2>{L("zakat.s.totalTitle")}</h2>
        {!anyEntered ? (
          <p data-testid="zakat-total-empty">{L("zakat.s.totalEmpty")}</p>
        ) : !hasDue ? (
          <p className="zakat-total-none">{L("zakat.s.totalNone")}</p>
        ) : (
          <>
            {totalMoney > 0 ? (
              <p className="zakat-total-amount" data-testid="zakat-total-amount">
                {money(totalMoney)}
              </p>
            ) : null}
            {totalOther.length > 0 ? (
              <p className="zakat-total-other" data-testid="zakat-total-other">
                {totalMoney > 0
                  ? L("zakat.s.totalAlso", { v: totalOther.join(locale === "ar" ? "، " : ", ") })
                  : totalOther.join(locale === "ar" ? "، " : ", ")}
              </p>
            ) : null}
          </>
        )}
        <p className="muted small">{L("zakat.s.yearNote")}</p>
      </section>
    </div>
  );
}
