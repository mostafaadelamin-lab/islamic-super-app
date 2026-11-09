import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { TasbihView } from "@/components/TasbihView";
import { current, tasbihStore } from "@/lib/tasbih";
import { resetStores } from "./reset";

beforeEach(() => {
  resetStores();
  tasbihStore.reload();
});
afterEach(() => vi.restoreAllMocks());

describe("TasbihView", () => {
  it("counts per dhikr, switches to beads, colours, sound and vibration", async () => {
    const u = userEvent.setup();
    render(<TasbihView locale="en" />);
    await u.click(screen.getByTestId("tasbih-tap"));
    await u.click(screen.getByTestId("tasbih-tap"));
    expect(screen.getByTestId("tasbih-count")).toHaveTextContent("2");
    expect(screen.getByTestId("tasbih-today")).toHaveTextContent("Today for this dhikr: 2");
    await u.selectOptions(screen.getByLabelText("Dhikr"), "tahmid");
    expect(screen.getByTestId("tasbih-count")).toHaveTextContent("0");
    await u.click(screen.getByTestId("tasbih-mode-beads"));
    const tap = screen.getByTestId("tasbih-tap");
    expect(tap).toHaveAttribute("data-mode", "beads");
    expect(tap.querySelectorAll(".strand-bead")).toHaveLength(33);
    await u.click(tap);
    expect(tap.querySelectorAll(".strand-bead.done")).toHaveLength(1);
    await u.click(screen.getByTestId("tasbih-color-plum"));
    expect(screen.getByTestId("tasbih-color-plum")).toHaveAttribute("aria-pressed", "true");
    await u.click(screen.getByTestId("tasbih-sound"));
    await u.click(screen.getByTestId("tasbih-vibrate"));
    expect(tasbihStore.get()).toMatchObject({ mode: "beads", color: "plum", sound: true, vibrate: false });
    await u.selectOptions(screen.getByLabelText("Dhikr"), "tasbih");
    expect(screen.getByTestId("tasbih-count")).toHaveTextContent("2");
  });

  it("adds the user's own dhikr, keeps a history and clears it", async () => {
    vi.spyOn(window, "confirm").mockReturnValue(true);
    const u = userEvent.setup();
    render(<TasbihView locale="ar" />);
    expect(screen.getByText("لا يوجد تسبيح مسجل بعد.")).toBeInTheDocument();
    await u.type(screen.getByTestId("tasbih-new"), "اللهم صل على محمد");
    await u.click(screen.getByTestId("tasbih-add"));
    expect(screen.getByLabelText("الذكر")).toHaveValue("c1");
    expect(document.querySelector(".tasbih-phrase")).toHaveTextContent("اللهم صل على محمد");
    await u.click(screen.getByTestId("tasbih-tap"));
    const history = screen.getByTestId("tasbih-history");
    expect(within(history).getByText("اللهم صل على محمد")).toBeInTheDocument();
    expect(within(history).getByText("١")).toBeInTheDocument();
    await u.click(screen.getByTestId("tasbih-clear-history"));
    expect(screen.queryByTestId("tasbih-history")).toBeNull();
    expect(current(tasbihStore.get()).count).toBe(1);
    await u.click(screen.getByRole("button", { name: "حذف «اللهم صل على محمد»" }));
    expect(tasbihStore.get().custom).toEqual([]);
    expect(screen.getByLabelText("الذكر")).toHaveValue("tasbih");
  });
});
