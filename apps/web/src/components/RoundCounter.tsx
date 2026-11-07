"use client";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import { addRound, roundsStore, ROUNDS_TARGET, type RoundTool } from "@/lib/rounds";
import { useStore } from "@/hooks/useStore";

export function RoundCounter({ locale, tool }: { locale: Locale; tool: RoundTool }) {
  const rounds = useStore(roundsStore);
  const n = rounds[tool];
  const done = n >= ROUNDS_TARGET;
  return (
    <div className="round-counter" id={`counter-${tool}`} data-testid={`rounds-${tool}`}>
      <strong>{t(locale, `hajj.counter.${tool}`)}</strong>
      <ol className="round-dots" aria-hidden="true">
        {Array.from({ length: ROUNDS_TARGET }, (_, i) => (
          <li key={i} className={i < n ? "on" : undefined} />
        ))}
      </ol>
      <p role="status" className={done ? "alert alert-ok" : "muted"} data-testid={`rounds-${tool}-status`}>
        {done
          ? t(locale, "hajj.counter.done")
          : t(locale, "hajj.counter.progress", {
              n: localizeDigits(n, locale),
              total: localizeDigits(ROUNDS_TARGET, locale),
            })}
      </p>
      <div className="row">
        <button
          type="button"
          className="btn btn-primary"
          disabled={done}
          onClick={() => roundsStore.set((r) => addRound(r, tool, 1))}
        >
          {t(locale, "hajj.counter.add")}
        </button>
        <button
          type="button"
          className="btn"
          disabled={n === 0}
          onClick={() => roundsStore.set((r) => addRound(r, tool, -1))}
        >
          {t(locale, "hajj.counter.undo")}
        </button>
        <button
          type="button"
          className="btn"
          disabled={n === 0}
          onClick={() => roundsStore.set((r) => ({ ...r, [tool]: 0 }))}
        >
          {t(locale, "hajj.counter.reset")}
        </button>
      </div>
    </div>
  );
}
