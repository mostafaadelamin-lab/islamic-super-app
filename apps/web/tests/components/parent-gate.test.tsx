import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ParentGate } from "@/components/ParentGate";
import {
  PARENT_AGE_KEY,
  PARENT_PIN_KEY,
  hashPin,
  isValidPin,
  parentChallenge,
  pinMatches,
  setParentLockOpen,
} from "@/lib/parent-lock";

beforeEach(() => {
  localStorage.clear();
  setParentLockOpen(false);
});
afterEach(() => vi.restoreAllMocks());

const Secret = () => <p>videos here</p>;
const gate = () =>
  render(
    <ParentGate locale="en">
      <Secret />
    </ParentGate>,
  );

describe("parent lock (Families policy, owner 2026-11-20)", () => {
  it("PIN rules, hash and challenge", async () => {
    expect(isValidPin("1234")).toBe(true);
    expect(isValidPin("123")).toBe(false);
    expect(isValidPin("12a4")).toBe(false);
    const h = await hashPin("1234");
    expect(h).toHaveLength(64);
    expect(h).not.toContain("1234");
    expect(await pinMatches("1234", h)).toBe(true);
    expect(await pinMatches("4321", h)).toBe(false);
    expect(await pinMatches("1234", null)).toBe(false);
    expect(parentChallenge(() => 0.99)).toEqual([9, 19]);
  });

  it("age group: two equal buttons; 13 or older opens with no PIN and is not asked again", async () => {
    const user = userEvent.setup();
    const { unmount } = gate();
    expect(await screen.findByTestId("parent-gate-age")).toBeInTheDocument();
    expect(screen.getByText("Choose your age group")).toBeInTheDocument();
    expect(screen.getAllByRole("button").map((b) => b.textContent)).toEqual(["Under 13", "13 or older"]);
    expect(screen.queryByText(/PIN/)).toBeNull();
    await user.click(screen.getByRole("button", { name: "13 or older" }));
    expect(await screen.findByText("videos here")).toBeInTheDocument();
    expect(localStorage.getItem(PARENT_AGE_KEY)).toBe("adult");
    unmount();
    gate();
    expect(await screen.findByText("videos here")).toBeInTheDocument();
  });

  it("under 13: only kids videos; the parent sets a PIN to open all videos, later the PIN opens them", async () => {
    const user = userEvent.setup();
    const { unmount } = gate();
    await user.click(await screen.findByRole("button", { name: "Under 13" }));
    expect(localStorage.getItem(PARENT_AGE_KEY)).toBe("child");
    expect(screen.getByTestId("parent-gate-kids")).toBeInTheDocument();
    expect(screen.getByTestId("parent-gate-kids-prophets")).toHaveAttribute("href", "/en/kids/#prophets");
    expect(screen.queryByText("videos here")).toBeNull();
    await user.click(screen.getByRole("button", { name: /Parent: open all videos/ }));
    expect(screen.getByText("Please hand the phone to a parent to choose the PIN.")).toBeInTheDocument();
    await user.type(screen.getByLabelText("Parent: choose a 4-digit PIN"), "2468");
    await user.click(screen.getByRole("button", { name: "Next" }));
    await user.type(screen.getByLabelText("Type the PIN again to confirm"), "1111");
    await user.click(screen.getByRole("button", { name: "Save PIN" }));
    expect(screen.getByRole("alert")).toHaveTextContent("The two PINs don't match");
    await user.type(screen.getByLabelText("Parent: choose a 4-digit PIN"), "2468");
    await user.click(screen.getByRole("button", { name: "Next" }));
    await user.type(screen.getByLabelText("Type the PIN again to confirm"), "2468");
    await user.click(screen.getByRole("button", { name: "Save PIN" }));
    expect(await screen.findByText("videos here")).toBeInTheDocument();
    expect(localStorage.getItem(PARENT_PIN_KEY)).toBe(await hashPin("2468"));
    unmount();

    setParentLockOpen(false);
    gate();
    expect(await screen.findByTestId("parent-gate-kids")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: /Parent: open all videos/ }));
    await user.type(screen.getByLabelText("Type the PIN to open videos"), "0000");
    await user.click(screen.getByRole("button", { name: "Open" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Wrong PIN");
    await user.click(screen.getByRole("button", { name: "Back to children's videos" }));
    expect(screen.getByTestId("parent-gate-kids")).toBeInTheDocument();
    await user.click(screen.getByRole("button", { name: /Parent: open all videos/ }));
    await user.type(screen.getByLabelText("Type the PIN to open videos"), "2468");
    await user.click(screen.getByRole("button", { name: "Open" }));
    expect(await screen.findByText("videos here")).toBeInTheDocument();
  });

  it("forgot the PIN: the multiplication answer leads to a new PIN", async () => {
    localStorage.setItem(PARENT_AGE_KEY, "child");
    localStorage.setItem(PARENT_PIN_KEY, await hashPin("1357"));
    vi.spyOn(Math, "random").mockReturnValue(0);
    const user = userEvent.setup();
    gate();
    await user.click(await screen.findByRole("button", { name: /Parent: open all videos/ }));
    await user.click(screen.getByRole("button", { name: "Forgot the PIN?" }));
    await user.type(screen.getByLabelText("Question for adults: what is 6 × 12?"), "70");
    await user.click(screen.getByRole("button", { name: "Choose a new PIN" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Wrong answer");
    await user.type(screen.getByLabelText("Question for adults: what is 6 × 12?"), "72");
    await user.click(screen.getByRole("button", { name: "Choose a new PIN" }));
    expect(screen.getByLabelText("Parent: choose a 4-digit PIN")).toBeInTheDocument();
  });
});
