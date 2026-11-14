import dalil from "@/generated/dalil-hajj.json";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";

/**
 * The official guide's own words for each step (owner 2026-11-14: explanations come from a published
 * guide, never written by us). Anchors dalil-types, dalil-u1..4 and dalil-h1..9 are linked from the
 * numbered steps graphic (lib/hajj-flows.ts).
 */
export function OfficialHajjGuide({ locale }: { locale: Locale }) {
  const n = (i: number): string => localizeDigits(String(i + 1), locale);
  return (
    <section className="card dalil" id="dalil" data-testid="official-hajj-guide">
      <h3>{t(locale, "hajj.guide.title")}</h3>
      <h4 id="dalil-types">{t(locale, "hajj.guide.types")}</h4>
      <dl lang="ar">
        {dalil.types.map((x) => (
          <div key={x.name}>
            <dt>{x.name}</dt>
            <dd>{x.text}</dd>
          </div>
        ))}
      </dl>
      <p lang="ar">{dalil.typesNote}</p>
      <h4>{t(locale, "hajj.guide.umrah")}</h4>
      <ol lang="ar" className="dalil-list">
        {dalil.umrah.map((p, i) => (
          <li key={i} id={`dalil-u${i + 1}`} value={i + 1}>
            <span className="dalil-n" aria-hidden="true">
              {n(i)}
            </span>
            {p}
          </li>
        ))}
      </ol>
      <h4>{t(locale, "hajj.guide.hajj")}</h4>
      <ol lang="ar" className="dalil-list">
        {dalil.hajj.map((p, i) => (
          <li key={i} id={`dalil-h${i + 1}`} value={i + 1}>
            <span className="dalil-n" aria-hidden="true">
              {n(i)}
            </span>
            {p}
          </li>
        ))}
      </ol>
      <p className="muted small">
        {t(locale, "hajj.guide.source")}: <span lang="ar">{dalil.source.title}</span> —{" "}
        <span lang="ar">{dalil.source.publisher}</span>
      </p>
      <details className="muted small">
        <summary>{t(locale, "hajj.guide.corrections")}</summary>
        <ul lang="ar">
          {dalil.source.corrections.map((c) => (
            <li key={c}>{c}</li>
          ))}
        </ul>
      </details>
    </section>
  );
}
