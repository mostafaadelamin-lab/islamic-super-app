import type { Locale } from "./i18n";

/** Swaps the leading /ar or /en segment of a path. */
export function switchLocalePath(pathname: string, to: Locale): string {
  const m = /^\/(ar|en)(\/.*)?$/.exec(pathname);
  const rest = m ? (m[2] ?? "/") : "/";
  return `/${to}${rest === "" ? "/" : rest}`;
}

export function href(locale: Locale, path = ""): string {
  const p = path.replace(/^\/+|\/+$/g, "");
  return p ? `/${locale}/${p}/` : `/${locale}/`;
}
