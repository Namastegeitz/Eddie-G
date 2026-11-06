class_name Collection
## The showcase: every treasure and crumb gem in the house, room by room, from
## common to legendary. What you've found is saved (SaveSystem) and shown on
## the home screen's trophy shelf and the Showcase screen.

const ROOMS: Array[String] = ["Kitchen", "Living Room", "Backyard"]
const IDS := {
	"Kitchen": [&"treasure_button", &"treasure_bead", &"gem_amber", &"treasure_teaspoon", &"treasure_sea_glass",
		&"treasure_thimble", &"treasure_ring", &"gem_diamond"],
	"Living Room": [&"treasure_toy_brick", &"treasure_marble", &"gem_amethyst", &"treasure_pearl", &"treasure_gear",
		&"treasure_earring", &"gem_sapphire", &"treasure_brooch"],
	"Backyard": [&"treasure_acorn_cap", &"treasure_snail_shell", &"treasure_old_coin", &"treasure_beetle_shell",
		&"treasure_clover", &"gem_ruby", &"gem_emerald", &"treasure_golden_acorn"],
}


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for room in ROOMS:
		for id: StringName in IDS[room]:
			out.append(id)
	return out


static func def_of(id: StringName) -> ItemDef:
	return ItemDef.load_def(id)


static func is_found(id: StringName) -> bool:
	return SaveSystem.has_collectible(id)


static func found_count() -> int:
	var n := 0
	for id in all_ids():
		if is_found(id):
			n += 1
	return n


## [found, total] for each rarity (common, rare, epic, legendary).
static func by_rarity() -> Array:
	var out := [[0, 0], [0, 0], [0, 0], [0, 0]]
	for id in all_ids():
		var d := def_of(id)
		if d == null:
			continue
		var r := clampi(d.rarity, 0, 3)
		out[r][1] += 1
		if is_found(id):
			out[r][0] += 1
	return out


## Found pieces, rarest first (for the trophy shelf).
static func best_found(limit: int) -> Array[StringName]:
	var found: Array[StringName] = []
	for id in all_ids():
		if is_found(id):
			found.append(id)
	found.sort_custom(func(a: StringName, b: StringName) -> bool:
		return def_of(a).rarity > def_of(b).rarity)
	return found.slice(0, limit)


static func icon(id: StringName) -> Texture2D:
	var path := "res://assets/icons/items/%s.png" % id
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## One line for the home screen.
static func summary() -> String:
	var r := by_rarity()
	return "Showcase %d / %d  -  Legendary %d / %d" % [found_count(), all_ids().size(), r[3][0], r[3][1]]
