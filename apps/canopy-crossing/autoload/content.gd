extends Node
## Loads every content file and checks it. Animals, maps, hazards, lane
## generators, the store catalog, live ops, seasons and onboarding text all
## live under res://content; files under user://content (downloaded packs)
## are merged on top, so new content never needs a code change.

signal reloaded

const ROOTS := ["res://content", "user://content"]
const HAZARD_KINDS := ["mover", "platform", "surfacer", "striker", "swooper", "faller", "quicksand", "gap", "brush",
	"tide", "fire", "mudslide", "gust", "downpour"]
const GRANT_TYPES := ["flag", "amber", "berries", "animal", "animals", "map", "maps", "pass_premium", "item", "cosmetic"]

var animals := {}
var animal_order: Array[String] = []
var maps := {}
var map_order: Array[String] = []
var hazards := {}
var generators := {}
var rarities := {}
var collectibles := {}
var catalog := {}
var live_ops := {}
var daily_rewards := {}
var seasons := {}
var onboarding := {}
var settings_defaults := {}
var rules := {}                 # game rules (content/rules.json)
var skills := {}                # skill upgrade rules (content/skills.json)
var difficulty := {}            # difficulty tiers (content/difficulty.json)
var errors: PackedStringArray = []
var loaded_files := 0
var _items := {}


func _ready() -> void:
	reload()


func reload() -> void:
	animals.clear()
	maps.clear()
	hazards.clear()
	generators.clear()
	seasons.clear()
	errors.clear()
	loaded_files = 0
	for root in ROOTS:
		_load_dir(root + "/animals", animals)
		_load_dir(root + "/maps", maps)
		_load_dir(root + "/hazards", hazards)
		_load_dir(root + "/generators", generators)
		_load_dir(root + "/season", seasons)
	rarities = _load_one("rarities.json")
	collectibles = _load_one("collectibles.json")
	catalog = _load_one("store/catalog.json")
	live_ops = _load_one("store/live_ops.json")
	daily_rewards = _load_one("store/daily_rewards.json")
	onboarding = _load_one("onboarding.json")
	settings_defaults = _load_one("settings_defaults.json")
	rules = _load_one("rules.json")
	skills = _load_one("skills.json")
	difficulty = _load_one("difficulty.json")
	_items.clear()
	for it in collectibles.get("items", []):
		_items[String(it.id)] = it
	var bonus: Dictionary = collectibles.get("bonus", {})
	if not bonus.is_empty():
		_items[String(bonus.id)] = bonus
	_sort()
	_apply_tiers()
	validate()
	if not errors.is_empty():
		for e in errors:
			push_warning("content: " + e)
	reloaded.emit()


