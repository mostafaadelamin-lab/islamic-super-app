"use client";
import { useEffect, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { Icon } from "./Icon";

interface InstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
}

/** Edge/Chrome fire this once the site qualifies as an installable app (manifest + service worker). */
let deferred: InstallPromptEvent | null = null;
let installedNow = false;
const listeners = new Set<() => void>();
if (typeof window !== "undefined") {
  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    deferred = e as InstallPromptEvent;
    listeners.forEach((l) => l());
  });
  window.addEventListener("appinstalled", () => {
    deferred = null;
    installedNow = true;
    listeners.forEach((l) => l());
  });
}

const standalone = (): boolean =>
  typeof window !== "undefined" &&
  (window.matchMedia?.("(display-mode: standalone)").matches === true ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true);

/** "Install as an app": Windows desktop/Start menu shortcut (and Android/macOS) through the browser's install. */
export function InstallApp({ locale }: { locale: Locale }) {
  const [, force] = useState(0);
  const [installed, setInstalled] = useState(false);
  useEffect(() => {
    setInstalled(standalone() || installedNow);
    const l = (): void => {
      setInstalled(standalone() || installedNow);
      force((x) => x + 1);
    };
    listeners.add(l);
    return () => {
      listeners.delete(l);
    };
  }, []);

  return (
    <section className="card" data-testid="install-app" aria-labelledby="install-h">
      <h2 id="install-h" className="card-title">
        <Icon name="download" /> {t(locale, "pwa.install")}
      </h2>
      {installed ? (
        <p data-testid="install-done">{t(locale, "pwa.installed")}</p>
      ) : (
        <>
          <p>{t(locale, "pwa.installSub")}</p>
          {deferred ? (
            <p>
              <button
                type="button"
                className="btn btn-primary"
                data-testid="install-button"
                onClick={async () => {
                  const ev = deferred;
                  if (!ev) return;
                  await ev.prompt();
                  const { outcome } = await ev.userChoice;
                  if (outcome === "accepted") {
                    deferred = null;
                    setInstalled(true);
                  }
                }}
              >
                {t(locale, "pwa.install")}
              </button>
            </p>
          ) : (
            <p className="muted small" data-testid="install-howto">
              {t(locale, "pwa.howTo")}
            </p>
          )}
        </>
      )}
    </section>
  );
}
