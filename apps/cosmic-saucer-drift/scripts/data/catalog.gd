class_name Catalog
extends RefCounted
## All game content as data: surfaces, saucers, pilots, items, cups,
## cosmetics. Gameplay code looks things up here; tuning numbers for the
## driving model live in resources/tuning.tres.

# ---------------------------------------------------------------- surfaces
enum { S_METAL, S_DUST, S_ICE, S_RAIL, S_MOSS, S_LAVA }

const SURFACES := {
	S_METAL: {"name": "Metal decking", "grip": 1.0, "speed": 1.0, "color": Color(0.20, 0.22, 0.32)},
	S_DUST: {"name": "Moon dust", "grip": 0.72, "speed": 0.86, "color": Color(0.46, 0.42, 0.38)},
	S_ICE: {"name": "Comet ice", "grip": 0.30, "speed": 1.03, "color": Color(0.55, 0.80, 0.98)},
	S_RAIL: {"name": "Magnetic rail", "grip": 1.25, "speed": 1.15, "color": Color(0.12, 0.08, 0.30)},
	S_MOSS: {"name": "Bouncy moss", "grip": 0.88, "speed": 0.93, "color": Color(0.20, 0.48, 0.24)},
	S_LAVA: {"name": "Lava rock", "grip": 0.95, "speed": 0.97, "color": Color(0.17, 0.11, 0.11)},
}

static func surface(id: int) -> Dictionary:
	return SURFACES.get(id, SURFACES[S_METAL])

# ---------------------------------------------------------------- saucers
# Stats are 1-10. Upgrades add 0.5 per level (5 levels) on top.
const SAUCERS := [
	{"id": "classic", "name": "Classic Saucer", "blurb": "The all-rounder. Easy to fly, hard to beat.",
	 "speed": 5, "accel": 5, "handling": 5, "efficiency": 5, "weight": 5,
	 "price": 0, "stars": 0, "shape": "classic", "paint": Color(0.80, 0.84, 0.92)},
	{"id": "bubble", "name": "Bubble Pod", "blurb": "Big glass dome, nimble and quick off the line.",
	 "speed": 4, "accel": 6, "handling": 7, "efficiency": 5, "weight": 3,
	 "price": 0, "stars": 0, "shape": "bubble", "paint": Color(1.0, 0.55, 0.75)},
	{"id": "rocket", "name": "Rocket Fin", "blurb": "Twin fins, huge top speed, wide turns.",
	 "speed": 8, "accel": 4, "handling": 3, "efficiency": 4, "weight": 5,
	 "price": 2000, "stars": 8, "shape": "rocket", "paint": Color(0.95, 0.30, 0.25)},
	{"id": "ring", "name": "Ring Racer", "blurb": "Spinning outer ring for instant acceleration.",
	 "speed": 5, "accel": 8, "handling": 5, "efficiency": 4, "weight": 4,
	 "price": 2500, "stars": 14, "shape": "ring", "paint": Color(0.30, 0.85, 0.55)},
	{"id": "manta", "name": "Manta", "blurb": "Flat wing that loves to drift. Drift charge +15%.",
	 "speed": 6, "accel": 5, "handling": 8, "efficiency": 4, "weight": 4,
	 "price": 3500, "stars": 22, "shape": "manta", "paint": Color(0.25, 0.45, 0.95), "drift_bonus": 0.15},
	{"id": "mothership", "name": "Mothership Jr", "blurb": "Heavy, sips energy, shoves rivals aside.",
	 "speed": 6, "accel": 4, "handling": 4, "efficiency": 9, "weight": 9,
	 "price": 5000, "stars": 30, "shape": "mothership", "paint": Color(0.55, 0.50, 0.70)},
]

const STAT_KEYS := ["speed", "accel", "handling", "efficiency"]
const STAT_NAMES := {"speed": "Top Speed", "accel": "Acceleration", "handling": "Handling", "efficiency": "Energy Efficiency"}
const UPGRADE_COSTS := [150, 300, 600, 1000, 1600]
const UPGRADE_STEP := 0.5

