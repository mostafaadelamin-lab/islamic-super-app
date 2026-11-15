/**
 * The Rattil mark drawn inline, so it takes the chosen colour style (owner 2026-11-15): the tile is the
 * style's brand gradient and the mihrab, star and Mushaf are its gold. Same drawing as public/icon.svg
 * (the browser-tab and install icon, which stays one shared file).
 */
export function BrandLogo({ size, className }: { size: number; className?: string }) {
  return (
    <span
      className={className ? `brand-mark-logo ${className}` : "brand-mark-logo"}
      style={{ width: size, height: size }}
      aria-hidden="true"
      data-testid="brand-logo"
    >
      <svg viewBox="0 0 1024 1024" width={size} height={size} focusable="false">
        <circle cx="512" cy="512" r="430" fill="none" className="bl-ring" strokeWidth="6" />
        <g fill="none" strokeLinecap="round" strokeLinejoin="round">
          <path
            d="M300 812V500C300 392 392 318 512 236C632 318 724 392 724 500V812"
            className="bl-gold"
            strokeWidth="36"
          />
          <path
            d="M512 330L523.5 364.3L555.8 348.2L539.7 380.5L574 392L539.7 403.5L555.8 435.8L523.5 419.7L512 454L500.5 419.7L468.2 435.8L484.3 403.5L450 392L484.3 380.5L468.2 348.2L500.5 364.3Z"
            className="bl-gold-fill"
          />
          <path d="M400 660L628 812M624 660L396 812" className="bl-gold" strokeWidth="26" />
          <path
            d="M512 566C466 534 414 524 368 534V676C414 666 466 676 512 708C558 676 610 666 656 676V534C610 524 558 534 512 566Z"
            className="bl-book"
            strokeWidth="20"
          />
          <path d="M512 566V708" className="bl-spine" strokeWidth="14" />
        </g>
      </svg>
    </span>
  );
}
