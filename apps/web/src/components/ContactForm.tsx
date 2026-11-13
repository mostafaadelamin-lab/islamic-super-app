"use client";
import { useState, type FormEvent } from "react";
import { t, type Locale } from "@/lib/i18n";
import { APP_LINKS } from "@/lib/app-links";

export type ContactFields = Record<"title" | "name" | "phone" | "whatsapp" | "message", string>;
export type ContactSender = (endpoint: string, fields: Record<string, string>) => Promise<boolean>;

/** Posts to the form service (FormSubmit's AJAX endpoint answers JSON). */
export const postContactForm: ContactSender = async (endpoint, fields) => {
  try {
    const r = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(fields),
    });
    return r.ok;
  } catch {
    return false;
  }
};

/** Payload sent to the team's inbox: empty optional fields become "-". */
export function contactPayload(f: ContactFields): Record<string, string> {
  const v = (s: string): string => (s.trim() === "" ? "-" : s.trim());
  return {
    title: f.title.trim(),
    name: v(f.name),
    phone: v(f.phone),
    whatsapp: v(f.whatsapp),
    message: f.message.trim(),
    source: "website",
    _subject: `Rattil wa Salli website: ${f.title.trim()}`,
    _template: "table",
    _captcha: "false",
  };
}

const EMPTY: ContactFields = { title: "", name: "", phone: "", whatsapp: "", message: "" };
const MIN_MESSAGE = 3;

/** "Contact us" (owner, 2026-11-13): title, name, phone, WhatsApp and message. No email address is shown. */
export function ContactForm({
  locale,
  endpoint = APP_LINKS.contactForm,
  send = postContactForm,
}: {
  locale: Locale;
  endpoint?: string | null;
  send?: ContactSender;
}) {
  const [f, setF] = useState<ContactFields>(EMPTY);
  const [state, setState] = useState<"idle" | "sending" | "sent" | "failed">("idle");
  const [error, setError] = useState<string | null>(null);

  if (!endpoint) return <p className="muted">{t(locale, "help.contactPending")}</p>;
  if (state === "sent") {
    return (
      <p role="status" data-testid="contact-sent">
        {t(locale, "contact.thanks")}
      </p>
    );
  }

  const set = (k: keyof ContactFields) => (e: { target: { value: string } }) =>
    setF({ ...f, [k]: e.target.value });

  const onSubmit = async (e: FormEvent): Promise<void> => {
    e.preventDefault();
    if (f.title.trim() === "") return setError(t(locale, "contact.titleRequired"));
    if (f.message.trim().length < MIN_MESSAGE) return setError(t(locale, "contact.messageRequired"));
    setError(null);
    setState("sending");
    setState((await send(endpoint, contactPayload(f))) ? "sent" : "failed");
  };

  const field = (k: keyof ContactFields, type: "text" | "tel" = "text") => (
    <div className="field">
      <label htmlFor={`contact-${k}`}>{t(locale, `contact.${k}`)}</label>
      {k === "message" ? (
        <textarea id={`contact-${k}`} rows={6} value={f[k]} onChange={set(k)} data-testid={`contact-${k}`} />
      ) : (
        <input
          id={`contact-${k}`}
          type={type}
          dir={type === "tel" ? "ltr" : undefined}
          inputMode={type === "tel" ? "tel" : undefined}
          value={f[k]}
          onChange={set(k)}
          data-testid={`contact-${k}`}
        />
      )}
    </div>
  );

  return (
    <form onSubmit={onSubmit} noValidate data-testid="contact-form">
      <p>{t(locale, "contact.intro")}</p>
      {field("title")}
      {field("name")}
      {field("phone", "tel")}
      {field("whatsapp", "tel")}
      {field("message")}
      {error ? (
        <p role="alert" className="alert alert-error">
          {error}
        </p>
      ) : null}
      {state === "failed" ? (
        <p role="alert" className="alert alert-error">
          {t(locale, "contact.failed")}
        </p>
      ) : null}
      <button
        type="submit"
        className="btn btn-primary"
        disabled={state === "sending"}
        data-testid="contact-send"
      >
        {t(locale, "contact.send")}
      </button>
    </form>
  );
}
