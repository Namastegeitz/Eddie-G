# Credits and licences

Checked 27 Nov 2026. Everything below allows commercial store use.

| Asset or code | Source | Licence | Notes |
|---|---|---|---|
| 3D engine | three.js r162 (`js/vendor/three.module.min.js`) | MIT | Licence in `js/vendor/three.LICENSE` |
| Fonts | Lilita One, Baloo 2 (`assets/fonts/`) | SIL Open Font License 1.1 | Licence files next to the fonts; OFL allows bundling in commercial apps |
| Music and sound effects | Made by the game's own synthesizer in code (`js/audio.js`) | Ours | No samples or recordings |
| Voice ("Call out moves") | The player's device's built-in speech voice | Device's own | Nothing recorded or shipped |
| Monkey, skins, gear, stages, icons, store art | Made in code (`js/monkey.js`, `js/stage.js`, `js/foliage.js`, `scripts/make_*.js`) | Ours | No AI-generated or third-party images |
| Phone app shell | Capacitor 8.6.3 and plugins (app, haptics, splash screen, keep-awake) | MIT | |
| In-app purchases | cordova-plugin-purchase 13.19.1 | MIT | |
| Rating prompt | @capacitor-community/in-app-review 8.0.0 | MIT | |
| Crash reports (phones) | @capacitor-firebase/crashlytics 8.6.0; Firebase SDK | Apache 2.0 | Off until set up |
| Crash reports (all) | @sentry/browser 11.19.0 (`js/vendor/sentry.min.js`) | MIT | Shipped only in builds with a Sentry DSN |
| PC edition | Electron 45.5.0, electron-builder 26.18.0 | MIT | |
| Build tool | esbuild 0.24.2 | MIT | Not shipped |

Nothing unclear. If music, voice clips, samples or AI-made art are ever added,
list each here with its licence before release.
