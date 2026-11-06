import { readFileSync } from "node:fs";
import { join, resolve } from "node:path";

export const REPO = resolve(__dirname, "../../..");
export function readRepoJson<T>(rel: string): T {
  return JSON.parse(readFileSync(join(REPO, rel), "utf8")) as T;
}
