"use client";
import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import {
  hashPin,
  isParentLockOpen,
  isValidPin,
  parentChallenge,
  pinMatches,
  readPinHash,
  savePinHash,
  setParentLockOpen,
} from "@/lib/parent-lock";

type Step = "enter" | "create" | "confirm" | "challenge";

/** Parent lock in front of the videos page (same flow as the app). */
export function ParentGate({ locale, children }: { locale: Locale; children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState<Step>("create");
  const [pin, setPin] = useState("");
  const [first, setFirst] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState<[number, number]>([7, 13]);

  useEffect(() => {
    setOpen(isParentLockOpen());
    setStep(readPinHash() === null ? "create" : "enter");
    setReady(true);
    const onHide = (): void => {
      if (document.visibilityState === "hidden") {
        setParentLockOpen(false);
        setOpen(false);
        setStep(readPinHash() === null ? "create" : "enter");
        setPin("");
      }
    };
    document.addEventListener("visibilitychange", onHide);
    return () => document.removeEventListener("visibilitychange", onHide);
  }, []);

  const unlock = (): void => {
    setParentLockOpen(true);
    setOpen(true);
  };

  const submit = async (e: FormEvent): Promise<void> => {
    e.preventDefault();
    const v = pin.trim();
    setPin("");
    if (step === "enter") {
      if (await pinMatches(v, readPinHash())) unlock();
      else setError(t(locale, "parentLock.wrong"));
    } else if (step === "create") {
      if (!isValidPin(v)) return;
      setFirst(v);
      setStep("confirm");
      setError(null);
    } else if (step === "confirm") {
      if (v === first) {
        savePinHash(await hashPin(v));
        unlock();
      } else {
        setStep("create");
        setFirst("");
        setError(t(locale, "parentLock.mismatch"));
      }
    } else if (Number(v) === q[0] * q[1]) {
      setStep("create");
      setError(null);
    } else {
      setQ(parentChallenge());
      setError(t(locale, "parentLock.challengeWrong"));
    }
  };

  if (!ready) return null;
  if (open) return <>{children}</>;
  const challenge = step === "challenge";
  const prompt =
    step === "enter"
      ? t(locale, "parentLock.enter")
      : step === "create"
        ? t(locale, "parentLock.setTitle")
        : step === "confirm"
          ? t(locale, "parentLock.confirm")
          : t(locale, "parentLock.challenge", { a: q[0], b: q[1] });
  const button =
    step === "enter"
      ? t(locale, "parentLock.unlock")
      : step === "create"
        ? t(locale, "parentLock.next")
        : step === "confirm"
          ? t(locale, "parentLock.save")
          : t(locale, "parentLock.reset");
  return (
    <section className="card parent-gate" data-testid="parent-gate">
      <div className="parent-gate-lock" aria-hidden="true">
        🔒
      </div>
      <h2 className="card-title">{t(locale, "parentLock.title")}</h2>
      <p className="muted">{t(locale, "parentLock.intro")}</p>
      <form onSubmit={(e) => void submit(e)}>
        <label htmlFor="parent-pin" data-testid="parent-gate-prompt">
          {prompt}
        </label>
        <input
          id="parent-pin"
          className="parent-gate-pin"
          type={challenge ? "text" : "password"}
          inputMode="numeric"
          autoComplete="off"
          maxLength={challenge ? 3 : 4}
          placeholder={t(locale, challenge ? "parentLock.answer" : "parentLock.pin")}
          value={pin}
          onChange={(e) => setPin(e.target.value.replace(/\D/g, ""))}
        />
        {error && (
          <p className="parent-gate-error" role="alert">
            {error}
          </p>
        )}
        <button type="submit" className="btn btn-primary">
          {button}
        </button>
      </form>
      {step === "enter" && (
        <button
          type="button"
          className="btn btn-sm"
          onClick={() => {
            setQ(parentChallenge());
            setStep("challenge");
            setError(null);
            setPin("");
          }}
        >
          {t(locale, "parentLock.forgot")}
        </button>
      )}
    </section>
  );
}
