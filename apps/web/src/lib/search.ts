/** Diacritic-insensitive Arabic search per packages/shared-schemas/search-normalization.json. */
import normJson from "@/generated/search-normalization.json";

interface NormSpec {
  removeRanges: [string, string][];
  map: Record<string, string>;
}
const spec = normJson as unknown as NormSpec;

const ranges: [number, number][] = spec.removeRanges.map(([a, b]) => [parseInt(a, 16), parseInt(b, 16)]);

export function normalizeArabic(input: string): string {
  let out = "";
  for (const ch of input) {
    const cp = ch.codePointAt(0) as number;
    if (ranges.some(([a, b]) => cp >= a && cp <= b)) continue;
    out += ch;
  }
  let mapped = "";
  for (const ch of out) mapped += spec.map[ch] ?? ch;
  return mapped.replace(/\s+/g, " ").trim();
}

/** Number of letters (non-space characters) after normalisation. */
export function queryLength(q: string): number {
  return normalizeArabic(q).replace(/ /g, "").length;
}

export interface SearchHit {
  s: number;
  a: number;
  text: string;
}

export class SearchIndex {
  private readonly norm: { s: number; a: number; n: string }[] = [];
  constructor(private readonly surahs: readonly (readonly string[])[]) {
    surahs.forEach((ayahs, si) => {
      ayahs.forEach((text, ai) => this.norm.push({ s: si + 1, a: ai + 1, n: normalizeArabic(text) }));
    });
  }
  get size(): number {
    return this.norm.length;
  }
  search(q: string, limit = 50): { total: number; results: SearchHit[] } {
    const nq = normalizeArabic(q);
    if (nq.replace(/ /g, "").length < 2) return { total: 0, results: [] };
    const results: SearchHit[] = [];
    let total = 0;
    for (const e of this.norm) {
      if (e.n.includes(nq)) {
        total++;
        if (results.length < limit) {
          // Return the original, unmodified ayah text.
          results.push({
            s: e.s,
            a: e.a,
            text: (this.surahs[e.s - 1] as readonly string[])[e.a - 1] as string,
          });
        }
      }
    }
    return { total, results };
  }
}
