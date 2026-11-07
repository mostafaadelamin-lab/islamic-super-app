import type { Metadata, Viewport } from "next";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import "@/generated/tokens.css";
import "../globals.css";
import { tokens } from "@/generated/tokens";
import { dirOf, isLocale, LOCALES, t, type Locale } from "@/lib/i18n";
import { THEME_SCRIPT } from "../theme-script";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { ClientEffects } from "@/components/ClientEffects";
import { withBase } from "@/lib/base-path";

export const dynamicParams = false;

export function generateStaticParams(): { locale: Locale }[] {
  return LOCALES.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const l: Locale = isLocale(locale) ? locale : "ar";
  return {
    title: { default: t(l, "appName"), template: `%s — ${t(l, "appName")}` },
    description: t(l, "tagline"),
    manifest: withBase("/manifest.webmanifest"),
    icons: { icon: withBase("/icon.svg"), apple: withBase("/icon-192.png") },
  };
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: tokens.color.light.primary },
    { media: "(prefers-color-scheme: dark)", color: tokens.color.dark.bg },
  ],
};

export default async function LocaleLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  return (
    <html lang={locale} dir={dirOf(locale)} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      <body>
        <a className="skip-link" href="#main">
          {t(locale, "nav.skip")}
        </a>
        <Header locale={locale} />
        <main id="main" tabIndex={-1}>
          {children}
        </main>
        <Footer locale={locale} />
        <ClientEffects locale={locale} />
      </body>
    </html>
  );
}
