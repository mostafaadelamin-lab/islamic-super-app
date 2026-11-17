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

  it("shows the five kinds on one page, in the app's order, then the total; no review notice", () => {
    render(<ZakatSimple locale="ar" />);
    const heads = screen.getAllByRole("heading", { level: 2 }).map((h) => h.textContent);
    expect(heads).toEqual([
      "زكاة المال",
      "زكاة الذهب",
      "زكاة الفضة",
      "زكاة الأنعام",
      "زكاة المحاصيل",
      "إجمالي الزكاة المطلوبة",
    ]);
    expect(screen.queryByRole("tab")).toBeNull();
    expect(screen.getByTestId("zakat-total-empty")).toBeInTheDocument();
    expect(screen.queryByText(/المراجعة الشرعية/)).toBeNull();
  });

  it("gold: shows grams and money due beside the name, and keeps the value", () => {
    const { unmount } = render(<ZakatSimple locale="en" />);
    fireEvent.change(screen.getByTestId("zakat-in-gold"), { target: { value: "100" } });
    fireEvent.change(screen.getByTestId("zakat-in-goldPrice"), { target: { value: "4000" } });
    const badge = screen.getByTestId("zakat-due-gold");
    expect(badge.dataset.reached).toBe("true");
    expect(badge.textContent).toBe("8750 EGP");
    expect(screen.getByTestId("zakat-result-gold").textContent).toContain("2.5");
    unmount();
    render(<ZakatSimple locale="en" />);
    expect((screen.getByTestId("zakat-in-gold") as HTMLInputElement).value).toBe("100");
  });

  it("money asks for the gold price (typed in the gold card), then compares with the nisab", () => {
    render(<ZakatSimple locale="ar" />);
    fireEvent.change(screen.getByTestId("zakat-in-money"), { target: { value: "400000" } });
    expect(screen.getByTestId("zakat-need-price").textContent).toContain("سعر جرام الذهب");
    expect(screen.getByTestId("zakat-due-money").textContent).toBe("—");
    fireEvent.change(screen.getByTestId("zakat-in-goldPrice"), { target: { value: "4000" } });
    expect(screen.getByTestId("zakat-due-money").textContent).toBe("١٠٠٠٠ جنيه");
  });

  it("livestock: camels table", async () => {
    render(<ZakatSimple locale="ar" />);
    await userEvent.click(screen.getByRole("button", { name: "إبل" }));
    fireEvent.change(screen.getByTestId("zakat-in-animals"), { target: { value: "30" } });
    expect(screen.getByTestId("zakat-due-livestock").textContent).toContain("بنت مخاض");
  });

  it("crops: 5% when irrigated by machines", async () => {
    render(<ZakatSimple locale="ar" />);
    fireEvent.change(screen.getByTestId("zakat-in-crops"), { target: { value: "1000" } });
    expect(screen.getByTestId("zakat-due-crops").textContent).toBe("١٠٠ كيلو");
    await userEvent.click(screen.getByRole("button", { name: /تُروى بالآلات/ }));
    expect(screen.getByTestId("zakat-due-crops").textContent).toBe("٥٠ كيلو");
  });

  it("the total adds the money of every kind and lists the dues not paid in money (as the app)", async () => {
    render(<ZakatSimple locale="ar" />);
    fireEvent.change(screen.getByTestId("zakat-in-money"), { target: { value: "400000" } });
    fireEvent.change(screen.getByTestId("zakat-in-goldPrice"), { target: { value: "4000" } });
    fireEvent.change(screen.getByTestId("zakat-in-gold"), { target: { value: "100" } });
    fireEvent.change(screen.getByTestId("zakat-in-crops"), { target: { value: "1000" } });
    // 10000 (money) + 8750 (100 g of 21 carat at 4000) = 18750; crops have no price, listed apart.
    expect(screen.getByTestId("zakat-total").dataset.reached).toBe("true");
    expect(screen.getByTestId("zakat-total-amount").textContent).toBe("١٨٧٥٠ جنيه");
    expect(screen.getByTestId("zakat-total-other").textContent).toBe("وأيضًا: ١٠٠ كيلو (زكاة المحاصيل)");
  });

  it("the total says no zakat when nothing reaches the nisab", () => {
    render(<ZakatSimple locale="ar" />);
    fireEvent.change(screen.getByTestId("zakat-in-silver"), { target: { value: "100" } });
    expect(screen.getByTestId("zakat-total").textContent).toContain("لا زكاة عليك فيما كتبته");
  });
});
