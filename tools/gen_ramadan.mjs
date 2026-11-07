// Prints the "ramadanUmmAlQura" table of packages/shared-schemas/prayer/methods.json:
// Gregorian first and last day of Ramadan (inclusive) for each Hijri year, by the Umm al-Qura
// calendar as implemented by ICU (Intl "islamic-umalqura"). Usage: node tools/gen_ramadan.mjs
const f = new Intl.DateTimeFormat("en-u-ca-islamic-umalqura", { timeZone: "UTC", year: "numeric", month: "numeric", day: "numeric" });
const out = {};
for (let d = Date.UTC(2019, 0, 1); d < Date.UTC(2077, 0, 1); d += 86400000) {
  const p = Object.fromEntries(f.formatToParts(new Date(d)).map((x) => [x.type, x.value]));
  if (p.month !== "9") continue;
  const y = p.year.replace(/\D/g, "");
  const iso = new Date(d).toISOString().slice(0, 10);
  out[y] = out[y] ? [out[y][0], iso] : [iso, iso];
}
console.log(Object.entries(out).map(([y, [a, b]]) => `    "${y}": ["${a}", "${b}"]`).join(",\n"));
