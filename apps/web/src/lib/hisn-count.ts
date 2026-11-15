/** Arabic count phrases used in Hisn al-Muslim, and the number each one means (as the app's adhkar.dart). */
const HISN_COUNT_PHRASES: readonly [string, number][] = [
  ["ثلاث مرات", 3],
  ["أربع مرات", 4],
  ["سبع مرات", 7],
  ["عشر مرات", 10],
  ["مائة مرة", 100],
];

const MARKS = /[ً-ْٰـ]/g;

/** The repetition count stated in a Hisn text (diacritics ignored), or 1 when none is stated. */
export function countStatedIn(hisnText: string): number {
  const bare = hisnText.replace(MARKS, "");
  for (const [phrase, n] of HISN_COUNT_PHRASES) if (bare.includes(phrase)) return n;
  return 1;
}
