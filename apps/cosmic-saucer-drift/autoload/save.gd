extends Node
## Everything the player owns and has done, saved to user://save.json.
## Ghost laps are stored separately in user://ghosts/.

const PATH := "user://save.json"
const VERSION := 1

const DEFAULT_SETTINGS := {
	"master": 1.0, "music": 0.7, "sfx": 0.9,
	"steering": "joystick",         # joystick | buttons | tilt
	"tilt_sensitivity": 1.0, "tilt_invert": false,
	"auto_accel": true, "haptics": true, "shake": true,
	"camera": "far",                # far | near
	"quality": "auto",              # auto | low | medium | high | ultra
	"show_fps": false, "difficulty": 1,
}

var data := {}
var _dirty := false
var _timer := 0.0
var disabled := false   # tests run with saving off


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"controls_v3": true,
		"credits": 300,
		"cup_stars": {},          # "cup:race" -> bitmask of the 3 stars
		"cup_best": {},           # cup id -> best finishing place (1..8)
		"pilots": ["zib", "nova"],
		"saucers": ["classic", "bubble"],
		"upgrades": {},           # saucer id -> {stat: level}
		"owned": {"paints": ["stock"], "decals": ["none"], "domes": ["clear"], "trails": ["cyan"]},
		"garage": {"saucer": "classic", "pilot": "zib", "looks": {}},
		"won": {},                # "track:variant" -> true (unlocks reverse/mirror)
		"shards": {},             # track id -> [bool, bool, bool]
		"best_time": {},          # "track:variant" -> seconds
		"best_lap": {},
		"medals": {},             # "track:variant" -> 0..3 time trial medal
		"bosses": {},             # pilot id -> true once beaten
		"achievements": {},
		"stats": {},
		"daily": {"last_done": "", "streak": 0, "best_streak": 0},
		"settings": DEFAULT_SETTINGS.duplicate(),
		"ads": {"removed": false, "consent": "unknown", "sessions": 0, "races": 0, "since_interstitial": 0},
		"tutorial_done": false,
		"first_launch": Time.get_datetime_string_from_system(),
	}


func load_game() -> void:
	data = defaults()
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		migrate(parsed)
		_merge(data, parsed)
	data.ads.sessions = int(data.ads.sessions) + 1
	mark()


## Upgrades an older save in place before it is merged over the defaults.
static func migrate(parsed: Dictionary) -> void:
	# v1 saves called the currency Stardust.
	if parsed.has("stardust") and not parsed.has("credits"):
		parsed["credits"] = parsed["stardust"]
	parsed.erase("stardust")
	# Saves from before the joystick had "buttons" as the default steering:
	# move them to the joystick once (a later choice of buttons is kept).
	if not parsed.has("controls_v3"):
		var st: Variant = parsed.get("settings", {})
		if st is Dictionary and st.get("steering", "buttons") == "buttons":
			st["steering"] = "joystick"
		parsed["controls_v3"] = true


## Copy saved values over the defaults so new fields always exist.
func _merge(into: Dictionary, from: Dictionary) -> void:
	for k in from:
		if into.has(k) and into[k] is Dictionary and from[k] is Dictionary:
			_merge(into[k], from[k])
		else:
			into[k] = from[k]


func mark() -> void:
	_dirty = true
	_timer = 0.6


func _process(dt: float) -> void:
	if _dirty:
		_timer -= dt
		if _timer <= 0.0:
			flush()


func flush() -> void:
	_dirty = false
	if disabled:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _dirty:
			flush()


func reset_all() -> void:
	data = defaults()
	flush()


# ---------------------------------------------------------------- settings
func setting(k: String) -> Variant:
	return data.settings.get(k, DEFAULT_SETTINGS.get(k))


func set_setting(k: String, v: Variant) -> void:
	data.settings[k] = v
	mark()


# ---------------------------------------------------------------- currency
func credits() -> int:
	return int(data.credits)


func add_credits(n: int) -> void:
	data.credits = credits() + n
	stat_add("credits_earned", n)
	mark()


func spend(n: int) -> bool:
	if credits() < n:
		return false
	data.credits = credits() - n
	mark()
	return true


# ---------------------------------------------------------------- stars & unlocks
func total_stars() -> int:
	var t := 0
	for k in data.cup_stars:
		var m := int(data.cup_stars[k])
		t += (m & 1) + ((m >> 1) & 1) + ((m >> 2) & 1)
	return t


func race_stars(cup: String, race_i: int) -> int:
	return int(data.cup_stars.get("%s:%d" % [cup, race_i], 0))


