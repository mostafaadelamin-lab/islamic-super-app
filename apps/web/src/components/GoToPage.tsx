"use client";
import { useRouter } from "next/navigation";
import { useId, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import { parsePageInput } from "@/lib/pages";

export function GoToPage({ locale, initial = "" }: { locale: Locale; initial?: string }) {
  const router = useRouter();
  const [value, setValue] = useState(initial);
  const [error, setError] = useState(false);
  const id = useId();
  return (
    <form
      className="row"
      noValidate
      onSubmit={(e) => {
        e.preventDefault();
        const p = parsePageInput(value);
        if (p === null) {
          setError(true);
          return;
        }
        setError(false);
        router.push(href(locale, `page/${p}`));
      }}
    >
      <label htmlFor={`${id}-page`}>{t(locale, "quran.goToPage")}</label>
      <input
        id={`${id}-page`}
        type="text"
        inputMode="numeric"
        size={5}
        value={value}
        placeholder={t(locale, "quran.pageInput")}
        aria-invalid={error || undefined}
        aria-describedby={error ? `${id}-err` : undefined}
        onChange={(e) => setValue(e.target.value)}
      />
      <button type="submit" className="btn btn-primary">
        {t(locale, "quran.go")}
      </button>
      {error ? (
        <p id={`${id}-err`} className="alert alert-error" role="alert" style={{ flexBasis: "100%" }}>
          {t(locale, "quran.invalidPage")}
        </p>
      ) : null}
    </form>
  );
}
