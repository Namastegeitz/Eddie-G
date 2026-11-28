extends Node
## Remote switches: turn a risky feature off, or ask players to update,
## without a store release (Eddie's choice: a settings file on the project's
## GitHub Pages site, no extra service).
##
## The game ships with content/remote_config.json. At start-up it fetches the
## published copy (canopy/remote_config/url) in the background, with a time-out
## and two retries, and keeps the last good copy in user:// for offline starts.
## Nothing waits for it: until a newer copy arrives the shipped and cached
## values apply. A switch can only turn a shipped feature off or back on; it
## never adds anything new (App Review guideline 2.5.19).
##
##   RemoteConfig.enabled("first_person")      false only if the file says so
##   RemoteConfig.update_state()                "", "soft" or "forced"
## See docs/REMOTE_CONFIG.md.

signal updated

const CACHE := "user://remote_config.json"
const TIMEOUT := 6.0
const RETRY_DELAYS := [3.0, 10.0]

var config: Dictionary = {}
var source := "shipped"            # shipped | cached | remote
var _http: HTTPRequest
var _attempt := 0


func _ready() -> void:
	config = _shipped()
	var cached := _read(CACHE)
	if _valid(cached):
		config = _merged(config, cached)
		source = "cached"
	var url := String(ProjectSettings.get_setting("canopy/remote_config/url", ""))
	# the web build runs inside pages that block other hosts; it keeps the shipped values
	if url != "" and not OS.has_feature("web") and not OS.get_cmdline_user_args().has("--no-remote-config"):
		_http = HTTPRequest.new()
		_http.timeout = TIMEOUT
		_http.use_threads = true
		add_child(_http)
		_http.request_completed.connect(_on_done)
		_fetch()


func enabled(flag: String) -> bool:
	return bool(config.get("flags", {}).get(flag, true))


func build_number() -> int:
	return int(String(ProjectSettings.get_setting("canopy/build_number", "0")))


## "forced": this build is older than min_build (play waits for an update);
## "soft": a newer build exists (a one-off reminder); "" otherwise.
func update_state() -> String:
	var b := build_number()
	if b <= 0:
		return ""
	if int(config.get("min_build", 0)) > b:
		return "forced"
	if int(config.get("latest_build", 0)) > b:
		return "soft"
	return ""


func store_url() -> String:
	var urls: Dictionary = config.get("store_urls", {})
	var key := "android" if OS.has_feature("android") else ("ios" if OS.has_feature("ios") else "default")
	return String(urls.get(key, urls.get("default", "")))


func _fetch() -> void:
	var url := String(ProjectSettings.get_setting("canopy/remote_config/url", ""))
	if _http.request(url) != OK:
		_retry()


func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK and _valid(json.data):
			config = _merged(_shipped(), json.data)
			source = "remote"
			var f := FileAccess.open(CACHE, FileAccess.WRITE)
			if f:
				f.store_string(JSON.stringify(json.data))
				f.close()
			updated.emit()
			return
	if code == 404:
		return      # not published yet: keep the shipped values, don't keep asking
	_retry()


func _retry() -> void:
	if _attempt >= RETRY_DELAYS.size():
		return
	var wait: float = RETRY_DELAYS[_attempt]
	_attempt += 1
	get_tree().create_timer(wait).timeout.connect(_fetch)


func _shipped() -> Dictionary:
	return _read("res://content/remote_config.json")


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data


## A config is usable if it is a dictionary with a version and well-typed parts.
func _valid(d) -> bool:
	if typeof(d) != TYPE_DICTIONARY or not d.has("version"):
		return false
	if d.has("flags") and typeof(d.flags) != TYPE_DICTIONARY:
		return false
	for k in ["min_build", "latest_build"]:
		if d.has(k) and typeof(d[k]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
	return true


func _merged(base: Dictionary, over: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for k in over:
		if k == "flags" and typeof(over.flags) == TYPE_DICTIONARY:
			var fl: Dictionary = out.get("flags", {})
			for f in over.flags:
				fl[f] = bool(over.flags[f])
			out.flags = fl
		elif k != "_about":
			out[k] = over[k]
	return out
