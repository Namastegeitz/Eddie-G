/**
 * Runtime capability check (spec 2.3). Everything is feature-detected; nothing is assumed from the
 * user-agent string. The UI reads this to decide what a device may do.
 */
export type CapStatus = "yes" | "no" | "unknown";
export interface Capability {
  id: string;
  label: string;
  status: CapStatus;
  note: string;
}

// Minimal shape of the globals we probe, so tests can pass a fake environment.
export interface ProbeEnv {
  AudioContext?: { prototype?: object };
  webkitAudioContext?: unknown;
  AudioWorkletNode?: unknown;
  OffscreenCanvas?: unknown;
  navigator?: {
    serial?: unknown;
    bluetooth?: unknown;
    mediaDevices?: { getUserMedia?: unknown };
    vibrate?: unknown;
    wakeLock?: unknown;
    gpu?: unknown;
  };
  location?: { protocol?: string };
  matchMedia?: (q: string) => { matches: boolean };
  __TAURI__?: unknown;
  __TAURI_INTERNALS__?: unknown;
  Capacitor?: { isNativePlatform?: () => boolean };
  document?: { createElement?: (tag: string) => { getContext?: (k: string) => unknown } };
}

const has = (v: unknown): CapStatus => (v ? "yes" : "no");

export function detectCapabilities(env: ProbeEnv): Capability[] {
  const nav = env.navigator ?? {};
  const native = Boolean(env.__TAURI__ || env.__TAURI_INTERNALS__ || env.Capacitor?.isNativePlatform?.());
  const AC = env.AudioContext;
  const sink = AC?.prototype && "setSinkId" in AC.prototype;
  let webgl2: CapStatus = "unknown";
  try {
    const c = env.document?.createElement?.("canvas");
    if (c?.getContext) webgl2 = c.getContext("webgl2") ? "yes" : "no";
  } catch {
    webgl2 = "no";
  }
  const https = env.location?.protocol === "https:";
  const standalone = env.matchMedia?.("(display-mode: standalone)").matches ?? false;
  const caps: Capability[] = [
    { id: "webAudio", label: "Multi-tone audio (Web Audio)", status: has(AC || env.webkitAudioContext), note: "Needed for every tone and binaural layer." },
    { id: "audioWorklet", label: "AudioWorklet (click-free oscillators)", status: has(env.AudioWorkletNode), note: "Phase-continuous glides." },
    { id: "setSinkId", label: "Choose audio output device", status: sink ? "yes" : "no", note: sink ? "Can send DRIVE to a USB audio device." : "Not in this browser: use the desktop app, the ESP32 synth, or one shared output." },
    { id: "webSerial", label: "USB serial to the chamber (Web Serial)", status: native ? "unknown" : has(nav.serial), note: native ? "Native app: serial goes through the native layer (P8)." : "Chrome/Edge desktop only." },
    { id: "webBluetooth", label: "Bluetooth to the chamber (Web Bluetooth)", status: native ? "unknown" : has(nav.bluetooth), note: native ? "Native app: BLE goes through the native plugin (P8)." : "Not available in Safari / iOS." },
    { id: "lan", label: "Talk to LAN devices (WLED / ESP32 over http/ws)", status: native ? "yes" : https ? "no" : "unknown", note: native ? "Native networking." : "Browsers block http:// and ws:// from an https page (mixed content); use the desktop or mobile app." },
    { id: "camera", label: "Camera (calibration, Symmetry Score)", status: has(nav.mediaDevices?.getUserMedia), note: "Used for the Bowl Fingerprint (P5)." },
    { id: "vibration", label: "Vibration / haptics", status: has(nav.vibrate), note: "Optional cues." },
    { id: "wakeLock", label: "Keep the screen awake", status: has(nav.wakeLock), note: "Long sessions may pause when the screen locks, especially on iOS." },
    { id: "webgl2", label: "WebGL2 (water simulator)", status: webgl2, note: "Simulator quality tiers (P2)." },
    { id: "webgpu", label: "WebGPU (faster simulator)", status: has(nav.gpu), note: "Optional; WebGL2 is the baseline." },
    { id: "offscreen", label: "OffscreenCanvas (camera analysis off the main thread)", status: has(env.OffscreenCanvas), note: "CV worker (P5)." },
    { id: "installed", label: "Installed as an app (PWA)", status: standalone ? "yes" : "no", note: "Install for offline use." },
  ];
  return caps;
}

/** What this device may be in the system (spec 2.3 consequences). */
export function deviceRole(caps: Capability[]): { controller: boolean; summary: string } {
  const s = (id: string) => caps.find((c) => c.id === id)?.status;
  const controller = s("webSerial") === "yes" || s("webBluetooth") === "yes" || s("lan") === "yes";
  return controller
    ? { controller, summary: "This device can control a chamber (serial, Bluetooth or LAN available)." }
    : { controller, summary: "This device can be a listener, remote viewer, Lab and Forge, but not a chamber controller. Use the desktop app, an Android/Chrome device, or the mobile app build for hardware." };
}
