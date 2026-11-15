#!/usr/bin/env node
/**
 * Our own isometric ("3D") drawings for each step of Umrah and Hajj (owner 2026-11-15: a clear picture at
 * every step, made by us, never copied). Each drawing is a list of flat shapes (polygons, ellipses, lines,
 * text) in a fixed box, written to dist/hajj-scenes.v1.json; the website draws them as SVG and the app with
 * a CustomPainter, from the same file. Colours are roles, not values: each platform maps a role to the
 * colour of the chosen style (ground, primary, accent, gold, ink...), and only things that have one real
 * colour (the Kaaba's black, the green lights of the Mas'a, white ihram cloth) keep a fixed one.
 *
 * A drawing shows only the places of its own rite (owner 2026-11-15: no Mina, Muzdalifah or Arafah in an
 * Umrah picture); the tests check that per rite.
 *
 *   node content/pilgrimage/build-scenes.mjs [--check]
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, "../..");
const OUT = "content/pilgrimage/dist/hajj-scenes.v1.json";

const C = Math.cos(Math.PI / 6);
const S = Math.sin(Math.PI / 6);
const r1 = (n) => Math.round(n * 10) / 10;

/** A scene: an isometric projection around origin [ox, oy] at scale k. */
function scene(w, h, ox, oy, k = 1) {
  const shapes = [];
  const P = (x, y, z = 0) => [r1(ox + (x - y) * C * k), r1(oy + (x + y) * S * k - z * k)];
  const flat = (pts) => pts.flat();
  const api = {
    shapes,
    P,
    poly(pts, f, extra = {}) {
      shapes.push({ t: "poly", p: flat(pts), f, ...extra });
    },
    /** A box: [x, y] its back corner on the ground, w along x, d along y, h up. Faces: top, left, right. */
    box(x, y, w, d, hgt, roles, z0 = 0) {
      const [top, left, right] = roles;
      api.poly([P(x, y + d, z0), P(x + w, y + d, z0), P(x + w, y + d, z0 + hgt), P(x, y + d, z0 + hgt)], left);
      api.poly([P(x + w, y, z0), P(x + w, y + d, z0), P(x + w, y + d, z0 + hgt), P(x + w, y, z0 + hgt)], right);
      api.poly(
        [P(x, y, z0 + hgt), P(x + w, y, z0 + hgt), P(x + w, y + d, z0 + hgt), P(x, y + d, z0 + hgt)],
        top,
      );
    },
    /** A flat plate (ground) with a visible edge [th] thick. */
    plate(x, y, w, d, th, roles) {
      api.box(x, y, w, d, th, roles, -th);
    },
    /** A circle lying on the ground at height z. */
    disc(cx, cy, r, f, extra = {}, z = 0) {
      const [x, y] = P(cx, cy, z);
      shapes.push({ t: "ell", cx: x, cy: y, rx: r1(r * C * k * Math.SQRT2), ry: r1(r * S * k * Math.SQRT2), f, ...extra });
    },
    /** A cylinder standing on the ground (side then top). */
    cyl(cx, cy, r, hgt, top, side, z0 = 0) {
      const [x, y0] = P(cx, cy, z0);
      const [, y1] = P(cx, cy, z0 + hgt);
      const rx = r1(r * C * k * Math.SQRT2);
      const ry = r1(r * S * k * Math.SQRT2);
      shapes.push({ t: "ell", cx: x, cy: y0, rx, ry, f: side });
      api.poly([[r1(x - rx), y0], [r1(x + rx), y0], [r1(x + rx), y1], [r1(x - rx), y1]], side);
      shapes.push({ t: "ell", cx: x, cy: y1, rx, ry, f: top });
    },
    /** A dome: half ellipse on a ring. */
    dome(cx, cy, r, z0, f, shade) {
      const [x, y] = P(cx, cy, z0);
      const rx = r1(r * C * k * Math.SQRT2);
      const ry = r1(r * S * k * Math.SQRT2);
      shapes.push({ t: "dome", cx: x, cy: y, rx, ry, h: r1(rx * 1.05), f, s: shade });
    },
    line(pts, s, sw = 2, extra = {}) {
      shapes.push({ t: "line", p: flat(pts), s, sw, ...extra });
    },
    text(x, y, z, v, f, size = 13, extra = {}) {
      const [px, py] = P(x, y, z);
      shapes.push({ t: "text", x: px, y: py, v, f, size, ...extra });
    },
    label(px, py, v, f, size = 13, extra = {}) {
      shapes.push({ t: "text", x: r1(px), y: r1(py), v, f, size, ...extra });
    },
    /** A name in free space with a thin leader line to the thing it names. */
    callout(x, y, z, px, py, v, f, size = 11.5, extra = {}) {
      const [ax, ay] = P(x, y, z);
      shapes.push({ t: "line", p: [ax, ay, r1(px), r1(py - size * 0.4)], s: "muted", sw: 1 });
      shapes.push({ t: "text", x: r1(px), y: r1(py), v, f, size, ...extra });
    },
    /** Text [dy] pixels below a ground point. */
    under(x, y, dy, v, f, size = 12, extra = {}) {
      const [px, py] = P(x, y, 0);
      shapes.push({ t: "text", x: px, y: r1(py + dy), v, f, size, ...extra });
    },
    /** A numbered pin standing at a ground point. */
    pin(x, y, z, n, f = "accent") {
      const [px, py] = P(x, y, z);
      shapes.push({ t: "line", p: [px, py, px, r1(py - 22)], s: f, sw: 2 });
      shapes.push({ t: "circle", cx: px, cy: r1(py - 29), r: 9, f });
      shapes.push({ t: "text", x: px, y: r1(py - 25), v: n, f: "onAccent", size: 11, w: 700 });
    },
    done(places, title) {
      return { w, h, title, places, shapes };
    },
  };
  return api;
}

