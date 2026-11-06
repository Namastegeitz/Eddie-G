class_name PowerUps
## What bug food and crumb gems do when picked up. Timed effects are stored
## on the bug (BugBase.add_effect) and read by its movement, stealth and
## damage code; level-wide effects (freeze, calm, decoy) happen here.

const NAMES := {
	&"speed": "Sugar Rush", &"hearty": "Hearty", &"fresh": "Fresh Scent",
	&"soft_step": "Soft Step", &"wired": "Wired", &"big_meal": "Big Meal",
	&"cloak": "Shadow Cloak", &"freeze": "Time Freeze", &"calm": "Calm",
	&"iron_shell": "Iron Shell", &"magnet": "Crumb Magnet", &"decoy": "Echo Decoy",
	&"turbo": "Turbo", &"spring": "Spring Legs", &"radar": "Bug Radar", &"double": "Double Crumbs",
	&"shrink": "Shrink",
}


static func label(effect: StringName) -> String:
	return String(NAMES.get(effect, String(effect).capitalize()))


## Applies the item to the bug. Returns the line to show on screen.
static func apply(def: ItemDef, bug: BugBase) -> String:
	if def == null or bug == null:
		return ""
	if def.kind == ItemDef.Kind.TREASURE:
		Feedback.rumble(0.2 + 0.1 * def.rarity, 0.12)
		return "%s treasure: %s!" % [def.rarity_name(), def.display_name]
	match def.effect:
		&"speed":
			bug.add_effect(&"speed", def.duration, def.amount)
			bug.refill()
		&"hearty":
			bug.heal(int(maxf(def.amount, 1.0)))
		&"big_meal":
			if Level.current:
				Level.current.add_bonus_crumbs(int(def.amount))
		&"freeze":
			for t in PerceptionSystem.threats:
				if t.present:
					t.stun(def.duration, true)
			AudioManager.play(&"freeze")
		&"calm":
			bug.add_effect(&"calm", def.duration, def.amount)
			PerceptionSystem.calm_down()
		&"decoy":
			var d := DecoyEcho.new()
			d.time_left = def.duration
			d.loudness = def.amount
			var parent: Node = Level.current if Level.current else bug.get_parent()
			parent.add_child(d)
			d.global_position = bug.global_position
		&"iron_shell":
			bug.add_effect(&"iron_shell", def.duration, def.amount)
			AudioManager.play(&"shield", -4.0)
		_:
			bug.add_effect(def.effect, def.duration, def.amount)
	if def.kind != ItemDef.Kind.FOOD or def.duration > 0.0:
		AudioManager.play(&"powerup", -8.0)
	Feedback.rumble(0.25, 0.12)
	return "%s! %s" % [def.display_name, def.blurb]
