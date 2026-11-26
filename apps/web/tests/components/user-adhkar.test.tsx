import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhkarView } from "@/components/AdhkarView";
import adhkar from "@/generated/adhkar.json";
import { sessionItems } from "@/lib/adhkar";
import { USER_DHIKR_BASE, sanitizeUserAdhkar, saveUserDhikr, userAdhkarStore } from "@/lib/custom-adhkar";
import { resetStores } from "./reset";

const ITEMS = (adhkar as { items: string[] }).items;

beforeEach(() => {
  resetStores();
  window.location.hash = "#morning";
});
afterEach(() => vi.unstubAllGlobals());

describe("«أذكاري»", () => {
  it("adds a dhikr with its count to the morning only, counts it, edits it and deletes it", async () => {
    render(<AdhkarView locale="ar" items={ITEMS} />);
    const save = screen.getByTestId("user-dhikr-save");
    expect(save).toBeDisabled();
    await userEvent.type(screen.getByTestId("user-dhikr-text"), "قراءة سورة الملك");
    await userEvent.click(screen.getByTestId("user-dhikr-quick-3"));
    await userEvent.click(screen.getByTestId("user-dhikr-plus"));
    expect(screen.getByTestId("user-dhikr-count")).toHaveTextContent("٤ مرة");
    await userEvent.click(save);

    expect(userAdhkarStore.get()).toEqual([
      { id: 1, text: "قراءة سورة الملك", count: 4, sessions: ["morning"] },
    ]);
    expect(localStorage.getItem("rattil.adhkar.custom")).toContain("قراءة سورة الملك");
    const mine = screen.getByTestId("dhikr-mine");
    expect(screen.getByTestId("mine-head")).toHaveTextContent("أذكاري");
    expect(screen.getAllByTestId("dhikr")).toHaveLength(sessionItems(ITEMS, "morning").length);
    // The form is empty again.
    expect(screen.getByTestId("user-dhikr-text")).toHaveValue("");

    await userEvent.click(within(mine).getByTestId("dhikr-count"));
    expect(within(mine).getByTestId("dhikr-count")).toHaveTextContent("١ / ٤");

    // Not in the evening.
    await userEvent.click(screen.getByTestId("session-evening"));
    expect(screen.queryByTestId("dhikr-mine")).toBeNull();
    await userEvent.click(screen.getByTestId("session-morning"));

    // Edit: show it in both sessions.
    await userEvent.click(screen.getByTestId("user-dhikr-edit-1"));
    expect(screen.getByTestId("user-dhikr-text")).toHaveValue("قراءة سورة الملك");
    await userEvent.click(screen.getByTestId("user-dhikr-where-both"));
    await userEvent.click(screen.getByTestId("user-dhikr-save"));
    expect(userAdhkarStore.get()[0]!.sessions).toEqual(["morning", "evening"]);
    // The count made today stays.
    expect(within(screen.getByTestId("dhikr-mine")).getByTestId("dhikr-count")).toHaveTextContent("١ / ٤");

    // Delete after asking.
    vi.stubGlobal("confirm", () => true);
    await userEvent.click(screen.getByTestId("user-dhikr-delete-1"));
    expect(userAdhkarStore.get()).toEqual([]);
    expect(screen.queryByTestId("dhikr-mine")).toBeNull();
  });

  it("the list keeps working with a broken saved value", () => {
    expect(sanitizeUserAdhkar("x")).toEqual([]);
    expect(
      sanitizeUserAdhkar([
        { id: 1, text: "  ذكر ", count: 5000, sessions: ["morning", "noon"] },
        { id: 1, text: "مكرر", count: 1, sessions: ["evening"] },
        { id: 2, text: "", count: 1, sessions: ["evening"] },
        { id: 3, text: "بلا وقت", count: 1, sessions: [] },
      ]),
    ).toEqual([{ id: 1, text: "ذكر", count: 1000, sessions: ["morning"] }]);
    expect(saveUserDhikr([], { text: "   ", count: 1, sessions: ["morning"] })).toEqual([]);
    expect(USER_DHIKR_BASE).toBeGreaterThan(ITEMS.length);
  });
});
