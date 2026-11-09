import type { Metadata } from "next";
import { isLocale, t } from "@/lib/i18n";
import { resolveLocale, type LocaleParams } from "@/lib/page-locale";
import { APP_LINKS } from "@/lib/app-links";
import { ShareAppButton } from "@/components/ShareApp";

/** Number of questions in the help strings (help.q1 … help.q7 with help.a1 … help.a7). */
const FAQ_COUNT = 7;
const FAQ = Array.from({ length: FAQ_COUNT }, (_, i) => i + 1);

export async function generateMetadata({ params }: { params: LocaleParams }): Promise<Metadata> {
  const { locale } = await params;
  return { title: t(isLocale(locale) ? locale : "ar", "help.title") };
}

export default async function HelpPage({ params }: { params: LocaleParams }) {
  const locale = await resolveLocale(params);
  const { contactEmail, playStore, appStore } = APP_LINKS;
  return (
    <>
      <h1>{t(locale, "help.title")}</h1>
      <section className="card" aria-labelledby="faq-h">
        <h2 id="faq-h" className="card-title">
          {t(locale, "help.faq")}
        </h2>
        {FAQ.map((n) => (
          <details key={n} className="faq" data-testid={`faq-${n}`}>
            <summary>{t(locale, `help.q${n}`)}</summary>
            <p>{t(locale, `help.a${n}`)}</p>
          </details>
        ))}
      </section>
      <section className="card" aria-labelledby="contact-h">
        <h2 id="contact-h" className="card-title">
          {t(locale, "help.contact")}
        </h2>
        {contactEmail ? (
          <p>
            <a className="btn" href={`mailto:${contactEmail}`} data-testid="contact-email">
              {t(locale, "help.email")}
            </a>
          </p>
        ) : (
          <p className="muted" data-testid="contact-pending">
            {t(locale, "help.contactPending")}
          </p>
        )}
      </section>
      <section className="card" aria-labelledby="spread-h">
        <h2 id="spread-h" className="card-title">
          {t(locale, "help.spread")}
        </h2>
        <p>{t(locale, "help.spreadBody")}</p>
        <p>
          <ShareAppButton locale={locale} className="btn btn-primary" />
        </p>
        {playStore || appStore ? (
          <p className="row">
            {playStore ? (
              <a className="btn" href={playStore} data-testid="rate-play">
                {t(locale, "help.ratePlay")}
              </a>
            ) : null}
            {appStore ? (
              <a className="btn" href={appStore} data-testid="rate-appstore">
                {t(locale, "help.rateAppStore")}
              </a>
            ) : null}
          </p>
        ) : (
          <p className="muted small">{t(locale, "help.ratePending")}</p>
        )}
      </section>
    </>
  );
}
