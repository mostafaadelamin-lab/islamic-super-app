import { fireEvent, render, screen } from "@testing-library/react";
import { StepPager, stepFromHash } from "@/components/StepPager";
import { HajjTypeFlow, typeFromHash } from "@/components/HajjTypeFlow";

const flows = {
  tamattu: [
    { title: "الأولى", text: "نص ١" },
    { title: "الثانية", text: "نص ٢" },
  ],
  qiran: [{ title: "قران", text: "نص ق" }],
  ifrad: [{ title: "إفراد", text: "نص إ" }],
};

describe("one step at a time (owner 2026-11-15)", () => {
  it("shows only the chosen step, with next / previous", () => {
    render(
      <StepPager locale="ar" titles={["أ", "ب", "ج"]} idPrefix="umrah-step" label="خطوات">
        <p>خطوة ١</p>
        <p>خطوة ٢</p>
        <p>خطوة ٣</p>
      </StepPager>,
    );
    expect(screen.getByText("خطوة ١")).toBeVisible();
    expect(screen.getByText("خطوة ٢")).not.toBeVisible();
    expect(screen.getByTestId("step-count-umrah-step")).toHaveTextContent("الخطوة ١ من ٣");
    expect(screen.getByTestId("step-prev-umrah-step")).toBeDisabled();
    fireEvent.click(screen.getByTestId("step-next-umrah-step"));
    expect(screen.getByText("خطوة ١")).not.toBeVisible();
    expect(screen.getByText("خطوة ٢")).toBeVisible();
    fireEvent.click(screen.getByTestId("steps-flow-umrah-step-3"));
    expect(screen.getByText("خطوة ٣")).toBeVisible();
    expect(screen.getByTestId("step-next-umrah-step")).toBeDisabled();
    expect(screen.getByTestId("steps-flow-umrah-step-3")).toHaveAttribute("aria-current", "step");
  });

  it("reads #umrah-step-N and #hajj-<type> links", () => {
    expect(stepFromHash("#umrah-step-2", "umrah-step", 4)).toBe(1);
    expect(stepFromHash("#umrah-step-9", "umrah-step", 4)).toBeNull();
    expect(stepFromHash("#umrah", "umrah-step", 4)).toBeNull();
    expect(typeFromHash("#hajj-ifrad")).toBe("ifrad");
    expect(typeFromHash("#hajj-stage-2")).toBeNull();
  });

  it("Hajj types: a step shows the guide's words alone; next goes on", () => {
    render(<HajjTypeFlow locale="ar" flows={flows} source="دليل" />);
    expect(screen.getByTestId("hajj-step-text")).toHaveTextContent("نص ١");
    fireEvent.click(screen.getByTestId("step-next-hajj-tamattu"));
    expect(screen.getByTestId("hajj-step-text")).toHaveTextContent("نص ٢");
    fireEvent.click(screen.getByTestId("hajj-type-qiran"));
    expect(screen.getByTestId("hajj-step-text")).toHaveTextContent("نص ق");
    expect(screen.queryByText("نص ١")).toBeNull();
  });
});
