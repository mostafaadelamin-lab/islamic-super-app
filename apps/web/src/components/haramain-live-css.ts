/**
 * Home radio card: the two Haramain live-video buttons and the inline player (owner 2026-11-28,
 * mockup «اقتراح ٢»). Styles and strings live with the component so an update does not rewrite the
 * shared stylesheet and string chunk of every page.
 */
export const HARAMAIN_LIVE_CSS = `
.radio-haramain{grid-column:1/-1;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:var(--space-sm)}
.radio-haramain-btn{display:flex;align-items:center;gap:10px;min-height:var(--min-touch);padding:8px 12px;border:1.5px solid var(--color-line);border-radius:var(--radius-md);background:var(--color-surface);color:var(--color-ink);font:inherit;text-align:start;cursor:pointer}
.radio-haramain-btn[aria-pressed="true"]{border-color:var(--color-accent);background:var(--color-verse-highlight)}
.radio-haramain-ic{flex:none;display:inline-flex;align-items:center;justify-content:center;width:36px;height:36px;border-radius:10px;background:var(--color-primary);color:var(--color-on-primary)}
.radio-haramain-txt{flex:1;min-width:0;display:flex;flex-direction:column;line-height:1.3}
.radio-haramain-txt strong{font-size:var(--font-size-sm)}
.radio-haramain-txt small{color:var(--color-muted,inherit);opacity:.8;font-size:var(--font-size-xs)}
.radio-haramain-live{flex:none;display:inline-flex;align-items:center;gap:4px;background:#c62828;color:#fff;border-radius:6px;padding:2px 8px;font-size:var(--font-size-xs);font-weight:600;white-space:nowrap}
.radio-video{grid-column:1/-1;position:relative;width:100%;max-width:640px;margin-inline:auto;aspect-ratio:16/9;border-radius:var(--radius-md);overflow:hidden;background:#000}
.radio-video iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
.radio-video-bar{position:absolute;top:8px;inset-inline-end:8px;display:flex;gap:6px;z-index:1}
.radio-video-bar button{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;border:0;border-radius:50%;background:rgba(0,0,0,.6);color:#fff;font-size:16px;cursor:pointer}
.radio-station-field{position:relative}
.radio-station-face{flex:1;min-width:0;display:flex;align-items:center;gap:6px;padding-block:4px;color:var(--color-ink);font-weight:600;font-size:var(--font-size-sm);line-height:1.35}
.radio-station-name{flex:1;min-width:0;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.radio-audio-tag{flex:none;display:inline-flex;align-items:center;gap:3px;padding:1px 8px;border-radius:999px;border:1px solid var(--color-line);background:var(--color-verse-highlight);color:var(--color-primary);font-size:var(--font-size-xs);font-weight:600}
.radio-station-face>.icon:last-child{flex:none;color:var(--color-ink)}
.radio-station-field select{position:absolute;inset:0;width:100%;height:100%;opacity:0;cursor:pointer}
.radio-station-field:focus-within{outline:2px solid var(--color-primary);outline-offset:2px}
@media (max-width:560px){.radio-haramain{grid-template-columns:1fr 1fr}.radio-haramain-btn{flex-wrap:wrap;gap:6px;padding:8px}.radio-haramain-ic{width:30px;height:30px}.radio-haramain-live{font-size:11px;padding:1px 6px}}
`;

export const HARAMAIN_LIVE_STRINGS = {
  ar: {
    audio: "صوتي",
    liveVideo: "مباشر الآن فيديو",
    makkah: "المسجد الحرام",
    makkahSub: "مكة المكرمة",
    madinah: "المسجد النبوي",
    madinahSub: "المدينة المنورة",
    close: "إغلاق الفيديو",
    full: "ملء الشاشة",
  },
  en: {
    audio: "Audio",
    liveVideo: "Live now · video",
    makkah: "Masjid al-Haram",
    makkahSub: "Makkah",
    madinah: "The Prophet's Mosque",
    madinahSub: "Madinah",
    close: "Close video",
    full: "Full screen",
  },
} as const;
