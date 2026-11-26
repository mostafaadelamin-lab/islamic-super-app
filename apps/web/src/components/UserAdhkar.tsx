"use client";
import { useEffect, useRef, useState } from "react";
import { t, type Locale } from "@/lib/i18n";
import { localizeDigits } from "@/lib/digits";
import type { Session } from "@/lib/adhkar";
import {
  QUICK_COUNTS,
  USER_DHIKR_BASE,
  USER_DHIKR_MAX_COUNT,
  USER_DHIKR_MAX_LENGTH,
  deleteUserDhikr,
  saveUserDhikr,
  userAdhkarStore,
  type UserDhikr,
} from "@/lib/custom-adhkar";
import { Icon } from "./Icon";

type Where = "morning" | "evening" | "both";

/** «أضف ذكرًا» form at the end of the morning / evening list; also edits one of the visitor's adhkar. */
export function UserDhikrForm({
  locale,
  session,
  editing,
  onDone,
}: {
  locale: Locale;
  session: Session;
  editing: UserDhikr | null;
  onDone: () => void;
}) {
  const [text, setText] = useState("");
  const [count, setCount] = useState(1);
  const [where, setWhere] = useState<Where>(session);
  const box = useRef<HTMLTextAreaElement>(null);
  useEffect(() => {
    setText(editing?.text ?? "");
    setCount(editing?.count ?? 1);
    setWhere(editing ? (editing.sessions.length === 2 ? "both" : editing.sessions[0]!) : session);
    if (editing) box.current?.focus();
  }, [editing, session]);
  const clamp = (n: number): number => Math.min(USER_DHIKR_MAX_COUNT, Math.max(1, n));
  const save = (): void => {
    if (!text.trim()) return;
    userAdhkarStore.set((list) =>
      saveUserDhikr(list, {
        id: editing?.id,
        text,
        count,
        sessions: where === "both" ? ["morning", "evening"] : [where],
      }),
    );
    setText("");
    setCount(1);
    onDone();
  };
  const choices: readonly Where[] = ["morning", "evening", "both"];
  return (
    <form
      className="user-dhikr-form"
      data-testid="user-dhikr-form"
      id="user-dhikr-form"
      onSubmit={(e) => {
        e.preventDefault();
        save();
      }}
    >
      <h3>
        <Icon name="plus" size={18} /> {t(locale, editing ? "adhkar.mineEditTitle" : "adhkar.mineAdd")}
      </h3>
      <p className="muted small">{t(locale, "adhkar.mineHint")}</p>
      <label className="sr-only" htmlFor="user-dhikr-text">
        {t(locale, "adhkar.mineTextHint")}
      </label>
      <textarea
        id="user-dhikr-text"
        ref={box}
        data-testid="user-dhikr-text"
        dir="rtl"
        lang="ar"
        rows={3}
        maxLength={USER_DHIKR_MAX_LENGTH}
        placeholder={t(locale, "adhkar.mineTextHint")}
        value={text}
        onChange={(e) => setText(e.target.value)}
      />
      <p className="user-dhikr-label">{t(locale, "adhkar.mineCount")}</p>
      <div className="user-dhikr-stepper">
        <button
          type="button"
          className="btn btn-sm"
          data-testid="user-dhikr-minus"
          aria-label={t(locale, "adhkar.mineLess")}
          disabled={count <= 1}
          onClick={() => setCount((c) => clamp(c - 1))}
        >
          <Icon name="minus" size={18} />
        </button>
        <output data-testid="user-dhikr-count" aria-live="polite">
          {t(locale, "adhkar.mineTimes", { n: localizeDigits(count, locale) })}
        </output>
        <button
          type="button"
          className="btn btn-sm"
          data-testid="user-dhikr-plus"
          aria-label={t(locale, "adhkar.mineMore")}
          disabled={count >= USER_DHIKR_MAX_COUNT}
          onClick={() => setCount((c) => clamp(c + 1))}
        >
          <Icon name="plus" size={18} />
        </button>
      </div>
      <div className="user-dhikr-quick">
        {QUICK_COUNTS.map((n) => (
          <button
            key={n}
            type="button"
            aria-pressed={count === n}
            data-testid={`user-dhikr-quick-${n}`}
            onClick={() => setCount(n)}
          >
            {localizeDigits(n, locale)}
          </button>
        ))}
      </div>
      <p className="user-dhikr-label">{t(locale, "adhkar.mineShowIn")}</p>
      <div className="segmented" role="group" aria-label={t(locale, "adhkar.mineShowIn")}>
        {choices.map((w) => (
          <button
            key={w}
            type="button"
            aria-pressed={where === w}
            data-testid={`user-dhikr-where-${w}`}
            onClick={() => setWhere(w)}
          >
            {t(locale, w === "both" ? "adhkar.mineBoth" : `adhkar.${w}`)}
          </button>
        ))}
      </div>
      <div className="row user-dhikr-actions">
        <button
          type="submit"
          className="btn btn-primary"
          data-testid="user-dhikr-save"
          disabled={!text.trim()}
        >
          {t(locale, "adhkar.mineSave")}
        </button>
        {editing ? (
          <button type="button" className="btn" data-testid="user-dhikr-cancel" onClick={onDone}>
            {t(locale, "adhkar.mineCancel")}
          </button>
        ) : null}
      </div>
    </form>
  );
}

/** Edit / delete under one of the visitor's adhkar. */
export function UserDhikrTools({
  locale,
  id,
  onEdit,
}: {
  locale: Locale;
  /** The list item's id (USER_DHIKR_BASE + the stored id). */
  id: number;
  onEdit: (d: UserDhikr) => void;
}) {
  const own = id - USER_DHIKR_BASE;
  return (
    <div className="dhikr-tools user-dhikr-tools">
      <button
        type="button"
        className="btn btn-sm"
        data-testid={`user-dhikr-edit-${own}`}
        onClick={() => {
          const d = userAdhkarStore.get().find((x) => x.id === own);
          if (d) onEdit(d);
        }}
      >
        <Icon name="edit" size={16} /> {t(locale, "adhkar.mineEdit")}
      </button>
      <button
        type="button"
        className="btn btn-sm"
        data-testid={`user-dhikr-delete-${own}`}
        onClick={() => {
          if (window.confirm(t(locale, "adhkar.mineDeleteAsk"))) {
            userAdhkarStore.set((list) => deleteUserDhikr(list, own));
          }
        }}
      >
        <Icon name="trash" size={16} /> {t(locale, "adhkar.mineDelete")}
      </button>
    </div>
  );
}