func add_race_stars(cup: String, race_i: int, mask: int) -> int:
	var key := "%s:%d" % [cup, race_i]
	var old := int(data.cup_stars.get(key, 0))
	var nw := old | mask
	data.cup_stars[key] = nw
	mark()
	var gained := 0
	for b in 3:
		if (nw >> b) & 1 and not ((old >> b) & 1):
			gained += 1
	return gained


func cup_unlocked(cup: Dictionary) -> bool:
	return total_stars() >= int(cup.stars)


func track_unlocked(track_id: String) -> bool:
	# Tracks open with the first cup that uses them.
	for cup in Catalog.CUPS:
		if not cup_unlocked(cup):
			continue
		for r in cup.races:
			if r[0] == track_id:
				return true
	return false


func variant_unlocked(track_id: String, variant: int) -> bool:
	if variant == Catalog.V_NORMAL:
		return track_unlocked(track_id)
	return data.won.get("%s:0" % track_id, false)


func mark_won(track_id: String, variant: int) -> void:
	data.won["%s:%d" % [track_id, variant]] = true
	mark()


func has_pilot(id: String) -> bool:
	return id in data.pilots


func unlock_pilot(id: String) -> void:
	if not has_pilot(id):
		data.pilots.append(id)
		mark()


func has_saucer(id: String) -> bool:
	return id in data.saucers


func unlock_saucer(id: String) -> void:
	if not has_saucer(id):
		data.saucers.append(id)
		mark()


func upgrade_level(saucer_id: String, stat: String) -> int:
	return int(data.upgrades.get(saucer_id, {}).get(stat, 0))


func upgrades_for(saucer_id: String) -> Dictionary:
	return data.upgrades.get(saucer_id, {})


func set_upgrade(saucer_id: String, stat: String, lvl: int) -> void:
	if not data.upgrades.has(saucer_id):
		data.upgrades[saucer_id] = {}
	data.upgrades[saucer_id][stat] = lvl
	mark()


func owns(kind: String, id: String) -> bool:
	return id in data.owned.get(kind, [])


func buy(kind: String, id: String) -> void:
	if not owns(kind, id):
		data.owned[kind].append(id)
		mark()


## Current look for a saucer: {saucer, pilot, paint, decal, dome, trail}.
func look_for(saucer_id: String, pilot_id: String) -> Dictionary:
	var l: Dictionary = data.garage.looks.get(saucer_id, {})
	return {"saucer": saucer_id, "pilot": pilot_id, "paint": l.get("paint", "stock"),
		"decal": l.get("decal", "none"), "dome": l.get("dome", "clear"), "trail": l.get("trail", "cyan")}


func set_look(saucer_id: String, key: String, id: String) -> void:
	if not data.garage.looks.has(saucer_id):
		data.garage.looks[saucer_id] = {}
	data.garage.looks[saucer_id][key] = id
	mark()


func player_look() -> Dictionary:
	return look_for(data.garage.saucer, data.garage.pilot)


func shards_for(track_id: String) -> Array:
	return data.shards.get(track_id, [false, false, false])


func take_shard(track_id: String, slot: int) -> bool:
	var a: Array = shards_for(track_id).duplicate()
	if a[slot]:
		return false
	a[slot] = true
	data.shards[track_id] = a
	mark()
	return true


func shard_total() -> int:
	var t := 0
	for k in data.shards:
		for b in data.shards[k]:
			if b:
				t += 1
	return t


# ---------------------------------------------------------------- stats
func stat(k: String) -> float:
	return float(data.stats.get(k, 0))


func stat_add(k: String, v: float) -> void:
	data.stats[k] = stat(k) + v
	mark()


func stat_max(k: String, v: float) -> void:
	if v > stat(k):
		data.stats[k] = v
		mark()


# ---------------------------------------------------------------- ghosts
func ghost_path(key: String) -> String:
	return "user://ghosts/%s.bin" % key


func save_ghost(key: String, frames: PackedFloat32Array) -> void:
	if disabled:
		return
	DirAccess.make_dir_recursive_absolute("user://ghosts")
	var f := FileAccess.open(ghost_path(key), FileAccess.WRITE)
	if f:
		f.store_var(frames)


func load_ghost(key: String) -> PackedFloat32Array:
	if not FileAccess.file_exists(ghost_path(key)):
		return PackedFloat32Array()
	var f := FileAccess.open(ghost_path(key), FileAccess.READ)
	var v: Variant = f.get_var() if f else null
	return v if v is PackedFloat32Array else PackedFloat32Array()
