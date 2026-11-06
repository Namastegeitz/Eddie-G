extends Node
## Owns game state, the selected bug/level/time slot, scene flow with fades,
## progression (unlocks, colony banking) and the current run.

signal state_changed(new_state: int)
signal run_finished(result: Dictionary)

enum State { MENU, PLAYING, PAUSED, CAUGHT, WIN, HUB }

## In unlock order: each comes out of the shade when you escape a room as the
## one before it (BugStats.unlock_after_bug).
const BUG_IDS: Array[StringName] = [&"cockroach", &"fly", &"spider", &"ant", &"cricket", &"ladybug",
	&"firefly", &"stink_bug"]
const LEVEL_IDS: Array[StringName] = [&"kitchen", &"living_room", &"backyard"]
const SCENES := {
	&"main_menu": "res://scenes/ui/main_menu.tscn",
	&"level_select": "res://scenes/ui/level_select.tscn",
	&"bug_select": "res://scenes/ui/bug_select.tscn",
	&"settings": "res://scenes/ui/settings_menu.tscn",
	&"colony": "res://scenes/hub/colony_hub.tscn",
	&"showcase": "res://scenes/ui/showcase.tscn",
}
const UPGRADE_PATHS: Array[String] = [
	"res://resources/upgrades/swift_legs.tres",
	"res://resources/upgrades/hushed_steps.tres",
	"res://resources/upgrades/deep_camo.tres",
	"res://resources/upgrades/tough_shell.tres",
	"res://resources/upgrades/long_silk.tres",
	"res://resources/upgrades/hushed_wings.tres",
	"res://resources/upgrades/keen_senses.tres",
	"res://resources/upgrades/strong_wings.tres",
]

var state: int = State.MENU
var current_bug: StringName = &"cockroach"
var current_level: StringName = &"kitchen"
var current_time_slot: StringName = &"morning"
var run: RunStats
var last_result: Dictionary = {}
var scoring: ScoringConfig
var level_node: Node = null
## Show each bug's how-to-play card the first time it's played (tests turn it off).
var guides_enabled := true
## Step quality down when the frame rate stays low (the "Auto quality" setting;
## tests turn it off).
var auto_quality_enabled := true
const FPS_FLOOR := 24.0
const FPS_WINDOW := 6
var _fps_samples: Array[float] = []
var _fps_timer := 0.0
var _quality_cd := 0.0
var _bugs: Dictionary = {}
var _levels: Dictionary = {}
var _upgrades: Array[UpgradeDef] = []
var _fade: ColorRect
var _changing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in BUG_IDS:
		var p := "res://resources/bugs/%s.tres" % id
		if ResourceLoader.exists(p):
			_bugs[id] = load(p)
	for id in LEVEL_IDS:
		var lp := "res://resources/levels/%s.tres" % id
		if ResourceLoader.exists(lp):
			_levels[id] = load(lp)
	for up in UPGRADE_PATHS:
		if ResourceLoader.exists(up):
			_upgrades.append(load(up))
	var sp := "res://resources/config/scoring_config.tres"
	scoring = load(sp) if ResourceLoader.exists(sp) else ScoringConfig.new()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	InputRouter.pause_requested.connect(toggle_pause)
	SaveSystem.settings_changed.connect(apply_quality)
	apply_quality()


# --- Data access ------------------------------------------------------------

func get_bug_stats(id: StringName) -> BugStats:
	return _bugs.get(id) as BugStats


## Base stats with every owned colony upgrade multiplied in.
func build_bug_stats(id: StringName) -> BugStats:
	var base := get_bug_stats(id)
	if base == null:
		return BugStats.new()
	var s: BugStats = base.duplicate()
	for u in _upgrades:
		if SaveSystem.has_upgrade(u.id) and u.applies(id):
			for prop: Variant in u.modifiers.keys():
				var key := StringName(prop)
				var cur: Variant = s.get(key)
				if cur is float or cur is int:
					s.set(key, float(cur) * float(u.modifiers[prop]))
	return s


