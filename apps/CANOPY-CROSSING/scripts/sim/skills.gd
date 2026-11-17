class_name Skills
extends RefCounted
## Skill levels: each animal's signature ability levels up (1..max) with
## Berries. The rules in content/skills.json scale the ability modules'
## parameters (shorter cooldowns, longer durations, more distance or
## charges). Pure functions for the sim; the level itself lives in the save.


static func max_level() -> int:
	return int(Content.skills.get("max_level", 5))


static func level_of(animal_id: String) -> int:
	return clampi(int(Save.data.get("skill_levels", {}).get(animal_id, 1)), 1, max_level())


## Berries to go from `level` to the next one (0 at max).
static func next_cost(level: int) -> int:
	if level >= max_level():
		return 0
	return int(Content.skills.get("cost", {}).get(str(level + 1), 0))


## One ability module's parameters at a skill level.
static func scaled(params: Dictionary, level: int) -> Dictionary:
	if level <= 1:
		return params
	var out := params.duplicate(true)
	var rules: Dictionary = Content.skills.get("rules", {})
	for key in params:
		if not rules.has(key):
			continue
		var v = params[key]
		if typeof(v) != TYPE_FLOAT and typeof(v) != TYPE_INT:
			continue
		out[key] = _apply(rules[key], float(v), level, typeof(v) == TYPE_INT)
	return out


static func _apply(rule: Dictionary, base: float, level: int, whole: bool) -> Variant:
	var v := base
	if rule.has("skip_above") and base > float(rule.skip_above):
		return int(base) if whole else base
	if rule.has("mul"):
		var f := 1.0 + float(rule.mul) * (level - 1)
		if rule.has("min"):
			f = maxf(f, float(rule.min))
		v = base * f
	if rule.has("add_at"):
		for at in rule.add_at:
			if level >= int(at):
				v += float(rule.add_at[at])
	if rule.has("add_per"):
		v += float(rule.add_per) * (level - 1)
		if rule.has("max"):
			v = minf(v, float(rule.max))
	if whole:
		return int(roundf(v))
	return snappedf(v, 0.01)


## What the next level changes, for the upgrade button: ["Cooldown 3.5s -> 3.2s", ...].
static func describe_next(animal: Dictionary, level: int) -> Array[String]:
	var out: Array[String] = []
	if level >= max_level():
		return out
	var rules: Dictionary = Content.skills.get("rules", {})
	for m in animal.get("ability", {}).get("modules", []):
		var now := scaled(m, level)
		var nxt := scaled(m, level + 1)
		for key in nxt:
			if rules.has(key) and str(now[key]) != str(nxt[key]):
				var r: Dictionary = rules[key]
				var unit := String(r.get("unit", ""))
				out.append("%s %s%s → %s%s" % [String(r.get("label", key)), _fmt(now[key]), unit, _fmt(nxt[key]), unit])
	return out


static func _fmt(v) -> String:
	if typeof(v) == TYPE_INT:
		return str(v)
	return ("%.2f" % float(v)).rstrip("0").rstrip(".")


## Spend Berries to raise an owned animal's skill one level.
static func upgrade(animal_id: String) -> bool:
	var lvl := level_of(animal_id)
	var cost := next_cost(lvl)
	if cost <= 0 or not Save.owns_animal(animal_id):
		return false
	if not Economy.spend({"berries": cost}, "skill_upgrade"):
		return false
	if not Save.data.has("skill_levels"):
		Save.data["skill_levels"] = {}
	Save.data.skill_levels[animal_id] = lvl + 1
	Save.mark()
	Analytics.event("skill_upgrade", {"animal": animal_id, "level": lvl + 1, "berries": cost})
	return true