static func saucer(id: String) -> Dictionary:
	for s in SAUCERS:
		if s.id == id:
			return s
	return SAUCERS[0]

# ---------------------------------------------------------------- pilots
# passive: what the pilot does for you. style: how the pilot drives as AI.
const PILOTS := [
	{"id": "zib", "name": "Zib", "color": Color(0.45, 0.95, 0.35), "eyes": 2,
	 "passive": "drift", "passive_name": "Drift Ace", "passive_text": "Drifts charge Plasma Boost 25% faster.",
	 "style": "clean", "unlock": "start", "home": "asteroid_belt"},
	{"id": "nova", "name": "Nova Quark", "color": Color(0.35, 0.85, 1.0), "eyes": 2,
	 "passive": "shield_start", "passive_name": "Shield Start", "passive_text": "Starts every race holding an Ion Shield.",
	 "style": "clean", "unlock": "start", "home": "neon_ring"},
	{"id": "gloop", "name": "Gloop", "color": Color(0.75, 0.40, 1.0), "eyes": 1,
	 "passive": "efficient", "passive_name": "Slow Burner", "passive_text": "Dark Matter core drains 25% slower.",
	 "style": "hoarder", "unlock": "boss", "stars": 3, "home": "jungle_moon"},
	{"id": "krell", "name": "Captain Krell", "color": Color(0.95, 0.45, 0.20), "eyes": 4,
	 "passive": "bumper", "passive_name": "Bumper", "passive_text": "Bumps shove rivals 60% harder; you barely budge.",
	 "style": "aggressive", "unlock": "boss", "stars": 7, "home": "lava_moon"},
	{"id": "vexa", "name": "Vexa Starling", "color": Color(1.0, 0.35, 0.65), "eyes": 2,
	 "passive": "lucky", "passive_name": "Lucky Crates", "passive_text": "Crates roll as if you were two places further back.",
	 "style": "hoarder", "unlock": "boss", "stars": 12, "home": "orbital_station"},
	{"id": "bleep", "name": "Bleep-0", "color": Color(0.80, 0.82, 0.88), "eyes": 1,
	 "passive": "magnet", "passive_name": "Pod Magnet", "passive_text": "Energy Pods fly to you from three times farther.",
	 "style": "clean", "unlock": "boss", "stars": 18, "home": "comet_ice"},
	{"id": "zorba", "name": "Mama Zorba", "color": Color(1.0, 0.82, 0.25), "eyes": 3,
	 "passive": "tricks", "passive_name": "Trick Queen", "passive_text": "Landed tricks give double boost and energy.",
	 "style": "aggressive", "unlock": "boss", "stars": 25, "home": "jungle_moon"},
	{"id": "comet", "name": "Comet the Space Pup", "color": Color(0.85, 0.65, 0.45), "eyes": 2,
	 "passive": "draft", "passive_name": "Draft Hound", "passive_text": "Slipstream charges twice as fast.",
	 "style": "aggressive", "unlock": "boss", "stars": 33, "home": "neon_ring"},
]

static func pilot(id: String) -> Dictionary:
	for p in PILOTS:
		if p.id == id:
			return p
	return PILOTS[0]

# ---------------------------------------------------------------- items
const ITEMS := {
	"tractor": {"name": "Tractor Beam", "color": Color(0.4, 1.0, 0.5), "text": "Drags the racer ahead back toward you."},
	"meteor": {"name": "Meteor Strike", "color": Color(1.0, 0.55, 0.2), "text": "A meteor falls on the leader."},
	"shield": {"name": "Ion Shield", "color": Color(0.35, 0.8, 1.0), "text": "Blocks every hit for a few seconds."},
	"warp": {"name": "Hyperspace Warp", "color": Color(0.85, 0.5, 1.0), "text": "Teleport-dash forward along the track."},
	"bolt": {"name": "Plasma Bolt", "color": Color(1.0, 0.3, 0.45), "text": "A homing shot at the racer ahead."},
	"mine": {"name": "Gravity Mine", "color": Color(1.0, 0.9, 0.3), "text": "Drop it behind you."},
	"nebula": {"name": "Nebula Cloud", "color": Color(0.75, 0.35, 0.95), "text": "Smears the screens of everyone ahead."},
	"blackhole": {"name": "Black Hole", "color": Color(0.30, 0.20, 0.45), "text": "A vortex ahead that drags racers in."},
}

