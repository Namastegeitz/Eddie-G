import { describe, expect, it } from "vitest";
import { detectCapabilities, deviceRole } from "./capabilities";

const get = (caps: ReturnType<typeof detectCapabilities>, id: string) => caps.find((c) => c.id === id)!.status;

describe("runtime capability check", () => {
  it("iOS-Safari-like environment: audio yes, serial/bluetooth no, not a controller", () => {
    const caps = detectCapabilities({
      AudioContext: { prototype: {} },
      AudioWorkletNode: function () {},
      navigator: { mediaDevices: { getUserMedia: () => 0 } },
      location: { protocol: "https:" },
      matchMedia: () => ({ matches: false }),
    });
    expect(get(caps, "webAudio")).toBe("yes");
    expect(get(caps, "webSerial")).toBe("no");
    expect(get(caps, "webBluetooth")).toBe("no");
    expect(get(caps, "setSinkId")).toBe("no");
    expect(get(caps, "lan")).toBe("no");
    expect(deviceRole(caps).controller).toBe(false);
  });
  it("Chrome-desktop-like environment: serial, bluetooth and sink selection", () => {
    const caps = detectCapabilities({
      AudioContext: { prototype: { setSinkId() {} } },
      navigator: { serial: {}, bluetooth: {}, wakeLock: {} },
      location: { protocol: "https:" },
    });
    expect(get(caps, "setSinkId")).toBe("yes");
    expect(get(caps, "webSerial")).toBe("yes");
    expect(deviceRole(caps).controller).toBe(true);
  });
  it("native shells get LAN access and defer serial/BLE to native plugins", () => {
    const caps = detectCapabilities({ Capacitor: { isNativePlatform: () => true }, navigator: {} });
    expect(get(caps, "lan")).toBe("yes");
    expect(get(caps, "webBluetooth")).toBe("unknown");
    expect(deviceRole(caps).controller).toBe(true);
  });
  it("never reads the user-agent string", () => {
    const caps = detectCapabilities({ navigator: { userAgent: "iPhone Chrome Android Safari" } as never });
    expect(get(caps, "webAudio")).toBe("no");
  });
});
