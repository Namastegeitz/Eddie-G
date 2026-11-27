# Screenshot and video list

## Done (in `../stores/screenshots/` and `../stores/trailer/`)
| Store | Size | Count | Folder |
|---|---|---|---|
| App Store iPhone 6.9" | 2868×1320 | 4 | `iphone-2868x1320/` |
| App Store iPhone 6.3" | 2622×1206 | 6 | `iphone-2622x1206/` |
| App Store iPad 13" | 2752×2064 | 5 | `ipad-2752x2064/` |
| Google Play / Steam / promo | 1920×1080 | 7 | `1920x1080/` |
| Google Play phone | 1280×720 | 14 | `game/docs/store/` |
| App previews | 1920×886 iPhone, 1600×1200 iPad (30 s) | 2 | `trailer/` |
| Trailer | 1080p | 1 | `trailer/` |
| Settings/Credits (new screens) | 1280×720, 720×1280, 2048×1536 | 10 | `../upgrade-shots/after/` |

## To add for 2027 rules
| When | Store | What | How |
|---|---|---|---|
| Apr 2027 | App Store | **iPhone Duo** screenshots (size set by Apple's update) | `xvfb-run godot --path game --rendering-driver opengl3 --resolution <W>x<H> res://tests/shots.tscn` then `stores/screenshots/finish.py` |
| Apr 2027 | Google Play | **≥3 foldable** screenshots (inner screen, e.g. 2208×1768) **+ 1 phone** | same tool at the foldable size |
| Optional now | All | One shot showing Settings with the new accessibility options | `tests/menu_shots.tscn` (`upgrade-shots/after/menu_settings*.png`) |

Shot order (keep across stores): 1 Saturn Rings (hero), 2 Mars + Aurora HD craft, 3 Io cockpit
view, 4 HD 189733b storm, 5 Kepler-16b twin suns, 6 TRAPPIST-1b, 7 WASP-76b.
