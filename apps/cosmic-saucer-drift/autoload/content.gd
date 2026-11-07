extends Node
## Data-driven content. Loads the shipped JSON files in res://content/
## (wonders, upgrades, biomes) and then every content pack: *.json files in
## res://content/packs/ and user://packs/. A pack can add pilots, craft,
## mods, mod sets, Wonders and biomes with no code changes:
##
##   {"pack": "my_pack", "pilots": [...], "saucers": [...], "mods": [...],
##    "sets": [...], "wonders": [...], "biomes": [...]}
##
## Colours are written "#rrggbb" or "#rrggbbaa". Effects use the keys in
## scripts/data/effects.gd. Problems are collected in `issues` (also printed)
## and the bad entry is skipped, so a broken pack never stops the game.
## tools/validate_content.gd prints the same report from the command line.
##
## Loaded in _init, before the other autoloads' _ready (Save reads pilots).

const SHIPPED := ["res://content/wonders.json", "res://content/upgrades.json", "res://content/biomes.json"]
const PACK_DIRS := ["res://content/packs", "user://packs"]
const PILOT_KEYS := ["id", "name", "color", "eyes", "passive_name", "passive_text", "style", "unlock", "home"]
const SAUCER_KEYS := ["id", "name", "blurb", "speed", "accel", "handling", "efficiency", "weight", "price", "stars", "shape", "paint"]
const SHAPES := ["classic", "bubble", "rocket", "ring", "orb", "manta", "crystal", "bioship", "mothership", "arrow", "sail", "phantom", "dragon", "dyson"]
const MECHANICS := ["spinnaker", "lighthouse", "jet", "harvest"]
const STYLES := ["clean", "aggressive", "hoarder"]

var wonders: Array = []
var wonder_by_craft := {}
var overclock := {}
var stardust := {}
var slots: Array = []
var sets: Array = []
var set_by_id := {}
var mods: Array = []
var mod_by_id := {}
var biomes: Array = []
var biome_by_id := {}
var biome_defaults := {}
var issues: PackedStringArray = []
var packs: PackedStringArray = []


func _init() -> void:
	load_all()


func load_all() -> void:
	for f in SHIPPED:
		_load_file(f, false)
	for dir in PACK_DIRS:
		var files := _list_json(dir)
		for f in files:
			_load_file(f, true)
	for msg in issues:
		push_warning("content: " + msg)


static func _list_json(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		# Exported builds list "x.json" as-is (JSON is kept as a plain file).
		if f.ends_with(".json"):
			out.append(dir.path_join(f))
	out.sort()
	return out


func _load_file(path: String, is_pack: bool) -> void:
	if not FileAccess.file_exists(path):
		if not is_pack:
			issues.append("%s is missing" % path)
		return
	var txt := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary):
		issues.append("%s is not valid JSON" % path)
		return
	var d: Dictionary = norm(parsed)
	if is_pack:
		packs.append(String(d.get("pack", path.get_file())))
	var src := path.get_file()
	if d.has("overclock"):
		overclock = d.overclock
	if d.has("stardust"):
		stardust = d.stardust
	if d.has("slots"):
		slots = d.slots
	if d.has("biome_defaults"):
		biome_defaults.merge(d.biome_defaults, true)
	for s: Dictionary in d.get("sets", []):
		add_set(s, src)
	for m: Dictionary in d.get("mods", []):
		add_mod(m, src)
	for w: Dictionary in d.get("wonders", []):
		add_wonder(w, src)
	for b: Dictionary in d.get("biomes", []):
		add_biome(b, src)
	for p: Dictionary in d.get("pilots", []):
		add_pilot(p, src)
	for s: Dictionary in d.get("saucers", []):
		add_saucer(s, src)