## Marks `bug` as having escaped a room and unlocks every bug waiting on it.
## Returns the ids that were newly unlocked.
func unlock_after_escape(bug: StringName) -> Array[StringName]:
	SaveSystem.mark_bug_completed(bug)
	var out: Array[StringName] = []
	for id in BUG_IDS:
		var s := get_bug_stats(id)
		if s and s.unlock_after_bug == bug and SaveSystem.unlock_bug(id):
			out.append(id)
	return out


## The next bug still in the shade, or &"" when all are out.
func next_locked_bug() -> StringName:
	for id in BUG_IDS:
		if not SaveSystem.is_bug_unlocked(id):
			return id
	return &""


func get_level(id: StringName) -> LevelConfig:
	return _levels.get(id) as LevelConfig


func get_upgrades() -> Array[UpgradeDef]:
	return _upgrades


func is_level_unlocked(id: StringName) -> bool:
	var cfg := get_level(id)
	if cfg == null:
		return false
	return cfg.unlock_after == &"" or SaveSystem.is_level_completed(cfg.unlock_after)


func is_slot_unlocked(level_id: StringName, slot: StringName) -> bool:
	return slot == &"morning" or SaveSystem.is_level_completed(level_id)


# --- Flow -----------------------------------------------------------------

func _process(delta: float) -> void:
	if state != State.PLAYING:
		_fps_samples.clear()
		_fps_timer = 0.0
		return
	_quality_cd -= delta
	_fps_timer += delta
	if _fps_timer < 1.0:
		return
	_fps_timer = 0.0
	_fps_samples.append(Engine.get_frames_per_second())
	if _fps_samples.size() > FPS_WINDOW:
		_fps_samples.pop_front()
	if _fps_samples.size() == FPS_WINDOW:
		var total := 0.0
		for f in _fps_samples:
			total += f
		check_frame_rate(total / FPS_WINDOW)


## Running slowly for a while: step quality down one notch (high -> medium ->
## low) and say so. Returns true if it changed.
func check_frame_rate(avg_fps: float) -> bool:
	if not auto_quality_enabled or not bool(SaveSystem.get_setting("auto_quality", true)):
		return false
	if _quality_cd > 0.0 or avg_fps >= FPS_FLOOR:
		return false
	var next: String = {"high": "medium", "medium": "low"}.get(String(SaveSystem.get_setting("quality", "medium")), "")
	if next == "":
		return false
	SaveSystem.set_setting("quality", next)
	SaveSystem.save_game()
	apply_quality()
	if level_node is Level:
		(level_node as Level).refresh_quality()
		(level_node as Level).set_hint("Switched to %s quality for smoother play" % next.capitalize())
	_quality_cd = 20.0
	_fps_samples.clear()
	return true


func set_state(s: int) -> void:
	if s == state:
		return
	state = s
	get_tree().paused = s == State.PAUSED
	InputRouter.set_enabled(s == State.PLAYING)
	state_changed.emit(s)


func goto(key_or_path: String) -> void:
	var path: String = SCENES.get(StringName(key_or_path), key_or_path)
	if _changing:
		return
	_changing = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.2)
	await tw.finished
	if path.begins_with("res://scenes/levels/"):
		set_state(State.PLAYING)
	else:
		set_state(State.HUB if path == SCENES[&"colony"] else State.MENU)
		InputRouter.set_enabled(false)
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.25)
	_changing = false


func start_level(level_id: StringName, bug_id: StringName, slot: StringName) -> void:
	current_level = level_id
	current_bug = bug_id
	current_time_slot = slot
	var cfg := get_level(level_id)
	if cfg:
		goto(cfg.scene_path)


func restart_level() -> void:
	start_level(current_level, current_bug, current_time_slot)


func next_level_id() -> StringName:
	var i := LEVEL_IDS.find(current_level)
	if i >= 0 and i + 1 < LEVEL_IDS.size():
		return LEVEL_IDS[i + 1]
	return &""


## Clean shutdown: silence audio and let playbacks drain before quitting.
func quit_game(exit_code: int = 0) -> void:
	AudioManager.stop_all()
	for i in 3:
		await get_tree().process_frame
	get_tree().quit(exit_code)


func toggle_pause() -> void:
	if state == State.PLAYING:
		set_state(State.PAUSED)
	elif state == State.PAUSED:
		set_state(State.PLAYING)


func begin_run(r: RunStats) -> void:
	run = r


