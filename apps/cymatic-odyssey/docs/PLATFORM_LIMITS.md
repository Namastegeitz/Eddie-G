# Platform limits

What each platform can and can't do. The app doesn't rely on this table: `apps/web/src/capabilities.ts` feature-detects every capability at runtime (never from the browser name), and the UI reads the result. This table is the expectation; **"verify"** marks cells nobody has tested on a real device yet.

| Capability | Chrome/Edge desktop | Safari macOS | Android Chrome (PWA) | iOS Safari (PWA) | Tauri desktop (P8) | Capacitor iOS/Android (P8) |
|---|---|---|---|---|---|---|
| Web Audio multi-tone / binaural | Yes | Yes | Yes | Yes | Yes | Yes |
| Choose audio output device (`setSinkId`) | Yes | No (verify) | Partial | No | Windows (WebView2) likely yes; macOS/Linux need a native audio route (verify) | Native plugin |
| Web Serial | Yes | **No** | Verify (recent versions only) | **No** | Native serial via Rust | n/a |
| Web Bluetooth | Yes | **No** | Yes | **No** | Native | Native BLE plugin |
| Reach LAN devices (WLED / ESP32 over `http://`, `ws://`) | Blocked from an HTTPS page (mixed content) | Blocked | Blocked | Blocked | Yes, native HTTP/WS | Yes, native HTTP |
| Camera (`getUserMedia`) | Yes | Yes | Yes | Yes | Yes | Yes |
| Vibration / haptics | Vibration API | No | Vibration API | No | n/a | Haptics plugin |
| Long sessions with the screen locked | n/a | n/a | May pause | **Likely pauses** | Yes | Background-audio mode |
| Screen Wake Lock | Yes | Verify | Yes | Verify | Yes | Keep-awake plugin |

## What this means in the product

- **iPhone / iPad in the browser:** listener (Silent Sound Bath), remote viewer, Lab and Forge. **Not** a chamber controller; the app says so on the "This device" panel. Hardware on iOS goes through the Capacitor app (BLE) or a desktop/tablet hub.
- **Phones with the OS "Mono Audio" accessibility setting on** collapse binaural beats into monaural. The Headphone Check (P1) catches this and keeps binaural modes off until it passes.
- **LAN gear (WLED, ESP32 over Wi-Fi)** can't be reached from the hosted HTTPS web app; use the desktop or mobile build, BLE, or USB serial.

## Runtime checks implemented (P0)

Web Audio, AudioWorklet, `setSinkId`, Web Serial, Web Bluetooth, LAN access (https vs native shell), camera, vibration, Wake Lock, WebGL2, WebGPU, OffscreenCanvas, installed-PWA. Unit tests cover an iOS-like, a Chrome-desktop-like and a native-shell environment, and confirm that the user-agent string is never read.

## Native apps (built Nov 2026, ahead of P8)

`apps/mobile` wraps the same web build with Capacitor 8 for Android and iOS. Today they add no native features beyond the web app (no BLE, haptics, keep-awake or background audio yet), so the table's Capacitor column describes what P8 will add, not what ships now. The Android app was built and signature-checked here but not run on a device; the iOS app is built on a cloud Mac (Codemagic).

## Not verified yet

Nothing in this table has been checked on physical devices in P0. Real-device runs come with Playwright (P8, plugin question at that checkpoint) and with Eddie's own phone/tablet testing.
