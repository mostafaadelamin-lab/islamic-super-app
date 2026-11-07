import type { ReactNode } from "react";
import "@/generated/tokens.css";
import "../globals.css";
import { withBase } from "@/lib/base-path";

export const metadata = { title: "Rattil — رتّل", manifest: withBase("/manifest.webmanifest") };

export default function RootRedirectLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
