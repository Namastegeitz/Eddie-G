class_name AddOns
## Add-ons bought with credits (earned in the mini maps) and loaded into the
## six chambers of your revolver. Open the revolver in play, turn it to a
## chamber, and fire to use it. Three kinds:
##   strength - Power Legs, Dash Burst, Ground Pound
##   defense  - Iron Shell, Spiky Armor, Shadow Cloak, Second Wind
##   tactics  - Smoke Bomb, Decoy Chirp, Flash Bead, Silk Grapple, Crumb Magnet
## Each has three levels: more uses per run and a stronger effect.

const CHAMBERS := 6
const MAX_LEVEL := 3
## Add-ons you start with (already in the first two chambers).
const STARTERS: Array[StringName] = [&"decoy_chirp", &"iron_shell"]

## id -> [name, kind, price, blurb, colour]
const DEFS := {
	&"power_legs": ["Power Legs", "strength", 30, "Jump twice as high and climb fast", Color(1.0, 0.55, 0.2)],
	&"dash_burst": ["Dash Burst", "strength", 35, "A long untouchable dash, then a burst of speed", Color(1.0, 0.45, 0.15)],
	&"ground_pound": ["Ground Pound", "strength", 50, "Stomp: stuns pets and the vacuum nearby", Color(0.95, 0.35, 0.15)],
	&"iron_shell": ["Iron Shell", "defense", 30, "Nothing can hurt you for a while", Color(0.4, 0.7, 1.0)],
	&"spiky_armor": ["Spiky Armor", "defense", 40, "Blocks the next hits and stuns whoever struck", Color(0.3, 0.55, 1.0)],
	&"shadow_cloak": ["Shadow Cloak", "defense", 35, "Almost invisible for a while", Color(0.55, 0.5, 1.0)],
	&"second_wind": ["Second Wind", "defense", 45, "One more hit of health, and every meter refilled", Color(0.35, 0.85, 1.0)],
	&"smoke_bomb": ["Smoke Bomb", "tactic", 30, "A cloud ahead: people and pets inside can't see", Color(0.6, 0.9, 0.4)],
	&"decoy_chirp": ["Decoy Chirp", "tactic", 25, "A noise where you look: threats go and check", Color(0.45, 0.9, 0.55)],
	&"flash_bead": ["Flash Bead", "tactic", 40, "Dazzles every person and pet close by", Color(0.95, 0.95, 0.45)],
	&"silk_grapple": ["Silk Grapple", "tactic", 45, "Zip to the spot you aim at", Color(0.75, 0.95, 0.9)],
	&"crumb_magnet": ["Crumb Magnet", "tactic", 35, "Pulls crumbs and gem shards to you", Color(0.5, 1.0, 0.7)],
}
const KIND_NAMES := {"strength": "Strength", "defense": "Defense", "tactic": "Tactics"}
const KIND_COLORS := {"strength": Color(1.0, 0.55, 0.2), "defense": Color(0.4, 0.7, 1.0), "tactic": Color(0.5, 0.95, 0.5)}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in DEFS.keys():
		out.append(k)
	return out


static func display_name(id: StringName) -> String:
	return String(DEFS[id][0]) if DEFS.has(id) else ""


static func kind(id: StringName) -> String:
	return String(DEFS[id][1]) if DEFS.has(id) else ""


static func blurb(id: StringName) -> String:
	return String(DEFS[id][3]) if DEFS.has(id) else ""


static func color(id: StringName) -> Color:
	return DEFS[id][4] if DEFS.has(id) else Color.WHITE


## Credits to buy (level 1) or to raise to `level`.
static func price(id: StringName, level: int) -> int:
	return int(DEFS[id][2]) * maxi(level, 1) if DEFS.has(id) else 0


## Uses per run at a level.
static func charges(level: int) -> int:
	return 1 + clampi(level, 1, MAX_LEVEL)


## Effect strength at a level (1.0, 1.25, 1.5).
static func power(level: int) -> float:
	return 1.0 + 0.25 * (clampi(level, 1, MAX_LEVEL) - 1)


static func icon(id: StringName) -> Texture2D:
	var p := "res://assets/icons/addons/%s.png" % id
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


