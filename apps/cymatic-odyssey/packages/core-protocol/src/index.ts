/**
 * @clc/core-protocol - chamber controller messages (spec 3.2), version 1.
 * Status: types + envelope validation (P0). Transports (BLE GATT, WebSocket, Serial) arrive in P3.
 */
export const PROTOCOL_VERSION = 1 as const;

export type Wave = "sine" | "triangle" | "soft-square";
export type ToChamber =
  | { v: 1; type: "hello" }
  | { v: 1; type: "drive"; tones: Array<{ f: number; a: number; wave: Wave }>; ramp_ms: number }
  | { v: 1; type: "light"; scene: { mode: "palette"; colors: string[]; fade_ms: number } }
  | { v: 1; type: "heartbeat"; t: number }
  | { v: 1; type: "status" }
  | { v: 1; type: "stop"; fade_ms: number };

const TYPES = new Set(["hello", "drive", "light", "heartbeat", "status", "stop"]);

/** Envelope check only: right version and a known type. Field validation lands with the transports in P3. */
export function isEnvelope(msg: unknown): msg is ToChamber {
  if (typeof msg !== "object" || msg === null) return false;
  const m = msg as { v?: unknown; type?: unknown };
  return m.v === PROTOCOL_VERSION && typeof m.type === "string" && TYPES.has(m.type);
}

/** Firmware watchdog (spec 3.2): no heartbeat for this long -> fade to safe idle over WATCHDOG_FADE_MS. */
export const WATCHDOG_TIMEOUT_MS = 3000;
export const WATCHDOG_FADE_MS = 2000;
