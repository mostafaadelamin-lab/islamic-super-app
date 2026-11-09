"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { withBase } from "@/lib/base-path";
import { isoDate } from "@/lib/time";
import { shareAppData, sharePromptStore, visit } from "@/lib/app-links";

async function shareApp(locale: Locale): Promise<"shared" | "copied" | "failed"> {
  const data = shareAppData(
    t(locale, "help.shareText"),
    `${window.location.origin}${withBase(`/${locale}/`)}`,
  );
  if (typeof navigator.share === "function") {
    try {
      await navigator.share(data);
      return "shared";
    } catch (e) {
      if (e instanceof DOMException && e.name === "AbortError") return "shared";
    }
  }
  try {
    await navigator.clipboard.writeText(`${data.text} ${data.url}`);
    return "copied";
  } catch {
    return "failed";
  }
}

/** "Share Rattil" button (share sheet, or copies the link). */
export function ShareAppButton({ locale, className = "btn" }: { locale: Locale; className?: string }) {
  const [notice, setNotice] = useState("");
  return (
    <>
      <button
        type="button"
        className={className}
        data-testid="share-app"
        onClick={async () => {
          const r = await shareApp(locale);
          setNotice(r === "copied" ? t(locale, "help.linkCopied") : "");
        }}
      >
        {t(locale, "help.shareApp")}
      </button>{" "}
      <span className="muted small" role="status">
        {notice}
      </span>
    </>
  );
}

/** One-time suggestion to share the app, after the site has been used on a few different days. */
export function SharePrompt({ locale }: { locale: Locale }) {
  const [show, setShow] = useState(false);
  useEffect(() => {
    const d = new Date();
    const r = visit(
      sharePromptStore.get(),
      isoDate({ year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() }),
    );
    sharePromptStore.set(() => r.next);
    setShow(r.show);
  }, []);
  if (!show) return null;
  const close = (): void => {
    sharePromptStore.set((p) => ({ ...p, done: true }));
    setShow(false);
  };
  return (
    <div
      className="share-prompt card"
      role="dialog"
      aria-labelledby="share-prompt-h"
      data-testid="share-prompt"
    >
      <h2 id="share-prompt-h" className="card-title">
        {t(locale, "help.promptTitle")}
      </h2>
      <p>{t(locale, "help.promptBody")}</p>
      <div className="row">
        <button
          type="button"
          className="btn btn-primary"
          data-testid="share-prompt-share"
          onClick={async () => {
            await shareApp(locale);
            close();
          }}
        >
          {t(locale, "help.shareApp")}
        </button>
        <button type="button" className="btn" data-testid="share-prompt-later" onClick={close}>
          {t(locale, "help.notNow")}
        </button>
      </div>
    </div>
  );
}