# Item odds by how far back you are: 0 = leader, 1 = middle, 2 = back.
const ITEM_ODDS := [
	{"shield": 28, "mine": 30, "bolt": 18, "tractor": 10, "blackhole": 8, "nebula": 6},
	{"bolt": 20, "tractor": 16, "mine": 14, "shield": 10, "nebula": 14, "blackhole": 14, "warp": 6, "meteor": 6},
	{"warp": 24, "meteor": 18, "tractor": 16, "bolt": 14, "nebula": 10, "blackhole": 10, "shield": 8},
]

# ---------------------------------------------------------------- tracks & cups
const TRACK_IDS := ["asteroid_belt", "neon_ring", "jungle_moon", "comet_ice", "orbital_station", "lava_moon"]
enum { V_NORMAL, V_REVERSE, V_MIRROR }
const VARIANT_NAMES := ["", "Reverse", "Mirror"]

# Each race: [track id, variant, challenge id]
const CUPS := [
	{"id": "nebula", "name": "Nebula Cup", "stars": 0, "color": Color(0.55, 0.4, 1.0), "class": 0,
	 "races": [["asteroid_belt", 0, "pods10"], ["jungle_moon", 0, "tricks3"], ["comet_ice", 0, "no_hover"], ["neon_ring", 0, "purple2"]]},
	{"id": "supernova", "name": "Supernova Cup", "stars": 8, "color": Color(1.0, 0.6, 0.2), "class": 1,
	 "races": [["orbital_station", 0, "hits2"], ["lava_moon", 0, "no_hover"], ["asteroid_belt", 1, "shard1"], ["neon_ring", 1, "slip3"]]},
	{"id": "quasar", "name": "Quasar Cup", "stars": 20, "color": Color(0.3, 0.9, 1.0), "class": 2,
	 "races": [["jungle_moon", 1, "shortcut"], ["comet_ice", 1, "purple3"], ["orbital_station", 1, "tricks4"], ["lava_moon", 1, "lead_lap"]]},
	{"id": "horizon", "name": "Event Horizon Cup", "stars": 34, "color": Color(1.0, 0.3, 0.6), "class": 3,
	 "races": [["asteroid_belt", 2, "no_hover"], ["neon_ring", 2, "hits3"], ["jungle_moon", 2, "pods15"], ["lava_moon", 2, "margin2"]]},
]

const CUP_POINTS := [10, 8, 6, 5, 4, 3, 2, 1]

# Challenge id -> [text, stat key, target]. Checked at the finish.
const CHALLENGES := {
	"pods10": ["Collect 10 Energy Pods", "pods", 10],
	"pods15": ["Collect 15 Energy Pods", "pods", 15],
	"tricks3": ["Land 3 tricks", "tricks", 3],
	"tricks4": ["Land 4 tricks", "tricks", 4],
	"no_hover": ["Never drop into Emergency Hover", "hover_count", 0],
	"purple2": ["Fire 2 purple drift boosts", "purple", 2],
	"purple3": ["Fire 3 purple drift boosts", "purple", 3],
	"hits2": ["Hit rivals 2 times with items", "hits", 2],
	"hits3": ["Hit rivals 3 times with items", "hits", 3],
	"shard1": ["Grab a Star Shard", "shards", 1],
	"slip3": ["Slipstream 3 times", "slips", 3],
	"shortcut": ["Take the hidden shortcut", "shortcuts", 1],
	"lead_lap": ["Lead a whole lap", "lead_laps", 1],
	"margin2": ["Win by 2 seconds or more", "margin", 2],
}

