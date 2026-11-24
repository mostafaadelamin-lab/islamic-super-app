import type { Metadata, Viewport } from "next";
import { notFound } from "next/navigation";
import type { ReactNode } from "react";
import "@/generated/tokens.css";
import "../globals.css";
import { tokens } from "@/generated/tokens";
import { dirOf, isLocale, LOCALES, t, type Locale } from "@/lib/i18n";
import { THEME_SCRIPT } from "../theme-script";
import { SITE_STATUS_SCRIPT } from "../site-status-script";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { Breadcrumbs } from "@/components/Breadcrumbs";
import { BackButton } from "@/components/BackButton";
import { ClientEffects } from "@/components/ClientEffects";
import { UpdateBanner } from "@/components/UpdateBanner";
import { AdhanAlerts } from "@/components/AdhanAlerts";
import { DhikrReminderAlerts } from "@/components/DhikrReminders";
import { PlayerBar } from "@/components/PlayerBar";
import { FirstRunTour } from "@/components/FirstRunTour";
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
    icons: {
      icon: [
        { url: withBase("/icon.svg"), type: "image/svg+xml" },
        { url: withBase("/favicon-32.png"), sizes: "32x32", type: "image/png" },
      ],
      apple: withBase("/apple-touch-icon.png"),
    },
  };
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: tokens.palettes[tokens.defaultPalette].light.primary },
    { media: "(prefers-color-scheme: dark)", color: tokens.palettes[tokens.defaultPalette].dark.bg },
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
        <script dangerouslySetInnerHTML={{ __html: SITE_STATUS_SCRIPT }} />
      </head>
      <body>
        {/* Filled by SITE_STATUS_SCRIPT while an upload runs; React leaves its content alone. */}
        <div
          id="site-status"
          className="site-status"
          role="status"
          hidden
          suppressHydrationWarning
          dangerouslySetInnerHTML={{ __html: "" }}
        />
        <a className="skip-link" href="#main">
          {t(locale, "nav.skip")}
        </a>
        <Header locale={locale} />
        <main id="main" tabIndex={-1}>
          <Breadcrumbs locale={locale} />
          <BackButton locale={locale} />
          {children}
        </main>
        <Footer locale={locale} />
        <PlayerBar locale={locale} />
        <ClientEffects locale={locale} />
        <UpdateBanner locale={locale} />
        <AdhanAlerts locale={locale} />
        <DhikrReminderAlerts locale={locale} />
        <FirstRunTour locale={locale} />
      </body>
    </html>
  );
}
