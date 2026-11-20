/**
 * The Rattil mark drawn inline, so it takes the chosen colour style: the tile is the style's brand gradient
 * and the mihrab, crescent and Mushaf are its gold. Logo «crescent in the mihrab» (owner pick 2026-11-17).
 * Same drawing as public/icon.svg (the browser-tab and install icon, which stays one shared file).
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
        <g fill="none" strokeLinecap="round" strokeLinejoin="round">
          <path
            d="M282 800V512C282 398 384 314 512 226C640 314 742 398 742 512V800"
            className="bl-gold"
            strokeWidth="44"
          />
          <path d="M531.1 328.2A84 84 0 1 0 588.9 443.8A66 66 0 0 1 531.1 328.2Z" className="bl-gold-fill" />
          <path
            d="M584.0 330.0L580.2 342.8L568.4 336.4L574.8 348.2L562.0 352.0L574.8 355.8L568.4 367.6L580.2 361.2L584.0 374.0L587.8 361.2L599.6 367.6L593.2 355.8L606.0 352.0L593.2 348.2L599.6 336.4L587.8 342.8Z"
            className="bl-star"
          />
          <path
            d="M512 640C458 602 392 592 330 604V770C392 758 458 768 512 806C566 768 632 758 694 770V604C632 592 566 602 512 640Z"
            className="bl-book"
            strokeWidth="22"
          />
          <path d="M512 640V806" className="bl-spine" strokeWidth="14" />
          <path
            d="M372 652C412 646 452 652 488 670M372 700C412 694 452 700 488 718M536 670C572 652 612 646 652 652M536 718C572 700 612 694 652 700"
            className="bl-lines"
            strokeWidth="10"
          />
        </g>
      </svg>
    </span>
  );
}
