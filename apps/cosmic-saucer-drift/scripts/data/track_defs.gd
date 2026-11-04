class_name TrackDefs
extends RefCounted
## The six tracks as data. Positions along the track are given as control
## point indices ("at": 10.5 = halfway between point 10 and 11), so features
## stay put when a track is tweaked and flip cleanly for reverse/mirror.
##
## Feature types:
##   boost   {at, lane}            boost pad
##   crates  {at}                  row of item crates
##   pods    {at, lane, n, form}   energy pods; form "line" (along) or "row" (across)
##   jump    {at, gap, h, len}     kicker ramp ending at `at`; optional gap after it
##   lowg    {a, b}                low-gravity range
##   rail    {a, b}                magnetic rail surface range
##   surface {a, b, s}             surface range (Catalog.S_*)
##   tube    {a, b}                enclosed tunnel visual (station/crystal)
##   roller  {at, period, size}    tumbling asteroid rolling across
##   flare   {at, period}          solar flare beam sweeping across
##   laser   {at, period}          station laser sweeping across
##   snapper {at, side}            alien plant lunging in from an edge
##   geyser  {at, lane}            launches you into the air while erupting
##   dropper {a, b}                falling ice shards with warning shadows
##   eruption{at, len}             lava erupts on one half of the road, alternating
## Shortcut: {side (+1 right / -1 left of the road, normal direction), a, b,
##            via: [Vector3], width, lift (bridge height, launched by a geyser)}
## Shards:   3 per track: {at, lane, h} or {shortcut: 0..1, h}