## JSON has no colours or integers: "#rrggbb" strings become Colors and
## whole numbers become ints, recursively.
static func norm(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k: Variant in v:
			out[k] = norm(v[k])
		return out
	if v is Array:
		var out: Array = []
		for e: Variant in v:
			out.append(norm(e))
		return out
	if v is float and v == floorf(v) and absf(v) < 1e9:
		return int(v)
	if v is String and v.begins_with("#") and (v.length() == 7 or v.length() == 9) and v.substr(1).is_valid_hex_number():
		return Color.html(v)
	return v


func _missing(d: Dictionary, keys: Array) -> String:
	var miss := PackedStringArray()
	for k: String in keys:
		if not d.has(k):
			miss.append(k)
	return ", ".join(miss)


func _check_effects(fx: Variant, where: String) -> Dictionary:
	if not (fx is Dictionary):
		return {}
	for k in Effects.unknown_keys(fx):
		issues.append("%s: unknown effect key '%s' (ignored)" % [where, k])
	var out := {}
	for k: String in fx:
		if Effects.KEYS.has(k):
			out[k] = fx[k]
	return out


func add_set(s: Dictionary, src := "") -> bool:
	var miss := _missing(s, ["id", "name", "bonus_name", "bonus_text", "effects"])
	if miss != "":
		issues.append("%s: set %s missing %s" % [src, s.get("id", "?"), miss])
		return false
	s.effects = _check_effects(s.effects, "set " + String(s.id))
	if set_by_id.has(s.id):
		sets.erase(set_by_id[s.id])
	sets.append(s)
	set_by_id[s.id] = s
	return true


func add_mod(m: Dictionary, src := "") -> bool:
	var miss := _missing(m, ["id", "slot", "name", "cost", "effects"])
	if miss != "":
		issues.append("%s: mod %s missing %s" % [src, m.get("id", "?"), miss])
		return false
	var slot_ids := slots.map(func(s: Dictionary) -> String: return String(s.id))
	if not (String(m.slot) in slot_ids):
		issues.append("%s: mod %s has unknown slot '%s'" % [src, m.id, m.slot])
		return false
	if String(m.get("set", "")) != "" and not set_by_id.has(m.set):
		issues.append("%s: mod %s names unknown set '%s' (treated as no set)" % [src, m.id, m.set])
		m.set = ""
	m.effects = _check_effects(m.effects, "mod " + String(m.id))
	if mod_by_id.has(m.id):
		mods.erase(mod_by_id[m.id])
	mods.append(m)
	mod_by_id[m.id] = m
	return true


func add_wonder(w: Dictionary, src := "") -> bool:
	var miss := _missing(w, ["id", "craft", "name", "text", "mechanic", "tiers", "global_perk"])
	if miss != "":
		issues.append("%s: wonder %s missing %s" % [src, w.get("id", "?"), miss])
		return false
	if not (String(w.mechanic) in MECHANICS):
		issues.append("%s: wonder %s has unknown mechanic '%s'" % [src, w.id, w.mechanic])
		return false
	var tiers: Array = w.tiers
	if tiers.size() != 3:
		issues.append("%s: wonder %s needs exactly 3 tiers" % [src, w.id])
		return false
	# Each tier inherits the previous tier's params, so packs only list changes.
	var params := {}
	for t: Dictionary in tiers:
		params = params.duplicate()
		params.merge(t.get("params", {}), true)
		t.params = params
		t.effects = _check_effects(t.get("effects", {}), "wonder %s tier %s" % [w.id, t.get("name", "?")])
	w.global_perk.effects = _check_effects(w.global_perk.get("effects", {}), "perk of " + String(w.id))
	if not w.has("color"):
		w.color = Color(1, 1, 1)
	if wonder_by_craft.has(w.craft):
		wonders.erase(wonder_by_craft[w.craft])
	wonders.append(w)
	wonder_by_craft[w.craft] = w
	return true


func add_biome(b: Dictionary, src := "") -> bool:
	var miss := _missing(b, ["id", "name", "palette", "formations"])
	if miss != "":
		issues.append("%s: biome %s missing %s" % [src, b.get("id", "?"), miss])
		return false
	var forms: Array = b.formations
	if forms.size() < 3 or forms.size() > 4:
		issues.append("%s: biome %s should have 3 or 4 formation variants (has %d)" % [src, b.id, forms.size()])
	for f: Dictionary in forms:
		var fm := _missing(f, ["id", "kind", "recipe"])
		if fm != "":
			issues.append("%s: biome %s formation %s missing %s" % [src, b.id, f.get("id", "?"), fm])
			return false
	if biome_by_id.has(b.id):
		biomes.erase(biome_by_id[b.id])
	biomes.append(b)
	biome_by_id[b.id] = b
	return true


func add_pilot(p: Dictionary, src := "") -> bool:
	var miss := _missing(p, PILOT_KEYS)
	if miss != "":
		issues.append("%s: pilot %s missing %s" % [src, p.get("id", "?"), miss])
		return false
	if Catalog.has_pilot_id(String(p.id)):
		issues.append("%s: pilot id '%s' already exists (skipped)" % [src, p.id])
		return false
	if not TrackDefs.has(String(p.home)):
		issues.append("%s: pilot %s home track '%s' unknown (using mars)" % [src, p.id, p.home])
		p.home = "mars"
	if not (String(p.style) in STYLES):
		p.style = "clean"
	p.effects = _check_effects(p.get("effects", {}), "pilot " + String(p.id))
	if p.has("look") and p.look is Dictionary:
		var lk: Dictionary = p.look
		for k: String in ["head", "iris", "suit", "trim", "acc"]:
			if not lk.has(k):
				issues.append("%s: pilot %s look missing '%s' (using Zib's look)" % [src, p.id, k])
				p.erase("look")
				break
	Catalog.PILOTS.append(p)
	return true


func add_saucer(s: Dictionary, src := "") -> bool:
	var miss := _missing(s, SAUCER_KEYS)
	if miss != "":
		issues.append("%s: craft %s missing %s" % [src, s.get("id", "?"), miss])
		return false
	for c in Catalog.SAUCERS:
		if c.id == s.id:
			issues.append("%s: craft id '%s' already exists (skipped)" % [src, s.id])
			return false
	if not (String(s.shape) in SHAPES):
		issues.append("%s: craft %s shape '%s' unknown (using classic)" % [src, s.id, s.shape])
		s.shape = "classic"
	for k in Catalog.STAT_KEYS + ["weight"]:
		s[k] = clampi(int(s[k]), 1, 10)
	s.effects = _check_effects(s.get("effects", {}), "craft " + String(s.id))
	Catalog.SAUCERS.append(s)
	return true


# ---------------------------------------------------------------- lookups
func wonder_for(saucer_id: String) -> Dictionary:
	return wonder_by_craft.get(saucer_id, {})


func mods_for_slot(slot: String) -> Array:
	return mods.filter(func(m: Dictionary) -> bool: return String(m.slot) == slot)


func biome(id: String) -> Dictionary:
	return biome_by_id.get(id, {})
