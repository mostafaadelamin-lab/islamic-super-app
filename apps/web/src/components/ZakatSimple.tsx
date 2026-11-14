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
  ZAKAT_TABS,
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

/** The app's five-tab zakat calculator (silver, gold, money, livestock, crops), same rules and wording. */
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
    <label className="field" key={`${s.tab}-${k}`}>
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
  const result = (reached: boolean, text: string, note?: string) => (
    <div
      className={`card zakat-simple-result${reached ? " reached" : ""}`}
      role="status"
      data-testid="zakat-simple-result"
      data-reached={reached}
    >
      <p className="zakat-simple-answer">
        {text.split("\n").map((line, i) => (
          <span key={i}>
            {i > 0 ? <br /> : null}
            {line}
          </span>
        ))}
      </p>
      {note ? (
        <p className="muted small">
          {note.split("\n").map((line, i) => (
            <span key={i}>
              {i > 0 ? <br /> : null}
              {line}
            </span>
          ))}
        </p>
      ) : null}
    </div>
  );
  const rule = (key: string) => <p className="muted small">{L(key)}</p>;

  let body: React.ReactNode;
  switch (s.tab) {
    case "silver": {
      const grams = n("silver") ?? 0;
      const r = silverZakat(grams, n("silverPrice"));
      body = (
        <>
          {grams > 0
            ? result(
                r.reached,
                r.reached
                  ? L("zakat.s.dueSilver", { g: fmt(r.dueGrams) }) +
                      (r.dueMoney == null ? "" : `\n${L("zakat.s.dueMoney", { v: fmt(r.dueMoney) })}`)
                  : L("zakat.s.belowNisab"),
                L("zakat.s.yearNote"),
              )
            : null}
          {field("silver", L("zakat.s.silverGrams"), L("zakat.s.gram"))}
          {field("silverPrice", L("zakat.s.silverPrice"))}
          {rule("zakat.s.silverRule")}
        </>
      );
      break;
    }
    case "gold": {
      const grams = n("gold") ?? 0;
      const r = goldZakat(grams, s.karat, n("goldPrice"));
      body = (
        <>
          {grams > 0
            ? result(
                r.reached,
                r.reached
                  ? L("zakat.s.dueGold", { g: fmt(r.dueGrams), k: localizeDigits(s.karat, locale) }) +
                      (r.dueMoney == null ? "" : `\n${L("zakat.s.dueMoney", { v: fmt(r.dueMoney) })}`)
                  : L("zakat.s.belowNisab"),
                L("zakat.s.yearNote"),
              )
            : null}
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
          {rule("zakat.s.goldRule")}
        </>
      );
      break;
    }
    case "money": {
      const byGold = s.basis === "gold";
      const price = byGold ? n("goldPrice") : n("silverPrice");
      const amount = n("money") ?? 0;
      const nisab = price == null ? 0 : price * (byGold ? GOLD_NISAB_GRAMS : SILVER_NISAB_GRAMS);
      const r = moneyZakat(amount, nisab);
      body = (
        <>
          {amount > 0
            ? result(
                r.reached,
                price == null
                  ? L(byGold ? "zakat.s.needGoldPrice" : "zakat.s.needSilverPrice")
                  : r.reached
                    ? L("zakat.s.dueMoney", { v: fmt(r.due) })
                    : L("zakat.s.belowNisab"),
                price == null ? undefined : `${L("zakat.s.nisabIs", { v: fmt(nisab, 0) })}\n${L("zakat.s.yearNote")}`,
              )
            : null}
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
          {byGold ? field("goldPrice", L("zakat.s.goldPrice")) : field("silverPrice", L("zakat.s.silverPrice"))}
          {rule("zakat.s.moneyRule")}
        </>
      );
      break;
    }
    case "livestock": {
      const count = Math.floor(n("animals") ?? 0);
      const due = livestockZakat(s.animal, count);
      const unit = (u: string): string => L(`zakat.s.unit${u[0]!.toUpperCase()}${u.slice(1)}`);
      body = (
        <>
          {count > 0
            ? result(
                due.length > 0,
                due.length === 0
                  ? L("zakat.s.belowNisab")
                  : L("zakat.s.dueAnimals", {
                      v: due.map(([k, u]) => `${localizeDigits(k, locale)} ${unit(u)}`).join(" + "),
                    }),
                L("zakat.s.livestockNote"),
              )
            : null}
          {seg(
            L("zakat.s.tabLivestock"),
            "animal",
            ANIMALS.map(([a, k]) => [a, L(k)] as [Livestock, string]),
            s.animal,
            (a) => patch({ animal: a }),
          )}
          {field("animals", L("zakat.s.animalCount"))}
          {rule("zakat.s.livestockRule")}
        </>
      );
      break;
    }
    case "crops": {
      const kg = n("crops") ?? 0;
      const r = cropsZakat(kg, s.rain);
      body = (
        <>
          {kg > 0
            ? result(
                r.reached,
                r.reached ? L("zakat.s.dueCrops", { kg: fmt(r.dueKg) }) : L("zakat.s.belowNisab"),
                L("zakat.s.cropsNote"),
              )
            : null}
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
        </>
      );
      break;
    }
  }

  return (
    <div className="zakat-simple" data-testid="zakat-simple">
      <div className="segmented zakat-tabs" role="tablist" aria-label={L("zakat.title")} data-testid="zakat-tabs">
        {ZAKAT_TABS.map((tab) => (
          <button
            key={tab}
            type="button"
            role="tab"
            aria-selected={s.tab === tab}
            aria-pressed={s.tab === tab}
            data-testid={`zakat-tab-${tab}`}
            onClick={() => patch({ tab })}
          >
            {L(TAB_KEY[tab])}
          </button>
        ))}
      </div>
      <section className="card zakat-simple-body" role="tabpanel" data-testid={`zakat-panel-${s.tab}`}>
        {body}
      </section>
    </div>
  );
}
