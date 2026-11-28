/**
 * Styles of the videos page (owner 2026-11-28, layout option 2), rendered with the page instead of globals.css:
 * a change here then only touches the videos page files, not every page of the site (owner rule: upload
 * changed files only).
 */
export const VIDEOS_PAGE_CSS = `
/* Videos page (owner 2026-11-28, layout option 2): circles for the live streams and the reciters, tall tiles. */
.videos-stories {
  display: flex;
  gap: var(--space-xs);
  overflow-x: auto;
  padding: var(--space-xs) 0;
  scrollbar-width: thin;
}
.videos-circle {
  flex: 0 0 78px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  border: 0;
  background: none;
  padding: 0;
  font: inherit;
  font-size: var(--font-size-xs);
  line-height: 1.25;
  color: var(--color-ink);
  cursor: pointer;
  text-align: center;
}
.videos-circle i {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 64px;
  height: 64px;
  border-radius: 50%;
  overflow: hidden;
  outline: 2.5px solid var(--brand-gold);
  outline-offset: 2px;
  margin: 4px;
  background: linear-gradient(135deg, var(--brand-gold-soft), var(--brand-gold));
  color: var(--brand-hero-deep);
  font-style: normal;
  font-weight: 700;
  font-size: var(--font-size-lg);
}
.videos-circle i img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.videos-circle span {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.videos-circle.is-live i {
  outline-color: #e53935;
  color: #fff;
  font-size: var(--font-size-sm);
  background: linear-gradient(135deg, #2e4a3c, #122019);
}
.videos-circle.live-madinah i {
  background: linear-gradient(135deg, #2b3550, #10141f);
}
.videos-circle .live-dot-label {
  color: #d32f2f;
  font-weight: 700;
}
.videos-circle .live-dot-label::before {
  content: "";
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: currentColor;
  margin-inline-end: 4px;
  vertical-align: middle;
}
.videos-tiles {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 3px;
}
@media (min-width: 900px) {
  .videos-tiles {
    grid-template-columns: repeat(5, minmax(0, 1fr));
  }
}
.videos-tile {
  position: relative;
  aspect-ratio: 9 / 16;
  overflow: hidden;
  border: 0;
  padding: 0;
  cursor: pointer;
  font: inherit;
  background: linear-gradient(160deg, var(--brand-hero-top), var(--brand-hero-deep));
}
.videos-tile img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.videos-tile svg {
  position: absolute;
  top: 6px;
  inset-inline-end: 6px;
  width: 20px;
  height: 20px;
  color: #fff;
  filter: drop-shadow(0 1px 2px rgb(0 0 0 / 60%));
}
.videos-tile span {
  position: absolute;
  inset-inline: 0;
  bottom: 0;
  padding: 18px 6px 6px;
  background: linear-gradient(transparent, rgb(0 0 0 / 80%));
  color: #fff;
  font-size: var(--font-size-xs);
  font-weight: 600;
  text-align: start;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
`;
