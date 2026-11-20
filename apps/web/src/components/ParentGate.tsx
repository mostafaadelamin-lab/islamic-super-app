"use client";
import Link from "next/link";
import { useEffect, useState, type FormEvent, type ReactNode } from "react";
import { t, type Locale } from "@/lib/i18n";
import { href } from "@/lib/locale-path";
import {
  hashPin,
  isParentLockOpen,
  isValidPin,
  parentChallenge,
  pinMatches,
  readParentAge,
  readPinHash,
  saveParentAge,
  savePinHash,
  setParentLockOpen,
  type ParentAge,
} from "@/lib/parent-lock";
import { Icon } from "./Icon";

type Step = "age" | "kids" | "enter" | "create" | "confirm" | "challenge";

const pinStep = (): Step => (readPinHash() === null ? "create" : "enter");

/**
 * Parent lock in front of the videos page (owner 2026-11-20, Google Play Families
 * policy; same flow as the app). First visit: a neutral age-group question with two
 * equal buttons. 13 or older: videos open, never asked again. Under 13: only the kids
 * section videos; the parent's 4-digit PIN opens all videos.
 */
export function ParentGate({ locale, children }: { locale: Locale; children: ReactNode }) {
  const [ready, setReady] = useState(false);
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState<Step>("age");
  const [pin, setPin] = useState("");
  const [first, setFirst] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [q, setQ] = useState<[number, number]>([7, 13]);

  useEffect(() => {
    const age = readParentAge();
    setOpen(isParentLockOpen() || age === "adult");
    setStep(age === null ? "age" : "kids");
    setReady(true);
    const onHide = (): void => {
      if (document.visibilityState === "hidden" && readParentAge() === "child") {
        setParentLockOpen(false);
        setOpen(false);
        setStep("kids");
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

  const pickAge = (age: ParentAge): void => {
    saveParentAge(age);
    if (age === "adult") setOpen(true);
    else setStep("kids");
  };

  const toPin = (): void => {
    setStep(pinStep());
    setError(null);
    setPin("");
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

  if (step === "age") {
    return (
      <section className="card parent-gate" data-testid="parent-gate-age">
        <h2 className="card-title">{t(locale, "parentLock.ageTitle")}</h2>
        <p>{t(locale, "parentLock.ageAsk")}</p>
        <div className="parent-gate-ages">
          <button type="button" className="btn" onClick={() => pickAge("child")}>
            {t(locale, "parentLock.ageUnder13")}
          </button>
          <button type="button" className="btn" onClick={() => pickAge("adult")}>
            {t(locale, "parentLock.age13plus")}
          </button>
        </div>
      </section>
    );
  }

  if (step === "kids") {
    const series: readonly [string, string, string][] = [
      ["prophets", "kids.prophets", "kids.prophetsSub"],
      ["stories", "kids.stories", "kids.storiesSub"],
    ];
    return (
      <section data-testid="parent-gate-kids">
        <h2>{t(locale, "parentLock.kidsTitle")}</h2>
        <p className="muted">{t(locale, "parentLock.kidsNote")}</p>
        <ul className="tiles tiles-sm">
          {series.map(([id, title, sub]) => (
            <li key={id}>
              <Link
                className="tile tile-sm"
                href={`${href(locale, "kids")}#${id}`}
                data-testid={`parent-gate-kids-${id}`}
              >
                <span className="tile-icon">
                  <Icon name="video" />
                </span>
                <span className="tile-text">
                  <strong>{t(locale, title)}</strong>
                  <span className="muted small">{t(locale, sub)}</span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
        <p className="parent-gate-parent">
          <button type="button" className="btn" onClick={toPin}>
            🔒 {t(locale, "parentLock.parentOpen")}
          </button>
        </p>
      </section>
    );
  }

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
      {(step === "create" || step === "confirm") && (
        <p className="parent-gate-handover">{t(locale, "parentLock.handOver")}</p>
      )}
      <form onSubmit={(e) => void submit(e)}>
        <label htmlFor="parent-pin">{prompt}</label>
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
      <button type="button" className="btn btn-sm" onClick={() => setStep("kids")}>
        {t(locale, "parentLock.back")}
      </button>
    </section>
  );
}
