"""Gives every step picture a file name that carries its content hash (w-hands-1a2b3c4d.webp), so a
changed picture gets a new address and no browser, service worker or CDN can keep showing the old
one (owner 2026-11-21: old pictures still showed after Ctrl+F5). Run after render.js; it renames the
files in both output folders, deletes the older versions and updates `pic` in content/kids/learn/steps.json.
Usage: python3 tools/kids_steps_3d/version_names.py"""
import hashlib, json, pathlib, re

repo = pathlib.Path(__file__).resolve().parents[2]
outs = [repo / 'apps/mobile/assets/kids/steps', repo / 'apps/web/public/kids/steps']
steps_file = repo / 'content/kids/learn/steps.json'
NAME = re.compile(r'^([a-z]-[a-z0-9]+?)(?:-[0-9a-f]{8})?\.webp$')

def newest(folder, pose):
    files = [f for f in folder.glob(f'{pose}*.webp') if (m := NAME.match(f.name)) and m.group(1) == pose]
    return max(files, key=lambda f: f.stat().st_mtime_ns)

mobile = outs[0]
poses = sorted({NAME.match(f.name).group(1) for f in mobile.glob('*.webp') if NAME.match(f.name)})
names = {}
for pose in poses:
    src = newest(mobile, pose)
    data = src.read_bytes()
    stem = f'{pose}-{hashlib.sha256(data).hexdigest()[:8]}'
    names[pose] = stem
    for folder in outs:
        (folder / f'{stem}.webp').write_bytes(data)
        for f in folder.glob(f'{pose}*.webp'):
            m = NAME.match(f.name)
            if m and m.group(1) == pose and f.name != f'{stem}.webp':
                f.unlink()

text = steps_file.read_text(encoding='utf-8')
def swap(m):
    base = NAME.match(m.group(1) + '.webp').group(1)
    return f'"pic": "{names[base]}"'
text = re.sub(r'"pic": "([a-z]-[a-z0-9-]+)"', swap, text)
json.loads(text)
steps_file.write_text(text, encoding='utf-8')
print('\n'.join(f'{k} -> {v}.webp' for k, v in names.items()))