const GROUND = ["ground", "groundL", "groundR"];
const DIGITS = "٠١٢٣٤٥٦٧٨٩";
const ar = (n) => String(n).replace(/\d/g, (d) => DIGITS[Number(d)]);

/** A standing person in ihram: [wrap] "full" (both shoulders), "idtiba" (right shoulder bare), "woman". */
function person(s, x, y, wrap, scale = 1) {
  const k = scale;
  const [fx, fy] = s.P(x, y, 0);
  const H = 64 * k;
  const body = wrap === "woman" ? "robe" : "cloth";
  // shadow
  s.shapes.push({ t: "ell", cx: fx, cy: r1(fy), rx: r1(15 * k), ry: r1(5 * k), f: "shadow" });
  // legs / lower garment (izar or robe)
  const lw = 12 * k;
  s.poly(
    [
      [fx - lw, fy - 2 * k],
      [fx + lw, fy - 2 * k],
      [fx + lw - 1 * k, fy - H * 0.5],
      [fx - lw + 1 * k, fy - H * 0.5],
    ],
    body,
    { s: "outline", sw: 1 },
  );
  if (wrap !== "woman") {
    // feet (sandals)
    s.poly([[fx - 9 * k, fy], [fx - 2 * k, fy], [fx - 2 * k, fy - 3 * k], [fx - 9 * k, fy - 3 * k]], "skin");
    s.poly([[fx + 2 * k, fy], [fx + 9 * k, fy], [fx + 9 * k, fy - 3 * k], [fx + 2 * k, fy - 3 * k]], "skin");
  }
  // torso
  const tw = 14 * k;
  const t0 = fy - H * 0.5;
  const t1 = fy - H * 0.85;
  if (wrap === "woman") {
    s.poly([[fx - tw, t0], [fx + tw, t0], [fx + tw - 3 * k, t1], [fx - tw + 3 * k, t1]], "robe", { s: "outline", sw: 1 });
    // head covering
    s.shapes.push({ t: "ell", cx: fx, cy: r1(t1 - 8 * k), rx: r1(10 * k), ry: r1(11 * k), f: "robe", s: "outline", sw: 1 });
    s.shapes.push({ t: "ell", cx: fx, cy: r1(t1 - 7 * k), rx: r1(6 * k), ry: r1(7 * k), f: "skin" });
    return;
  }
  // skin under the rida
  s.poly([[fx - tw, t0], [fx + tw, t0], [fx + tw - 2 * k, t1], [fx - tw + 2 * k, t1]], "skin");
  if (wrap === "full") {
    s.poly([[fx - tw, t0], [fx + tw, t0], [fx + tw - 2 * k, t1], [fx - tw + 2 * k, t1]], "cloth", { s: "outline", sw: 1 });
  } else {
    // idtiba: the rida passes under the right arm (viewer's left) and over the left shoulder
    s.poly([[fx - tw, t0 + 2 * k], [fx + tw, t0], [fx + tw - 2 * k, t1], [fx + 2 * k, t1], [fx - tw, t0 - 10 * k]], "cloth", {
      s: "outline",
      sw: 1,
    });
  }
  // arms
  s.line([[fx - tw - 1 * k, t1 + 3 * k], [fx - tw - 3 * k, t0 + 4 * k]], wrap === "idtiba" ? "skin" : "cloth", 5 * k);
  s.line([[fx + tw + 1 * k, t1 + 3 * k], [fx + tw + 3 * k, t0 + 4 * k]], "cloth", 5 * k);
  // head
  s.shapes.push({ t: "ell", cx: fx, cy: r1(t1 - 8 * k), rx: r1(7 * k), ry: r1(8 * k), f: "skin", s: "outline", sw: 1 });
}

