class_name Upgrades
extends RefCounted
## Super Upgrades & Technical Wonders: the rules over the save data.
##
## Save.data.wonders = {
##   "stardust": int, "earned": int,          # wallet and lifetime total
##   "tiers": {craft_id: 0..3},               # Wonder track: 0 none, 1 Prototype, 2 Refined, 3 Transcendent
##   "mods": [mod_id, ...],                   # owned mods (any craft can fit them)
##   "fit": {craft_id: {"core": id, "field": id, "drive": id}},
##   "overclock": {craft_id: level index},    # into Content.overclock.levels
##   "perks": [perk_id, ...]                  # global perks (from a Transcendent Wonder)
## }
## Data (Wonders, mods, sets, Stardust rules) comes from Content.

const TIER_NAMES := ["Not built", "Prototype", "Refined", "Transcendent"]


static func defaults() -> Dictionary:
	return {"stardust": 0, "earned": 0, "tiers": {}, "mods": [], "fit": {}, "overclock": {}, "perks": []}


static func st() -> Dictionary:
	if not Save.data.has("wonders") or not (Save.data.wonders is Dictionary):
		Save.data["wonders"] = defaults()
	var w: Dictionary = Save.data.wonders
	for k: String in defaults():
		if not w.has(k):
			w[k] = defaults()[k]
	return w


# ---------------------------------------------------------------- stardust
static func stardust() -> int:
	return int(st().stardust)


static func add_stardust(n: int) -> void:
	if n <= 0:
		return
	var w := st()
	w.stardust = int(w.stardust) + n
	w.earned = int(w.earned) + n
	Save.mark()


static func spend_stardust(n: int) -> bool:
	var w := st()
	if n < 0 or int(w.stardust) < n:
		return false
	w.stardust = int(w.stardust) - n
	Save.mark()
	return true


## Stardust for one finished drift. clean: no wall hit, spin-out or long
## jump during it. mult: the racer's stardust_pct multiplier.
static func drift_stardust(seconds: float, meters: float, tier: int, clean: bool, mult := 1.0) -> int:
	var rules: Dictionary = Content.stardust
	if not clean or seconds < float(rules.get("min_drift_time", 1.0)):
		return 0
	var bonus: Array = rules.get("tier_bonus", [1.0, 1.2, 1.45, 1.75])
	var raw := float(rules.get("per_second", 3.0)) * seconds + float(rules.get("per_meter", 0.025)) * meters
	return int(round(raw * float(bonus[clampi(tier, 0, bonus.size() - 1)]) * mult))


static func finish_bonus(place: int) -> int:
	var fb: Array = Content.stardust.get("finish_bonus", [])
	if place < 1 or place > fb.size():
		return 0
	return int(fb[place - 1])


# ---------------------------------------------------------------- wonders
static func wonder(craft: String) -> Dictionary:
	return Content.wonder_for(craft)


static func tier(craft: String) -> int:
	return clampi(int(st().tiers.get(craft, 0)), 0, 3)


## Stardust for the next tier, or -1 when there is none.
static func next_cost(craft: String) -> int:
	var w := wonder(craft)
	var t := tier(craft)
	if w.is_empty() or t >= 3:
		return -1
	return int(w.tiers[t].cost)


static func buy_tier(craft: String) -> bool:
	var cost := next_cost(craft)
	if cost < 0 or not Save.has_saucer(craft) or not spend_stardust(cost):
		return false
	var t := tier(craft) + 1
	st().tiers[craft] = t
	if t == 3:
		var perk: Dictionary = wonder(craft).global_perk
		if not (perk.id in st().perks):
			st().perks.append(perk.id)
	Save.mark()
	return true


static func perks() -> Array:
	var out: Array = []
	var owned: Array = st().perks
	for w: Dictionary in Content.wonders:
		if w.global_perk.id in owned:
			out.append(w.global_perk)
	return out


