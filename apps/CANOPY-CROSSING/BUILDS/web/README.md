# **CANOPY CROSSING: web build**

**Uses:** the beta testers' link (https://claude.ai/artifact/NHzAQ2w4jCjWjLkoxLSdB3)
and itch.io's "playable in browser" (HTML5) page.

`CanopyCrossing-Web.zip` is the whole web version; the loose files next to it
are the same thing unzipped (`canopy-crossing.html` is the page). The game
data is split into parts under 14 MB so hosts with file-size limits take it.

**Test it:** serve the folder (`python3 -m http.server`) and open
`canopy-crossing.html`, or use the testers' link. `tools/build_web.sh` checks
every web build in a real browser: phone and tablet taps, a mouse click and
the X key all switch the view.