/** Tents of Mina in rows. */
function tents(s, x0, y0, cols, rows, gap = 22) {
  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const x = x0 + c * gap;
      const y = y0 + r * gap;
      s.box(x, y, 14, 14, 7, ["tent", "tentL", "tentR"]);
      const top = [s.P(x, y, 7), s.P(x + 14, y, 7), s.P(x + 14, y + 14, 7), s.P(x, y + 14, 7)];
      const peak = s.P(x + 7, y + 7, 15);
      s.poly([top[3], top[2], peak], "tentL");
      s.poly([top[1], top[2], peak], "tentR");
      s.poly([top[0], top[1], peak], "tent");
    }
  }
}

function kaaba(s, x, y, size = 60, hgt = 70) {
  s.box(x, y, size, size, hgt, ["kaaba", "kaabaL", "kaabaR"]);
  const b = hgt * 0.76;
  s.poly([s.P(x, y + size, b), s.P(x + size, y + size, b), s.P(x + size, y + size, b + 6), s.P(x, y + size, b + 6)], "gold");
  s.poly([s.P(x + size, y, b), s.P(x + size, y + size, b), s.P(x + size, y + size, b + 6), s.P(x + size, y, b + 6)], "goldDark");
}

const scenes = {};

// ---------- Miqat: the five miqats around Makkah, each with the people it is for ----------
{
  const s = scene(360, 300, 180, 150, 0.44);
  s.plate(-230, -230, 460, 460, 12, GROUND);
  // bearing (degrees from north) to the ground plane: north is screen-up.
  const B = (deg, r) => {
    const n = Math.cos((deg * Math.PI) / 180);
    const e = Math.sin((deg * Math.PI) / 180);
    return [((-n + e) / Math.SQRT2) * r, ((-n - e) / Math.SQRT2) * r];
  };
  const M = [
    ["ذو الحليفة", "أهل المدينة", 355, 205],
    ["الجحفة", "أهل الشام ومصر", 300, 200],
    ["ذات عرق", "أهل العراق", 45, 180],
    ["قرن المنازل", "أهل نجد", 95, 190],
    ["يلملم", "أهل اليمن", 165, 190],
  ];
  for (const [, , deg, r] of M) {
    const [x, y] = B(deg, r);
    s.line([s.P(0, 0), s.P(x, y)], "primary", 1.5, { dash: [5, 4] });
  }
  kaaba(s, -14, -14, 28, 34);
  s.text(0, 0, 66, "مكة المكرمة", "primary", 13, { w: 700 });
  for (const [name, who, deg, r] of M) {
    const [x, y] = B(deg, r);
    s.cyl(x, y, 9, 22, "accent", "accentDark");
    s.text(x, y, 90, name, "primary", 12.5, { w: 700 });
    s.text(x, y, 52, who, "ink", 11);
  }
  s.label(36, 24, "↑ الشمال", "muted", 11, { w: 700 });
  s.label(180, 292, "رسم توضيحي للاتجاهات، وليس خريطة بمقياس", "muted", 10);
  scenes.miqat = s.done(["miqat", "makkah"], "المواقيت حول مكة");
}

