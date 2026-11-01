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
		"levels": {},
		"colony": {"banked": 0, "lifetime": 0, "upgrades": []},
		"settings": {
			"master_volume": 0.9,
			"music_volume": 0.6,
			"sfx_volume": 0.9,
			"haptics": true,
			"quality": "medium",
			"touch_controls": "auto",
			"look_sensitivity": 1.0,
			"invert_y": false,
		},
		"bindings": {},
	}


func load_game() -> void:
	data = default_data()
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_merge(data, parsed as Dictionary)


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
	progress_changed.emit()
	return true


# --- Levels -------------------------------------------------------------

func get_level_record(id: StringName) -> Dictionary:
	var levels: Dictionary = data["levels"]
	var key := String(id)
	if not levels.has(key):
		levels[key] = {"completed": false, "best_score": 0, "best_time": 0.0,
			"badges": {"ghost": false, "speedrun": false, "golden": false}}
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
