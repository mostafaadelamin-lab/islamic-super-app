"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { reportBody, reportMailto, shareBody, shareDhikr } from "@/lib/dhikr-share";

/** Share and "report a mistake" for one dhikr. `where` names it (chapter and number) in the report. */
export function DhikrTools({
  locale,
  text,
  source,
  where,
  testId,
}: {
  locale: Locale;
  text: string;
  source: string;
  where: string;
  testId: string;
}) {
  const [notice, setNotice] = useState("");
  const share = async (): Promise<void> => {
    const r = await shareDhikr(shareBody(text, source));
    if (r === "copied") setNotice(t(locale, "dhikr.copied"));
    else if (r === "failed") setNotice(t(locale, "dhikr.shareFailed"));
    else setNotice("");
  };
  const mail = reportMailto(
    t(locale, "dhikr.reportSubject"),
    reportBody(where, text, t(locale, "dhikr.reportIntro")),
  );
  return (
    <div className="dhikr-tools">
      <button
        type="button"
        className="btn btn-sm"
        onClick={() => void share()}
        data-testid={`${testId}-share`}
      >
        {t(locale, "dhikr.share")}
      </button>
      <a className="btn btn-sm" href={mail} data-testid={`${testId}-report`}>
        {t(locale, "dhikr.report")}
      </a>
      <span className="muted small" role="status">
        {notice}
      </span>
    </div>
  );
}
