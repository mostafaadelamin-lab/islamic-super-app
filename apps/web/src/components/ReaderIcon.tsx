/** Line icons used only by the Mushaf reader (24×24, currentColor). Decorative: always aria-hidden. */
const PATHS = {
  chevronDown: "M6 9l6 6 6-6",
  back: "M9 6l6 6-6 6",
  help: "M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18ZM9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.6.3-1 .9-1 1.6v.6M12 17v.5",
  list: "M9 6h11M9 12h11M9 18h11M4.5 6h.5M4.5 12h.5M4.5 18h.5",
  bookmarks: "M6 3h12v18l-6-4-6 4zM9.5 7.5h5",
  khatma: "M3 12c3-2 6-2 9 1 3-3 6-3 9-1M3 12l2 6c3-1.5 5-1 7 1 2-2 4-2.5 7-1l2-6M12 13v6",
  search: "M10.5 4a6.5 6.5 0 1 1 0 13 6.5 6.5 0 0 1 0-13ZM15.5 15.5 21 21",
  repeat: "M4 10V8a2 2 0 0 1 2-2h12l-3-3M20 14v2a2 2 0 0 1-2 2H6l3 3",
  split: "M4 4h16v16H4zM4 12h16M7 8h10M7 16h6",
  reciter:
    "M12 4a3.5 3.5 0 1 1 0 7 3.5 3.5 0 0 1 0-7ZM5 20c.5-3.5 3.3-6 7-6s6.5 2.5 7 6M17.5 5.5c1 .9 1.5 2 1.5 3.3s-.5 2.4-1.5 3.3",
} as const;

export type ReaderIconName = keyof typeof PATHS;
const DEFAULT_SIZE = 22;

export function ReaderIcon({ name, size = DEFAULT_SIZE }: { name: ReaderIconName; size?: number }) {
  return (
    <svg
      className="icon"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      <path d={PATHS[name]} />
    </svg>
  );
}
