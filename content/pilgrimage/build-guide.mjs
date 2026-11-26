#!/usr/bin/env node
/**
 * Builds the sourced Hajj & Umrah guide (owner 2026-11-15/16: every word of religious text quoted from a
 * published source, never written by us; every ayah from the King Fahd Complex text).
 *
 *   node content/pilgrimage/build-guide.mjs          # writes content/pilgrimage/dist/hajj-guide.v2.json
 *   node content/pilgrimage/build-guide.mjs --check  # fails if the written file is stale
 *
 * guide.v2.src.json holds references only: a page and the first and last words of a passage of Ibn Baz's
 * «التحقيق والإيضاح» (upstream/ibn-baz-tahqiq-shamela-31235.txt), a hadith number and the first and last
 * words of the quoted part, a Hisn al-Muslim chapter, or a Quran ayah. This script cuts the exact text out
 * of those files. The only words written by the project are the step titles, sub-step headings and the
 * names on the drawings. Any ayah inside a quoted passage ({...} [سورة: n]) is replaced by the same words
 * from the King Fahd Complex text (content/quran/dist/quran.v1.json), found by matching their letters; if
 * they cannot be found the build fails. The few digitisation errors corrected are listed in the output.
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "../..");
const read = (p) => readFileSync(join(repo, p), "utf8");
const json = (p) => JSON.parse(read(p));

const src = json("content/pilgrimage/guide.v2.src.json");
const quran = json("content/quran/dist/quran.v1.json");
const hisn = json("content/adhkar/hisn.json");
const dalil = json("content/pilgrimage/dalil-hajj.v1.json");
const OUT = "content/pilgrimage/dist/hajj-guide.v2.json";

const AR = "٠١٢٣٤٥٦٧٨٩";
export const ar = (n) => String(n).replace(/\d/g, (d) => AR[Number(d)]);
const fromAr = (s) => Number(s.replace(/[٠-٩]/g, (d) => String(AR.indexOf(d))));
const fail = (msg) => {
  throw new Error(`hajj guide: ${msg}`);
};

// ---------- Ibn Baz: pages and footnotes ----------
const book = (() => {
  const raw = read(src.sources.ibnbaz.file);
  const pages = new Map();
  const parts = raw.split(/^=== id \d+ pg (\d+) ===$/m);
  for (let i = 1; i < parts.length; i += 2) {
    const pg = Number(parts[i]);
    let body = parts[i + 1];
    const notes = {};
    const cut = body.indexOf("\n----\n");
    if (cut >= 0) {
      for (const line of body.slice(cut + 6).split("\n")) {
        const m = /^\(([٠-٩]+)\)\s*(.+)$/.exec(line.trim());
        if (m) notes[m[1]] = m[2].trim();
      }
      body = body.slice(0, cut);
    }
    if (pages.has(pg)) fail(`page ${pg} twice`);
    pages.set(pg, { text: body.trim().normalize("NFC"), notes });
  }
  for (const c of src.corrections) {
    const p = pages.get(c.page);
    if (!p || p.text.split(c.from).length !== 2) fail(`correction not found once on page ${c.page}: ${c.from}`);
    p.text = p.text.replace(c.from, c.to);
  }
  return pages;
})();

function bookQuote({ b: page, from: rawFrom, to: rawTo }) {
  const from = rawFrom.normalize("NFC");
  const to = rawTo.normalize("NFC");
  let text = "";
  const starts = [];
  for (let p = page; p <= page + 8 && book.has(p); p++) {
    if (text) text += " ";
    starts.push([p, text.length]);
    text += book.get(p).text;
  }
  const pageStart = starts[0][1];
  const pageEnd = starts[1]?.[1] ?? text.length;
  const i = text.indexOf(from, pageStart);
  if (i < 0 || i >= pageEnd) fail(`p${page}: start not found on that page: ${from}`);
  const j = text.indexOf(to, i);
  if (j < 0) fail(`p${page}: end not found: ${to}`);
  const end = j + to.length;
  const pageAt = (k) => starts.filter(([, s]) => s <= k).at(-1)[0];
  const p1 = pageAt(i);
  const p2 = pageAt(end - 1);
  const quoted = text.slice(i, end);
  const notes = [];
  for (let p = p1; p <= p2; p++) {
    for (const [n, t] of Object.entries(book.get(p).notes)) {
      if (quoted.includes(`(${n})`)) notes.push(`(${n}) ${t}`);
    }
  }
  return { text: quoted, p1, p2, notes };
}

// ---------- Quran: KFGQPC words for an ayah quoted in a simpler spelling ----------
const surahByName = new Map(quran.surahs.map((s, i) => [s.nameAr, i + 1]));
const ayah = (s, a) => quran.surahs[s - 1]?.ayahs[a - 1] ?? fail(`no ayah ${s}:${a}`);
/** Letters only: no marks, and none of the letters the two spellings write differently. */
const skeleton = (t) =>
  t
    .normalize("NFC")
    .replace(/[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g, "")
    .replace(/[اأإآٱءئؤىيوۥۦ\s.،؛:\-–«»"]/g, "")
    .replace(/ة/g, "ه");

function quranPart(s, a1, a2, quoted) {
  const want = skeleton(quoted);
  if (a2 > a1 || !want) {
    const all = [];
    for (let a = a1; a <= a2; a++) all.push(ayah(s, a));
    if (want && skeleton(all.join(" ")) !== want) fail(`${s}:${a1}-${a2} does not match: ${quoted}`);
    return { s, from: a1, to: a2, texts: all };
  }
  const words = ayah(s, a1).split(" ");
  const sk = words.map(skeleton);
  for (let i = 0; i < words.length; i++) {
    let acc = "";
    for (let j = i; j < words.length; j++) {
      acc += sk[j];
      if (acc === want) {
        if (i === 0 && j === words.length - 1) return { s, from: a1, to: a1, texts: [ayah(s, a1)] };
        return { s, from: a1, to: a1, part: words.slice(i, j + 1).join(" "), texts: [ayah(s, a1)] };
      }
      if (acc.length > want.length || !want.startsWith(acc)) break;
    }
  }
  fail(`ayah ${s}:${a1} has no words matching: ${quoted}`);
}

const QREF = /([{﴿])([^}﴾]*)[}﴾]\s*(?:\[([^\]:]+):\s*([٠-٩]+)(?:\s*[-،]\s*([٠-٩]+))?\])?/g;

/**
 * Splits a quoted passage into text and ayahs. [hints] give the ayah of a {…} without a reference, in order.
 */
function segments(text, hints = []) {
  for (const b of src.bare) {
    text = text.split(b.text).join(`{${b.text}} [${quran.surahs[b.quran[0] - 1].nameAr}: ${ar(b.quran[1])}]`);
  }
  const segs = [];
  let last = 0;
  let h = 0;
  for (const m of text.matchAll(QREF)) {
    const before = text.slice(last, m.index).trim();
    if (before) segs.push({ t: "text", v: before });
    let s;
    let a1;
    let a2;
    if (m[3]) {
      s = surahByName.get(m[3].trim()) ?? fail(`unknown surah name ${m[3]}`);
      a1 = fromAr(m[4]);
      a2 = m[5] ? fromAr(m[5]) : a1;
    } else {
      const hint = hints[h++] ?? fail(`ayah without reference and no hint: ${m[2]}`);
      [s, a1] = hint;
      a2 = hint[2] ?? a1;
    }
    segs.push({ t: "quran", ...quranPart(s, a1, a2, m[2]) });
    last = m.index + m[0].length;
  }
  const rest = text.slice(last).trim();
  if (rest) segs.push({ t: "text", v: rest });
  if (h !== hints.length) fail(`unused ayah hints in: ${text.slice(0, 60)}`);
  if (segs.some((x) => x.t === "text" && /[{}﴿﴾]/.test(x.v))) fail(`unmatched ayah brackets in: ${text}`);
  return segs;
}

// ---------- Hadith (bundled Open-Hadith-Data, al-Alamiyya numbering) ----------
const HADITH_BOOK = {
  bukhari: "صحيح البخاري",
  muslim: "صحيح مسلم",
  abudawud: "سنن أبي داود",
  tirmidhi: "سنن الترمذي",
  nasai: "سنن النسائي",
};
const SUNNAH_BOOKS = new Set(["bukhari", "muslim"]);
const hadithCache = new Map();
function hadith(bookId, n) {
  const key = `${bookId}:${n}`;
  if (hadithCache.has(key)) return hadithCache.get(key);
  let text;
  for (let chunk = 0; chunk < 400 && text === undefined; chunk++) {
    let d;
    try {
      d = json(`content/hadith/dist/${bookId}/${chunk}.json`);
    } catch {
      break;
    }
    if (n >= d.from && n < d.from + d.ahadith.length) text = d.ahadith[n - d.from];
  }
  if (text === undefined) fail(`no hadith ${key}`);
  text = text.replace(/\u200f/g, "").replace(/\s+/g, " ").trim().normalize("NFC");
  hadithCache.set(key, text);
  return text;
}
function hadithQuote(it) {
  const [b, n] = it.h.split(":");
  const t = hadith(b, Number(n));
  it = { ...it, from: it.from.normalize("NFC"), to: it.to.normalize("NFC") };
  const i = t.indexOf(it.from);
  if (i < 0) fail(`${it.h}: start not found: ${it.from}`);
  const j = t.indexOf(it.to, i);
  if (j < 0) fail(`${it.h}: end not found: ${it.to}`);
  const std = it.std ? `${HADITH_BOOK[b]} ${ar(it.std)}` : HADITH_BOOK[b];
  const also = it.also ? `، و${it.also.replace(/\d+/g, (d) => ar(d))}` : "";
  return {
    text: t.slice(i, j + it.to.length),
    // Bukhari and Muslim are the sunnah.com copy: std is already the number a reader finds there.
    src: SUNNAH_BOOKS.has(b)
      ? `${std}${also}${it.narrator ? ` (${it.narrator})` : ""}`
      : `${std}${also} (رقمه في نسخة التطبيق ${ar(n)}${it.narrator ? `، ${it.narrator}` : ""})`,
  };
}

// ---------- Items ----------
const range = (p1, p2) => (p1 === p2 ? `ص${ar(p1)}` : `ص${ar(p1)}–${ar(p2)}`);
function item(it) {
  if (it.b !== undefined) {
    const q = bookQuote(it);
    return {
      k: it.say ? "say" : "text",
      segs: segments(q.text, it.q),
      src: `${src.sources.ibnbaz.short}، ${range(q.p1, q.p2)}`,
      ...(q.notes.length ? { notes: q.notes } : {}),
      ...(it.times ? { times: it.times } : {}),
    };
  }
  if (it.h) {
    const q = hadithQuote(it);
    return {
      k: it.say ? "say" : "hadith",
      segs: segments(q.text, it.q),
      src: q.src,
      ...(it.times ? { times: it.times } : {}),
    };
  }
  if (it.f) {
    // A passage of another saved source file (e.g. an Ibn Baz fatwa from binbaz.org.sa), cut by its first
    // and last words.
    const meta = src.sources[it.f] ?? fail(`no source ${it.f}`);
    const t = read(meta.file).normalize("NFC");
    const from = it.from.normalize("NFC");
    const to = it.to.normalize("NFC");
    const i = t.indexOf(from);
    if (i < 0) fail(`${it.f}: start not found: ${it.from}`);
    const j = t.indexOf(to, i);
    if (j < 0) fail(`${it.f}: end not found: ${it.to}`);
    return { k: it.say ? "say" : "text", segs: segments(t.slice(i, j + to.length), it.q), src: meta.short };
  }
  if (it.hisn) {
    const c = hisn[it.hisn - 1] ?? fail(`no Hisn chapter ${it.hisn}`);
    const full = c[1].join("\n").normalize("NFC");
    if (it.part && !full.includes(it.part.normalize("NFC"))) fail(`Hisn ${it.hisn}: part not found: ${it.part}`);
    const text = it.part?.normalize("NFC") ?? full;
    return {
      k: it.say ? "say" : "hadith",
      segs: segments(text, it.q),
      src: `${src.sources.hisn.short}، باب ${ar(it.hisn)}: ${c[0]}`,
    };
  }
  if (it.quran) {
    const [s, a1, a2 = a1] = it.quran;
    // cite: the hadith that says where the ayah is said, quoted up to the ayah (shown once, above).
    const cite = it.cite ? hadithQuote(it.cite) : null;
    return {
      k: "quran",
      ...quranPart(s, a1, a2, ""),
      ...(it.say ? { say: true } : {}),
      ...(cite ? { cite: { text: cite.text, src: cite.src } } : {}),
    };
  }
  if (it.table) {
    const t = it.table;
    const pool = skeleton(
      t.check
        .map((c) => {
          if (c.b !== undefined) return bookQuote(c).text;
          if (c.h) return hadithQuote(c).text;
          return fail("table check: unknown source");
        })
        .join(" "),
    );
    for (const row of t.rows) {
      for (const cell of row) {
        for (const frag of cell === "—" ? [] : cell.split("، ")) {
          if (!pool.includes(skeleton(frag))) fail(`table cell not in its sources: ${frag}`);
        }
      }
    }
    return { k: "table", head: t.head, rows: t.rows, src: t.src };
  }
  return fail(`unknown item ${JSON.stringify(it)}`);
}

function sub(key) {
  const s = src.subs[key] ?? fail(`no sub-step ${key}`);
  return {
    title: s.title,
    ...(s.tags ? { tags: s.tags } : {}),
    ...(s.scene ? { scene: s.scene } : {}),
    items: s.items.map(item),
  };
}

const SCENES = new Set(src.scenes);
const steps = {};
const subs = {};
for (const [id, s] of Object.entries(src.steps)) {
  if (s.scene !== null && !SCENES.has(s.scene)) fail(`step ${id}: unknown scene ${s.scene}`);
  for (const key of s.subs) {
    subs[key] ??= sub(key);
    if (subs[key].scene && !SCENES.has(subs[key].scene)) fail(`sub ${key}: unknown scene`);
  }
  steps[id] = { title: s.title, scene: s.scene, subs: s.subs };
}
for (const key of Object.keys(src.subs)) if (!subs[key]) fail(`sub-step ${key} is used by no step`);
for (const [kind, list] of Object.entries(src.flows)) {
  for (const f of list) if (!steps[f.step]) fail(`flow ${kind}: no step ${f.step}`);
}
for (const id of [...src.hub.days, ...src.hub.ihram, src.hub.madinah, src.hub.umrahIntro, src.hub.pillars]) {
  if (!steps[id]) fail(`hub: no step ${id}`);
}

// The official guide's paragraphs, their ayahs in the King Fahd Complex text too.
const official = {
  title: dalil.source.title,
  types: dalil.types.map((x) => ({ name: x.name, segs: segments(x.text) })),
  typesNote: segments(dalil.typesNote),
  umrah: dalil.umrah.map((p) => segments(p)),
  hajj: dalil.hajj.map((p) => segments(p)),
};

const out = {
  schema: "hajj-guide.v2",
  note: "Generated by content/pilgrimage/build-guide.mjs from guide.v2.src.json. Do not edit.",
  sources: Object.values(src.sources).map(({ file, ...rest }) => rest),
  corrections: src.corrections.map((c) => `${src.sources.ibnbaz.short} ص${ar(c.page)}: «${c.from}» صُحّحت إلى «${c.to}»`),
  scenes: src.scenes,
  subs,
  steps,
  flows: src.flows,
  hub: src.hub,
  official,
};
const text = `${JSON.stringify(out, null, 1)}\n`;
if (process.argv.includes("--check")) {
  let old = "";
  try {
    old = read(OUT);
  } catch {
    /* missing */
  }
  if (old !== text) {
    console.error(`${OUT} is stale: run node content/pilgrimage/build-guide.mjs`);
    process.exit(1);
  }
  console.log(`${OUT} up to date`);
} else {
  mkdirSync(join(repo, "content/pilgrimage/dist"), { recursive: true });
  writeFileSync(join(repo, OUT), text);
  console.log(`wrote ${OUT}: ${Object.keys(steps).length} steps`);
}
