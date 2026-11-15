import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { GUIDE, Segs } from "./HajjGuide";

/**
 * The official guide «دليل الحاج والمعتمر» in full (owner 2026-11-14: explanations come from a published
 * guide). Its ayahs are shown in the KFGQPC text (content/pilgrimage/build-guide.mjs puts them in).
 */
export function OfficialHajjGuide({ locale }: { locale: Locale }) {
  const n = (i: number): string => localizeDigits(String(i + 1), locale);
  const o = GUIDE.official;
  return (
    <section className="card dalil" id="dalil" data-testid="official-hajj-guide">
      <h3>{t(locale, "hajj.guide.title")}</h3>
      <h4 id="dalil-types">{t(locale, "hajj.guide.types")}</h4>
      <dl lang="ar">
        {o.types.map((x) => (
          <div key={x.name}>
            <dt>{x.name}</dt>
            <dd>
              <Segs segs={x.segs} />
            </dd>
          </div>
        ))}
      </dl>
      <p lang="ar">
        <Segs segs={o.typesNote} />
      </p>
      {(["umrah", "hajj"] as const).map((part) => (
        <div key={part}>
          <h4>{t(locale, `hajj.guide.${part}`)}</h4>
          <ol lang="ar" className="dalil-list">
            {o[part].map((p, i) => (
              <li key={i} id={`dalil-${part[0]}${i + 1}`} value={i + 1}>
                <span className="dalil-n" aria-hidden="true">
                  {n(i)}
                </span>
                <Segs segs={p} />
              </li>
            ))}
          </ol>
        </div>
      ))}
      <p className="muted small">
        {t(locale, "hajj.ref")}: <span lang="ar">{o.title}</span>
      </p>
    </section>
  );
}
