"use client";
import { useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { bookmarksStore, markAllDirty } from "@/lib/bookmarks";
import { accountStore, ApiClient, ApiError, normalizeBase, syncBookmarks, type FetchLike } from "@/lib/sync";
import { useStore } from "@/hooks/useStore";

type Msg = { kind: "ok" | "error"; text: string } | null;

export function errorMessage(locale: Locale, e: unknown): string {
  if (e instanceof ApiError) {
    if (e.kind === "offline") return t(locale, "settings.errOffline");
    if (e.kind === "network") return t(locale, "settings.errNetwork", { msg: e.message });
    if (e.kind === "invalid") return t(locale, "settings.errInvalidUrl");
    return t(locale, "settings.errHttp", { status: e.status ?? "?", msg: e.message });
  }
  return t(locale, "common.error");
}

export function AccountSync({ locale, fetchImpl }: { locale: Locale; fetchImpl?: FetchLike }) {
  const account = useStore(accountStore);
  const [base, setBase] = useState(account.apiBase);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<Msg>(null);

  const client = (): ApiClient => new ApiClient({ base: account.apiBase, fetch: fetchImpl });

  const run = async (fn: () => Promise<string>): Promise<void> => {
    setBusy(true);
    setMsg(null);
    try {
      setMsg({ kind: "ok", text: await fn() });
    } catch (e) {
      setMsg({ kind: "error", text: errorMessage(locale, e) });
    } finally {
      setBusy(false);
    }
  };

  const validateCreds = (): string | null => {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) return t(locale, "settings.errEmail");
    if (password.length < 10) return t(locale, "settings.errPassword");
    return null;
  };

  const doLogin = async (c: ApiClient): Promise<string> => {
    const res = await c.login(email.trim(), password);
    accountStore.set((a) => ({
      ...a,
      email: email.trim(),
      token: res.access_token,
      lastSync: 0,
      lastSyncAt: null,
    }));
    // A fresh sign-in uploads everything stored on this device to the account.
    bookmarksStore.set((s) => markAllDirty(s));
    setPassword("");
    return t(locale, "settings.loggedIn");
  };

  const onAuth = (mode: "login" | "register"): void => {
    const invalid = validateCreds();
    if (invalid) {
      setMsg({ kind: "error", text: invalid });
      return;
    }
    void run(async () => {
      const c = client();
      if (mode === "register") {
        await c.register(email.trim(), password);
        setMsg({ kind: "ok", text: t(locale, "settings.registered") });
      }
      return doLogin(c);
    });
  };

  const onSync = (): void => {
    void run(async () => {
      const token = accountStore.get().token;
      if (!token) throw new ApiError("http", "not signed in", 401);
      try {
        const res = await syncBookmarks(client(), token, bookmarksStore.get(), accountStore.get().lastSync);
        bookmarksStore.set(res.state);
        accountStore.set((a) => ({ ...a, lastSync: res.lastSync, lastSyncAt: Date.now() }));
        return t(locale, "settings.syncDone", { pulled: res.pulled, pushed: res.pushed });
      } catch (e) {
        if (e instanceof ApiError && e.status === 401) accountStore.set((a) => ({ ...a, token: null }));
        throw e;
      }
    });
  };

  return (
    <section className="card" aria-labelledby="account-h">
      <h2 id="account-h" style={{ marginTop: 0 }}>
        {t(locale, "settings.account")}
      </h2>
      <p className="muted">{t(locale, "settings.accountNote")}</p>
      <form
        className="field"
        noValidate
        onSubmit={(e) => {
          e.preventDefault();
          try {
            const nb = normalizeBase(base);
            accountStore.set((a) => ({
              ...a,
              apiBase: nb,
              token: nb === a.apiBase ? a.token : null,
              lastSync: 0,
            }));
            setBase(nb);
            setMsg({ kind: "ok", text: t(locale, "settings.saved") });
          } catch (err) {
            setMsg({ kind: "error", text: errorMessage(locale, err) });
          }
        }}
      >
        <label htmlFor="api-base">{t(locale, "settings.apiBase")}</label>
        <div className="row">
          <input
            id="api-base"
            type="url"
            dir="ltr"
            value={base}
            onChange={(e) => setBase(e.target.value)}
            style={{ flex: "1 1 240px" }}
          />
          <button type="submit" className="btn">
            {t(locale, "settings.save")}
          </button>
        </div>
      </form>

      {account.token ? (
        <>
          <p data-testid="signed-in">{t(locale, "settings.signedInAs", { email: account.email ?? "" })}</p>
          <p className="muted">
            {t(locale, "settings.lastSync", {
              time: account.lastSyncAt
                ? new Date(account.lastSyncAt).toLocaleString(locale === "ar" ? "ar" : "en")
                : t(locale, "settings.never"),
            })}
          </p>
          <div className="row">
            <button type="button" className="btn btn-primary" onClick={onSync} disabled={busy}>
              {t(locale, "settings.syncNow")}
            </button>
            <button
              type="button"
              className="btn"
              disabled={busy}
              onClick={() => {
                accountStore.set((a) => ({ ...a, token: null, email: null, lastSync: 0, lastSyncAt: null }));
                setMsg(null);
              }}
            >
              {t(locale, "settings.logout")}
            </button>
          </div>
        </>
      ) : (
        <form
          noValidate
          onSubmit={(e) => {
            e.preventDefault();
            onAuth("login");
          }}
        >
          <div className="field">
            <label htmlFor="email">{t(locale, "settings.email")}</label>
            <input
              id="email"
              type="email"
              dir="ltr"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="password">{t(locale, "settings.password")}</label>
            <input
              id="password"
              type="password"
              dir="ltr"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <div className="row">
            <button type="submit" className="btn btn-primary" disabled={busy}>
              {t(locale, "settings.login")}
            </button>
            <button type="button" className="btn" disabled={busy} onClick={() => onAuth("register")}>
              {t(locale, "settings.register")}
            </button>
          </div>
        </form>
      )}
      <div aria-live="polite" data-testid="account-status">
        {busy ? <p className="muted">{t(locale, "settings.working")}</p> : null}
        {msg ? (
          <p
            className={`alert ${msg.kind === "error" ? "alert-error" : "alert-ok"}`}
            role={msg.kind === "error" ? "alert" : "status"}
          >
            {msg.text}
          </p>
        ) : null}
      </div>
    </section>
  );
}
