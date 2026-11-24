import { applyFx, hasFx } from "@/lib/audio-fx";

/** A quiet series is lifted by up to 12 dB. */
const BOOST_DB = 12;

/** Just enough of Web Audio to see the settings (jsdom has none). */
class FakeParam {
  value = 0;
}
class FakeNode {
  frequency = new FakeParam();
  gain = new FakeParam();
  Q = new FakeParam();
  threshold = new FakeParam();
  ratio = new FakeParam();
  attack = new FakeParam();
  release = new FakeParam();
  type = "";
  connect<T>(n: T): T {
    return n;
  }
}
class FakeContext {
  static made = 0;
  state = "running";
  destination = new FakeNode();
  constructor() {
    FakeContext.made += 1;
  }
  createMediaElementSource = (): FakeNode => new FakeNode();
  createBiquadFilter = (): FakeNode => new FakeNode();
  createDynamicsCompressor = (): FakeNode => new FakeNode();
  createGain = (): FakeNode => new FakeNode();
  resume = async (): Promise<void> => undefined;
}

describe("lesson sound evened out while playing (owner 2026-11-24)", () => {
  beforeEach(() => vi.stubGlobal("AudioContext", FakeContext));
  afterEach(() => vi.unstubAllGlobals());

  it("leaves other audio alone, and routes a quiet / old lesson through gain + voice lift with CORS", () => {
    const plain = document.createElement("audio");
    applyFx(plain, undefined);
    expect(hasFx(plain)).toBe(false);
    expect(plain.getAttribute("crossorigin")).toBeNull();

    const el = document.createElement("audio");
    applyFx(el, { g: BOOST_DB, c: 1 });
    expect(hasFx(el)).toBe(true);
    expect(el.getAttribute("crossorigin")).toBe("anonymous");
    // Next lesson without fx: same graph (one per element), neutral.
    applyFx(el, undefined);
    expect(FakeContext.made).toBe(1);
  });

  it("plays as published on iPhone (Web Audio stops on the lock screen there)", () => {
    vi.spyOn(navigator, "userAgent", "get").mockReturnValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)");
    const el = document.createElement("audio");
    applyFx(el, { g: BOOST_DB });
    expect(hasFx(el)).toBe(false);
    vi.restoreAllMocks();
  });
});
