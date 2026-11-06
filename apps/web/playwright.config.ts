import { defineConfig, devices } from "@playwright/test";

const EVIDENCE = "../../tests/evidence/web";
const PORT = 4173;
const API_PYTHON = process.env.API_PYTHON; // python with services/api requirements installed
const BROWSERS = (process.env.E2E_BROWSERS ?? "chromium").split(",");

const deviceFor: Record<string, (typeof devices)[string]> = {
  chromium: devices["Desktop Chrome"],
  firefox: devices["Desktop Firefox"],
  webkit: devices["Desktop Safari"],
};

export default defineConfig({
  testDir: "./tests/e2e",
  outputDir: "./test-results",
  fullyParallel: true,
  workers: 4,
  retries: 0,
  timeout: 60_000,
  reporter: [
    ["list"],
    ["junit", { outputFile: `${EVIDENCE}/playwright-junit.xml` }],
    ["json", { outputFile: `${EVIDENCE}/playwright-results.json` }],
  ],
  use: {
    baseURL: `http://127.0.0.1:${PORT}`,
    trace: "retain-on-failure",
    // Service workers are exercised in offline.spec.ts; elsewhere they would precache ~26 MB per test.
    serviceWorkers: "block",
    launchOptions: process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {},
  },
  projects: BROWSERS.map((name) => ({ name, use: { ...deviceFor[name] } })),
  webServer: [
    {
      command: "node scripts/serve.mjs",
      url: `http://127.0.0.1:${PORT}/ar/`,
      reuseExistingServer: true,
      env: { PORT: String(PORT) },
    },
    ...(API_PYTHON
      ? [
          {
            command: `${API_PYTHON} -m uvicorn app.main:app --host 127.0.0.1 --port 8000`,
            cwd: "../../services/api",
            url: "http://127.0.0.1:8000/health",
            reuseExistingServer: true,
            env: {
              ISA_DATABASE_URL: `sqlite:///${process.env.API_DB ?? "/tmp/rattil-e2e.db"}`,
              ISA_AUTH_RATE: "1000",
              ISA_GENERAL_RATE: "10000",
            },
          },
        ]
      : []),
  ],
});