# AI speed class per cup / difficulty (multiplier on AI top speed and skill).
const AI_CLASSES := [
	{"name": "Cadet", "speed": 0.90, "skill": 0.55},
	{"name": "Pilot", "speed": 0.95, "skill": 0.70},
	{"name": "Ace", "speed": 0.99, "skill": 0.85},
	{"name": "Legend", "speed": 1.02, "skill": 0.95},
]

# Stardust payout by finishing place.
const PLACE_REWARD := [300, 220, 170, 130, 100, 80, 65, 50]

# ---------------------------------------------------------------- cosmetics
const PAINTS := [
	{"id": "stock", "name": "Factory", "price": 0, "color": Color(0, 0, 0, 0)},
	{"id": "chrome", "name": "Chrome", "price": 200, "color": Color(0.88, 0.9, 0.95)},
	{"id": "cherry", "name": "Cherry", "price": 200, "color": Color(0.9, 0.15, 0.25)},
	{"id": "tangerine", "name": "Tangerine", "price": 200, "color": Color(1.0, 0.55, 0.1)},
	{"id": "lemon", "name": "Lemon", "price": 200, "color": Color(1.0, 0.88, 0.2)},
	{"id": "lime", "name": "Alien Lime", "price": 250, "color": Color(0.5, 0.95, 0.25)},
	{"id": "teal", "name": "Deep Teal", "price": 250, "color": Color(0.1, 0.6, 0.6)},
	{"id": "cobalt", "name": "Cobalt", "price": 250, "color": Color(0.15, 0.3, 0.9)},
	{"id": "grape", "name": "Grape", "price": 300, "color": Color(0.5, 0.2, 0.8)},
	{"id": "bubblegum", "name": "Bubblegum", "price": 300, "color": Color(1.0, 0.5, 0.8)},
	{"id": "midnight", "name": "Midnight", "price": 400, "color": Color(0.08, 0.08, 0.14)},
	{"id": "gold", "name": "Solid Gold", "price": 900, "color": Color(1.0, 0.78, 0.25)},
]
const DECALS := [
	{"id": "none", "name": "Plain", "price": 0},
	{"id": "stripes", "name": "Racing Stripes", "price": 300},
	{"id": "checker", "name": "Checker Rim", "price": 350},
	{"id": "flames", "name": "Comet Flames", "price": 450},
	{"id": "stars", "name": "Starfield", "price": 450},
	{"id": "zigzag", "name": "Zap Zigzag", "price": 500},
]
const DOMES := [
	{"id": "clear", "name": "Clear", "price": 0, "color": Color(0.7, 0.95, 1.0, 0.35)},
	{"id": "mint", "name": "Mint", "price": 200, "color": Color(0.5, 1.0, 0.75, 0.45)},
	{"id": "rose", "name": "Rose", "price": 200, "color": Color(1.0, 0.55, 0.75, 0.45)},
	{"id": "amber", "name": "Amber", "price": 250, "color": Color(1.0, 0.75, 0.3, 0.5)},
	{"id": "smoke", "name": "Smoke", "price": 300, "color": Color(0.2, 0.2, 0.25, 0.7)},
	{"id": "rainbow", "name": "Prism", "price": 600, "color": Color(0.8, 0.6, 1.0, 0.5)},
]
const TRAILS := [
	{"id": "cyan", "name": "Ion Cyan", "price": 0, "color": Color(0.3, 0.9, 1.0)},
	{"id": "pink", "name": "Plasma Pink", "price": 250, "color": Color(1.0, 0.35, 0.8)},
	{"id": "green", "name": "Toxic Green", "price": 250, "color": Color(0.4, 1.0, 0.3)},
	{"id": "gold", "name": "Gold Dust", "price": 400, "color": Color(1.0, 0.8, 0.3)},
	{"id": "white", "name": "Starlight", "price": 400, "color": Color(1.0, 1.0, 1.0)},
	{"id": "rainbow", "name": "Rainbow", "price": 800, "color": Color(1.0, 0.4, 0.4)},
]

static func find(list: Array, id: String) -> Dictionary:
	for e in list:
		if e.id == id:
			return e
	return list[0]
