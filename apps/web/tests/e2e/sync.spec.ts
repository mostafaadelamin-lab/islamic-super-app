import { expect, test, type Page } from "@playwright/test";

const API = "http://127.0.0.1:8000";

async function apiUp(): Promise<boolean> {
  try {
    const r = await fetch(`${API}/health`);
    return r.ok;
  } catch {
    return false;
  }
}

async function signIn(page: Page, email: string, register: boolean): Promise<void> {
  await page.goto("/en/settings/");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel(/^Password/).fill("correct-horse-battery");
  await page.getByRole("button", { name: register ? "Create account" : "Sign in" }).click();
  await expect(page.getByTestId("signed-in")).toContainText(email);
}

test("bookmark sync against the real FastAPI backend (LWW + tombstones across two devices)", async ({
  browser,
}) => {
  test.skip(!(await apiUp()), "FastAPI not running on :8000 (set API_PYTHON to let Playwright start it)");
  const email = `e2e-${Date.now()}@example.org`;

  // Device A: bookmark two ayahs, register, sync.
  const a = await browser.newContext();
  const pa = await a.newPage();
  await pa.goto("/en/surah/2/");
  await pa.getByTestId("bookmark-255").click();
  await pa.getByTestId("bookmark-286").click();
  await signIn(pa, email, true);
  await pa.getByRole("button", { name: "Sync now" }).click();
  await expect(pa.getByTestId("account-status")).toContainText("Sync complete: 0 received, 2 sent.");

  // Device B: sign in, sync, sees both; delete one (tombstone) and sync.
  const b = await browser.newContext();
  const pb = await b.newPage();
  await signIn(pb, email, false);
  await pb.getByRole("button", { name: "Sync now" }).click();
  await expect(pb.getByTestId("account-status")).toContainText("Sync complete: 2 received");
  await pb.goto("/en/bookmarks/");
  await expect(pb.getByTestId("bookmark-list").locator("li")).toHaveCount(2);
  await pb.getByRole("button", { name: "Remove — Al-Baqarah, ayah 286" }).click();
  await pb.goto("/en/settings/");
  await pb.getByRole("button", { name: "Sync now" }).click();
  await expect(pb.getByTestId("account-status")).toContainText("1 sent");

  // Device A syncs again: tombstone arrives and removes the bookmark.
  await pa.getByRole("button", { name: "Sync now" }).click();
  await expect(pa.getByTestId("account-status")).toContainText("Sync complete");
  await pa.goto("/en/bookmarks/");
  await expect(pa.getByTestId("bookmark-list").locator("li")).toHaveCount(1);
  await expect(pa.getByRole("link", { name: "Al-Baqarah, ayah 255" })).toBeVisible();

  // Server state confirms LWW result incl. tombstone.
  const token = await pa.evaluate(() => JSON.parse(localStorage.getItem("rattil.account")!).token as string);
  const res = await fetch(`${API}/v1/bookmarks?since=0`, { headers: { Authorization: `Bearer ${token}` } });
  const body = (await res.json()) as { items: { id: string; deleted: boolean }[] };
  const byId = Object.fromEntries(body.items.map((i) => [i.id, i.deleted]));
  expect(byId).toEqual({ "s2-a255": false, "s2-a286": true });

  // Wrong password is reported.
  const c = await browser.newContext();
  const pc = await c.newPage();
  await pc.goto("/en/settings/");
  await pc.getByLabel("Email").fill(email);
  await pc.getByLabel(/^Password/).fill("wrong-password-123");
  await pc.getByRole("button", { name: "Sign in" }).click();
  await expect(pc.getByTestId("account-status").getByRole("alert")).toContainText("401");
  await Promise.all([a.close(), b.close(), c.close()]);
});
