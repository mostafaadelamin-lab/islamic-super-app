import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./tests/setup.ts"],
    // Mirrors next.config.ts `trailingSlash: true` for next/link outside a Next build.
    env: { __NEXT_TRAILING_SLASH: "true" },
    include: ["tests/unit/**/*.test.ts", "tests/components/**/*.test.tsx"],
    reporters: ["default", "junit", "json"],
    outputFile: {
      junit: "../../tests/evidence/web/vitest-junit.xml",
      json: "../../tests/evidence/web/vitest-results.json",
    },
    coverage: {
      provider: "v8",
      include: ["src/lib/**/*.ts"],
      exclude: ["src/lib/server/**"],
      reporter: ["text", "json-summary", "html"],
      reportsDirectory: "../../tests/evidence/web/coverage",
    },
  },
});
