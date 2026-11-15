/**
 * Splits a Hajj / Umrah step's text so the duas and words to be said can be shaded (owner 2026-11-15).
 * The text itself is never changed: joining the parts gives the input back exactly.
 * A part is a dua when it is: a Quran passage in ﴿…﴾ (with its [surah: ayah] reference), a [bracketed]
 * dhikr such as the talbiya, or a (…) / «…» quote that follows a colon ("وقل: «…»") or another dua.
 * Same rule in the app: apps/mobile/lib/domain/dua_segments.dart.
 */
export interface TextPart {
  readonly text: string;
  readonly dua: boolean;
}

const QUOTE = /﴿[^﴾]+﴾(?:\s*\[[^\]]+\])?|\[[^\]]+\]|\([^)]+\)|«[^»]+»/g;
const REFERENCE = /^\[[^\]]*:\s*[\d٠-٩]+(?:\s*[-–]\s*[\d٠-٩]+)?\]$/;

export function duaParts(text: string): TextPart[] {
  const parts: TextPart[] = [];
  let at = 0;
  let lastDuaEnd = -1;
  for (const m of text.matchAll(QUOTE)) {
    const q = m[0];
    const start = m.index ?? 0;
    const before = text.slice(at, start);
    let dua: boolean;
    if (q.startsWith("﴿")) dua = true;
    else if (q.startsWith("[")) dua = !REFERENCE.test(q);
    else dua = /:\s*$/.test(before) || (lastDuaEnd === at && /^[\s.،,]*$/.test(before));
    if (!dua) continue;
    if (before) parts.push({ text: before, dua: false });
    parts.push({ text: q, dua: true });
    at = start + q.length;
    lastDuaEnd = at;
  }
  if (at < text.length) parts.push({ text: text.slice(at), dua: false });
  return parts;
}
