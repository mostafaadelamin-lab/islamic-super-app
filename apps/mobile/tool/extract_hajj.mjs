// Mechanically extracts the Hajj & Umrah guide text from the prototype source
// content/pilgrimage/source-hajj.js into assets/content/hajj.v1.json.
// Nothing is typed by hand: the prototype's own view functions are evaluated
// with a stub DOM builder and every text node is copied verbatim.
//
// Usage (from repo root or anywhere):
//   node apps/mobile/tool/extract_hajj.mjs           # write
//   node apps/mobile/tool/extract_hajj.mjs --check   # fail if the bundled copy is stale
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const app = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const root = resolve(app, '../..');
const srcPath = resolve(root, 'content/pilgrimage/source-hajj.js');
const outPath = resolve(app, 'assets/content/hajj.v1.json');
const src = readFileSync(srcPath, 'utf8');

const digits = '٠١٢٣٤٥٦٧٨٩';
const ctx = vm.createContext({
  // Stub DOM builder: returns a plain tree; event handlers are never called.
  el: (tag, attrs, ...children) => {
    const node = { tag, cls: (attrs && attrs.class) || '', children: children.flat() };
    node.append = (...more) => node.children.push(...more.flat());
    return node;
  },
  ar: (n) => String(n).replace(/[0-9]/g, (d) => digits[+d]),
  VIEWS: {},
  store: { get: (_k, d) => d, set: () => {} },
});
vm.runInContext(src, ctx, { filename: 'source-hajj.js' });
const views = vm.runInContext('({umrah: umrahView(), hajj: hajjView(), ihram: ihramView()})', ctx);

const text = (n) => (typeof n === 'string' ? n : n.children.map(text).join(''));

// Converts one prototype "card" (<section>) or top-level <p> into a block.
function block(node) {
  if (node.tag === 'p') return { kind: 'intro', text: text(node) };
  const out = { kind: 'card', label: null, title: null, items: [], paragraphs: [], dua: null, defs: [] };
  const walk = (n) => {
    if (typeof n === 'string') return;
    if (n.tag === 'span' && n.cls === 'label') out.label = text(n);
    else if (n.tag === 'h2') out.title = text(n);
    else if (n.tag === 'li') out.items.push(text(n));
    else if (n.tag === 'p') out.paragraphs.push(text(n));
    else if (n.cls === 'example') out.dua = text(n);
    else if (n.cls === 'item') {
      const [b, small] = n.children[0].children;
      out.defs.push({ term: text(b), detail: text(small) });
    } else if (n.tag === 'div' && n.children.length === 2 && n.children[0].tag === 'b') {
      out.defs.push({ term: text(n.children[0]).replace(/:\s*$/, ''), detail: text(n.children[1]) });
    } else if (n.tag === 'button' || n.tag === 'a') return; // UI controls, not content
    else n.children.forEach(walk);
  };
  node.children.forEach(walk);
  return out;
}

const out = {
  schema: 'hajj.v1',
  source: 'content/pilgrimage/source-hajj.js (Rattil prototype text, project-owned)',
  reviewStatus: 'pending religious review by a qualified scholar',
  talbiya: vm.runInContext('TALBIYA', ctx),
  sections: Object.fromEntries(Object.entries(views).map(([k, v]) => [k, v.map(block)])),
};
const json = JSON.stringify(out, null, 1) + '\n';
if (process.argv.includes('--check')) {
  if (!existsSync(outPath) || readFileSync(outPath, 'utf8') !== json) {
    console.error('stale: assets/content/hajj.v1.json (run node apps/mobile/tool/extract_hajj.mjs)');
    process.exit(1);
  }
  console.log('hajj.v1.json matches source-hajj.js');
} else {
  writeFileSync(outPath, json);
  console.log(`wrote ${outPath}`);
}
