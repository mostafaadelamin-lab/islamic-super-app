import { preload } from "react-dom";
import { withBase } from "@/lib/base-path";

/** Emits <link rel="preload"> for the self-hosted Quran font on routes that render Quran text. */
export function PreloadQuranFont() {
  preload(withBase("/fonts/AmiriQuran-Regular.ttf"), {
    as: "font",
    type: "font/ttf",
    crossOrigin: "anonymous",
  });
  return null;
}
