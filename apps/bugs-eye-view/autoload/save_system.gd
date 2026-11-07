extends Node
## Persists unlocks, level records, colony progress, settings and key bindings
## as JSON in user:// so it works the same on every platform.

signal settings_changed
signal progress_changed

## Tests point this at a scratch file so they never touch a real save.
var save_path := "user://save.json"
const SAVE_VERSION := 1

var data: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked_bugs": ["cockroach"],
		## Bugs that have escaped a room (each one unlocks the next).
		"bugs_completed": [],
		## Bugs unlocked but not played yet (shown as NEW).
		"new_bugs": [],
		## Bugs whose how-to-play card has been shown.
		"guides_seen": [],
		"levels": {},
		"colony": {"banked": 0, "lifetime": 0, "upgrades": []},
		"gems": {},
		## Treasures found (id -> times), for the showcase on the home screen.
		"treasures": {},
		## Credits (from gem shards in the mini maps) to spend on add-ons.
		"credits": 0,
		## Add-ons owned: id -> level (1-3).
		"addons": {"decoy_chirp": 1, "iron_shell": 1},
		## The revolver's six chambers (add-on ids, "" = empty).
		"revolver": ["decoy_chirp", "iron_shell", "", "", "", ""],
		## Mini maps finished: id -> {"done": bool, "best": shards}.
		"minis": {},
		## Rooms whose crawl space has opened up (it closes again once played).
		"crawl_open": {},
		"settings": {
			"master_volume": 0.9,
			"music_volume": 0.6,
			"sfx_volume": 0.9,
			"haptics": true,
			"quality": "medium",
			"touch_controls": "auto",
			"look_sensitivity": 1.0,
			"touch_look_sensitivity": 1.0,
			"invert_y": false,
			"fly_follow_look": true,
			"auto_quality": true,
			"first_person": false,
		},
		"bindings": {},
	}


func load_game() -> void:
	data = default_data()
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_merge(data, parsed as Dictionary)
	_tune_for_phone_browser()


func is_phone_browser() -> bool:
	return OS.has_feature("web") and (OS.has_feature("web_android") or OS.has_feature("web_ios"))


## In a phone's browser (or an app's web viewer) start on Low quality once:
## no shadows, 75% render scale, 30 fps - the rooms are big now. The player
## can raise it again in Settings.
func _tune_for_phone_browser() -> void:
	var settings: Dictionary = data["settings"]
	if is_phone_browser() and not bool(settings.get("web_phone_tuned", false)):
		settings["quality"] = "low"
		settings["web_phone_tuned"] = true


func save_game() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: cannot write %s" % save_path)
		return
	f.store_string(JSON.stringify(data, "  "))


func reset_progress() -> void:
	var settings: Dictionary = data["settings"]
	var bindings: Dictionary = data["bindings"]
	data = default_data()
	data["settings"] = settings
	data["bindings"] = bindings
	save_game()
	progress_changed.emit()


## Recursively copies saved values over defaults so new keys keep their defaults.
func _merge(into: Dictionary, from: Dictionary) -> void:
	for key: Variant in from.keys():
		if into.has(key) and into[key] is Dictionary and from[key] is Dictionary:
			_merge(into[key], from[key])
		else:
			into[key] = from[key]


# --- Bugs ---------------------------------------------------------------

func is_bug_unlocked(id: StringName) -> bool:
	return (data["unlocked_bugs"] as Array).has(String(id))


func unlock_bug(id: StringName) -> bool:
	if is_bug_unlocked(id):
		return false
	(data["unlocked_bugs"] as Array).append(String(id))
	_list("new_bugs").append(String(id))
	progress_changed.emit()
	return true


func _list(key: String) -> Array:
	if not data.has(key) or not data[key] is Array:
		data[key] = []
	return data[key]


func mark_bug_completed(id: StringName) -> void:
	if not _list("bugs_completed").has(String(id)):
		_list("bugs_completed").append(String(id))


func is_bug_completed(id: StringName) -> bool:
	return _list("bugs_completed").has(String(id))


func is_bug_new(id: StringName) -> bool:
	return _list("new_bugs").has(String(id))


func mark_bug_played(id: StringName) -> void:
	_list("new_bugs").erase(String(id))


func has_seen_guide(id: StringName) -> bool:
	return _list("guides_seen").has(String(id))


func mark_guide_seen(id: StringName) -> void:
	if not has_seen_guide(id):
		_list("guides_seen").append(String(id))


# --- Levels -------------------------------------------------------------

func get_level_record(id: StringName) -> Dictionary:
	var levels: Dictionary = data["levels"]
	var key := String(id)
	if not levels.has(key):
		levels[key] = {"completed": false, "best_score": 0, "best_time": 0.0,
			"badges": {"ghost": false, "speedrun": false, "golden": false, "gem_hunter": false}}
	return levels[key]


func is_level_completed(id: StringName) -> bool:
	return bool(get_level_record(id)["completed"])


## Stores a finished run. Returns the badges newly earned this time.
func record_level_result(id: StringName, won: bool, score: int, time: float, badges: Dictionary) -> Array:
	var rec := get_level_record(id)
	var newly: Array = []
	if won:
		rec["completed"] = true
		if score > int(rec["best_score"]):
			rec["best_score"] = score
		if float(rec["best_time"]) <= 0.0 or time < float(rec["best_time"]):
			rec["best_time"] = time
	var have: Dictionary = rec["badges"]
	for b: String in badges.keys():
		if bool(badges[b]) and not bool(have.get(b, false)):
			have[b] = true
			newly.append(b)
	progress_changed.emit()
	return newly


