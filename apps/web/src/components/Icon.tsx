/** Small inline line icons (24×24, currentColor). Decorative: always aria-hidden. */
const PATHS = {
  home: "M3 11.5 12 4l9 7.5M5.5 9.5V20h5v-5.5h3V20h5V9.5",
  quran: "M12 6.5C10 5 7 4.5 4 5v13c3-.5 6 0 8 1.5M12 6.5c2-1.5 5-2 8-1.5v13c-3-.5-6 0-8 1.5M12 6.5v13",
  prayer:
    "M12 3c1.5 2 3.5 3 3.5 5.5a3.5 3.5 0 0 1-7 0C8.5 6 10.5 5 12 3ZM5 21V12h14v9M9 21v-4a3 3 0 0 1 6 0v4",
  adhkar:
    "M12 3a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm-5.5 3.5a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm11 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4ZM5 13a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm14 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4Zm-7 4v4",
  more: "M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z",
  play: "M8 5v14l11-7z",
  headphones: "M4 14v-2a8 8 0 0 1 16 0v2M4 14h3v6H5a1 1 0 0 1-1-1v-5Zm16 0h-3v6h2a1 1 0 0 0 1-1v-5Z",
  reels: "M7 3h10a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2ZM10 9v6l5-3z",
  pause: "M7 5h4v14H7zM13 5h4v14h-4z",
  stop: "M6 6h12v12H6z",
  next: "M6 6v12l8.5-6zM16 6h2v12h-2z",
  prev: "M18 6v12L9.5 12zM6 6h2v12H6z",
  bookmark: "M6 3h12v18l-6-4-6 4z",
  copy: "M9 9h11v11H9zM5 15H4V4h11v1",
  close: "M6 6l12 12M18 6 6 18",
  search: "M10.5 4a6.5 6.5 0 1 1 0 13 6.5 6.5 0 0 1 0-13ZM15.5 15.5 21 21",
  compass: "M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18Zm3.5 5.5-2 5-5 2 2-5z",
  beads: "M12 4a8 8 0 1 1-5.7 13.7M12 4a1.6 1.6 0 1 1 0 .1M6.3 17.7 4 20",
  book: "M5 4h10a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h10",
  kaaba: "M4 8l8-4 8 4v10l-8 3-8-3zM4 8l8 3 8-3M12 11v10M4 12.5l8 3 8-3",
  khatma: "M12 3a9 9 0 1 0 9 9M12 3v4M21 12h-4M8.5 12.5l2.5 2.5 5-5",
  calendarCheck: "M4 5h16v15H4zM4 9h16M8 3v4M16 3v4M8.5 14.5l2 2 4.5-4.5",
  settings:
    "M12 9a3 3 0 1 1 0 6 3 3 0 0 1 0-6ZM19 12l2-1-1-3-2.3.3-1.3-1.3L16.7 4l-3-1-1 2h-1.4l-1-2-3 1 .3 2.3L6.3 7.6 4 7.3 3 10l2 1v2l-2 1 1 3 2.3-.3 1.3 1.3L7.3 20l3 1 1-2h1.4l1 2 3-1-.3-2.3 1.3-1.3 2.3.3 1-3-2-1z",
  info: "M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18ZM12 11v6M12 7.5v.5",
  sun: "M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8ZM12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
  moon: "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z",
  location:
    "M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11Zm0-13.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5Z",
  undo: "M9 7 4 12l5 5M4 12h11a5 5 0 0 1 0 10h-2",
  reset: "M4 12a8 8 0 1 0 2.3-5.7M4 4v4h4",
  check: "M5 12.5 10 17l9-10",
  sunrise: "M3 19h18M7 19a5 5 0 0 1 10 0M12 3v6M9.5 5.5 12 3l2.5 2.5M4.6 13.6l1.4.9M19.4 13.6l-1.4.9",
  sunset: "M3 19h18M7 19a5 5 0 0 1 10 0M12 3v6M9.5 6.5 12 9l2.5-2.5M4.6 13.6l1.4.9M19.4 13.6l-1.4.9",
  sunHigh:
    "M12 8a4 4 0 1 1 0 8 4 4 0 0 1 0-8ZM12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4",
  sunLow:
    "M3 20h18M12 10a4 4 0 1 1 0 8 4 4 0 0 1 0-8ZM12 4v2.5M5.6 7.6l1.6 1.6M18.4 7.6l-1.6 1.6M3 14h2M19 14h2",
  calendar: "M4 6h16v14H4zM4 10h16M8 3.5v4M16 3.5v4M8 14h2M14 14h2M8 17h2",
  chevron: "M15 6l-6 6 6 6",
  plus: "M12 5v14M5 12h14",
  minus: "M5 12h14",
  dua: "M8 21v-4.5L4.5 12V5.5a1.5 1.5 0 0 1 3 0V10M16 21v-4.5l3.5-4.5V5.5a1.5 1.5 0 0 0-3 0V10M7.5 10l2.6 2.8c.6.6.9 1.4.9 2.2V21M16.5 10l-2.6 2.8c-.6.6-.9 1.4-.9 2.2V21",
  clock: "M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18ZM12 7v5l3.5 2",
  radio: "M4 9h16v11H4zM8 9l9-5M15.5 14.5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0ZM7 13h3M7 16h3",
} as const;

export type IconName = keyof typeof PATHS;
const DEFAULT_SIZE = 22;
const FILLED: ReadonlySet<string> = new Set(["play", "pause", "stop", "next", "prev"]);

export function Icon({ name, size = DEFAULT_SIZE }: { name: IconName; size?: number }) {
  return (
    <svg
      className="icon"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={FILLED.has(name) ? "currentColor" : "none"}
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
