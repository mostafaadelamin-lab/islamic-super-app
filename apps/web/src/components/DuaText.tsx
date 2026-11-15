import { duaParts } from "@/lib/dua-segments";

/** A step's text with every dua in it shaded (owner 2026-11-15); the words are shown exactly as given. */
export function DuaText({ text }: { text: string }) {
  return (
    <>
      {duaParts(text).map((p, i) =>
        p.dua ? (
          <mark key={i} className="dua-inline" data-testid="dua-inline">
            {p.text}
          </mark>
        ) : (
          <span key={i}>{p.text}</span>
        ),
      )}
    </>
  );
}
