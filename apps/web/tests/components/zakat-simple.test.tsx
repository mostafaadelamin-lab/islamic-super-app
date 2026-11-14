import { describe, expect, it, beforeEach } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ZakatSimple, parseAmount } from "@/components/ZakatSimple";
import {
  cropsZakat,
  goldZakat,
  livestockZakat,
  moneyZakat,
  silverZakat,
  simpleZakatStore,
} from "@/lib/zakat-simple";

describe("simple zakat rules (same as the app's zakat_simple.dart)", () => {
  it("gold: 85 g of 24 carat, 21 carat priced by purity, 2.5%", () => {
    expect(goldZakat(80, 24, 4000).reached).toBe(false);
    const r = goldZakat(100, 21, 4000);
    expect(r.reached).toBe(true);
    expect(r.dueGrams).toBe(2.5);
    expect(r.dueMoney).toBeCloseTo(((100 * 21) / 24) * 0.025 * 4000, 6);
    expect(goldZakat(90, 18, null).reached).toBe(false);
  });
  it("silver, money, crops", () => {
    expect(silverZakat(594, 50).reached).toBe(false);
    expect(silverZakat(600, 50).dueMoney).toBe(600 * 0.025 * 50);
    expect(moneyZakat(400000, 85 * 4000).due).toBe(10000);
    expect(moneyZakat(100, 85 * 4000).reached).toBe(false);
    expect(cropsZakat(1000, true).dueKg).toBe(100);
    expect(cropsZakat(1000, false).dueKg).toBe(50);
    expect(cropsZakat(600, true).reached).toBe(false);
  });
  it("livestock tables", () => {
    expect(livestockZakat("sheep", 39)).toEqual([]);
    expect(livestockZakat("sheep", 121)).toEqual([[2, "sheep"]]);
    expect(livestockZakat("camels", 10)).toEqual([[2, "sheep"]]);
    expect(livestockZakat("camels", 30)).toEqual([[1, "bintMakhad"]]);
    expect(livestockZakat("camels", 130)).toEqual([
      [2, "bintLabun"],
      [1, "hiqqa"],
    ]);
    expect(livestockZakat("cattle", 30)).toEqual([[1, "tabi"]]);
    expect(livestockZakat("cattle", 70)).toEqual([
      [1, "tabi"],
      [1, "musinna"],
    ]);
  });
  it("reads Arabic digits and decimal commas", () => {
    expect(parseAmount("١٢٫٥")).toBe(12.5);
    expect(parseAmount("12,5")).toBe(12.5);
    expect(parseAmount("")).toBeNull();
    expect(parseAmount("abc")).toBeNull();
  });
});

describe("ZakatSimple", () => {
  beforeEach(() => {
    localStorage.clear();
    simpleZakatStore.reload();
  });

  it("has the app's five tabs and no review notice", () => {
    render(<ZakatSimple locale="ar" />);
    for (const label of ["زكاة الفضة", "زكاة الذهب", "زكاة المال", "زكاة الأنعام", "زكاة المحاصيل"]) {
      expect(screen.getByRole("tab", { name: label })).toBeInTheDocument();
    }
    expect(screen.queryByText(/المراجعة الشرعية/)).toBeNull();
  });

  it("gold: shows grams and money due, and keeps the value", async () => {
    const { unmount } = render(<ZakatSimple locale="en" />);
    await userEvent.click(screen.getByTestId("zakat-tab-gold"));
    fireEvent.change(screen.getByTestId("zakat-in-gold"), { target: { value: "100" } });
    fireEvent.change(screen.getByTestId("zakat-in-goldPrice"), { target: { value: "4000" } });
    const res = screen.getByTestId("zakat-simple-result");
    expect(res.dataset.reached).toBe("true");
    expect(res.textContent).toContain("2.5");
    unmount();
    render(<ZakatSimple locale="en" />);
    expect((screen.getByTestId("zakat-in-gold") as HTMLInputElement).value).toBe("100");
  });

  it("money asks for the gold price, then compares with the nisab", async () => {
    render(<ZakatSimple locale="ar" />);
    await userEvent.click(screen.getByTestId("zakat-tab-money"));
    fireEvent.change(screen.getByTestId("zakat-in-money"), { target: { value: "400000" } });
    expect(screen.getByTestId("zakat-simple-result").textContent).toContain("سعر جرام الذهب");
    fireEvent.change(screen.getByTestId("zakat-in-goldPrice"), { target: { value: "4000" } });
    expect(screen.getByTestId("zakat-simple-result").textContent).toContain("١٠٠٠٠");
  });

  it("livestock: camels table", async () => {
    render(<ZakatSimple locale="ar" />);
    await userEvent.click(screen.getByTestId("zakat-tab-livestock"));
    await userEvent.click(screen.getByRole("button", { name: "إبل" }));
    fireEvent.change(screen.getByTestId("zakat-in-animals"), { target: { value: "30" } });
    expect(screen.getByTestId("zakat-simple-result").textContent).toContain("بنت مخاض");
  });

  it("crops: 5% when irrigated by machines", async () => {
    render(<ZakatSimple locale="ar" />);
    await userEvent.click(screen.getByTestId("zakat-tab-crops"));
    fireEvent.change(screen.getByTestId("zakat-in-crops"), { target: { value: "1000" } });
    expect(screen.getByTestId("zakat-simple-result").textContent).toContain("١٠٠");
    await userEvent.click(screen.getByRole("button", { name: /تُروى بالآلات/ }));
    expect(screen.getByTestId("zakat-simple-result").textContent).toContain("٥٠");
  });
});
