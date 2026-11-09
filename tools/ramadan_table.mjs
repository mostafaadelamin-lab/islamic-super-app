// Prints the Umm al-Qura Ramadan table stored in packages/shared-schemas/prayer/methods.json
// ("ramadanUmmAlQura": first and last Gregorian day of Ramadan, 1440-1499 AH), from ICU's
// islamic-umalqura calendar (the official Umm al-Qura tables). Run: node tools/ramadan_table.mjs
const f = new Intl.DateTimeFormat("en-u-ca-islamic-umalqura", { timeZone: "UTC", day: "numeric", month: "numeric", year: "numeric" });
const out = [];
let cur = null;
for (let t = Date.UTC(2019, 0, 1); t < Date.UTC(2077, 0, 1); t += 864e5) {
  const p = Object.fromEntries(f.formatToParts(new Date(t)).map((x) => [x.type, x.value]));
  const iso = new Date(t).toISOString().slice(0, 10);
  if (+p.month === 9) {
    if (!cur) cur = [iso];
    cur[1] = iso;
  } else if (cur) {
    out.push(cur);
    cur = null;
  }
}
console.log(JSON.stringify(out));
