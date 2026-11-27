# firmware/chamber-esp32 (PlatformIO) - STUB, arrives in P3

Planned (spec 3.2): I2S stereo synth (4+ oscillators, phase-continuous glides, hard amplitude ceiling in firmware),
3 s heartbeat watchdog that fades drive and lights to idle over 2 s, FastLED at <= 60 fps with its own flicker guard
(same rules as `packages/core-safety`), BLE GATT + Wi-Fi WebSocket + USB serial transports speaking the versioned JSON
in `packages/core-protocol`, optional NTC thermal cutoff. Board: ESP32-S3 on a pre-certified radio module.
Signed OTA updates only after Eddie approves. Nothing is implemented yet.
