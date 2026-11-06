import { preload } from "react-dom";

/** Emits <link rel="preload"> for the self-hosted Quran font on routes that render Quran text. */
export function PreloadQuranFont() {
  preload("/fonts/AmiriQuran-Regular.ttf", { as: "font", type: "font/ttf", crossOrigin: "anonymous" });
  return null;
}