# ---------------------------------------------------------------- overclock
static func levels() -> Array:
	return Content.overclock.get("levels", [{"pct": 100, "name": "Stock", "power": 1.0, "heat": 0.0}])


static func overclock(craft: String) -> int:
	return clampi(int(st().overclock.get(craft, 0)), 0, levels().size() - 1)


static func set_overclock(craft: String, lvl: int) -> void:
	st().overclock[craft] = clampi(lvl, 0, levels().size() - 1)
	Save.mark()


## Heat one activation adds at this craft's overclock (0 at Stock).
static func heat_per_use(craft: String, fx := {}) -> float:
	var w := wonder(craft)
	if w.is_empty():
		return 0.0
	var lv: Dictionary = levels()[overclock(craft)]
	return float(w.get("heat_per_use", 25)) * float(lv.heat) * Effects.mult(fx, "heat_pct")


# ---------------------------------------------------------------- mods
static func owns_mod(id: String) -> bool:
	return id in st().mods


static func buy_mod(id: String) -> bool:
	var m: Dictionary = Content.mod_by_id.get(id, {})
	if m.is_empty() or owns_mod(id) or not spend_stardust(int(m.cost)):
		return false
	st().mods.append(id)
	Save.mark()
	return true


static func fitted(craft: String) -> Dictionary:
	var f: Dictionary = st().fit.get(craft, {})
	var out := {}
	for s: Dictionary in Content.slots:
		var id := String(f.get(s.id, ""))
		out[s.id] = id if owns_mod(id) and Content.mod_by_id.has(id) else ""
	return out


## Fit an owned mod (or "" to empty the slot).
static func fit(craft: String, slot: String, mod_id: String) -> bool:
	if mod_id != "":
		var m: Dictionary = Content.mod_by_id.get(mod_id, {})
		if m.is_empty() or String(m.slot) != slot or not owns_mod(mod_id):
			return false
	var f: Dictionary = st().fit.get(craft, {})
	f[slot] = mod_id
	st().fit[craft] = f
	Save.mark()
	return true


## The set whose mods fill every slot of this craft, or {}.
static func set_bonus(craft: String) -> Dictionary:
	var f := fitted(craft)
	var set_id := ""
	for slot: String in f:
		var id: String = f[slot]
		if id == "":
			return {}
		var s := String(Content.mod_by_id[id].get("set", ""))
		if s == "" or (set_id != "" and s != set_id):
			return {}
		set_id = s
	return Content.set_by_id.get(set_id, {})


# ---------------------------------------------------------------- race kit
## Everything Super Upgrades add to one craft in a race:
## {"effects": {...}, "wonder": {"id", "craft", "tier", "overclock"} or absent}
static func kit_for(craft: String) -> Dictionary:
	var sources: Array = []
	var f := fitted(craft)
	for slot: String in f:
		if f[slot] != "":
			sources.append(Content.mod_by_id[f[slot]].effects)
	var sb := set_bonus(craft)
	if not sb.is_empty():
		sources.append(sb.effects)
	for p: Dictionary in perks():
		sources.append(p.effects)
	var t := tier(craft)
	var w := wonder(craft)
	var kit := {}
	if t > 0 and not w.is_empty():
		sources.append(w.tiers[t - 1].get("effects", {}))
		kit["wonder"] = {"id": w.id, "craft": craft, "tier": t, "overclock": overclock(craft)}
	kit["effects"] = Effects.sum(sources)
	return kit


## A summary line per craft for menus: "Refined · 2/3 mods · Void set".
static func summary(craft: String) -> String:
	var parts := PackedStringArray()
	if not wonder(craft).is_empty():
		parts.append(TIER_NAMES[tier(craft)])
	var n := 0
	var f := fitted(craft)
	for s: String in f:
		if f[s] != "":
			n += 1
	parts.append("%d/%d mods" % [n, f.size()])
	var sb := set_bonus(craft)
	if not sb.is_empty():
		parts.append("%s set" % sb.name)
	return "  ·  ".join(parts)