// ---------- Ihram clothes: a man in izar and rida, a woman in her usual covering clothes ----------
{
  const s = scene(360, 210, 180, 92, 1);
  s.plate(-90, -60, 180, 140, 6, GROUND);
  person(s, -10, 40, "full", 1.25);
  person(s, 40, -30, "woman", 1.25);
  s.under(-10, 40, 22, "الرجل: إزار ورداء", "ink", 12, { w: 700 });
  s.under(40, -30, 22, "المرأة", "ink", 12, { w: 700 });
  scenes.ihram = s.done([], "لباس الإحرام");
}

// ---------- Idtiba: the rida under the right arm, the right shoulder bare (first tawaf, men) ----------
{
  const s = scene(360, 210, 180, 92, 1);
  s.plate(-90, -60, 180, 140, 6, GROUND);
  person(s, -10, 40, "full", 1.25);
  person(s, 40, -30, "idtiba", 1.25);
  s.under(-10, 40, 22, "الرداء على الكتفين", "muted", 11.5, { w: 700 });
  s.under(40, -30, 22, "الاضطباع", "primary", 13, { w: 700 });
  scenes.idtiba = s.done([], "الاضطباع");
}

// ---------- Tawaf: the Kaaba, Black Stone (start), corners, Hijr, Maqam, the way round ----------
function tawafScene(withMaqam) {
  const s = scene(360, 250, 180, 34, 0.5);
  s.plate(10, 10, 380, 380, 10, GROUND);
  s.disc(200, 200, 175, "mataf");
  // the stretch between the Yemeni corner and the Black Stone
  const zone = [];
  for (let a = 48; a <= 132; a += 4) {
    const t = (a * Math.PI) / 180;
    zone.push(s.P(200 + 170 * Math.cos(t), 200 + 170 * Math.sin(t)));
  }
  for (let a = 132; a >= 48; a -= 4) {
    const t = (a * Math.PI) / 180;
    zone.push(s.P(200 + 52 * Math.cos(t), 200 + 52 * Math.sin(t)));
  }
  s.poly(zone, "goldSoft");
  // the way round, anticlockwise seen from above
  const ring = [];
  for (let a = 0; a <= 320; a += 8) {
    const t = (-a * Math.PI) / 180 + Math.PI / 4;
    ring.push(s.P(200 + 128 * Math.cos(t), 200 + 128 * Math.sin(t)));
  }
  s.line(ring, "primary", 3, { dash: [9, 6], arrow: true });
  // Hijr Isma'il, the half circle on the far side
  const hijr = [];
  for (let a = 180; a <= 360; a += 10) {
    const t = (a * Math.PI) / 180;
    hijr.push(s.P(200 + 32 * Math.cos(t), 166 + 24 * Math.sin(t)));
  }
  s.line(hijr, "hijr", 6);
  // start line from the Black Stone
  s.line([s.P(230, 230), s.P(352, 352)], "accent", 2.5, { dash: [5, 4] });
  kaaba(s, 170, 170, 60, 78);
  // door on the right face, near the Black Stone end
  s.poly([s.P(230, 196, 8), s.P(230, 212, 8), s.P(230, 212, 38), s.P(230, 196, 38)], "gold");
  const [bx, by] = s.P(230, 230, 10);
  s.shapes.push({ t: "circle", cx: bx, cy: by, r: 5, f: "stone", s: "stoneFrame", sw: 2 });
  if (withMaqam) s.box(268, 194, 9, 9, 13, ["gold", "goldDark", "gold"]);
  s.pin(232, 232, 10, "١");
  s.label(180, 222, "الحجر الأسود", "accent", 12, { w: 700 });
  s.callout(170, 230, 20, 58, 150, "الركن اليماني", "ink", 11.5, { w: 700 });
  s.callout(200, 330, 0, 58, 206, "بين الركنين", "goldDark", 11.5, { w: 700 });
  s.callout(200, 150, 0, 300, 70, "حِجر إسماعيل", "muted", 11, { w: 700 });
  if (withMaqam) s.callout(272, 198, 13, 310, 190, "مقام إبراهيم", "ink", 11.5, { w: 700 });
  s.label(60, 22, "اتجاه الطواف ↺", "primary", 12, { w: 700 });
  return s;
}
scenes.tawaf = tawafScene(true).done(["kaaba"], "الطواف حول الكعبة");

