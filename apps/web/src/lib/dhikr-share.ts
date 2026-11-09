/**
 * Sharing a dhikr (text unchanged, with where it comes from) and reporting a mistake in one. A report opens
 * the reader's email app with the details filled in; they choose where to send it.
 */
import { createStore } from "./store";

/** How long a report quotes the dhikr: enough to find it, short enough for a mail link. */
const QUOTE_CHARS = 80;

export type AdhkarMode = "list" | "cards";
export interface AdhkarViewPrefs {
  mode: AdhkarMode;
}
export const adhkarViewStore = createStore<AdhkarViewPrefs>(
  "rattil.adhkarView",
  { mode: "list" },
  (raw: unknown): AdhkarViewPrefs => ({
    mode:
      typeof raw === "object" && raw !== null && (raw as { mode?: unknown }).mode === "cards"
        ? "cards"
        : "list",
  }),
);

/** The text shared for a dhikr: the text itself, then its source line. */
export const shareBody = (text: string, source: string): string => `${text}\n\n— ${source}`;

export function reportBody(where: string, text: string, intro: string): string {
  const quote = text.length > QUOTE_CHARS ? `${text.slice(0, QUOTE_CHARS)}…` : text;
  return `${intro}\n\n${where}\n«${quote}»\n\n`;
}

/** mailto: link with no recipient: the reader picks the address (the project contact page lists it). */
export const reportMailto = (subject: string, body: string): string =>
  `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

export type ShareResult = "shared" | "copied" | "cancelled" | "failed";

/** System share sheet when available, otherwise the clipboard. */
export async function shareDhikr(body: string): Promise<ShareResult> {
  if (typeof navigator.share === "function") {
    try {
      await navigator.share({ text: body });
      return "shared";
    } catch (e) {
      if (e instanceof DOMException && e.name === "AbortError") return "cancelled";
    }
  }
  try {
    await navigator.clipboard.writeText(body);
    return "copied";
  } catch {
    return "failed";
  }
}
