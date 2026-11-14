import { fireEvent, render, screen } from "@testing-library/react";
import { ZakatCalculator } from "@/components/ZakatCalculator";
import { zakatStore } from "@/lib/zakat";

beforeEach(() => {
  localStorage.clear();
  zakatStore.reload();
});

describe("ZakatCalculator", () => {
  it("shows no review notice, the adornment fatwa and every source link", () => {
    render(<ZakatCalculator locale="ar" />);
    expect(screen.queryByTestId("zakat-review")).toBeNull();
    expect(screen.getByTestId("zakat-adornment").textContent).toContain(
      "لا زكاة على المرأة في الذهب الذي تملكه بقصد استعماله في التزيُّنِ به والتحلي",
    );
    expect(screen.getByTestId("zakat-result").dataset.status).toBe("needPrice");
    const links = [...document.querySelectorAll<HTMLAnchorElement>("a[href*='dar-alifta.org']")];
    expect(links.length).toBeGreaterThanOrEqual(8);
  });

  it("works out the zakat as the user types, with Arabic digits too, and keeps the numbers", () => {
    render(<ZakatCalculator locale="en" />);
    fireEvent.change(screen.getByTestId("zakat-price"), { target: { value: "4000" } });
    fireEvent.change(screen.getByTestId("zakat-cash"), { target: { value: "400000" } });
    expect(screen.getByTestId("zakat-result").dataset.status).toBe("yearNotPassed");
    fireEvent.click(screen.getByTestId("zakat-year"));
    expect(screen.getByTestId("zakat-amount").textContent).toBe("Zakat due: 10,000");
    fireEvent.change(screen.getByTestId("zakat-debts"), { target: { value: "390000" } });
    expect(screen.getByTestId("zakat-result").dataset.status).toBe("belowNisab");
    expect(zakatStore.get()).toMatchObject({
      price: 4000,
      yearPassed: true,
      values: { cash: 400000, debts: 390000 },
    });
  });
});
