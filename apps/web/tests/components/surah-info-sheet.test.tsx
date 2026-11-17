import { readFileSync } from "node:fs";
import { join } from "node:path";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { SurahInfoSheet } from "@/components/SurahInfoSheet";
import { loadSurahInfo, surahInfoUrl } from "@/lib/surah-info";

const asset = JSON.parse(
  readFileSync(join(process.cwd(), "../mobile/assets/content/surah-info.v1.json"), "utf8"),
) as { surahs: { n: number; asbab?: string; wahidi?: { ayah: number; text: string }[] }[] };

describe("«عن السورة وأسباب النزول» in the Mushaf (as in the app)", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("loads one surah's card from /data/surah-info and shows the app's text verbatim", async () => {
    const s = asset.surahs.find((x) => x.asbab || (x.wahidi && x.wahidi.length > 0))!;
    const fetchMock = vi.fn(() => Promise.resolve(new Response(JSON.stringify(s), { status: 200 })));
    vi.stubGlobal("fetch", fetchMock);
    const onClose = vi.fn();
    render(<SurahInfoSheet locale="ar" surah={s.n} onClose={onClose} />);
    expect(await screen.findByTestId("surah-info-asbab")).toHaveTextContent("أسباب النزول");
    expect(fetchMock).toHaveBeenCalledWith(surahInfoUrl(s.n));
    const first = (s.asbab || s.wahidi![0]!.text).split("\n").find((p) => p.trim() !== "")!;
    expect(screen.getByTestId("surah-info-sheet").textContent).toContain(first);
    await userEvent.click(screen.getByTestId("surah-info-close"));
    expect(onClose).toHaveBeenCalled();
  });

  it("a failed load can be retried", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response("", { status: 500 }))),
    );
    await expect(loadSurahInfo(2)).rejects.toThrow();
    const ok = asset.surahs.find((x) => x.n === 2)!;
    vi.stubGlobal(
      "fetch",
      vi.fn(() => Promise.resolve(new Response(JSON.stringify(ok), { status: 200 }))),
    );
    await expect(loadSurahInfo(2)).resolves.toMatchObject({ n: 2 });
  });
});
