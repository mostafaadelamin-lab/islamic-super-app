import type { MetadataRoute } from "next";
import { tokens } from "@/generated/tokens";
import { withBase } from "@/lib/base-path";

export const dynamic = "force-static";

/** [route, label]: the manifest has one language, Arabic (the site's default). */
const SHORTCUTS: readonly (readonly [string, string])[] = [
  ["page/1", "المصحف"],
  ["prayer", "مواقيت الصلاة"],
  ["adhkar", "الأذكار"],
  ["tasbih", "السبحة"],
  ["reels", "فيديوهات"],
];

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "رتّل وصلِّ — Rattil wa Salli",
    short_name: "رتّل وصلِّ",
    description: "Quran, prayer and remembrance — free, no ads",
    // A stable id lets Windows/Chrome/Edge keep one installed app across updates.
    id: withBase("/"),
    start_url: withBase("/"),
    scope: withBase("/"),
    display: "standalone",
    // Installed on Windows: its own window with the app's title bar (falls back to standalone elsewhere).
    display_override: ["standalone", "minimal-ui"],
    orientation: "any",
    categories: ["education", "lifestyle", "books"],
    dir: "rtl",
    lang: "ar",
    background_color: tokens.color.light.bg,
    theme_color: tokens.color.light.primary,
    // Long-press shortcuts on the installed app's icon (Android / desktop).
    shortcuts: SHORTCUTS.map(([path, name]) => ({
      name,
      url: withBase(`/ar/${path}/`),
      icons: [{ src: withBase("/icon-192.png"), sizes: "192x192", type: "image/png" }],
    })),
    icons: [
      { src: withBase("/icon-192.png"), sizes: "192x192", type: "image/png" },
      { src: withBase("/icon-512.png"), sizes: "512x512", type: "image/png" },
      { src: withBase("/icon-maskable-512.png"), sizes: "512x512", type: "image/png", purpose: "maskable" },
      { src: withBase("/icon.svg"), sizes: "any", type: "image/svg+xml" },
    ],
  };
}
