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

# ---------------------------------------------------------------- spacecraft
# Stats are 1-10. Upgrades add 0.5 per level (5 levels) on top.
# price is in Race Credits; stars is the star count needed to buy.
# Premium craft also carry a store product id (real-money layer, off in v1)
# and a perk. Behaviour lives in each entry's "effects" (scripts/data/effects.gd);
# content packs (autoload/content.gd) can append more craft and pilots.
static var SAUCERS: Array = [
	{"id": "classic", "name": "Classic Saucer", "blurb": "The all-rounder. Easy to fly, hard to beat.",
	 "speed": 5, "accel": 5, "handling": 5, "efficiency": 5, "weight": 5,
	 "price": 0, "stars": 0, "shape": "classic", "paint": Color(0.80, 0.84, 0.92)},
	{"id": "bubble", "name": "Bubble Pod", "blurb": "Big glass dome, nimble and quick off the line.",
	 "speed": 4, "accel": 6, "handling": 7, "efficiency": 5, "weight": 3,
	 "price": 0, "stars": 0, "shape": "bubble", "paint": Color(1.0, 0.55, 0.75)},
	{"id": "rocket", "name": "Rocket Fin", "blurb": "Twin fins, huge top speed, wide turns.",
	 "speed": 8, "accel": 4, "handling": 3, "efficiency": 4, "weight": 5,
	 "price": 2000, "stars": 6, "shape": "rocket", "paint": Color(0.95, 0.30, 0.25)},
	{"id": "ring", "name": "Ring Racer", "blurb": "Spinning outer ring for instant acceleration.",
	 "speed": 5, "accel": 8, "handling": 5, "efficiency": 4, "weight": 4,
	 "price": 2500, "stars": 10, "shape": "ring", "paint": Color(0.30, 0.85, 0.55)},
	{"id": "orb", "name": "Orb Drone", "blurb": "A probe-like sphere ringed by gyroscopes. Turns on a dime.",
	 "speed": 5, "accel": 6, "handling": 8, "efficiency": 5, "weight": 3,
	 "price": 3000, "stars": 14, "shape": "orb", "paint": Color(0.75, 0.78, 0.85)},
	{"id": "manta", "name": "Manta", "blurb": "Flat wing that loves to drift. Drift charge +15%.",
	 "speed": 6, "accel": 5, "handling": 8, "efficiency": 4, "weight": 4,
	 "price": 3500, "stars": 18, "shape": "manta", "paint": Color(0.25, 0.45, 0.95), "effects": {"drift_charge_pct": 15}},
	{"id": "crystal", "name": "Crystal Shard", "blurb": "Grown, not built: a faceted crystal ship that cuts through the air.",
	 "speed": 7, "accel": 5, "handling": 5, "efficiency": 6, "weight": 4,
	 "price": 4000, "stars": 22, "shape": "crystal", "paint": Color(0.55, 0.9, 1.0)},
	{"id": "bioship", "name": "Bio-Ship", "blurb": "A living craft with trailing tendrils. Heals its core slowly.",
	 "speed": 6, "accel": 6, "handling": 6, "efficiency": 7, "weight": 5,
	 "price": 4500, "stars": 26, "shape": "bioship", "paint": Color(0.55, 0.85, 0.35), "effects": {"regen": 0.4}},
	{"id": "mothership", "name": "Mothership Jr", "blurb": "Heavy, sips energy, shoves rivals aside.",
	 "speed": 6, "accel": 4, "handling": 4, "efficiency": 9, "weight": 9,
	 "price": 5000, "stars": 30, "shape": "mothership", "paint": Color(0.55, 0.50, 0.70)},
	{"id": "arrow", "name": "Arrowhead Interceptor", "blurb": "A sharp alien interceptor. Fast, light, twitchy.",
	 "speed": 8, "accel": 6, "handling": 6, "efficiency": 4, "weight": 3,
	 "price": 6000, "stars": 34, "shape": "arrow", "paint": Color(0.95, 0.75, 0.2)},
	{"id": "sail", "name": "Solar Sail Yacht", "blurb": "PREMIUM. Shimmering sails drink starlight: boosting recharges your core.",
	 "speed": 7, "accel": 7, "handling": 7, "efficiency": 7, "weight": 4,
	 "price": 12000, "stars": 12, "shape": "sail", "paint": Color(0.95, 0.85, 0.55), "premium": true,
	 "perk": "solar", "effects": {"boost_energy": 2.5}, "perk_text": "Boosting recharges your Dark Matter core.", "product": "craft_sail"},
	{"id": "phantom", "name": "Pulsar Phantom", "blurb": "PREMIUM. Half here, half elsewhere: spin-outs end 30% sooner.",
	 "speed": 8, "accel": 7, "handling": 6, "efficiency": 6, "weight": 5,
	 "price": 15000, "stars": 20, "shape": "phantom", "paint": Color(0.6, 0.4, 1.0), "premium": true,
	 "perk": "phase", "effects": {"spin_time_pct": -30}, "perk_text": "Spin-outs from hits end 30% sooner.", "product": "craft_phantom"},
	{"id": "dragon", "name": "Quasar Dragon", "blurb": "PREMIUM. A serpent of light. Drift boosts last 25% longer.",
	 "speed": 8, "accel": 6, "handling": 8, "efficiency": 5, "weight": 6,
	 "price": 18000, "stars": 28, "shape": "dragon", "paint": Color(1.0, 0.35, 0.3), "premium": true,
	 "perk": "dragonfire", "effects": {"drift_boost_pct": 25}, "perk_text": "Drift boosts last 25% longer.", "product": "craft_dragon"},
	{"id": "dyson", "name": "Dyson Racer", "blurb": "PREMIUM. A captured star in a ring of panels. Pods refill 50% more.",
	 "speed": 7, "accel": 8, "handling": 7, "efficiency": 8, "weight": 7,
	 "price": 22000, "stars": 36, "shape": "dyson", "paint": Color(1.0, 0.7, 0.2), "premium": true,
	 "perk": "starcore", "effects": {"pod_pct": 50}, "perk_text": "Energy Pods refill 50% more.", "product": "craft_dyson"},
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
static var PILOTS: Array = [
	{"id": "zib", "name": "Zib", "color": Color(0.45, 0.95, 0.35), "eyes": 2,
	 "effects": {"drift_charge_pct": 25}, "passive": "drift", "passive_name": "Drift Ace", "passive_text": "Drifts charge Plasma Boost 25% faster.",
	 "style": "clean", "unlock": "start", "home": "ceres"},
	{"id": "nova", "name": "Nova Quark", "color": Color(0.35, 0.85, 1.0), "eyes": 2,
	 "effects": {"start_item": "shield"}, "passive": "shield_start", "passive_name": "Shield Start", "passive_text": "Starts every race holding an Ion Shield.",
	 "style": "clean", "unlock": "start", "home": "saturn_rings"},
	{"id": "gloop", "name": "Gloop", "color": Color(0.75, 0.40, 1.0), "eyes": 1,
	 "effects": {"drain_pct": -25}, "passive": "efficient", "passive_name": "Slow Burner", "passive_text": "Dark Matter core drains 25% slower.",
	 "style": "hoarder", "unlock": "boss", "stars": 3, "home": "trappist1e"},
	{"id": "krell", "name": "Captain Krell", "color": Color(0.95, 0.45, 0.20), "eyes": 4,
	 "effects": {"weight_add": 4, "bump_pct": 60}, "passive": "bumper", "passive_name": "Bumper", "passive_text": "Bumps shove rivals 60% harder; you barely budge.",
	 "style": "aggressive", "unlock": "boss", "stars": 7, "home": "io"},
	{"id": "vexa", "name": "Vexa Starling", "color": Color(1.0, 0.35, 0.65), "eyes": 2,
	 "effects": {"crate_luck": 2}, "passive": "lucky", "passive_name": "Lucky Crates", "passive_text": "Crates roll as if you were two places further back.",
	 "style": "hoarder", "unlock": "boss", "stars": 12, "home": "proxima_station"},
	{"id": "bleep", "name": "Bleep-0", "color": Color(0.80, 0.82, 0.88), "eyes": 1,
	 "effects": {"pod_magnet_pct": 200}, "passive": "magnet", "passive_name": "Pod Magnet", "passive_text": "Energy Pods fly to you from three times farther.",
	 "style": "clean", "unlock": "boss", "stars": 18, "home": "trappist1h"},
	{"id": "zorba", "name": "Mama Zorba", "color": Color(1.0, 0.82, 0.25), "eyes": 3,
	 "effects": {"trick_pct": 100}, "passive": "tricks", "passive_name": "Trick Queen", "passive_text": "Landed tricks give double boost and energy.",
	 "style": "aggressive", "unlock": "boss", "stars": 25, "home": "kepler16b"},
	{"id": "comet", "name": "Comet the Space Pup", "color": Color(0.85, 0.65, 0.45), "eyes": 2,
	 "effects": {"slip_charge_pct": 100}, "passive": "draft", "passive_name": "Draft Hound", "passive_text": "Slipstream charges twice as fast.",
	 "style": "aggressive", "unlock": "boss", "stars": 33, "home": "alpha_cen"},
	# The creatures: mystical things from the dark between the stars. They
	# race amongst the field from the start; some fly for you right away,
	# some are bought with Race Credits, the rest must be beaten 1-on-1.
	{"id": "imp", "name": "Ember Imp", "color": Color(1.0, 0.40, 0.18), "eyes": 2, "kind": "creature",
	 "effects": {"boost_time_pct": 20}, "passive": "hot_core", "passive_name": "Hot Core", "passive_text": "Every boost burns 20% longer.",
	 "style": "aggressive", "unlock": "start", "home": "io",
	 "blurb": "Hatched in a lava vent on Io. Cackles at every corner."},
	{"id": "moth", "name": "Moon Moth", "color": Color(0.93, 0.88, 0.72), "eyes": 2, "kind": "creature",
	 "effects": {"glide_sink_pct": -35}, "passive": "light_wings", "passive_name": "Light Wings", "passive_text": "Glides sink 35% slower.",
	 "style": "clean", "unlock": "start", "home": "trappist1h",
	 "blurb": "Drawn to any bright light. Especially the finish line."},
	{"id": "seer", "name": "Crystal Seer", "color": Color(0.72, 0.88, 1.0), "eyes": 3, "kind": "creature",
	 "effects": {"near_energy_pct": 200}, "passive": "foresight", "passive_name": "Foresight", "passive_text": "Near misses give triple Dark Matter.",
	 "style": "clean", "unlock": "credits", "price": 600, "home": "cancri_e",
	 "blurb": "Grew in the diamond rain of 55 Cancri e. Sees the gap before it opens."},
	{"id": "squid", "name": "Abyss Squid", "color": Color(0.42, 0.28, 0.68), "eyes": 2, "kind": "creature",
	 "effects": {"low_grip_pct": 35}, "passive": "grip", "passive_name": "Tentacle Grip", "passive_text": "Ice and dust grip 35% better.",
	 "style": "hoarder", "unlock": "credits", "price": 900, "home": "trappist1e",
	 "blurb": "From the ocean under the ice of TRAPPIST-1e. Never lets go."},
	{"id": "jelly", "name": "Star Jelly", "color": Color(0.55, 0.85, 1.0), "eyes": 2, "kind": "creature",
	 "effects": {"regen": 0.5}, "passive": "glow_core", "passive_name": "Glow Core", "passive_text": "The Dark Matter core slowly refills itself.",
	 "style": "hoarder", "unlock": "credits", "price": 1200, "home": "wasp76b",
	 "blurb": "A drifting bell of light that fell from a nebula. Hums when happy."},
	{"id": "wraith", "name": "Void Wraith", "color": Color(0.62, 0.70, 0.92), "eyes": 2, "kind": "creature",
	 "effects": {"spin_time_pct": -40}, "passive": "phase", "passive_name": "Phase Walker", "passive_text": "Spin-outs end 40% sooner.",
	 "style": "clean", "unlock": "boss", "stars": 10, "home": "trappist1b",
	 "blurb": "Half here, half somewhere else. Hits barely find it."},
	{"id": "troll", "name": "Bog Troll", "color": Color(0.42, 0.58, 0.32), "eyes": 2, "kind": "creature",
	 "effects": {"rough_pct": -50}, "passive": "moss_born", "passive_name": "Moss Born", "passive_text": "Dust, moss and lava slow you half as much.",
	 "style": "aggressive", "unlock": "boss", "stars": 20, "home": "hd189733b",
	 "blurb": "Dug out of a swamp moon. Smells like it. Drives like a landslide."},
	{"id": "hive", "name": "Hive Mind", "color": Color(0.52, 0.56, 0.30), "eyes": 4, "kind": "creature",
	 "effects": {"slip_range_pct": 100}, "passive": "swarm", "passive_name": "Swarm Sense", "passive_text": "Slipstreams reach twice as far.",
	 "style": "aggressive", "unlock": "boss", "stars": 30, "home": "proxima_b",
	 "blurb": "A thousand minds in one helmet. They all want to win."},
]

static func pilot(id: String) -> Dictionary:
	for p in PILOTS:
		if p.id == id:
			return p
	return PILOTS[0]


static func has_pilot_id(id: String) -> bool:
	for p in PILOTS:
		if p.id == id:
			return true
	return false


## One line on how a pilot is unlocked (unlock kinds: start, credits, boss).
static func pilot_unlock_text(p: Dictionary) -> String:
	match String(p.get("unlock", "boss")):
		"start":
			return "Flies for you from the start"
		"credits":
			return "Unlock for %d Race Credits" % int(p.get("price", 0))
	return "Beat them in a Boss Race (needs %d stars)" % int(p.get("stars", 0))

# ---------------------------------------------------------------- items
const ITEMS := {
	"rocket": {"name": "Homing Rocket", "color": Color(1.0, 0.45, 0.25), "kind": "Attack", "text": "Locks onto the racer just ahead and chases them down."},
	"laser": {"name": "Pulse Laser", "color": Color(0.3, 1.0, 0.95), "kind": "Attack", "text": "An instant beam that hits everything in a line ahead of you. Clears mines too."},
	"comet": {"name": "Comet Strike", "color": Color(0.6, 0.85, 1.0), "kind": "Attack", "text": "A comet falls on the leader. Only for racers well behind."},
	"emp": {"name": "EMP Shockwave", "color": Color(1.0, 0.95, 0.35), "kind": "Attack", "text": "Spins out everyone close around you and knocks their items loose."},
	"nitro": {"name": "Nitro Rocket", "color": Color(1.0, 0.3, 0.75), "kind": "Speed", "text": "Strap-on rocket boost, 1-3 uses: more the further back you are."},
	"shield": {"name": "Ion Shield", "color": Color(0.35, 0.7, 1.0), "kind": "Defence", "text": "Use it to block every hit for 6 s, or just hold it to stop one hit."},
	"mine": {"name": "Gravity Mine", "color": Color(1.0, 0.8, 0.2), "kind": "Trap", "text": "Drop it behind you. Whoever flies into it spins out."},
	"tractor": {"name": "Tractor Beam", "color": Color(0.45, 1.0, 0.45), "kind": "Attack", "text": "Drags the racer ahead back toward you and gives you a small boost."},
	"warp": {"name": "Warp Jump", "color": Color(0.6, 0.45, 1.0), "kind": "Speed", "text": "Jumps you 40-80 m ahead along the track in a flash: the further back you are, the further it takes you."},
	"decoy": {"name": "Decoy Drone", "color": Color(0.6, 0.95, 1.0), "kind": "Defence", "text": "A hologram of you trails behind for 8 s. Homing rockets and tractor beams go for it instead of you."},
	"leech": {"name": "Energy Leech", "color": Color(0.72, 0.3, 1.0), "kind": "Attack", "text": "For 5 s, drains Dark Matter from every racer near you into your own core."},
	"well": {"name": "Gravity Well", "color": Color(0.5, 0.3, 0.9), "kind": "Trap", "text": "Drops a vortex behind you for 7 s that drags racers toward its centre and slows them."},
	"frost": {"name": "Frost Trail", "color": Color(0.75, 0.95, 1.0), "kind": "Trap", "text": "Lays comet ice behind you for 4 s. Anyone who drives onto it slides."},
	"overcharge": {"name": "Overcharge", "color": Color(1.0, 0.6, 0.15), "kind": "Speed", "text": "Burns 60% of your core for a boost: the fuller the core, the longer it lasts (up to 3 s)."},
	"flare": {"name": "Solar Flare", "color": Color(1.0, 0.95, 0.6), "kind": "Attack", "text": "A blinding burst: every racer ahead of you within 70 m sees nothing but white for 2 s."},
	"chain": {"name": "Chain Lightning", "color": Color(0.6, 0.9, 1.0), "kind": "Attack", "text": "A bolt leaps to the racer ahead, then jumps on to the next two within reach."},
	"plasma": {"name": "Plasma Wall", "color": Color(1.0, 0.3, 0.75), "kind": "Trap", "text": "Raises a glowing wall across half the road behind you for 6 s. Racers bounce off it; it shatters after three hits or a laser."},
	"stasis": {"name": "Stasis Field", "color": Color(0.3, 0.95, 0.85), "kind": "Attack", "text": "For 3 s every racer within 22 m of you is held at little more than half speed."},
	"cloak": {"name": "Phase Cloak", "color": Color(0.8, 0.7, 1.0), "kind": "Defence", "text": "5 s out of phase: nothing can lock on, hit or slow you, and you pass through traps and other racers."},
	"repulsor": {"name": "Repulsor Pulse", "color": Color(1.0, 0.45, 0.2), "kind": "Attack", "text": "Shoves every racer within 12 m away from you, hard. Great in a crowd or next to a wall."},
}

# Five power-up lineups by race position: what each place can roll from a
# crate. The further back you are, the stronger the comeback items.
const LINEUPS := [
	{"name": "Leader", "places": "1st", "odds": {"shield": 16, "decoy": 14, "frost": 12, "plasma": 12, "well": 10, "mine": 10, "cloak": 8, "laser": 6, "overcharge": 6, "stasis": 6}, "nitro": 1},
	{"name": "Front pack", "places": "2nd-3rd", "odds": {"rocket": 12, "decoy": 10, "plasma": 10, "frost": 8, "well": 8, "shield": 8, "cloak": 8, "stasis": 8, "laser": 8, "tractor": 6, "leech": 6, "repulsor": 4, "overcharge": 4}, "nitro": 1},
	{"name": "Midfield", "places": "4th-5th", "odds": {"rocket": 12, "leech": 10, "tractor": 10, "nitro": 10, "chain": 10, "flare": 8, "warp": 8, "laser": 6, "emp": 6, "stasis": 6, "repulsor": 6, "cloak": 4, "overcharge": 4}, "nitro": 2},
	{"name": "Chasers", "places": "6th-7th", "odds": {"nitro": 14, "warp": 14, "chain": 12, "flare": 10, "rocket": 10, "emp": 10, "leech": 8, "tractor": 6, "comet": 6, "overcharge": 6, "repulsor": 4}, "nitro": 2},
	{"name": "Last place", "places": "last", "odds": {"warp": 20, "nitro": 18, "comet": 14, "chain": 12, "flare": 10, "emp": 10, "leech": 6, "overcharge": 6, "rocket": 4}, "nitro": 3},
]

## Which lineup a place uses in a field of n racers.
static func lineup_for(place: int, n: int) -> int:
	if place <= 1:
		return 0
	if place >= n:
		return 4
	var f := float(place) / float(n)
	if f <= 0.375:
		return 1
	if f <= 0.625:
		return 2
	return 3

# ---------------------------------------------------------------- systems, tracks & cups
const TRACK_IDS := ["mars", "ceres", "io", "saturn_rings", "trappist1b", "trappist1e", "trappist1h",
	"proxima_b", "proxima_station", "alpha_cen", "hd189733b", "cancri_e", "kepler16b", "wasp76b"]
enum { V_NORMAL, V_REVERSE, V_MIRROR }
const VARIANT_NAMES := ["", "Reverse", "Mirror"]

const SYSTEMS := {
	"sol": {"name": "Our Solar System", "star": "The Sun (yellow dwarf)", "distance": "home",
		"text": "Eight planets around an ordinary yellow star. We've sent probes to every one of them."},
	"trappist1": {"name": "TRAPPIST-1", "star": "TRAPPIST-1 (ultracool red dwarf)", "distance": "about 40 light-years",
		"text": "Seven Earth-sized planets packed closer to their star than Mercury is to the Sun."},
	"alphacen": {"name": "Alpha Centauri", "star": "Alpha Centauri A & B + Proxima Centauri", "distance": "about 4.2-4.4 light-years",
		"text": "The nearest stars to the Sun: a pair of Sun-like stars and a small, flaring red dwarf."},
	"extremes": {"name": "Exoplanet Extremes", "star": "four different stars", "distance": "60 to 640 light-years",
		"text": "Some of the strangest worlds astronomers have measured: glass storms, lava oceans, two suns, iron rain."},
}

# Each race: [track id, variant, challenge id]
const CUPS := [
	{"id": "sol", "name": "Solar System Cup", "system": "sol", "stars": 0, "color": Color(1.0, 0.8, 0.35), "class": 0,
	 "races": [["mars", 0, "pods10"], ["ceres", 0, "tricks3"], ["io", 0, "no_hover"], ["saturn_rings", 0, "purple2"]]},
	{"id": "trappist1", "name": "TRAPPIST-1 Cup", "system": "trappist1", "stars": 8, "color": Color(1.0, 0.45, 0.3), "class": 1,
	 "races": [["trappist1b", 0, "hits2"], ["trappist1e", 0, "shortcut"], ["trappist1h", 0, "no_hover"]]},
	{"id": "alphacen", "name": "Alpha Centauri Cup", "system": "alphacen", "stars": 16, "color": Color(1.0, 0.9, 0.6), "class": 1,
	 "races": [["proxima_b", 0, "slip3"], ["proxima_station", 0, "tricks4"], ["alpha_cen", 0, "purple3"]]},
	{"id": "extremes", "name": "Exoplanet Extremes Cup", "system": "extremes", "stars": 24, "color": Color(0.35, 0.6, 1.0), "class": 2,
	 "races": [["hd189733b", 0, "no_hover"], ["cancri_e", 0, "hits3"], ["kepler16b", 0, "shortcut"], ["wasp76b", 0, "pods15"]]},
	{"id": "grand", "name": "Galactic Grand Prix", "system": "", "stars": 36, "color": Color(1.0, 0.35, 0.8), "class": 3,
	 "races": [["mars", 2, "lead_lap"], ["trappist1e", 1, "shard1"], ["alpha_cen", 2, "margin2"], ["hd189733b", 1, "purple3"]]},
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
# AI difficulty. band = [slow-down when ahead of you, catch-up when behind]:
# easier classes ease off more when leading and catch up less.
const AI_CLASSES := [
	{"name": "Cadet", "speed": 0.90, "skill": 0.55, "band": [0.08, 0.03]},
	{"name": "Pilot", "speed": 0.95, "skill": 0.70, "band": [0.06, 0.045]},
	{"name": "Ace", "speed": 0.99, "skill": 0.85, "band": [0.045, 0.055]},
	{"name": "Legend", "speed": 1.02, "skill": 0.95, "band": [0.03, 0.06]},
]

# Race Credits payout by finishing place.
const PLACE_REWARD := [400, 300, 230, 180, 140, 110, 90, 70]

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
