import { computeZakat, sanitizeZakat, ZAKAT, zakatSource } from "@/lib/zakat";

const PRICE = 4000; // one gram of 21-karat gold
const NISAB = 85 * PRICE;

describe("zakat after Dar al-Ifta al-Misriyya", () => {
  it("uses the published rules: 85 g of 21-karat gold, 2.5%, a lunar year, pending review", () => {
    expect(ZAKAT.rules).toEqual({ nisabGoldGrams: 85, nisabKarat: 21, rate: 0.025, year: "lunar" });
    expect(ZAKAT.reviewStatus).toBe("pending");
    for (const f of ZAKAT.fields) for (const id of f.sources) expect(zakatSource(id)).toBeDefined();
    for (const s of ZAKAT.sources)
      expect(s.url).toMatch(/^https:\/\/www\.dar-alifta\.org\/ar\/fatwa\/details\/\d+$/);
  });

  it("asks for the gold price first", () => {
    expect(computeZakat({ cash: 1_000_000 }, 0, true)).toEqual({ status: "needPrice" });
  });

  it("is 2.5% of the wealth once it reaches the nisab and a year has passed", () => {
    expect(computeZakat({ cash: 400_000 }, PRICE, true)).toEqual({
      status: "due",
      net: 400_000,
      nisab: NISAB,
      zakat: 10_000,
    });
  });

  it("is not due below the nisab, or before the year has passed", () => {
    expect(computeZakat({ cash: NISAB - 1 }, PRICE, true).status).toBe("belowNisab");
    expect(computeZakat({ cash: NISAB }, PRICE, false).status).toBe("yearNotPassed");
  });

  it("subtracts debts, so a debt that brings the wealth under the nisab removes zakat", () => {
    expect(computeZakat({ cash: NISAB + 100, debts: 200 }, PRICE, true).status).toBe("belowNisab");
    const r = computeZakat({ cash: 500_000, debts: 100_000 }, PRICE, true);
    expect(r).toMatchObject({ status: "due", net: 400_000, zakat: 10_000 });
  });

  it("adds every kind of wealth, and prices gold of other karats by purity against 21 karat", () => {
    const r = computeZakat(
      { cash: 1, certificates: 2, certificateReturns: 3, shares: 4, trade: 5, gold21: 85 },
      PRICE,
      true,
    );
    expect(r).toMatchObject({ status: "due", net: NISAB + 15 });
    const g24 = computeZakat({ gold24: 21 }, 1, false);
    const g18 = computeZakat({ gold18: 21 }, 1, false);
    expect(g24).toMatchObject({ net: 24 });
    expect(g18).toMatchObject({ net: 18 });
  });

  it("ignores negative or invalid numbers", () => {
    expect(computeZakat({ cash: -5, trade: Number.NaN }, PRICE, true)).toMatchObject({ net: 0 });
  });

  it("sanitizes what was stored", () => {
    expect(sanitizeZakat({ price: 5, yearPassed: true, values: { cash: 3, junk: 9, trade: -1 } })).toEqual({
      price: 5,
      yearPassed: true,
      values: { cash: 3 },
    });
    expect(sanitizeZakat("x")).toEqual({ price: 0, yearPassed: false, values: {} });
  });
});
