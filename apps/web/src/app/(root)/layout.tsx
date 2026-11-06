import type { ReactNode } from "react";
import "@/generated/tokens.css";
import "../globals.css";

export const metadata = { title: "Rattil — رتّل", manifest: "/manifest.webmanifest" };

export default function RootRedirectLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
