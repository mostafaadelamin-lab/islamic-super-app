import type { MetadataRoute } from "next";
import { tokens } from "@/generated/tokens";
import { withBase } from "@/lib/base-path";

export const dynamic = "force-static";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Rattil — رتّل",
    short_name: "Rattil",
    description: "Quran, prayer and remembrance — free, no ads",
    start_url: withBase("/"),
    scope: withBase("/"),
    display: "standalone",
    dir: "rtl",
    lang: "ar",
    background_color: tokens.color.light.bg,
    theme_color: tokens.color.light.primary,
    icons: [
      { src: withBase("/icon-192.png"), sizes: "192x192", type: "image/png" },
      { src: withBase("/icon-512.png"), sizes: "512x512", type: "image/png" },
      { src: withBase("/icon-512.png"), sizes: "512x512", type: "image/png", purpose: "maskable" },
      { src: withBase("/icon.svg"), sizes: "any", type: "image/svg+xml" },
    ],
  };
}
