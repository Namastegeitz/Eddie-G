extends CanvasLayer
## In-game HUD: lives, crumbs, objective, clock + routine, threat indicator
## with escalation stages, stealth meters, hints, boss banner, reticle,
## off-screen threat markers and touch controls. Scales for portrait/landscape.

var level: Level
var player: BugBase
var _lives: Label
var _crumbs: Label
var _objective: Label
var _clock: Label
var _threat: Label
var _stages: Label
var _hint: Label
var _banner: Label
var _banner_sub: Label
var _toast: Label
var _reticle: Control
var _tint: ColorRect
var _meters: StealthMeters
var _markers: ThreatMarkers
var _touch: TouchControls
var _alarm: AlarmGauge
var _root: Control


func _ready() -> void:
	layer = 10
	_root = Control.new()
	UIKit.setup_root(_root)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_tint = ColorRect.new()
	_tint.color = Color(0.3, 0.55, 1.0, 0.14)
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.visible = false
	_root.add_child(_tint)
	_markers = ThreatMarkers.new()
	_root.add_child(_markers)
	_build_top()
	_meters = StealthMeters.new()
	_meters.position = Vector2(12, 150)
	_root.add_child(_meters)
	_hint = _make_label("", 22, UIKit.TEXT)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.anchor_left = 0.1
	_hint.anchor_right = 0.9
	_hint.offset_top = -230
	_hint.offset_bottom = -190
	_root.add_child(_hint)
	_banner = _make_label("", 46, UIKit.GOLD)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.offset_top = -120
	_banner.offset_bottom = -60
	_banner.visible = false
	_root.add_child(_banner)
	_banner_sub = _make_label("", 22, UIKit.TEXT)
	_banner_sub.set_anchors_preset(Control.PRESET_CENTER)
	_banner_sub.anchor_left = 0.05
	_banner_sub.anchor_right = 0.95
	_banner_sub.offset_top = -56
	_banner_sub.offset_bottom = -10
	_banner_sub.visible = false
	_root.add_child(_banner_sub)
	_toast = _make_label("", 30, UIKit.GOLD)
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.offset_top = 40
	_toast.offset_bottom = 90
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	_reticle = Control.new()
	_reticle.set_anchors_preset(Control.PRESET_CENTER)
	_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reticle.draw.connect(func() -> void:
		_reticle.draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color(1, 1, 1, 0.8), 2.0)
		_reticle.draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.9)))
	_reticle.visible = false
	_root.add_child(_reticle)
	_touch = TouchControls.new()
	_root.add_child(_touch)


func _make_label(text: String, size: int, color: Color) -> Label:
	var l := UIKit.label(text, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	return l


func _build_top() -> void:
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "right", "top"]:
		top.add_theme_constant_override("margin_" + side, 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)
	var row := UIKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(row)
	var left := UIKit.vbox(2)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	_lives = _make_label("", 24, UIKit.RED)
	_lives.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(_lives)
	_crumbs = _make_label("", 24, UIKit.GOLD)
	_crumbs.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(_crumbs)
	var mid := UIKit.vbox(2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 2.0
	row.add_child(mid)
	_objective = _make_label("", 22, UIKit.TEXT)
	mid.add_child(_objective)
	_clock = _make_label("", 18, UIKit.DIM)
	mid.add_child(_clock)
	_threat = _make_label("", 20, UIKit.GREEN)
	mid.add_child(_threat)
	_alarm = AlarmGauge.new()
	_alarm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alarm.custom_minimum_size.y = 38
	mid.add_child(_alarm)
	_stages = _make_label("", 15, UIKit.DIM)
	mid.add_child(_stages)
	var pause := Button.new()
	pause.text = "II"
	pause.custom_minimum_size = Vector2(64, 64)
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	pause.pressed.connect(GameManager.toggle_pause)
	row.add_child(pause)


func bind(lvl: Level) -> void:
	level = lvl
	player = lvl.player
	_markers.camera_rig = lvl.camera
	_meters.bind_player(player)
	_touch.bind_player(player)
	_reticle.visible = player is Spider
	lvl.crumbs_changed.connect(_on_crumbs)
	lvl.objective_changed.connect(func(t: String) -> void: _objective.text = t)
	lvl.hint_changed.connect(func(t: String) -> void: toast(t))
	lvl.boss_announced.connect(_on_boss)
	lvl.close_call.connect(func() -> void: toast("CLOSE CALL!"))
	PerceptionSystem.alarm_raised.connect(_on_alarm_raised)
	PerceptionSystem.alarm_cleared.connect(_on_alarm_cleared)
	player.hit_taken.connect(func(_l: int) -> void:
		_update_lives()
		toast("Hit! Shake it off"))
	player.died.connect(func(_c: StringName) -> void: _update_lives())
	player.hint_changed.connect(func(t: String) -> void: _hint.text = t)
	player.sense_changed.connect(func(on: bool) -> void: _tint.visible = on and player is Fly)
	PerceptionSystem.alert_level_changed.connect(_on_alert_level)
	PerceptionSystem.escalation_changed.connect(_on_alert_level)
	HouseClock.hour_changed.connect(_on_hour)
	HouseClock.routine_changed.connect(_update_clock)
	_update_lives()
	_update_threat()
	_update_clock()


func _on_alarm_raised() -> void:
	toast("FULL ALARM! Everyone is after you")


func _on_alarm_cleared() -> void:
	toast("The alarm died down")


func _on_alert_level(_v: int) -> void:
	_update_threat()


func _on_hour(_h: float) -> void:
	_update_clock()


func _on_crumbs(got: int, needed: int) -> void:
	_crumbs.text = "CRUMBS %d / %d" % [got, needed]


func _update_lives() -> void:
	if player == null:
		return
	var s := ""
	for i in player.stats.max_hits:
		s += "O " if i < player.hits_left else "x "
	_lives.text = "SHELL " + s if player.stats.max_hits > 1 else "LIFE " + s


func _update_threat() -> void:
	var names := ["CALM", "SUSPICIOUS ?", "SEARCHING ?", "SPOTTED !"]
	var cols := [UIKit.GREEN, Color(1, 0.9, 0.2), Color(1, 0.55, 0.1), UIKit.RED]
	var a := clampi(PerceptionSystem.max_alert, 0, 3)
	_threat.text = "THREAT: " + String(names[a])
	_threat.add_theme_color_override("font_color", cols[a])
	var stage := PerceptionSystem.escalation_stage
	var cfg := PerceptionSystem.config
	var parts: PackedStringArray = []
	for i in range(1, cfg.stage_names.size()):
		var n := cfg.stage_names[i]
		parts.append("[%s]" % n.to_upper() if i <= stage else n.to_lower())
	_stages.text = " > ".join(parts)
	_stages.add_theme_color_override("font_color", UIKit.RED if stage > 0 else UIKit.DIM)


func _update_clock() -> void:
	var labels := HouseClock.active_labels()
	_clock.text = HouseClock.clock_text() + ("  -  " + ", ".join(labels) if not labels.is_empty() else "")


func _on_boss(title: String, sub: String) -> void:
	_banner.text = title.to_upper()
	_banner_sub.text = sub
	_banner.visible = true
	_banner_sub.visible = true
	_banner.modulate.a = 1.0
	_banner_sub.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(_banner_sub, "modulate:a", 0.0, 0.6)


func toast(text: String) -> void:
	if text == "":
		return
	_toast.text = text
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)