## Called by the level when the run ends. Scores, banks crumbs, unlocks, saves.
func finish_run(won: bool, cause: StringName = &"") -> Dictionary:
	if run == null:
		return {}
	Engine.time_scale = 1.0
	run.won = won
	run.cause = cause
	var cfg := get_level(current_level)
	var par := cfg.par_time if cfg else 180.0
	var sc := run.score(scoring, par)
	var badges := run.badges(par)
	var was_completed := SaveSystem.is_level_completed(current_level)
	var newly := SaveSystem.record_level_result(current_level, won, int(sc["total"]), run.time, badges)
	var banked := run.crumbs + (5 if run.golden else 0)
	if not won:
		banked = int(run.crumbs * scoring.caught_bank_ratio)
	SaveSystem.bank_crumbs(banked)
	var unlocks: Array = []
	if won and cfg and cfg.unlocks_bug != &"":
		if SaveSystem.unlock_bug(cfg.unlocks_bug):
			var bs := get_bug_stats(cfg.unlocks_bug)
			unlocks.append("%s unlocked!" % (bs.display_name if bs else String(cfg.unlocks_bug)))
	if won:
		for b in unlock_after_escape(current_bug):
			unlocks.append("%s is out of the shade - new bug unlocked!" % get_bug_stats(b).display_name)
	if won and not was_completed:
		var nxt := next_level_id()
		if nxt != &"":
			var ncfg := get_level(nxt)
			if ncfg and ncfg.unlock_after == current_level:
				unlocks.append("%s unlocked!" % ncfg.display_name)
	SaveSystem.save_game()
	last_result = {
		"won": won, "cause": cause, "score": sc, "badges": badges, "new_badges": newly,
		"banked": banked, "unlocks": unlocks, "time": run.time,
		"level": current_level, "bug": current_bug, "new_treasures": run.new_treasures.duplicate(),
	}
	set_state(State.WIN if won else State.CAUGHT)
	run_finished.emit(last_result)
	return last_result


# --- Settings ---------------------------------------------------------------

func apply_quality() -> void:
	var q := quality()
	var vp := get_viewport()
	match q:
		"low":
			vp.scaling_3d_scale = 0.75
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_2X
			Engine.max_fps = 30
		"high":
			vp.scaling_3d_scale = 1.0
			vp.msaa_3d = Viewport.MSAA_4X
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_8X
			Engine.max_fps = 0
		_:
			vp.scaling_3d_scale = 1.0
			# (Screen-space AA isn't available in the Compatibility renderer.)
			vp.msaa_3d = Viewport.MSAA_2X
			vp.anisotropic_filtering_level = Viewport.ANISOTROPY_4X
			Engine.max_fps = 60
	RenderingServer.directional_shadow_atlas_set_size(4096 if q == "high" else 2048, true)
	# Bump detail on every textured surface; off on low for speed.
	for m in _textured_materials():
		m.normal_enabled = q != "low"
	if Level.current and is_instance_valid(Level.current):
		Level.current.refresh_quality()


## Behind the bug <-> through its eyes (V, the EYES button, Settings).
func toggle_first_person() -> bool:
	var on := not bool(SaveSystem.get_setting("first_person", false))
	SaveSystem.set_setting("first_person", on)
	if Level.current and is_instance_valid(Level.current) and Level.current.camera:
		Level.current.camera.set_first_person(on)
		Level.current.set_hint("Bug's-eye view - V / EYES to switch back" if on else "Behind the bug")
	return on


func quality() -> String:
	return String(SaveSystem.get_setting("quality", "medium"))


## The textured materials, kept loaded so a quality change reaches every user.
var _textured: Array[BaseMaterial3D] = []


func _textured_materials() -> Array[BaseMaterial3D]:
	if _textured.is_empty():
		var dir := DirAccess.open("res://assets/materials")
		if dir:
			for f in dir.get_files():
				var file := f.trim_suffix(".remap")
				if not file.ends_with(".tres"):
					continue
				var m := load("res://assets/materials/" + file) as BaseMaterial3D
				if m and m.normal_texture:
					_textured.append(m)
	return _textured


func shadows_enabled() -> bool:
	return quality() != "low"
