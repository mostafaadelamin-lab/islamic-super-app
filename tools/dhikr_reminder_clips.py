"""Dhikr reminders (1.2.14, owner 2026-11-20): cuts the short spoken clips the reminder
notifications play, from Sheikh Alafasy's morning adhkar recording (the same file and the
same hand-checked clip times as driving mode, content/adhkar/drive-clips.json).

Each clip is ONE reading of the dhikr, so it doubles as the notification sound:
  apps/mobile/android/app/src/main/res/raw/dhikr_<id>.ogg   (Android channel sound)
  apps/mobile/ios/Runner/dhikr_<id>.caf                     (iOS sound, IMA4; iOS plays <= 30 s)
  apps/mobile/assets/audio/dhikr/dhikr_<id>.m4a             (the in-app "listen" button)
  apps/web/public/audio/dhikr/dhikr_<id>.mp3                (the website)

Usage: python3 tools/dhikr_reminder_clips.py /path/to/adhkar_morning_alafasy.mp3"""
import json, pathlib, subprocess, sys

# id -> index in adhkar.v1.json (keep in step with lib/domain/dhikr_reminders.dart and web lib/dhikr-reminders.ts)
ITEMS = {
    'salat': 28, 'subhan': 33, 'istighfar': 32, 'tahlil': 27,
    'hasbi': 16, 'subhanadad': 30, 'hayy': 21, 'radeetu': 20,
}
root = pathlib.Path(__file__).resolve().parent.parent
src = sys.argv[1]
clips = json.loads((root / 'content/adhkar/drive-clips.json').read_text())['morning']['clips']
m = root / 'apps/mobile'
outs = {
    'ogg': (m / 'android/app/src/main/res/raw', ['-c:a', 'libvorbis', '-q:a', '3', '-ar', '44100']),
    'caf': (m / 'ios/Runner', ['-c:a', 'adpcm_ima_qt', '-ar', '22050', '-f', 'caf']),
    'm4a': (m / 'assets/audio/dhikr', ['-c:a', 'aac', '-b:a', '48k', '-ar', '44100']),
    'mp3': (root / 'apps/web/public/audio/dhikr', ['-c:a', 'libmp3lame', '-b:a', '48k', '-ar', '44100']),
}
for id_, idx in ITEMS.items():
    a, b = clips[str(idx)][:2]
    dur = b - a
    assert dur < 30, (id_, dur)  # iOS notification sounds stop at 30 s
    for ext, (d, codec) in outs.items():
        d.mkdir(parents=True, exist_ok=True)
        fade = f'afade=t=in:d=0.03,afade=t=out:st={dur - 0.08:.3f}:d=0.08'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', f'{a:.3f}', '-t', f'{dur:.3f}', '-i', src,
                        '-ac', '1', '-af', fade, *codec, str(d / f'dhikr_{id_}.{ext}')], check=True)
    print(id_, round(dur, 1))
