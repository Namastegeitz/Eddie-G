#!/usr/bin/env python3
"""Post copy for the 15 show videos -> marketing/VIDEOS.md (captions, hooks, hashtags)."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
content = json.loads((ROOT / "catalog/content.json").read_text())
styles = {s["id"]: s for s in content["styles"]}
shows = content["shows"]
HOOKS = {
    "genesis": "What if sound could draw?", "solarwinds": "This is what a sunbeam sounds like.",
    "saturn": "Saturn's north pole has a hexagon storm. So does this glass of water.",
    "venusmars": "Venus traces a five-petal rose around us every 8 years. Here it is in water.",
    "quasicrystal": "Order that never repeats - grown in water with two notes.",
    "sacred": "Ancient geometry, drawn by vibrating water.", "fractal": "Patterns inside patterns inside patterns.",
    "hyperbolic": "An infinite universe inside a circle.", "ocean": "No screen. No projector. Just water and light.",
    "aurora": "Northern lights, made in a glass dish.", "nightgarden": "Lantern light and star patterns for long nights.",
    "fourthd": "The shadow of an 8-dimensional cube, on your wall.", "golden": "1, 1, 2, 3, 5, 8... in light.",
    "silence": "Ten minutes. Six breaths a minute. Let the rings reach the wall.",
    "supernova": "240 points of light. One finale.",
}
md = ["# Marketing videos: 15 light shows", "",
      "Each video is 33 seconds, vertical 1080 x 1920 (Reels, TikTok, Shorts), H.264 + AAC, in `marketing/videos/`. "
      "Each has a poster frame (`.jpg`). Pictures are simulations from the console's physics model and are labelled as such on screen; "
      "once the real chamber is built, film it and swap in real footage.", "",
      "**Rules for posts:** say *simulated preview* until you have real footage; no health claims (see docs/MARKET.md).", ""]
for i, sh in enumerate(shows, 1):
    names = [styles[s["style"]]["name"] for s in sh["steps"]]
    nxt = next(x["name"] for x in shows if x["id"] == sh["next"])
    md += [f"## {i}. {sh['name']}  ·  `marketing/videos/{i:02d}_{sh['id']}.mp4`", "",
           f"**Hook (first 2 s):** {HOOKS[sh['id']]}", "",
           f"**Caption:** {sh['name']}: a 10-minute light show for the CYMATIC ODYSSEY water-light chamber ({sh['mood']}). "
           f"Real sound shakes a thin layer of water; light through the ripples draws {names[1]}, {names[2]} and {names[3]} on the wall. "
           f"It flows straight into {nxt}. (Simulated preview.)", "",
           f"**Styles in order:** {' → '.join(names)}", "",
           "**Hashtags:** #cymatics #lightshow #sacredgeometry #sounddesign #3dprinting #bambulab #physics #ambientlight #homedecor #cymaticodyssey", ""]
(ROOT / "marketing").mkdir(exist_ok=True)
(ROOT / "marketing/VIDEOS.md").write_text("\n".join(md))
print("wrote marketing/VIDEOS.md")
