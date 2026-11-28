import { createHash } from "node:crypto";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import type { NextConfig } from "next";

const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

/**
 * Build id from the code itself (owner 2026-11-21: website uploads send only changed files). Next's default
 * id is random, so every build rewrote all ~4,300 pages; with this id an unchanged page stays byte-identical
 * and the upload skips it. Files under public/ (pictures, audio, data) do not change the id.
 */
function codeBuildId(): string {
  const h = createHash("sha256");
  const add = (p: string): void => {
    const st = statSync(p);
    if (st.isDirectory()) {
      for (const n of readdirSync(p).sort()) add(join(p, n));
    } else {
      h.update(p);
      h.update(readFileSync(p));
    }
  };
  for (const p of ["src", "package-lock.json", "next.config.ts", "tsconfig.json"]) add(p);
  for (const k of Object.keys(process.env)
    .filter((x) => x.startsWith("NEXT_PUBLIC_"))
    .sort()) {
    h.update(`${k}=${process.env[k]}`);
  }
  return h.digest("hex").slice(0, 20);
}

/**
 * RATTIL_PIN_BUILD_ID = the live site's build id (the `<!--id-->` comment at the top of any page). Owner
 * 2026-11-28: a small code change still re-sent all ~4,350 pages, because every page carries the build id.
 * With the live id pinned, a page is re-sent only when its own HTML/chunks changed; pages that use a changed
 * chunk get a new chunk name, so they still differ and go up. Old chunks are never deleted from the server.
 */
function pinnedBuildId(): string | null {
  const id = process.env.RATTIL_PIN_BUILD_ID?.trim();
  return id && /^[0-9a-f]{20}$/.test(id) ? id : null;
}

const config: NextConfig = {
  output: "export",
  ...(basePath ? { basePath } : {}),
  trailingSlash: true,
  images: { unoptimized: true },
  reactStrictMode: true,
  poweredByHeader: false,
  generateBuildId: async () => pinnedBuildId() ?? codeBuildId(),
};

export default config;
