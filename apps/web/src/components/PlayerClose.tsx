"use client";
import { t, type Locale } from "@/lib/i18n";
import { Icon } from "./Icon";

/** The ✕ on every player (owner 2026-11-20): stops the sound and hides the player. */
export function PlayerClose({
  locale,
  onClose,
  testId,
  className = "",
  size = 18,
}: {
  locale: Locale;
  onClose: () => void;
  testId: string;
  className?: string;
  size?: number;
}) {
  return (
    <button
      type="button"
      className={`btn btn-icon player-x ${className}`.trim()}
      aria-label={t(locale, "audio.close")}
      title={t(locale, "audio.close")}
      data-testid={testId}
      onClick={onClose}
    >
      <Icon name="close" size={size} />
    </button>
  );
}
