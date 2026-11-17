"""Driving mode (1.2.2): writes apps/mobile/assets/content/adhkar-drive.v1.json from the
hand-checked clip list content/adhkar/drive-clips.json.

drive-clips.json gives, for Sheikh Alafasy's morning and evening recordings (the files the
app downloads from rattilwasalli.com/audio), the start and end second of ONE reading of each
dhikr, keyed by its index in adhkar.v1.json. The recording reads every dhikr once or a few
times and then its virtue and narrator; the app plays the clip and repeats it itself the
number of times Hisn al-Muslim states (adhkarMeta), so no count is stored here.

How the times were found (2026-11-17): speech-to-text with word times (faster-whisper,
small model) for a first guess, then each boundary moved into the nearest quiet gap of the
loudness curve, then every clip cut out and transcribed again to check that it starts with
the first word and ends with the last word of the dhikr. Items the recording does not read
(e.g. index 0, and 2 = last two ayat of al-Baqarah) have no clip; driving mode skips them.

Usage: python3 tools/adhkar_drive_clips.py"""
import json, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = json.loads((root / 'content/adhkar/drive-clips.json').read_text())
out = {}
for session in ('morning', 'evening'):
    s = src[session]
    clips = {k: [round(v[0] * 1000), round(v[1] * 1000), *v[2:]] for k, v in s['clips'].items()}
    out[session] = {'file': s['file'], 'clips': dict(sorted(clips.items(), key=lambda kv: int(kv[0])))}
(root / 'apps/mobile/assets/content/adhkar-drive.v1.json').write_text(json.dumps(out, ensure_ascii=False, separators=(',', ':')) + '\n')
print({k: len(v['clips']) for k, v in out.items()})
