"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { HAJJ_FLOWS, HAJJ_TYPES, type HajjType } from "@/lib/hajj-flows";
import { StepsFlow } from "./StepsFlow";

/** Hajj steps 1, 2, 3… for the chosen type (tamattu' by default), each linking to its explanation. */
export function HajjTypeFlow({ locale }: { locale: Locale }) {
  const [type, setType] = useState<HajjType>("tamattu");
  const steps = HAJJ_FLOWS[type];
  return (
    <section className="card" data-testid="hajj-type-flow">
      <h3>{t(locale, "hajj.flow.hajj")}</h3>
      <div className="row" role="tablist" aria-label={t(locale, "hajj.flow.type")}>
        {HAJJ_TYPES.map((k) => (
          <button
            key={k}
            type="button"
            role="tab"
            aria-selected={type === k}
            className={type === k ? "btn btn-sm btn-primary" : "btn btn-sm"}
            onClick={() => setType(k)}
            data-testid={`hajj-type-${k}`}
          >
            {t(locale, `hajj.flow.${k}`)}
          </button>
        ))}
      </div>
      <StepsFlow
        locale={locale}
        titles={steps.map((s) => s.title)}
        hrefs={steps.map((s) => s.href)}
        idPrefix={`hajj-${type}`}
        label={`${t(locale, "hajj.flow.hajj")}: ${t(locale, `hajj.flow.${type}`)}`}
      />
    </section>
  );
}