# --- Crumb gems ----------------------------------------------------------

## Lifetime count of each crumb gem found.
func record_gem(id: StringName) -> void:
	var g: Dictionary = data.get("gems", {})
	g[String(id)] = int(g.get(String(id), 0)) + 1
	data["gems"] = g
	progress_changed.emit()


func gems_found() -> Dictionary:
	return data.get("gems", {})


## Records a treasure; true if it's new to the showcase.
func record_treasure(id: StringName) -> bool:
	var t: Dictionary = data.get("treasures", {})
	var fresh := not t.has(String(id))
	t[String(id)] = int(t.get(String(id), 0)) + 1
	data["treasures"] = t
	progress_changed.emit()
	return fresh


func treasures_found() -> Dictionary:
	return data.get("treasures", {})


# --- Credits, add-ons and the revolver -----------------------------------------

func credits() -> int:
	return int(data.get("credits", 0))


func add_credits(n: int) -> void:
	data["credits"] = maxi(credits() + n, 0)
	progress_changed.emit()


func spend_credits(n: int) -> bool:
	if n > credits():
		return false
	data["credits"] = credits() - n
	progress_changed.emit()
	return true


## 0 = not owned.
func addon_level(id: StringName) -> int:
	return int((data.get("addons", {}) as Dictionary).get(String(id), 0))


## Buys an add-on or its next level. False if it can't be afforded or is maxed.
func buy_addon(id: StringName) -> bool:
	var next := addon_level(id) + 1
	if next > AddOns.MAX_LEVEL or not spend_credits(AddOns.price(id, next)):
		return false
	var a: Dictionary = data.get("addons", {})
	a[String(id)] = next
	data["addons"] = a
	progress_changed.emit()
	return true


func revolver() -> Array:
	var r: Array = data.get("revolver", [])
	while r.size() < AddOns.CHAMBERS:
		r.append("")
	return r


## Loads an owned add-on into a chamber (each add-on in one chamber at most).
func set_chamber(i: int, id: StringName) -> void:
	var r := revolver()
	if id != &"":
		for j in r.size():
			if String(r[j]) == String(id):
				r[j] = ""
	r[i] = String(id)
	data["revolver"] = r
	progress_changed.emit()


func is_mini_done(id: StringName) -> bool:
	return bool(((data.get("minis", {}) as Dictionary).get(String(id), {}) as Dictionary).get("done", false))


func record_mini(id: StringName, won: bool, shards: int) -> void:
	var m: Dictionary = data.get("minis", {})
	var rec: Dictionary = m.get(String(id), {"done": false, "best": 0})
	rec["done"] = bool(rec.get("done", false)) or won
	rec["best"] = maxi(int(rec.get("best", 0)), shards)
	m[String(id)] = rec
	data["minis"] = m
	progress_changed.emit()


func mini_best(id: StringName) -> int:
	return int(((data.get("minis", {}) as Dictionary).get(String(id), {}) as Dictionary).get("best", 0))


func is_crawl_open(room: StringName) -> bool:
	return bool((data.get("crawl_open", {}) as Dictionary).get(String(room), false))


func set_crawl_open(room: StringName, open: bool) -> void:
	var c: Dictionary = data.get("crawl_open", {})
	c[String(room)] = open
	data["crawl_open"] = c
	progress_changed.emit()


## Whether a showcase piece (treasure or crumb gem) has ever been found.
func has_collectible(id: StringName) -> bool:
	return treasures_found().has(String(id)) or gems_found().has(String(id))


# --- Colony -------------------------------------------------------------

func colony() -> Dictionary:
	return data["colony"]


func bank_crumbs(amount: int) -> void:
	if amount <= 0:
		return
	var c := colony()
	c["banked"] = int(c["banked"]) + amount
	c["lifetime"] = int(c["lifetime"]) + amount
	progress_changed.emit()


func spend_crumbs(amount: int) -> bool:
	var c := colony()
	if int(c["banked"]) < amount:
		return false
	c["banked"] = int(c["banked"]) - amount
	progress_changed.emit()
	return true


## The colony grows one size step for every 10 crumbs ever delivered.
func colony_size() -> int:
	return 1 + floori(float(colony()["lifetime"]) / 10.0)


func has_upgrade(id: StringName) -> bool:
	return (colony()["upgrades"] as Array).has(String(id))


func add_upgrade(id: StringName) -> void:
	if not has_upgrade(id):
		(colony()["upgrades"] as Array).append(String(id))
		progress_changed.emit()


# --- Settings -------------------------------------------------------------

func get_setting(key: String, fallback: Variant = null) -> Variant:
	return (data["settings"] as Dictionary).get(key, fallback)


func set_setting(key: String, value: Variant) -> void:
	(data["settings"] as Dictionary)[key] = value
	settings_changed.emit()


func get_bindings() -> Dictionary:
	return data["bindings"]


func set_binding(action: String, events: Array) -> void:
	(data["bindings"] as Dictionary)[action] = events