// ---------- Maqam Ibrahim: pray two rak'ahs behind it, the Kaaba beyond ----------
{
  const s = scene(360, 220, 170, 60, 0.6);
  s.plate(0, 0, 260, 260, 8, GROUND);
  s.disc(110, 110, 105, "mataf");
  kaaba(s, 80, 80, 60, 78);
  s.box(178, 104, 12, 12, 16, ["gold", "goldDark", "gold"]);
  s.callout(184, 110, 16, 300, 196, "مقام إبراهيم", "ink", 12, { w: 700 });
  // a row of praying people behind the Maqam, the Maqam between them and the Kaaba
  for (const d of [-26, 0, 26]) s.box(214, 104 + d, 8, 8, 10, ["cloth", "clothL", "clothR"]);
  s.line([s.P(222, 108), s.P(150, 110)], "primary", 2, { dash: [5, 4], arrow: true });
  s.text(110, 110, 100, "الكعبة", "ink", 12, { w: 700 });
  scenes.maqam = s.done(["kaaba"], "ركعتا الطواف خلف المقام");
}

// ---------- Sa'i: Safa to Marwa, the green lights, seven laps ending at Marwa ----------
{
  const s = scene(360, 220, 84, 72, 0.42);
  s.plate(0, 0, 520, 90, 6, GROUND);
  s.box(0, 38, 520, 14, 1, ["groundL", "groundL", "groundL"]);
  s.box(200, 0, 120, 90, 1, ["greenSoft", "green", "green"]);
  for (const x of [200, 320]) {
    s.box(x - 3, -8, 6, 6, 62, ["greenLight", "green", "greenDark"]);
    s.box(x - 3, 92, 6, 6, 62, ["greenLight", "green", "greenDark"]);
  }
  s.box(-80, 8, 80, 74, 34, ["hill", "hillL", "hillR"]);
  s.box(520, 8, 80, 74, 26, ["hill", "hillL", "hillR"]);
  s.line([s.P(20, 22, 2), s.P(500, 22, 2)], "primary", 3, { arrow: true });
  s.line([s.P(500, 70, 2), s.P(20, 70, 2)], "primary", 3, { dash: [8, 5], arrow: true });
  s.text(-40, 45, 82, "الصفا", "primary", 16, { w: 700 });
  s.text(-40, 45, 28, "البداية", "muted", 11);
  s.text(560, 45, 74, "المروة", "primary", 16, { w: 700 });
  s.text(560, 45, 18, "النهاية", "muted", 11);
  s.text(260, -10, 100, "العلمان الأخضران", "greenDark", 11.5, { w: 700 });
  s.label(250, 40, "ذهابه شوط، ورجوعه شوط", "primary", 12, { w: 700 });
  scenes.sai = s.done(["safa", "marwah"], "السعي بين الصفا والمروة");
}

// ---------- Halq or taqsir: razor and scissors ----------
{
  const s = scene(360, 190, 180, 50, 1);
  s.plate(-80, -50, 160, 140, 6, GROUND);
  // razor: handle and blade
  s.box(-50, 10, 70, 10, 5, ["ink", "inkL", "ink"]);
  s.box(20, 10, 30, 10, 3, ["metal", "metalL", "metal"]);
  // scissors: two blades crossing and two rings
  s.line([s.P(-10, 50, 3), s.P(50, 70, 3)], "metalL", 4);
  s.line([s.P(-10, 70, 3), s.P(50, 50, 3)], "metalL", 4);
  s.disc(-22, 46, 8, "none", { s: "accent", sw: 3 }, 3);
  s.disc(-22, 74, 8, "none", { s: "accent", sw: 3 }, 3);
  s.under(0, 15, 26, "الحلق", "ink", 13, { w: 700 });
  s.under(20, 60, 34, "التقصير", "ink", 13, { w: 700 });
  scenes.halq = s.done([], "الحلق أو التقصير");
}

