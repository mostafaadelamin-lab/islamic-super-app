"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { computeZakat, ZAKAT, zakatSource, zakatStore, type ZakatResult } from "@/lib/zakat";
import { useStore } from "@/hooks/useStore";

const MONEY_DECIMALS = 2;
/** Arabic-Indic digits typed on an Arabic keyboard: "١٢٫٥" → matches "١" and "٢". https://regex101.com/?regex=%5B%D9%A0-%D9%A9%5D&testString=%D9%A1%D9%A2 */
const ARABIC_DIGIT_RE = /[٠-٩]/g;
const ARABIC_ZERO = "٠".charCodeAt(0);

/** Zakat on money after Dar al-Ifta al-Misriyya's fatwas; every rule links to its fatwa. */
export function ZakatCalculator({ locale }: { locale: Locale }) {
  const s = useStore(zakatStore);
  const money = (v: number): string =>
    localizeDigits(
      v.toLocaleString("en-US", { maximumFractionDigits: MONEY_DECIMALS, minimumFractionDigits: 0 }),
      locale,
    );
  const parse = (raw: string): number => {
    const v = Number(raw.replace(ARABIC_DIGIT_RE, (d) => String(d.charCodeAt(0) - ARABIC_ZERO)));
    return Number.isFinite(v) && v > 0 ? v : 0;
  };
  const setValue = (id: string, raw: string): void =>
    zakatStore.set((prev) => ({ ...prev, values: { ...prev.values, [id]: parse(raw) } }));
  const result = computeZakat(s.values, s.price, s.yearPassed);
  const adornment = zakatSource("adornment");

  return (
    <>
      <p className="alert alert-warn" role="note" data-testid="zakat-review">
        {t(locale, "zakat.review")}
      </p>
      <section className="card" aria-labelledby="zakat-price-h">
        <h2 id="zakat-price-h" className="card-title">
          {t(locale, "zakat.priceTitle")}
        </h2>
        <label className="field">
          <span>{t(locale, "zakat.price")}</span>
          <input
            type="number"
            inputMode="decimal"
            min={0}
            data-testid="zakat-price"
            defaultValue={s.price || ""}
            onChange={(e) => {
              const price = parse(e.target.value);
              zakatStore.set((prev) => ({ ...prev, price }));
            }}
          />
        </label>
        <p className="small muted">
          {t(locale, "zakat.nisabRule", {
            grams: localizeDigits(ZAKAT.rules.nisabGoldGrams, locale),
            karat: localizeDigits(ZAKAT.rules.nisabKarat, locale),
          })}
        </p>
      </section>
      <section className="card" aria-labelledby="zakat-wealth-h">
        <h2 id="zakat-wealth-h" className="card-title">
          {t(locale, "zakat.wealth")}
        </h2>
        {ZAKAT.fields.map((f) => (
          <label key={f.id} className="field">
            <span>{t(locale, `zakat.field.${f.id}`)}</span>
            <input
              type="number"
              inputMode="decimal"
              min={0}
              data-testid={`zakat-${f.id}`}
              defaultValue={s.values[f.id] || ""}
              onChange={(e) => setValue(f.id, e.target.value)}
            />
          </label>
        ))}
        <label className="check">
          <input
            type="checkbox"
            data-testid="zakat-year"
            checked={s.yearPassed}
            onChange={(e) => {
              const yearPassed = e.target.checked;
              zakatStore.set((prev) => ({ ...prev, yearPassed }));
            }}
          />
          <span>{t(locale, "zakat.yearPassed")}</span>
        </label>
      </section>
      <section className="card" aria-live="polite" data-testid="zakat-result" data-status={result.status}>
        <h2 className="card-title">{t(locale, "zakat.result")}</h2>
        <ResultText locale={locale} result={result} money={money} />
      </section>
      {adornment ? (
        <section className="card" aria-labelledby="zakat-adorn-h">
          <h2 id="zakat-adorn-h" className="card-title">
            {t(locale, "zakat.adornment")}
          </h2>
          <blockquote lang="ar" dir="rtl" data-testid="zakat-adornment">
            «{adornment.quotes[0]}»
          </blockquote>
          <p className="small">
            <a href={adornment.url} rel="noopener" target="_blank">
              {t(locale, "zakat.fatwa", { n: localizeDigits(adornment.number, locale) })}
            </a>
          </p>
        </section>
      ) : null}
      <section className="card" aria-labelledby="zakat-src-h">
        <h2 id="zakat-src-h" className="card-title">
          {t(locale, "zakat.sources", {
            ref: locale === "ar" ? ZAKAT.reference.nameAr : ZAKAT.reference.nameEn,
          })}
        </h2>
        {ZAKAT.sources.map((src) => (
          <details key={src.id} className="faq" data-testid={`zakat-src-${src.id}`}>
            <summary lang="ar">{src.titleAr}</summary>
            {src.quotes.map((q) => (
              <blockquote key={q} lang="ar" dir="rtl">
                «{q}»
              </blockquote>
            ))}
            <p className="small">
              <a href={src.url} rel="noopener" target="_blank">
                {t(locale, "zakat.fatwa", { n: localizeDigits(src.number, locale) })}
              </a>
            </p>
          </details>
        ))}
      </section>
    </>
  );
}

function ResultText({
  locale,
  result,
  money,
}: {
  locale: Locale;
  result: ZakatResult;
  money: (v: number) => string;
}) {
  if (result.status === "needPrice") return <p>{t(locale, "zakat.needPrice")}</p>;
  const amounts = { net: money(result.net), nisab: money(result.nisab) };
  if (result.status === "belowNisab") return <p>{t(locale, "zakat.belowNisab", amounts)}</p>;
  if (result.status === "yearNotPassed") return <p>{t(locale, "zakat.yearNotPassed", amounts)}</p>;
  return (
    <>
      <p className="zakat-due" data-testid="zakat-amount">
        {t(locale, "zakat.due", { zakat: money(result.zakat) })}
      </p>
      <p className="small muted">{t(locale, "zakat.dueDetail", amounts)}</p>
    </>
  );
}
