// Renders every pose in poses.js with three.js in headless Chromium (Playwright), then writes
// 720px webp files to apps/mobile/assets/kids/steps/ and apps/web/public/kids/steps/.
// Usage: cd tools/kids_steps_3d && npm i && node render.js [pose ...]
// Then version_names.py (run at the end) renames each file to <pose>-<hash>.webp and updates steps.json.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const { chromium } = require('playwright');

const here = __dirname;
const repo = path.resolve(here, '../..');
const outs = [path.join(repo, 'apps/mobile/assets/kids/steps'), path.join(repo, 'apps/web/public/kids/steps')];
const types = { '.html': 'text/html', '.js': 'text/javascript' };

(async () => {
  const src = fs.readFileSync(path.join(here, 'poses.js'), 'utf8');
  const all = [...src.matchAll(/^\s+'([ws]-[a-z0-9]+)':/gm)].map((m) => m[1]);
  const poses = process.argv.slice(2).length ? process.argv.slice(2) : all;
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 900, height: 900 }, deviceScaleFactor: 1 });
  await p.route('http://steps.local/**', (route) => {
    const file = path.join(here, new URL(route.request().url()).pathname.replace(/^\//, ''));
    route.fulfill({ body: fs.readFileSync(file), contentType: types[path.extname(file)] ?? 'application/octet-stream' });
  });
  p.on('pageerror', (e) => console.error('page error:', e.message));
  for (const o of outs) fs.mkdirSync(o, { recursive: true });
  const tmp = fs.mkdtempSync(path.join(require('os').tmpdir(), 'steps-'));
  for (const pose of poses) {
    await p.goto(`http://steps.local/scene.html?pose=${pose}`);
    await p.waitForFunction('window.__done === true', null, { timeout: 120000 });
    const png = path.join(tmp, `${pose}.png`);
    await p.screenshot({ path: png });
    const webp = path.join(outs[0], `${pose}.webp`); // newest file wins in version_names.py
    execFileSync('python3', ['-c', 'import sys;from PIL import Image;Image.open(sys.argv[1]).convert("RGB").resize((720,720),Image.LANCZOS).save(sys.argv[2],"WEBP",quality=82,method=6)', png, webp]);
    fs.copyFileSync(webp, path.join(outs[1], `${pose}.webp`));
    console.log(pose, fs.statSync(webp).size);
  }
  await b.close();
  // New file names carrying each picture's hash, so nobody keeps seeing an old picture.
  execFileSync('python3', [path.join(here, 'version_names.py')], { stdio: 'inherit' });
})();