// ---------- The holy sites: Mina, Muzdalifah, Arafah, each on its own ----------
{
  const s = scene(360, 220, 180, 96, 0.58);
  s.plate(-120, -100, 240, 200, 8, GROUND);
  s.box(-140, -110, 30, 220, 40, ["hill", "hillL", "hillR"]);
  tents(s, -96, -80, 8, 7, 24);
  s.label(310, 206, "منى", "primary", 14, { w: 700 });
  scenes.mina = s.done(["mina"], "منى");
}
{
  const s = scene(360, 220, 180, 92, 0.58);
  s.plate(-140, -100, 280, 220, 8, GROUND);
  // Jabal al-Rahmah: a stepped hill
  s.box(30, -40, 80, 80, 18, ["hill", "hillL", "hillR"]);
  s.box(45, -25, 50, 50, 16, ["hill", "hillL", "hillR"], 18);
  s.box(62, -8, 16, 16, 30, ["white", "whiteL", "whiteR"], 34);
  s.text(70, 0, 104, "جبل الرحمة", "ink", 11.5, { w: 700 });
  // Namirah mosque with its minarets
  s.box(-110, 40, 70, 50, 20, ["wall", "wallL", "wallR"]);
  for (const [x, y] of [[-110, 40], [-40, 40], [-110, 90]]) s.cyl(x, y, 3, 50, "wall", "wallL", 0);
  s.text(-75, 65, 66, "مسجد نمرة", "ink", 11.5, { w: 700 });
  // pilgrims facing the qiblah
  for (let i = 0; i < 6; i++) for (let j = 0; j < 3; j++) s.box(-20 + i * 14, 60 + j * 14, 6, 6, 9, ["cloth", "clothL", "clothR"]);
  s.label(310, 206, "عرفة", "primary", 14, { w: 700 });
  scenes.arafah = s.done(["arafah"], "عرفة");
}
{
  const s = scene(360, 220, 180, 92, 0.58);
  s.plate(-140, -100, 280, 220, 8, GROUND);
  // al-Mash'ar al-Haram mosque
  s.box(-40, -60, 90, 60, 22, ["wall", "wallL", "wallR"]);
  for (const [x, y] of [[-40, -60], [50, -60]]) s.cyl(x, y, 3, 56, "wall", "wallL", 0);
  s.text(5, -30, 74, "المشعر الحرام", "ink", 11.5, { w: 700 });
  // night sky dots (stars)
  for (const [x, y] of [[40, 30], [90, 22], [150, 36], [260, 26], [310, 40]]) s.shapes.push({ t: "circle", cx: x, cy: y, r: 1.6, f: "gold" });
  // pebbles
  for (let i = 0; i < 7; i++) s.disc(30 + (i % 4) * 9, 60 + Math.floor(i / 4) * 9, 3.2, "pebble");
  s.text(44, 66, -10, "الحصى", "muted", 11);
  // pilgrims resting
  for (let i = 0; i < 5; i++) s.box(-110 + i * 18, 70, 12, 6, 3, ["cloth", "clothL", "clothR"]);
  s.label(310, 206, "مزدلفة", "primary", 14, { w: 700 });
  scenes.muzdalifah = s.done(["muzdalifah"], "مزدلفة");
}

