import { ICON_FILLED, ICON_PATHS, ICON_STROKE_WIDTH } from "@/generated/icons";

/**
 * The Rattil icon set (packages/design-tokens/icons.json): our own 24×24 line icons, shared with
 * the mobile app (RIcon) so both look the same. currentColor; decorative, so always aria-hidden.
 */
export type IconName = keyof typeof ICON_PATHS;
const DEFAULT_SIZE = 22;
const FILLED: ReadonlySet<string> = new Set(ICON_FILLED);

export function Icon({ name, size = DEFAULT_SIZE }: { name: IconName; size?: number }) {
  return (
    <svg
      className="icon"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={FILLED.has(name) ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth={ICON_STROKE_WIDTH}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      <path d={ICON_PATHS[name]} />
    </svg>
  );
}
