extends Node
## Player-friendly ads: opt-in rewarded videos (Berries, a revive, doubled
## run rewards) and a light interstitial between runs that Remove Ads turns
## off. Nothing is ever shown during a run: every call is refused while
## `in_run` is true unless the run is stopped (fail screen).
##
## The default backend is a mock that shows a labelled test card. Set
## canopy/ads/backend = "admob" and add an AdMob plugin to use real ads
## (see docs/STORE.md); `scripts/platform/admob_ads.gd` adapts it.

signal finished(kind: String, placement: String, rewarded: bool)

const INTERSTITIAL_EVERY := 3
const MIN_RUNS_BEFORE_ADS := 3

var in_run := false
var run_stopped := false
var backend := "mock"
var mock_seconds := 4.0
var auto_complete := false      # tests
var _layer: CanvasLayer
var _admob: Node


func _ready() -> void:
	backend = String(ProjectSettings.get_setting("canopy/ads/backend", "mock"))
	if ProjectSettings.get_setting("canopy/debug/fast_ads", false):
		mock_seconds = 1.0
	if backend == "admob" and ResourceLoader.exists("res://scripts/platform/admob_ads.gd"):
		_admob = load("res://scripts/platform/admob_ads.gd").new()
		add_child(_admob)
		if not _admob.available():
			_admob.queue_free()
			_admob = null
			backend = "mock"
	process_mode = Node.PROCESS_MODE_ALWAYS


func ads_removed() -> bool:
	return Save.flag("remove_ads")


func _allowed() -> bool:
	return not in_run or run_stopped


func interstitial_due() -> bool:
	if ads_removed() or not _allowed():
		return false
	if int(Save.data.stats.get("runs", 0)) < MIN_RUNS_BEFORE_ADS:
		return false
	return int(Save.data.get("runs_since_ad", 0)) >= INTERSTITIAL_EVERY


func note_run_finished() -> void:
	Save.data.runs_since_ad = int(Save.data.get("runs_since_ad", 0)) + 1
	Save.mark()


## Between runs only. Calls `done` when closed (immediately if not due).
func maybe_interstitial(done: Callable) -> void:
	if not interstitial_due():
		done.call()
		return
	Save.data.runs_since_ad = 0
	Save.mark()
	Analytics.event("ad_shown", {"kind": "interstitial"})
	_show("interstitial", "between_runs", func(_ok): done.call())


## Opt-in reward video. `done(rewarded: bool)`.
func rewarded(placement: String, done: Callable) -> void:
	if not _allowed():
		done.call(false)
		return
	Analytics.event("ad_shown", {"kind": "rewarded", "placement": placement})
	_show("rewarded", placement, func(ok):
		if ok:
			Analytics.event("ad_reward", {"placement": placement})
		done.call(ok))


func _show(kind: String, placement: String, done: Callable) -> void:
	if auto_complete:
		finished.emit(kind, placement, true)
		done.call(true)
		return
	if _admob:
		_admob.show(kind, func(ok):
			finished.emit(kind, placement, ok)
			done.call(ok))
		return
	_mock(kind, placement, done)


func _mock(kind: String, placement: String, done: Callable) -> void:
	if _layer:
		_layer.queue_free()
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	var root := ColorRect.new()
	root.color = Color(0.03, 0.06, 0.05, 0.96)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(root)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	box.custom_minimum_size = Vector2(560, 0)
	box.position = Vector2(-280, -200)
	root.add_child(box)
	var title := Label.new()
	title.text = "TEST AD" if kind == "interstitial" else "TEST REWARD VIDEO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	var note := Label.new()
	note.text = "Sandbox build: a real ad network fills this space.\n" + ("Watch to the end for your reward." if kind == "rewarded" else "You can remove these in the store.")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 26)
	note.modulate = Color(1, 1, 1, 0.75)
	box.add_child(note)
	var count := Label.new()
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 64)
	box.add_child(count)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(320, 88)
	btn.add_theme_font_size_override("font_size", 30)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(btn)
	var left := [mock_seconds]
	var closed := [false]
	var close := func(ok: bool):
		if closed[0]:
			return
		closed[0] = true
		if is_instance_valid(_layer):
			_layer.queue_free()
		_layer = null
		finished.emit(kind, placement, ok)
		done.call(ok)
	btn.text = "Skip (no reward)" if kind == "rewarded" else "Close"
	btn.disabled = kind == "interstitial"
	btn.pressed.connect(func(): close.call(left[0] <= 0.0))
	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	root.add_child(timer)
	count.text = str(int(ceilf(left[0])))
	timer.timeout.connect(func():
		left[0] -= 0.1
		count.text = str(maxi(0, int(ceilf(left[0]))))
		if left[0] <= 0.0:
			btn.disabled = false
			btn.text = "Collect reward" if kind == "rewarded" else "Close"
			timer.stop())
