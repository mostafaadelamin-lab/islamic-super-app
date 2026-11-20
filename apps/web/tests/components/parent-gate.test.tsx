import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ParentGate } from "@/components/ParentGate";
import {
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

const Secret = () => <p>videos here</p>;

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
    const [a, b] = parentChallenge(() => 0.99);
    expect(a).toBe(9);
    expect(b).toBe(19);
  });

  it("first time: the parent sets a PIN, then the videos open; later the PIN opens them", async () => {
    const { unmount } = render(
      <ParentGate locale="en">
        <Secret />
      </ParentGate>,
    );
    expect(await screen.findByTestId("parent-gate")).toBeInTheDocument();
    expect(screen.queryByText("videos here")).toBeNull();
    const user = userEvent.setup();
    const pin = screen.getByLabelText("Parent: choose a 4-digit PIN");
    await user.type(pin, "2468");
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
    render(
      <ParentGate locale="en">
        <Secret />
      </ParentGate>,
    );
    await user.type(await screen.findByLabelText("Type the PIN to open videos"), "0000");
    await user.click(screen.getByRole("button", { name: "Open" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Wrong PIN");
    await user.type(screen.getByLabelText("Type the PIN to open videos"), "2468");
    await user.click(screen.getByRole("button", { name: "Open" }));
    expect(await screen.findByText("videos here")).toBeInTheDocument();
  });

  it("forgot the PIN: the multiplication answer leads to a new PIN", async () => {
    localStorage.setItem(PARENT_PIN_KEY, await hashPin("1357"));
    vi.spyOn(Math, "random").mockReturnValue(0);
    render(
      <ParentGate locale="en">
        <Secret />
      </ParentGate>,
    );
    const user = userEvent.setup();
    await user.click(await screen.findByRole("button", { name: "Forgot the PIN?" }));
    const q = screen.getByLabelText("Question for adults: what is 6 × 12?");
    await user.type(q, "70");
    await user.click(screen.getByRole("button", { name: "Choose a new PIN" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Wrong answer");
    await user.type(screen.getByLabelText("Question for adults: what is 6 × 12?"), "72");
    await user.click(screen.getByRole("button", { name: "Choose a new PIN" }));
    expect(screen.getByLabelText("Parent: choose a 4-digit PIN")).toBeInTheDocument();
    vi.restoreAllMocks();
  });
});
