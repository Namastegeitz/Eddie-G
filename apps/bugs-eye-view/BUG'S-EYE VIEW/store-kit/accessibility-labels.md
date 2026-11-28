# Apple Accessibility Nutrition Labels - answers

Labels are voluntary for now (Apple says they will become required later).
Only claim a label when **every common task** (first launch, menus, playing a
room, settings) works with it. Criteria checked 27 Nov 2026:
https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels

| Label | Claim? | Why |
|---|---|---|
| Larger Text | **Not yet - check on an iPhone first** | Settings > Text size goes to 200% (Apple allows an in-game setting). Menus scroll and the HUD fits at 200% in our screenshot tests (`tests/visual/phone_text200`). Claim it after one look through every screen on a real iPhone. |
| Reduced Motion | **Yes, once checked on an iPhone** | Settings > Motion off stops screen shake and the spinning menu diorama. No parallax, blur or vortex effects. |
| Differentiate Without Color Alone | No | Threat state is written out (CALM / SPOTTED), but some cues (detection colours, rarity colours) haven't been audited |
| Sufficient Contrast | No | Not measured yet (needs 4.5:1 for text, 3:1 for controls) |
| Dark Interface | No | The rooms are bright by design |
| Captions | Not applicable | No spoken dialogue |
| Audio Descriptions | No | |
| VoiceOver / Voice Control | No | A 3D action game can't be completed with them |
