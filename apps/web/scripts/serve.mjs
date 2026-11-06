// Minimal static server for the `out/` export (gzip, trailing-slash directories, 404.html).
import { createServer } from "node:http";
import { createReadStream, existsSync, statSync } from "node:fs";
import { extname, join, normalize, resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createGzip } from "node:zlib";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../out");
const port = Number(process.env.PORT ?? 4173);
const host = process.env.HOST ?? "127.0.0.1";
const types = {
  ".html": "text/html; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".webmanifest": "application/manifest+json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon",
  ".ttf": "font/ttf",
  ".woff2": "font/woff2",
};
const compressible = new Set([".html", ".txt", ".js", ".css", ".json", ".webmanifest", ".svg", ".ttf"]);

function send(req, res, file, status = 200) {
  const ext = extname(file);
  const headers = {
    "Content-Type": types[ext] ?? "application/octet-stream",
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": file.includes("/_next/static/")
      ? "public, max-age=31536000, immutable"
      : file.endsWith("sw.js")
        ? "no-cache"
        : "public, max-age=0, must-revalidate",
  };
  if (compressible.has(ext) && /\bgzip\b/.test(req.headers["accept-encoding"] ?? "")) {
    res.writeHead(status, { ...headers, "Content-Encoding": "gzip", Vary: "Accept-Encoding" });
    if (req.method === "HEAD") return res.end();
    createReadStream(file)
      .pipe(createGzip({ level: 6 }))
      .pipe(res);
  } else {
    res.writeHead(status, { ...headers, "Content-Length": statSync(file).size });
    if (req.method === "HEAD") return res.end();
    createReadStream(file).pipe(res);
  }
}

const server = createServer((req, res) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    res.writeHead(405).end();
    return;
  }
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(req.url ?? "/", "http://x").pathname);
  } catch {
    res.writeHead(400).end();
    return;
  }
  const file = normalize(join(root, pathname));
  if (!file.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  if (existsSync(file) && statSync(file).isDirectory()) {
    if (!pathname.endsWith("/")) {
      res.writeHead(308, {
        Location: pathname + "/" + (req.url?.includes("?") ? req.url.slice(req.url.indexOf("?")) : ""),
      });
      res.end();
      return;
    }
    const index = join(file, "index.html");
    if (existsSync(index)) return send(req, res, index);
  } else if (existsSync(file)) {
    return send(req, res, file);
  } else if (existsSync(file + ".html")) {
    return send(req, res, file + ".html");
  }
  send(req, res, join(root, "404.html"), 404);
});
server.listen(port, host, () => console.log(`serving ${root} on http://${host}:${port}`));
