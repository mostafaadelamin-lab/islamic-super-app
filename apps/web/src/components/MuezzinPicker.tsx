"use client";
import { useEffect, useMemo, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import {
  BUNDLED_ADHAN_VOICES,
  loadAdhanCatalog,
  normalizeArabic,
  type AdhanVoice,
} from "@/lib/adhan-voices";

/** At most this many matches are shown at once; searching narrows the list. */
const MAX_SHOWN = 80;

/**
 * Picks the muezzin for the adhan, or for the Fajr adhan when `fajr`: the voices served by the site
 * first, then the whole collection. Several recordings of one muezzin are numbered 1, 2, …
 */
export function MuezzinPicker({
  locale,
  fajr,
  value,
  onChange,
}: {
  locale: Locale;
  fajr: boolean;
  value: string;
  onChange: (id: string) => void;
}) {
  const [all, setAll] = useState<readonly AdhanVoice[]>(BUNDLED_ADHAN_VOICES);
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const ar = locale === "ar";
  const kind = fajr ? "fajr" : "regular";

  useEffect(() => {
    let alive = true;
    void (async () => {
      const c = await loadAdhanCatalog();
      if (alive) setAll(c);
    })();
    return () => {
      alive = false;
    };
  }, []);

  const titled = useMemo(() => {
    const list = all.filter((v) => v.fajr === fajr);
    const count = list.reduce((m, v) => m.set(v.nameAr, (m.get(v.nameAr) ?? 0) + 1), new Map<string, number>());
    const seen = new Map<string, number>();
    return list.map((v) => {
      const n = (seen.get(v.nameAr) ?? 0) + 1;
      seen.set(v.nameAr, n);
      const name = ar ? v.nameAr : v.nameEn;
      const title = (count.get(v.nameAr) ?? 0) > 1 ? `${name} (${localizeDigits(String(n), locale)})` : name;
      return { voice: v, title };
    });
  }, [all, fajr, ar, locale]);

  const q = normalizeArabic(query.trim());
  const matches = q
    ? titled.filter(({ voice: v }) => normalizeArabic(`${v.nameAr} ${v.nameEn} ${v.place}`).includes(q))
    : titled;
  const current = titled.find(({ voice }) => voice.id === value);
  const label = t(locale, fajr ? "adhan.fajrVoice" : "adhan.voice");

  return (
    <div className="field muezzin-picker" data-testid={`muezzin-${kind}`}>
      <span className="label">{label}</span>
      <div className="row">
        <strong data-testid={`muezzin-${kind}-current`}>{current?.title ?? value}</strong>
        <button
          type="button"
          className="btn"
          aria-expanded={open}
          onClick={() => setOpen((o) => !o)}
          data-testid={`muezzin-${kind}-change`}
        >
          {t(locale, open ? "adhan.voiceDone" : "adhan.voiceChange")}
        </button>
      </div>
      {open ? (
        <>
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t(locale, "adhan.voiceSearch")}
            aria-label={t(locale, "adhan.voiceSearch")}
            data-testid={`muezzin-${kind}-search`}
          />
          <ul className="muezzin-list" role="radiogroup" aria-label={label}>
            {matches.slice(0, MAX_SHOWN).map(({ voice: v, title }) => (
              <li key={v.id}>
                <label className="check">
                  <input
                    type="radio"
                    name={`muezzin-${kind}`}
                    checked={v.id === value}
                    onChange={() => onChange(v.id)}
                    data-testid={`muezzin-${kind}-${v.id}`}
                  />{" "}
                  {title}
                  {v.place ? <span className="muted"> · {v.place}</span> : null}
                </label>
              </li>
            ))}
          </ul>
          {matches.length > MAX_SHOWN ? (
            <p className="muted">
              {t(locale, "adhan.voiceMore").replace(
                "{n}",
                localizeDigits(String(matches.length - MAX_SHOWN), locale),
              )}
            </p>
          ) : null}
        </>
      ) : null}
    </div>
  );
}