// ---------- Jamarat: Aqaba alone on the day of Nahr; all three in order on the days of Tashriq ----------
function jamaratScene(aqabaOnly) {
  const s = scene(360, 240, 64, 58, 0.45);
  s.plate(0, 0, 600, 130, 8, GROUND);
  const J = [
    ["الجمرة الأولى", 70, "١"],
    ["الجمرة الوسطى", 290, "٢"],
    ["جمرة العقبة", 510, "٣"],
  ];
  for (const [name, x, n] of J) {
    const on = !aqabaOnly || n === "٣";
    const fade = on ? "" : "Faded";
    s.box(x - 34, 28, 68, 74, 7, [`basin${fade}`, `basinL${fade}`, `basinR${fade}`]);
    s.box(x - 7, 56, 14, 18, 70, [`pillar${fade}`, `pillarL${fade}`, `pillarR${fade}`]);
    if (on) s.pin(x, 64, 78, aqabaOnly ? "٧" : n);
    s.text(x + 30, 150, 0, name, on ? "primary" : "muted", 12, { w: 700 });

  }
  s.label(300, 24, aqabaOnly ? "يوم النحر" : "أيام التشريق", "primary", 13, { w: 700 });
  return s;
}
scenes.aqaba = jamaratScene(true).done(["jamarat"], "رمي جمرة العقبة");
scenes.jamarat = jamaratScene(false).done(["jamarat"], "رمي الجمرات الثلاث");

// ---------- Hady: a sheep ----------
{
  const s = scene(360, 200, 180, 84, 1.3);
  s.plate(-70, -50, 140, 110, 6, GROUND);
  for (const [x, y] of [[-26, -8], [14, -8], [-26, 10], [14, 10]]) s.box(x, y, 6, 6, 14, ["inkL", "ink", "ink"]);
  s.box(-30, -10, 54, 28, 22, ["wool", "woolL", "woolR"], 14);
  s.box(24, -6, 18, 20, 16, ["skin", "ink", "inkL"], 26);
  s.label(180, 190, "الهدي", "primary", 13, { w: 700 });
  scenes.hady = s.done([], "ذبح الهدي");
}

// ---------- Madinah: the Prophet's Mosque with the green dome, and Quba ----------
{
  const s = scene(360, 230, 180, 104, 0.55);
  s.plate(-140, -110, 280, 240, 8, GROUND);
  s.box(-110, -90, 150, 120, 26, ["wall", "wallL", "wallR"]);
  for (const [x, y] of [[-110, -90], [40, -90], [-110, 30], [40, 30]]) s.cyl(x, y, 4, 70, "wall", "wallL", 0);
  s.dome(10, 0, 18, 26, "greenDome", "greenDark");
  s.text(-35, -30, 96, "المسجد النبوي", "ink", 12, { w: 700 });
  s.box(80, -60, 50, 40, 16, ["white", "whiteL", "whiteR"]);
  s.dome(105, -40, 10, 16, "white", "whiteL");
  s.cyl(80, -60, 3, 44, "white", "whiteL");
  s.under(105, -20, 22, "مسجد قباء", "ink", 11.5, { w: 700 });
  s.label(310, 214, "المدينة المنورة", "primary", 13, { w: 700 });
  scenes.madinah = s.done(["madinah"], "المدينة المنورة");
}

const out = {
  schema: "hajj-scenes.v1",
  note: "Generated by content/pilgrimage/build-scenes.mjs. Shapes in each scene's own box (w x h); colours are roles.",
  scenes,
};
const text = `${JSON.stringify(out)}\n`;
if (process.argv.includes("--check")) {
  let old = "";
  try {
    old = readFileSync(join(repo, OUT), "utf8");
  } catch {
    /* missing */
  }
  if (old !== text) {
    console.error(`${OUT} is stale: run node content/pilgrimage/build-scenes.mjs`);
    process.exit(1);
  }
  console.log(`${OUT} up to date`);
} else {
  mkdirSync(join(repo, "content/pilgrimage/dist"), { recursive: true });
  writeFileSync(join(repo, OUT), text);
  const roles = new Set();
  for (const sc of Object.values(scenes)) for (const x of sc.shapes) for (const k of ["f", "s"]) if (x[k]) roles.add(x[k]);
  console.log(`wrote ${OUT}: ${Object.keys(scenes).length} scenes; roles: ${[...roles].sort().join(" ")}`);
}