## What a level does, for the Armory.
static func detail(id: StringName, level: int) -> String:
	var k := power(level)
	match id:
		&"power_legs":
			return "%d s of double jumps and fast climbing" % int(12 * k)
		&"dash_burst":
			return "A long dash, then %d s of Turbo" % int(8 * k)
		&"ground_pound":
			return "Stuns pets and the vacuum within %d for %d s" % [int(10 * k), int(3 * k)]
		&"iron_shell":
			return "%d s of nothing hurting you" % int(6 * k)
		&"spiky_armor":
			return "Blocks the next %d hits within 20 s" % clampi(level, 1, 3)
		&"shadow_cloak":
			return "%d s almost invisible" % int(8 * k)
		&"second_wind":
			return "+1 hit of health, meters full%s" % (", 6 s Iron Shell" if level >= 3 else "")
		&"smoke_bomb":
			return "A %d-wide cloud for %d s" % [int(16 * k), int(6 * k)]
		&"decoy_chirp":
			return "A loud decoy that lasts %d s" % int(6 * k)
		&"flash_bead":
			return "Dazzles threats within %d for %d s" % [int(12 * k), int(3 * k)]
		&"silk_grapple":
			return "Zips up to %d away" % int(28 * k)
		&"crumb_magnet":
			return "%d s pulling crumbs and shards within %d" % [int(8 * k), int(30 * k)]
	return ""


## Fires an add-on for the bug. Returns false (with a hint) if it can't be
## used right now (nothing to grapple to, a flyer already in the air...).
static func use(id: StringName, level: int, bug: BugBase) -> bool:
	if bug == null or bug.dead:
		return false
	var k := power(level)
	var lvl := Level.current
	match id:
		&"power_legs":
			bug.add_effect(&"spring", 12.0 * k, 1.9)
			bug.add_effect(&"grip", 12.0 * k, 1.6)
		&"dash_burst":
			bug.power_dash(0.45, 1.35)
			bug.add_effect(&"turbo", 8.0 * k, 1.5)
		&"ground_pound":
			var n := 0
			for t in PerceptionSystem.threats:
				if t.present and not t is Human and t.global_position.distance_to(bug.global_position) <= 10.0 * k:
					t.stun(3.0 * k)
					n += 1
			for p in bug.get_tree().get_nodes_in_group(Phys.GROUP_PROP):
				var pp := p as PhysicsProp
				if pp and pp.global_position.distance_to(bug.global_position) < 8.0 * k:
					pp.freeze = false
					pp.apply_central_impulse((pp.global_position - bug.global_position).normalized() * 4.0 * pp.mass + Vector3.UP * 3.0 * pp.mass)
			Feedback.rumble(0.8, 0.3)
			AudioManager.play(&"thud", 2.0, 0.6)
			bug.show_hint("Ground Pound! %d stunned" % n)
			return true
		&"iron_shell":
			bug.add_effect(&"iron_shell", 6.0 * k, 1.0)
		&"spiky_armor":
			bug.add_effect(&"spikes", 20.0, float(clampi(level, 1, 3)))
		&"shadow_cloak":
			bug.add_effect(&"cloak", 8.0 * k, 0.2)
		&"second_wind":
			bug.heal(1)
			bug.refill()
			if level >= 3:
				bug.add_effect(&"iron_shell", 6.0, 1.0)
		&"smoke_bomb":
			var c := StinkCloud.new()
			c.radius = 8.0 * k
			c.time_left = 6.0 * k
			c.smoke = true
			var parent: Node = lvl if lvl else bug.get_parent()
			parent.add_child(c)
			c.global_position = bug.aim_point(10.0)
			AudioManager.play(&"hiss", -2.0, 1.2)
		&"decoy_chirp":
			var d := DecoyEcho.new()
			d.time_left = 6.0 * k
			d.loudness = 3.0
			var dparent: Node = lvl if lvl else bug.get_parent()
			dparent.add_child(d)
			d.global_position = bug.aim_point(18.0)
			AudioManager.play_at(&"chirp", d.global_position, 4.0)
		&"flash_bead":
			var hit := 0
			for t in PerceptionSystem.threats:
				if t.present and t.eye_position().distance_to(bug.global_position) <= 12.0 * k:
					t.dazzle(3.0 * k)
					hit += 1
			AudioManager.play(&"gem", -2.0, 1.8)
			bug.show_hint("Flash! %d dazzled" % hit)
			return true
		&"silk_grapple":
			if not bug.grapple(28.0 * k):
				bug.show_hint("Nothing in reach to grapple")
				return false
		&"crumb_magnet":
			bug.add_effect(&"magnet", 8.0 * k, 30.0 * k)
	bug.show_hint("%s!" % display_name(id))
	return true
