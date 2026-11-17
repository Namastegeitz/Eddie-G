extends Node
## Persistent player data in user://canopy_save.json. Written atomically
## (temp file, then rename) with one backup, so a crash mid-write can't
## lose a purchase or an unlock.

signal changed

const PATH := "user://canopy_save.json"
const BACKUP := "user://canopy_save.bak.json"
const VERSION := 1

var data: Dictionary = {}
var path := PATH
var _dirty := false
var _timer := 0.0


func _ready() -> void:
	load_game()


func _process(delta: float) -> void:
	if _dirty:
		_timer -= delta
		if _timer <= 0.0:
			flush()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_EXIT_TREE]:
		if _dirty:
			flush()


func defaults() -> Dictionary:
	var owned: Array = []
	for id in Content.starters():
		owned.append(id)
	var free_maps: Array = []
	for id in Content.playable_maps():
		if Content.maps[id].get("access", {}).get("type", "") == "free":
			free_maps.append(id)
	return {
		"version": VERSION,
		"created": int(Time.get_unix_time_from_system()),
		"berries": 0,
		"amber": 0,
		"owned_animals": owned,
		"owned_maps": free_maps,
		"owned_products": [],
		"owned_cosmetics": [],
		"flags": {},
		"inventory": {},
		"berry_doubler_until": 0,
		"equipped_animal": owned[0] if not owned.is_empty() else "",
		"equipped_skin": {},
		"equipped_trail": "",
		"equipped_emote": "",
		"equipped_flag": "",
		"loadout": [],
		"selected_map": free_maps[0] if not free_maps.is_empty() else "amazon",
		"progress": {},
		"stats": {"runs": 0, "rows": 0, "deaths": {}, "collected": 0, "best_combo": 0},
		"tutorial_done": false,
		"tutorial_steps": [],
		"seen_intro": [],
		"seen_animals": [],
		"daily": {"last_day": -1, "streak": 0},
		"daily_challenge": {"day": -1, "best": 0, "rewarded": false},
		"pass": {"season": "", "xp": 0, "premium": false, "claimed_free": [], "claimed_premium": []},
		"prompts": {},
		"runs_since_ad": 0,
		"settings": Content.settings_defaults.duplicate(true),
	}


func load_game() -> void:
	var loaded := _read(path)
	if loaded.is_empty() and FileAccess.file_exists(BACKUP):
		loaded = _read(BACKUP)
	data = defaults()
	if not loaded.is_empty():
		_merge(data, loaded)
		data["settings"] = Content.settings_defaults.duplicate(true).merged(loaded.get("settings", {}), true)
	_migrate()
	changed.emit()


func _merge(base: Dictionary, over: Dictionary) -> void:
	for k in over:
		if base.has(k) and typeof(base[k]) == TYPE_DICTIONARY and typeof(over[k]) == TYPE_DICTIONARY and k != "progress":
			_merge(base[k], over[k])
		else:
			base[k] = over[k]


func _migrate() -> void:
	# Starter animals added in later content updates are always owned.
	for id in Content.starters():
		if not id in data.owned_animals:
			data.owned_animals.append(id)
	if not Content.animals.has(String(data.equipped_animal)):
		data.equipped_animal = Content.starters()[0] if not Content.starters().is_empty() else ""
	data.version = VERSION


func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(p)) != OK:
		return {}
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}


func mark() -> void:
	_dirty = true
	_timer = 0.4
	changed.emit()


func flush() -> void:
	_dirty = false
	var text := JSON.stringify(data, "  ")
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("save: cannot write " + tmp)
		return
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, BACKUP)
	DirAccess.rename_absolute(tmp, path)


func wipe() -> void:
	for p in [path, BACKUP]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	data = defaults()
	_migrate()
	flush()
	changed.emit()


# ------------------------------------------------------------------ helpers

func setting(key: String, fallback = null):
	return data.settings.get(key, fallback)


func set_setting(key: String, value) -> void:
	data.settings[key] = value
	mark()


func flag(key: String) -> bool:
	return bool(data.flags.get(key, false))


func set_flag(key: String, value := true) -> void:
	data.flags[key] = value
	mark()


func map_progress(map_id: String) -> Dictionary:
	if not data.progress.has(map_id):
		data.progress[map_id] = {"cleared": 0, "best_rows": 0, "best_score": 0, "stage_best": {}}
	return data.progress[map_id]


func owns_animal(id: String) -> bool:
	return id in data.owned_animals


func owns_map(id: String) -> bool:
	return id in data.owned_maps


func item_count(id: String) -> int:
	return int(data.inventory.get(id, 0))
