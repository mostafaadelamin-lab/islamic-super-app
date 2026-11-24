/**
 * Evens out the lesson recordings while they play (owner 2026-11-24: some are very quiet, some are old,
 * muffled tapes). The recordings stay as published; the list gives a series `fx` (tools/lessons_loudness.py):
 * `g` gain in dB, `c` clarity (cut the rumble, lift the voice). Web Audio, so the audio must come with CORS
 * (archive.org and Spreaker send it); the <audio> element then gets crossOrigin="anonymous".
 */
export interface AudioFx {
  /** Gain in dB (negative = quieter). */
  g?: number;
  /** 1: an old / narrow-band recording: high-pass the hum, lift the voice band. */
  c?: number;
}

interface Graph {
  ctx: AudioContext;
  hp: BiquadFilterNode;
  voice: BiquadFilterNode;
  air: BiquadFilterNode;
  comp: DynamicsCompressorNode;
  gain: GainNode;
}

const graphs = new WeakMap<HTMLMediaElement, Graph>();
/** Low cut for old tapes (Hz) and the voice band lifted (Hz, dB). */
const HUM_CUT_HZ = 110;
const VOICE_HZ = 2500;
const VOICE_DB = 6;
const AIR_HZ = 5000;
const AIR_DB = 4;
const DB_TO_RATIO = 20;
const DB_BASE = 10;
/** No low cut (Hz) for clear recordings. */
const NO_CUT_HZ = 20;
/** Compressor: evens out a voice that comes and goes and keeps a boosted lesson from clipping. */
const COMP_THRESHOLD_DB = -24;
const COMP_RATIO = 3;
const COMP_ATTACK_SEC = 0.01;
const COMP_RELEASE_SEC = 0.25;

/**
 * iPhone / iPad browsers stop Web Audio when the screen locks, which would stop the lesson: there the
 * recording plays as published (background listening matters more).
 */
const IOS = /iPad|iPhone|iPod/;
const isIos = (): boolean =>
  IOS.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);

export const fxSupported = (): boolean =>
  typeof window !== "undefined" && typeof window.AudioContext === "function" && !isIos();

/** Whether this element plays through the effects (it then needs CORS audio). */
export const hasFx = (el: HTMLMediaElement): boolean => graphs.has(el);

function graphFor(el: HTMLMediaElement): Graph {
  const had = graphs.get(el);
  if (had) return had;
  const ctx = new AudioContext();
  const src = ctx.createMediaElementSource(el);
  const hp = ctx.createBiquadFilter();
  hp.type = "highpass";
  const voice = ctx.createBiquadFilter();
  voice.type = "peaking";
  voice.frequency.value = VOICE_HZ;
  voice.Q.value = 1;
  const air = ctx.createBiquadFilter();
  air.type = "highshelf";
  air.frequency.value = AIR_HZ;
  const comp = ctx.createDynamicsCompressor();
  comp.threshold.value = COMP_THRESHOLD_DB;
  comp.ratio.value = COMP_RATIO;
  comp.attack.value = COMP_ATTACK_SEC;
  comp.release.value = COMP_RELEASE_SEC;
  const gain = ctx.createGain();
  src.connect(hp).connect(voice).connect(air).connect(comp).connect(gain).connect(ctx.destination);
  const g = { ctx, hp, voice, air, comp, gain };
  graphs.set(el, g);
  return g;
}

async function resume(ctx: AudioContext): Promise<void> {
  try {
    await ctx.resume();
  } catch {
    /* resumes on the next tap */
  }
}

/**
 * Sets the effects for the track about to play. Call before setting `src` (CORS must be on first).
 * Without fx and without a graph nothing changes; once an element has a graph it stays (Web Audio allows one
 * source per element), set to neutral for tracks without fx.
 */
export function applyFx(el: HTMLMediaElement, fx: AudioFx | undefined): void {
  if (!fxSupported()) return;
  if (!fx && !graphs.has(el)) return;
  el.setAttribute("crossorigin", "anonymous");
  try {
    const g = graphFor(el);
    const clarity = fx?.c === 1;
    g.hp.frequency.value = clarity ? HUM_CUT_HZ : NO_CUT_HZ;
    g.voice.gain.value = clarity ? VOICE_DB : 0;
    g.air.gain.value = clarity ? AIR_DB : 0;
    g.gain.gain.value = Math.pow(DB_BASE, (fx?.g ?? 0) / DB_TO_RATIO);
    if (g.ctx.state === "suspended") void resume(g.ctx);
  } catch {
    /* no Web Audio: plays as recorded */
  }
}
