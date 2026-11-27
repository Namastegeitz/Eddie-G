class_name ReviewPrompt
extends RefCounted
## Asks for a store rating at a happy moment: right after a podium finish,
## once the player has raced a few times. Uses the In-App Review plugin's
## native singleton when it's installed (Android/iOS store builds); anywhere
## else, or while content/review_prompt.json says "enabled": false, it does
## nothing. Never from a button: Google and Apple don't allow that.

const SINGLETON := "InappReviewPlugin"
const CONFIG := "res://content/review_prompt.json"
static var _cfg := {}
static var _busy := false


static func config() -> Dictionary:
	if _cfg.is_empty():
		_cfg = {"enabled": false, "min_races": 5, "min_podiums": 2, "days_between": 30, "max_asks": 3}
		if FileAccess.file_exists(CONFIG):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
			if d is Dictionary:
				_cfg.merge(d, true)
	return _cfg


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


static func _state() -> Dictionary:
	if not (Save.data.get("review") is Dictionary):
		Save.data["review"] = {"asked": 0, "last": 0, "podiums": 0}
	return Save.data["review"]


## Whether a podium finish now would ask (store limits aside).
static func should_ask(place: int, now := -1) -> bool:
	var c := config()
	var r := _state()
	if not bool(c.enabled) or place < 1 or place > 3:
		return false
	if int(Save.data.ads.get("races", 0)) < int(c.min_races) or int(r.get("podiums", 0)) < int(c.min_podiums):
		return false
	if int(r.get("asked", 0)) >= int(c.max_asks):
		return false
	var t := now if now >= 0 else int(Time.get_unix_time_from_system())
	return int(r.get("last", 0)) == 0 or t - int(r.get("last", 0)) >= int(c.days_between) * 86400


## Call once per finished race with the player's place. Returns true when it asked.
static func after_race(place: int) -> bool:
	var r := _state()
	if place >= 1 and place <= 3:
		r["podiums"] = int(r.get("podiums", 0)) + 1
		Save.mark()
	if not should_ask(place) or not available() or _busy:
		return false
	r["asked"] = int(r.get("asked", 0)) + 1
	r["last"] = int(Time.get_unix_time_from_system())
	Save.mark()
	_ask()
	return true


static func _ask() -> void:
	var p: Object = Engine.get_singleton(SINGLETON)
	_busy = true
	var done := func() -> void: _busy = false
	p.connect("review_info_generated", func() -> void: p.call("launch_review_flow"), CONNECT_ONE_SHOT)
	p.connect("review_flow_launched", done, CONNECT_ONE_SHOT)
	p.connect("review_info_generation_failed", done, CONNECT_ONE_SHOT)
	p.connect("review_flow_launch_failed", done, CONNECT_ONE_SHOT)
	p.call("generate_review_info")
