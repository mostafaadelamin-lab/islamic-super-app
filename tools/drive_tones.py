"""Makes the driving-mode cue sounds (the app's own synthesized tones, no recordings):
  apps/mobile/assets/audio/drive_tick.wav  soft short tone between two repetitions
  apps/mobile/assets/audio/drive_done.wav  two-note chime when a dhikr is complete
Usage: python3 tools/drive_tones.py"""
import math, struct, wave, pathlib
out = pathlib.Path(__file__).resolve().parent.parent / 'apps/mobile/assets/audio'
RATE = 22050
def tone(notes, vol):
    s = []
    for f, ms in notes:
        n = int(RATE * ms / 1000)
        for i in range(n):
            t = i / RATE
            env = min(1, i / (RATE * 0.008)) * math.exp(-4.5 * i / n)
            s.append(vol * env * (math.sin(2 * math.pi * f * t) + 0.25 * math.sin(4 * math.pi * f * t)))
    return s
def write(name, s):
    with wave.open(str(out / name), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x)) * 32767)) for x in s))
write('drive_tick.wav', tone([(880, 140)], 0.22))
write('drive_done.wav', tone([(660, 220), (990, 420)], 0.35))
