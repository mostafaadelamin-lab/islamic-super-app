import { describe, expect, it } from "vitest";
import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdhkarView } from "@/components/AdhkarView";
import { adhkarLookStore, dhikrShown } from "@/lib/adhkar-look";
import { adhkarViewStore } from "@/lib/dhikr-share";

const ITEMS = ["أَعُوذُ بِاللَّهِ ﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ﴾", "رَضِيتُ بِاللَّهِ رَبًّا"];

describe("«إعدادات الأذكار» and listening in the page (owner 2026-11-27, same as the app)", () => {
  it("hiding tashkeel is display only; Quran verses keep theirs", () => {
    expect(dhikrShown(ITEMS[0]!, true)).toBe(ITEMS[0]);
    expect(dhikrShown(ITEMS[0]!, false)).toBe("أعوذ بالله ﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ﴾");
  });

  it("the settings change the background, tashkeel and text size, kept", async () => {
    adhkarViewStore.set(() => ({ mode: "list" }));
    render(<AdhkarView locale="ar" items={ITEMS} />);
    await userEvent.click(screen.getByTestId("adhkar-settings-open"));
    expect(screen.getByTestId("adhkar-settings")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("adhkar-bg-pick-azure"));
    expect(adhkarLookStore.get().bg).toBe("azure");
    expect(screen.getByTestId("adhkar-bg-azure")).toBeInTheDocument();
    await userEvent.click(screen.getByTestId("adhkar-settings-tashkeel"));
    expect(adhkarLookStore.get().tashkeel).toBe(false);
    expect(screen.getAllByText("رضيت بالله ربا").length).toBeGreaterThan(0);
    act(() => adhkarLookStore.set((l) => ({ ...l, scale: 1.5 })));
    expect(screen.getByTestId("adhkar-bg-azure").getAttribute("style")).toContain("--dhikr-scale: 1.5");
    await userEvent.click(screen.getByTestId("adhkar-settings-close"));
    expect(screen.queryByTestId("adhkar-settings")).toBeNull();
    act(() => adhkarLookStore.set(() => adhkarLookStore.defaultValue));
  });

  it("«استمع للأذكار كاملة» plays Alafasy's recording right in the page", async () => {
    render(<AdhkarView locale="ar" items={ITEMS} />);
    expect(screen.queryByTestId("alafasy-audio")).toBeNull();
    await userEvent.click(screen.getByTestId("alafasy-listen"));
    const audio = screen.getByTestId("alafasy-audio");
    expect(audio.getAttribute("src")).toMatch(/adhkar_(morning|evening)_alafasy\.mp3$/);
  });
});
