/**
 * Optional URL prefix for hosting the static export under a sub-path
 * (e.g. GitHub Pages project sites: /islamic-super-app). Empty by default.
 * next/link and the router add it automatically; plain URLs (fetch, preload,
 * metadata, service worker) go through withBase().
 */
export const BASE_PATH: string = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

export function withBase(path: string): string {
  return BASE_PATH + path;
}
