import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { ContactForm, contactPayload } from "@/components/ContactForm";

describe("contact form (owner, 2026-11-13)", () => {
  it("needs a title and a message, then sends title, name, phone, WhatsApp and message", async () => {
    const send = vi.fn(async () => true);
    render(<ContactForm locale="en" endpoint="https://form.test/ajax/x" send={send} />);
    fireEvent.change(screen.getByTestId("contact-message"), { target: { value: "Adhan did not play" } });
    fireEvent.click(screen.getByTestId("contact-send"));
    expect(await screen.findByRole("alert")).toHaveTextContent("Please write a title");
    expect(send).not.toHaveBeenCalled();

    fireEvent.change(screen.getByTestId("contact-title"), { target: { value: "Adhan problem" } });
    fireEvent.change(screen.getByTestId("contact-name"), { target: { value: "Ahmed" } });
    fireEvent.change(screen.getByTestId("contact-phone"), { target: { value: "0100" } });
    fireEvent.change(screen.getByTestId("contact-whatsapp"), { target: { value: "0111" } });
    fireEvent.click(screen.getByTestId("contact-send"));
    await waitFor(() => expect(screen.getByTestId("contact-sent")).toBeInTheDocument());
    expect(send).toHaveBeenCalledWith(
      "https://form.test/ajax/x",
      expect.objectContaining({
        title: "Adhan problem",
        name: "Ahmed",
        phone: "0100",
        whatsapp: "0111",
        message: "Adhan did not play",
      }),
    );
  });

  it("shows an error when sending fails, and never shows an email address", async () => {
    render(<ContactForm locale="ar" endpoint="https://form.test/ajax/x" send={async () => false} />);
    fireEvent.change(screen.getByTestId("contact-title"), { target: { value: "x" } });
    fireEvent.change(screen.getByTestId("contact-message"), { target: { value: "hello" } });
    fireEvent.click(screen.getByTestId("contact-send"));
    expect(await screen.findByRole("alert")).toHaveTextContent("تعذّر الإرسال");
    expect(document.body.textContent).not.toMatch(/@/);
  });

  it("fills empty optional fields with a dash", () => {
    expect(contactPayload({ title: " t ", name: "", phone: " ", whatsapp: "", message: "m" })).toMatchObject({
      title: "t",
      name: "-",
      phone: "-",
      whatsapp: "-",
    });
  });
});
