# **CANOPY CROSSING: APPLE ACCESSIBILITY NUTRITION LABELS**

Voluntary today; Apple says they become mandatory "over time" (no date).
Shown on iOS 26 and later. Claim a label only if **every common task**
(start a run, hop, use the ability, switch view, pause, buy, change settings)
works with it. Criteria from developer.apple.com, checked 2026-11-27.

| Label | Our answer | Why |
|---|---|---|
| VoiceOver | **No** | Godot 4.7 has no screen reader on iOS (Android arrives in 4.8). |
| Voice Control | **No** | Tapping lanes needs touch; menus aren't named for voice. |
| Larger Text | **No** | No text-size setting yet (planned: see UPGRADE_REPORT.md). |
| Dark Interface | **Yes, if checked on device** | Menus are dark by default; first person has bright skies, so test for "no bright flashes" first. |
| Differentiate Without Color Alone | **Yes** | Settings > Colour-blind hazard markers adds warning triangles and outlines; lanes also differ by texture (water, road, grass). |
| Sufficient Contrast | **Check** | Text is white or yellow on dark green (well above 4.5:1); confirm the small grey hints (UI.MUTED) on device. |
| Reduced Motion | **No (not yet)** | Settings > Reduce motion removes screen shake, but the game doesn't read the system setting and camera bobbing stays. |
| Captions | **Not applicable** | No spoken dialogue. |
| Audio Descriptions | **No** | The short film has no narration of its visuals. |

Recommended answer today: **Differentiate Without Color Alone** only (and
Dark Interface after a device check).
