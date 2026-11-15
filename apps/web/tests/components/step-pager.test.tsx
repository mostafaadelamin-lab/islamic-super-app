import { fireEvent, render, screen } from "@testing-library/react";
import { StepPager, stepFromHash } from "@/components/StepPager";

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

  it("reads #umrah-step-N links", () => {
    expect(stepFromHash("#umrah-step-2", "umrah-step", 4)).toBe(1);
    expect(stepFromHash("#umrah-step-9", "umrah-step", 4)).toBeNull();
    expect(stepFromHash("#umrah", "umrah-step", 4)).toBeNull();
  });
});
