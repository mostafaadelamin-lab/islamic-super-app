/** Decorative line drawing of a mosque (dome, two minarets with crescents) for the home hero. */
export function MosqueArt() {
  return (
    <svg
      className="mosque-art"
      viewBox="0 0 160 130"
      fill="none"
      stroke="currentColor"
      strokeWidth="3.2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {/* tall minaret (left) */}
      <path d="M22 128V52l8-10 8 10v76" />
      <path d="M20 66h20M20 92h20" />
      <path d="M26 66l4 6 4-6M26 92l4 6 4-6" />
      <path d="M30 42V30" />
      <path d="M34 22a6 6 0 1 1-4-9 4.6 4.6 0 0 0 4 9Z" fill="currentColor" stroke="none" />
      {/* main dome on its drum */}
      <path d="M58 128V88h70v40" />
      <path d="M62 88c0-18 14-26 31-34 17 8 31 16 31 34" />
      <path d="M93 54V44" />
      <path d="M97 36a6 6 0 1 1-4-9 4.6 4.6 0 0 0 4 9Z" fill="currentColor" stroke="none" />
      {/* arched door and windows */}
      <path d="M84 128v-16a9 9 0 0 1 18 0v16" />
      <path d="M68 108v-6a4 4 0 0 1 8 0v6zM110 108v-6a4 4 0 0 1 8 0v6z" />
      {/* small minaret (right) */}
      <path d="M138 128V78l6-8 6 8v50" />
      <path d="M136 92h16" />
      <path d="M144 70v-8" />
      <path d="M147.5 56a5 5 0 1 1-3.5-7.5 3.8 3.8 0 0 0 3.5 7.5Z" fill="currentColor" stroke="none" />
      <path d="M6 128h150" />
    </svg>
  );
}