func _load_dir(path: String, into: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var files := DirAccess.get_files_at(path)
	for f in files:
		if not f.ends_with(".json"):
			continue
		var data = _parse(path + "/" + f)
		if typeof(data) != TYPE_DICTIONARY:
			continue
		if not data.has("id"):
			errors.append("%s/%s has no id" % [path, f])
			continue
		into[String(data.id)] = data
		loaded_files += 1


func _load_one(rel: String) -> Dictionary:
	var out := {}
	for root in ROOTS:
		var path: String = root + "/" + rel
		if FileAccess.file_exists(path):
			var data = _parse(path)
			if typeof(data) == TYPE_DICTIONARY:
				out.merge(data, true)
				loaded_files += 1
	return out


func _parse(path: String):
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		errors.append("cannot read " + path)
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		errors.append("%s: %s (line %d)" % [path, json.get_error_message(), json.get_error_line()])
		return null
	return json.data


func _sort() -> void:
	animal_order.clear()
	for id in animals:
		animal_order.append(String(id))
	animal_order.sort_custom(func(a, b): return int(animals[a].get("number", 999)) < int(animals[b].get("number", 999)))
	map_order.clear()
	for id in maps:
		map_order.append(String(id))
	map_order.sort_custom(func(a, b): return int(maps[a].get("order", 999)) < int(maps[b].get("order", 999)))


# ------------------------------------------------------------------ difficulty

## A map's difficulty tier ("easy", "medium", "hard", "expert"): its own
## "tier", else by its order on the globe (content/difficulty.json by_order).
func tier_of(m: Dictionary) -> String:
	if m.has("tier"):
		return String(m.tier)
	var order := int(m.get("order", 999))
	for r in difficulty.get("by_order", []):
		if order >= int(r[0]) and order <= int(r[1]):
			return String(r[2])
	return ""


func tier(id: String) -> Dictionary:
	return difficulty.get("tiers", {}).get(id, {})


## Fills each map's levels from its tier: length, difficulty range, canopy
## zones and star rating per level (rising from level 1 to level 10), and
## the map's hazard speed / density / band sizes / safe banks. Anything a
## map file sets itself is kept.
func _apply_tiers() -> void:
	var zones: Array = difficulty.get("zones", [1, 1, 1, 2, 2, 2, 3, 3, 3, 3])
	for id in maps:
		var m: Dictionary = maps[id]
		if m.get("status", "available") != "available":
			continue
		var tid := tier_of(m)
		var t := tier(tid)
		if t.is_empty():
			continue
		m["tier"] = tid
		var d: Dictionary = m.get("difficulty", {})
		var params: Dictionary = t.get("params", {})
		for k in params:
			if not d.has(k):
				d[k] = params[k]
		m["difficulty"] = d
		var stages: Array = m.get("stages", [])
		var rows: Array = t.get("rows", [40, 130])
		var dr: Array = t.get("difficulty", [[0.0, 0.2], [0.5, 0.9]])
		var cr: Array = t.get("canopy_rows", [[4, 6], [7, 11]])
		var stars: Array = t.get("stars", [1, 5])
		for i in stages.size():
			var st: Dictionary = stages[i]
			var k := float(i) / maxf(1.0, float(stages.size() - 1))
			if not st.has("rows"):
				st["rows"] = int(roundf(lerpf(float(rows[0]), float(rows[1]), k) / 5.0)) * 5
			if not st.has("difficulty"):
				st["difficulty"] = [snappedf(lerpf(float(dr[0][0]), float(dr[1][0]), k), 0.01), snappedf(lerpf(float(dr[0][1]), float(dr[1][1]), k), 0.01)]
			if not st.has("canopy"):
				st["canopy"] = {"zones": int(zones[mini(i, zones.size() - 1)]),
					"rows": [int(roundf(lerpf(float(cr[0][0]), float(cr[1][0]), k))), int(roundf(lerpf(float(cr[0][1]), float(cr[1][1]), k)))]}
			if not st.has("stars"):
				st["stars"] = int(roundf(lerpf(float(stars[0]), float(stars[1]), k)))


# ------------------------------------------------------------------ lookups

func animal(id: String) -> Dictionary:
	return animals.get(id, {})


func map(id: String) -> Dictionary:
	return maps.get(id, {})


func hazard(id: String) -> Dictionary:
	return hazards.get(id, {})


func collectible(id: String) -> Dictionary:
	return _items.get(id, {})


func playable_maps() -> Array[String]:
	var out: Array[String] = []
	for id in map_order:
		if maps[id].get("status", "available") == "available":
			out.append(id)
	return out


func starters() -> Array[String]:
	var out: Array[String] = []
	for id in animal_order:
		if animals[id].get("unlock", {}).get("type", "") == "free":
			out.append(id)
	return out


func product(id: String) -> Dictionary:
	for p in catalog.get("products", []):
		if p.id == id:
			return p
	return {}


func consumable(id: String) -> Dictionary:
	for c in catalog.get("consumables", []):
		if c.id == id:
			return c
	return {}


func cosmetic(id: String) -> Dictionary:
	for c in catalog.get("cosmetics", []):
		if c.id == id:
			return c
	return {}


## Animals matching a {"pack": ..., "region": ..., "unlock": ..., "rarity": ...} filter.
func animals_where(where: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id in animal_order:
		var a: Dictionary = animals[id]
		var ok := true
		for k in where:
			var v = a.get(k)
			if k == "unlock":
				v = a.get("unlock", {}).get("type", "")
			if String(v) != String(where[k]):
				ok = false
		if ok:
			out.append(id)
	return out


func maps_where(where: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id in playable_maps():
		var ok := true
		for k in where:
			if String(maps[id].get(k, "")) != String(where[k]):
				ok = false
		if ok:
			out.append(id)
	return out


func season(id: String) -> Dictionary:
	return seasons.get(id, {})


# ------------------------------------------------------------------ checks

func validate() -> void:
	var numbers := {}
	for id in animals:
		var a: Dictionary = animals[id]
		for key in ["name", "region", "rarity", "unlock", "ability", "look", "stats", "pack"]:
			if not a.has(key):
				errors.append("animal %s: missing %s" % [id, key])
		if not rarities.has(String(a.get("rarity", ""))):
			errors.append("animal %s: unknown rarity %s" % [id, a.get("rarity")])
		if not maps.has(String(a.get("region", ""))):
			errors.append("animal %s: unknown region %s" % [id, a.get("region")])
		for m in a.get("ability", {}).get("modules", []):
			if not Ability.exists(String(m.get("module", ""))):
				errors.append("animal %s: unknown ability module %s" % [id, m.get("module")])
		var n := int(a.get("number", 0))
		if numbers.has(n):
			errors.append("animal %s: number %d used twice" % [id, n])
		numbers[n] = true
		var u: Dictionary = a.get("unlock", {})
		if not String(u.get("type", "")) in ["free", "berries", "amber", "pack"]:
			errors.append("animal %s: bad unlock type" % id)
	for id in hazards:
		var h: Dictionary = hazards[id]
		if not String(h.get("kind", "")) in HAZARD_KINDS:
			errors.append("hazard %s: unknown kind %s" % [id, h.get("kind")])
	for id in maps:
		var m: Dictionary = maps[id]
		if m.get("status", "available") != "available":
			continue
		if not generators.has(String(m.get("generator", ""))):
			errors.append("map %s: unknown generator %s" % [id, m.get("generator")])
		for slot in m.get("hazards", {}):
			for entry in m.hazards[slot]:
				if not hazards.has(String(entry.get("id", ""))):
					errors.append("map %s: slot %s names unknown hazard %s" % [id, slot, entry.get("id")])
		for hid in m.get("intro_hazards", []):
			if not hazards.has(String(hid)):
				errors.append("map %s: intro names unknown hazard %s" % [id, hid])
		if m.get("stages", []).is_empty():
			errors.append("map %s: no stages" % id)
		if tier(tier_of(m)).is_empty():
			errors.append("map %s: unknown difficulty tier %s" % [id, tier_of(m)])
		for st in m.get("stages", []):
			if not st.has("rows") or not st.has("difficulty"):
				errors.append("map %s: level %s has no length or difficulty" % [id, st.get("name", "?")])
		for key in ["palette", "music", "facts", "difficulty", "lat", "lon"]:
			if not m.has(key):
				errors.append("map %s: missing %s" % [id, key])
		var acc: Dictionary = m.get("access", {})
		if acc.get("type", "") == "pack" and product(String(acc.get("product", ""))).is_empty():
			errors.append("map %s: access product %s not in catalog" % [id, acc.get("product")])
	for p in catalog.get("products", []):
		for g in p.get("grants", []):
			var gt := String(g.get("type", ""))
			if not gt in GRANT_TYPES:
				errors.append("product %s: unknown grant %s" % [p.get("id"), gt])
			if gt == "animal" and not animals.has(String(g.id)):
				errors.append("product %s: unknown animal %s" % [p.get("id"), g.id])
			if gt == "map" and not maps.has(String(g.id)):
				errors.append("product %s: unknown map %s" % [p.get("id"), g.id])
	for c in catalog.get("cosmetics", []):
		if c.get("type") == "skin":
			var a2: Dictionary = animals.get(String(c.get("animal", "")), {})
			var found := false
			for s in a2.get("skins", []):
				if s.id == c.get("skin"):
					found = true
			if not found:
				errors.append("cosmetic %s: skin %s not on animal %s" % [c.id, c.get("skin"), c.get("animal")])
	for sid in seasons:
		for tier in seasons[sid].get("tiers", []):
			for track in ["free", "premium"]:
				var r: Dictionary = tier.get(track, {})
				if r.has("animal") and not animals.has(String(r.animal)):
					errors.append("season %s: unknown animal %s" % [sid, r.animal])
				if r.has("cosmetic") and cosmetic(String(r.cosmetic)).is_empty():
					errors.append("season %s: unknown cosmetic %s" % [sid, r.cosmetic])
	for gid in generators:
		for b in generators[gid].get("bands", []):
			if not String(b.get("lane", "")) in ["safe", "ground", "water"]:
				errors.append("generator %s: band %s has bad lane" % [gid, b.get("id")])