const DEFS := {
	"asteroid_belt": {
		"name": "The Asteroid Belt", "theme": "asteroid", "width": 18.0, "laps": 3,
		"blurb": "Tight turns, tumbling space rocks and low-gravity jumps.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 0, -110), Vector3(0, 3, -190), Vector3(12, 6, -262),
			Vector3(55, 6, -318), Vector3(122, 4, -338), Vector3(182, 2, -308), Vector3(204, 0, -248),
			Vector3(176, 0, -188), Vector3(192, 2, -128), Vector3(250, 4, -98), Vector3(318, 6, -110),
			Vector3(370, 8, -62), Vector3(362, 6, 10), Vector3(300, 4, 32), Vector3(240, 2, 44),
			Vector3(204, 0, 96), Vector3(200, 0, 162), Vector3(160, 2, 212), Vector3(92, 4, 224),
			Vector3(40, 2, 184), Vector3(16, 0, 112), Vector3(0, 0, 52)],
		"features": [
			{"t": "boost", "at": 0.35, "lane": 0.0},
			{"t": "crates", "at": 0.75},
			{"t": "jump", "at": 1.45, "gap": 20.0, "h": 2.4, "len": 14.0},
			{"t": "lowg", "a": 1.1, "b": 2.05},
			{"t": "pods", "at": 1.62, "lane": 0.0, "n": 4, "form": "line", "h": 3.0},
			{"t": "roller", "at": 3.5, "period": 5.5, "size": 4.0},
			{"t": "pods", "at": 4.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "crates", "at": 6.5},
			{"t": "surface", "a": 6.3, "b": 8.6, "s": 1},
			{"t": "roller", "at": 8.0, "period": 6.0, "size": 3.6},
			{"t": "pods", "at": 9.0, "lane": 4.0, "n": 5, "form": "line"},
			{"t": "boost", "at": 11.3, "lane": -4.0},
			{"t": "crates", "at": 12.0},
			{"t": "pods", "at": 16.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "roller", "at": 17.5, "period": 5.0, "size": 4.2},
			{"t": "crates", "at": 18.5},
			{"t": "pods", "at": 20.5, "lane": -3.0, "n": 5, "form": "line"},
		],
		"shortcut": {"side": 1, "a": 10.0, "b": 15.0, "via": [Vector3(258, 3, -45), Vector3(252, 3, -2)], "width": 10.0},
		"shards": [{"at": 1.66, "lane": 0.0, "h": 6.5}, {"shortcut": 0.5, "h": 1.5}, {"at": 17.1, "lane": 7.0, "h": 1.5}],
	},
	"neon_ring": {
		"name": "Neon Ring of Saturn", "theme": "saturn", "width": 20.0, "laps": 3, "auto_bank": 650.0,
		"blurb": "Blistering magnetic rails around a ringed giant.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 0, -200), Vector3(0, 0, -400), Vector3(40, 5, -520),
			Vector3(140, 10, -580), Vector3(260, 12, -560), Vector3(340, 10, -480), Vector3(360, 6, -360),
			Vector3(320, 2, -260), Vector3(360, 0, -160), Vector3(420, 0, -60), Vector3(420, 0, 80),
			Vector3(380, 4, 200), Vector3(280, 8, 260), Vector3(160, 10, 250), Vector3(90, 8, 320),
			Vector3(20, 6, 370), Vector3(-70, 4, 330), Vector3(-90, 2, 220), Vector3(-40, 0, 130),
			Vector3(0, 0, 60)],
		"features": [
			{"t": "rail", "a": 0.3, "b": 1.9},
			{"t": "crates", "at": 1.95},
			{"t": "boost", "at": 2.6, "lane": -5.0},
			{"t": "boost", "at": 2.6, "lane": 5.0},
			{"t": "pods", "at": 3.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "flare", "at": 5.0, "period": 4.5},
			{"t": "crates", "at": 6.0},
			{"t": "boost", "at": 7.3, "lane": 0.0},
			{"t": "jump", "at": 7.8, "gap": 0.0, "h": 2.6, "len": 16.0},
			{"t": "pods", "at": 8.6, "lane": -6.0, "n": 5, "form": "line"},
			{"t": "rail", "a": 10.3, "b": 11.7},
			{"t": "pods", "at": 11.0, "lane": 0.0, "n": 4, "form": "line"},
			{"t": "crates", "at": 12.5},
			{"t": "pods", "at": 13.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "flare", "at": 15.6, "period": 5.0},
			{"t": "crates", "at": 17.5},
			{"t": "pods", "at": 18.5, "lane": 6.0, "n": 5, "form": "line"},
		],
		"shortcut": {"side": 1, "a": 14.0, "b": 19.0, "via": [Vector3(90, 8, 215), Vector3(20, 4, 175)], "width": 10.0},
		"shards": [{"at": 2.2, "lane": 8.5, "h": 1.5}, {"shortcut": 0.6, "h": 1.5}, {"at": 8.08, "lane": 0.0, "h": 7.5}],
	},
	"jungle_moon": {
		"name": "Alien Jungle Moon", "theme": "jungle", "width": 17.0, "laps": 3,
		"blurb": "Bouncy moss, snapping plants and geysers that launch you skyward.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 2, -100), Vector3(-30, 6, -180), Vector3(-100, 10, -222),
			Vector3(-172, 8, -192), Vector3(-212, 4, -120), Vector3(-202, 0, -40), Vector3(-242, -2, 40),
			Vector3(-302, 0, 92), Vector3(-332, 4, 172), Vector3(-292, 8, 242), Vector3(-212, 10, 262),
			Vector3(-140, 8, 232), Vector3(-130, 6, 322), Vector3(-62, 4, 382), Vector3(18, 4, 362),
			Vector3(42, 4, 262), Vector3(30, 2, 170), Vector3(10, 0, 80)],
		"features": [
			{"t": "crates", "at": 0.6},
			{"t": "surface", "a": 1.0, "b": 3.0, "s": 4},
			{"t": "pods", "at": 2.0, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "snapper", "at": 4.5, "side": 1},
			{"t": "crates", "at": 5.5},
			{"t": "pods", "at": 6.5, "lane": -3.0, "n": 5, "form": "line"},
			{"t": "surface", "a": 7.0, "b": 9.5, "s": 4},
			{"t": "snapper", "at": 8.5, "side": -1},
			{"t": "pods", "at": 9.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "geyser", "at": 10.5, "lane": 3.0},
			{"t": "crates", "at": 11.2},
			{"t": "snapper", "at": 14.0, "side": 1},
			{"t": "pods", "at": 14.5, "lane": 3.0, "n": 5, "form": "line"},
			{"t": "surface", "a": 16.5, "b": 18.0, "s": 4},
			{"t": "crates", "at": 17.0},
		],
		"shortcut": {"side": -1, "a": 11.6, "b": 16.6, "via": [Vector3(-95, 17, 218), Vector3(-45, 13, 216), Vector3(-5, 8, 218)], "width": 10.0, "lift": 7.5},
		"shards": [{"shortcut": 0.45, "h": 1.5}, {"at": 10.56, "lane": 3.0, "h": 10.0}, {"at": 14.8, "lane": -6.5, "h": 1.5}],
	},
	"comet_ice": {
		"name": "Comet Ice Run", "theme": "ice", "width": 18.0, "laps": 3,
		"blurb": "A slippery comet tail with falling ice shards.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 0, -120), Vector3(-20, -4, -230), Vector3(-80, -8, -300),
			Vector3(-160, -10, -310), Vector3(-230, -8, -260), Vector3(-250, -4, -180), Vector3(-300, 0, -120),
			Vector3(-370, 4, -100), Vector3(-430, 6, -140), Vector3(-480, 6, -80), Vector3(-470, 4, 10),
			Vector3(-410, 2, 60), Vector3(-330, 0, 70), Vector3(-260, -2, 120), Vector3(-250, -4, 200),
			Vector3(-190, -4, 250), Vector3(-110, -2, 240), Vector3(-60, 0, 170), Vector3(-20, 0, 90)],
		"features": [
			{"t": "boost", "at": 0.3, "lane": 0.0},
			{"t": "crates", "at": 1.0},
			{"t": "surface", "a": 1.5, "b": 5.5, "s": 2},
			{"t": "pods", "at": 2.5, "lane": 0.0, "n": 5, "form": "line"},
			{"t": "dropper", "a": 3.0, "b": 4.5},
			{"t": "crates", "at": 6.0},
			{"t": "pods", "at": 7.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "tube", "a": 8.5, "b": 10.5},
			{"t": "pods", "at": 10.0, "lane": 5.0, "n": 4, "form": "line"},
			{"t": "crates", "at": 11.0},
			{"t": "boost", "at": 12.5, "lane": 0.0},
			{"t": "surface", "a": 13.5, "b": 17.5, "s": 2},
			{"t": "pods", "at": 14.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "dropper", "a": 15.0, "b": 16.2},
			{"t": "crates", "at": 17.0},
			{"t": "jump", "at": 18.5, "gap": 0.0, "h": 2.4, "len": 14.0},
			{"t": "pods", "at": 18.9, "lane": -4.0, "n": 4, "form": "line"},
		],
		"shortcut": {"side": -1, "a": 7.0, "b": 13.0, "via": [Vector3(-322, 2, -60), Vector3(-336, 2, 10)], "width": 10.0, "surface": 2},
		"shards": [{"shortcut": 0.5, "h": 1.5}, {"at": 3.7, "lane": -7.0, "h": 1.5}, {"at": 18.75, "lane": 0.0, "h": 6.5}],
	},
	"orbital_station": {
		"name": "Orbital Station", "theme": "station", "width": 16.0, "laps": 3, "auto_bank": 300.0,
		"blurb": "Metal decks, sweeping lasers and low-gravity tubes.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 0, -150), Vector3(0, 0, -240), Vector3(20, 0, -270),
			Vector3(60, 0, -280), Vector3(200, 0, -280), Vector3(240, 2, -260), Vector3(260, 6, -220),
			Vector3(260, 10, -120), Vector3(280, 10, -90), Vector3(320, 10, -80), Vector3(420, 8, -80),
			Vector3(450, 6, -50), Vector3(460, 4, 0), Vector3(460, 2, 120), Vector3(440, 0, 160),
			Vector3(400, 0, 170), Vector3(300, 0, 170), Vector3(270, -2, 200), Vector3(260, -4, 260),
			Vector3(230, -4, 290), Vector3(180, -4, 300), Vector3(60, -2, 300), Vector3(20, 0, 280),
			Vector3(0, 0, 240), Vector3(0, 0, 120)],
		"features": [
			{"t": "boost", "at": 1.0, "lane": -4.0},
			{"t": "boost", "at": 1.0, "lane": 4.0},
			{"t": "crates", "at": 1.6},
			{"t": "pods", "at": 3.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "laser", "at": 5.0, "period": 4.0},
			{"t": "tube", "a": 7.2, "b": 8.8},
			{"t": "lowg", "a": 7.2, "b": 8.8},
			{"t": "pods", "at": 8.0, "lane": 0.0, "n": 5, "form": "line"},
			{"t": "crates", "at": 9.5},
			{"t": "laser", "at": 11.0, "period": 3.6},
			{"t": "boost", "at": 11.5, "lane": 0.0},
			{"t": "pods", "at": 12.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "crates", "at": 15.0},
			{"t": "laser", "at": 16.5, "period": 4.4},
			{"t": "pods", "at": 17.0, "lane": -4.0, "n": 5, "form": "line"},
			{"t": "tube", "a": 20.5, "b": 22.5},
			{"t": "lowg", "a": 20.5, "b": 22.5},
			{"t": "jump", "at": 21.1, "gap": 0.0, "h": 2.2, "len": 12.0},
			{"t": "laser", "at": 22.0, "period": 3.8},
			{"t": "crates", "at": 22.8},
			{"t": "pods", "at": 23.5, "lane": 4.0, "n": 5, "form": "line"},
			{"t": "boost", "at": 24.5, "lane": 0.0},
		],
		"shortcut": {"side": 1, "a": 13.0, "b": 18.0, "via": [Vector3(410, 2, 50), Vector3(340, 0, 120)], "width": 9.0, "tube": true},
		"shards": [{"shortcut": 0.5, "h": 1.5}, {"at": 21.45, "lane": 0.0, "h": 8.0}, {"at": 13.5, "lane": 6.0, "h": 1.5}],
	},
	"lava_moon": {
		"name": "Lava Moon", "theme": "lava", "width": 19.0, "laps": 3,
		"blurb": "Dust dunes, a lava jump and eruptions that close lanes.",
		"points": [
			Vector3(0, 0, 0), Vector3(0, 4, -90), Vector3(10, 0, -170), Vector3(40, 6, -240),
			Vector3(100, 2, -290), Vector3(180, 8, -300), Vector3(250, 4, -260), Vector3(290, 0, -190),
			Vector3(340, 6, -150), Vector3(410, 2, -160), Vector3(460, 8, -110), Vector3(470, 4, -30),
			Vector3(430, 0, 40), Vector3(360, 6, 80), Vector3(300, 2, 140), Vector3(310, 6, 220),
			Vector3(260, 2, 290), Vector3(180, 4, 300), Vector3(110, 0, 250), Vector3(60, 4, 180),
			Vector3(20, 0, 100)],
		"features": [
			{"t": "boost", "at": 0.5, "lane": 0.0},
			{"t": "surface", "a": 0.6, "b": 4.5, "s": 1},
			{"t": "crates", "at": 1.5},
			{"t": "pods", "at": 3.0, "lane": -4.0, "n": 5, "form": "line"},
			{"t": "crates", "at": 5.5},
			{"t": "surface", "a": 5.0, "b": 18.5, "s": 5},
			{"t": "eruption", "at": 6.0, "len": 30.0},
			{"t": "boost", "at": 7.1, "lane": 0.0},
			{"t": "jump", "at": 7.5, "gap": 11.0, "h": 2.8, "len": 14.0},
			{"t": "pods", "at": 8.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "surface", "a": 9.0, "b": 12.5, "s": 1},
			{"t": "eruption", "at": 11.0, "len": 30.0},
			{"t": "crates", "at": 12.0},
			{"t": "pods", "at": 13.5, "lane": 4.0, "n": 5, "form": "line"},
			{"t": "eruption", "at": 16.0, "len": 30.0},
			{"t": "pods", "at": 16.5, "lane": 0.0, "n": 5, "form": "row"},
			{"t": "crates", "at": 17.5},
			{"t": "eruption", "at": 19.5, "len": 28.0},
			{"t": "pods", "at": 19.8, "lane": 0.0, "n": 4, "form": "line"},
		],
		"shortcut": {"side": 1, "a": 14.0, "b": 18.0, "via": [Vector3(230, 4, 170), Vector3(170, 2, 215)], "width": 9.0, "surface": 5},
		"shards": [{"shortcut": 0.5, "h": 1.5}, {"at": 7.63, "lane": 0.0, "h": 7.0}, {"at": 10.5, "lane": -8.0, "h": 1.5}],
	},
}

static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["asteroid_belt"])
