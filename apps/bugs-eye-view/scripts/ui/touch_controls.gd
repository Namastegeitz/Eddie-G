class_name TouchControls
extends Control
## On-screen controls for phones: a floating move joystick (left), context
## action buttons (right) labelled for the current bug, a look stick above the
## buttons with a look-speed button beside it, drag anywhere else to look, and
## quick taps aim (spider web). Multi-touch safe; everything goes to
## InputRouter. Auto-shown on touchscreens.

const ACTIONS: Array[StringName] = [&"primary", &"jump", &"secondary", &"dodge", &"interact", &"sense"]
const TAP_TIME := 0.25
const TAP_MOVE := 14.0
## Drag-to-look gain (was 1.4: too twitchy on phones). Players can scale it
## with "Touch look speed" in Settings.
const LOOK_GAIN := 0.6
## Look speeds the speed button steps through (the "Touch look speed" setting).
const LOOK_SPEEDS: Array[float] = [0.5, 0.75, 1.0, 1.5, 2.0]

var player: BugBase
var _labels: Dictionary = {}
var _label_timer := 0.0
var _btn_pos: Dictionary = {}
var _btn_r: Dictionary = {}
var _held: Dictionary = {}
var _touch_kind: Dictionary = {}
var _touch_start: Dictionary = {}
var _touch_time: Dictionary = {}
var _stick_index := -1
var _stick_base := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _stick_r := 90.0
var _font: Font
# Look stick (fixed, right side above the buttons) and its speed button.
var look_center := Vector2.ZERO
var look_radius := 80.0
var speed_center := Vector2.ZERO
var speed_radius := 34.0
## Switches between the view behind the bug and through its eyes.
var view_center := Vector2.ZERO
## The TOOLS button: opens the add-on revolver.
var tools_center := Vector2.ZERO
var revolver: Revolver
var _tools_icon: TextureRect
var _view_held := false
var _look_index := -1
var _look_knob := Vector2.ZERO
var _speed_held := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	resized.connect(_layout)
	InputRouter.touch_mode_changed.connect(_on_touch_mode)
	visible = InputRouter.is_touch_mode()
	_layout()


func _on_touch_mode(on: bool) -> void:
	visible = on


func bind_player(p: BugBase) -> void:
	player = p
	_labels = p.action_labels()


func _layout() -> void:
	var s := size
	var m := minf(s.x, s.y)
	var r := clampf(m * 0.065, 34.0, 58.0)
	_stick_r = clampf(m * 0.14, 70.0, 140.0)
	var a := Vector2(s.x - 16.0, s.y - 16.0)
	_btn_pos = {
		&"primary": a + Vector2(-1.7, -1.7) * r,
		&"jump": a + Vector2(-1.5, -4.6) * r,
		&"secondary": a + Vector2(-4.6, -1.3) * r,
		&"dodge": a + Vector2(-4.3, -4.2) * r,
		&"interact": a + Vector2(-7.3, -1.1) * r,
		&"sense": a + Vector2(-1.3, -7.3) * r,
	}
	for k: StringName in ACTIONS:
		_btn_r[k] = r * (1.35 if k == &"primary" else 1.0)
	# Look stick just above the button cluster, speed button to its left.
	look_radius = clampf(m * 0.105, 56.0, 100.0)
	speed_radius = r * 0.78
	var buttons_top := float(_btn_pos[&"sense"].y) - r
	look_center = Vector2(s.x - 16.0 - look_radius - r * 0.4, buttons_top - 16.0 - look_radius)
	look_center.y = maxf(look_center.y, s.y * 0.13 + look_radius)
	speed_center = look_center + Vector2(-look_radius - 18.0 - speed_radius, look_radius * 0.3)
	view_center = speed_center + Vector2(0, -speed_radius * 2.0 - 14.0)
	# TOOLS (the add-on revolver) under the speed button, clear of the open
	# screen used for looking.
	tools_center = speed_center + Vector2(0, speed_radius * 2.0 + 14.0)
	_look_knob = look_center
	queue_redraw()


## Steps the look speed up through LOOK_SPEEDS, wrapping back to the slowest.
func cycle_look_speed() -> float:
	var cur := float(SaveSystem.get_setting("touch_look_sensitivity", 1.0))
	var next := LOOK_SPEEDS[0]
	for v in LOOK_SPEEDS:
		if v > cur + 0.01:
			next = v
			break
	SaveSystem.set_setting("touch_look_sensitivity", next)
	SaveSystem.save_game()
	queue_redraw()
	return next


static func speed_label(v: float) -> String:
	var t := String.num(v, 2)
	if t.ends_with(".0"):
		t = t.left(-2)
	return t + "x"


func _process(delta: float) -> void:
	if not visible:
		return
	_label_timer -= delta
	if _label_timer <= 0.0 and player and is_instance_valid(player):
		_label_timer = 0.5
		_labels = player.action_labels()
		queue_redraw()


func _button_at(pos: Vector2) -> StringName:
	for k: StringName in ACTIONS:
		if pos.distance_to(_btn_pos[k]) <= float(_btn_r[k]) * 1.15:
			return k
	return &""


func _input(event: InputEvent) -> void:
	if not visible or not InputRouter.enabled:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_on_down(t.index, t.position)
		else:
			_on_up(t.index, t.position)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		_on_drag(d.index, d.position, d.relative)


func _on_down(i: int, pos: Vector2) -> void:
	# Leave the top strip (pause button, HUD) to the regular GUI.
	if pos.y < size.y * 0.12:
		return
	var b := _button_at(pos)
	if b != &"":
		_touch_kind[i] = b
		_held[b] = true
		InputRouter.set_touch_action(b, true)
	elif pos.distance_to(speed_center) <= speed_radius * 1.2:
		_touch_kind[i] = &"speed"
		_speed_held = true
		cycle_look_speed()
	elif pos.distance_to(tools_center) <= speed_radius * 1.2 and revolver:
		_touch_kind[i] = &"tools"
		revolver.open()
	elif pos.distance_to(view_center) <= speed_radius * 1.2:
		_touch_kind[i] = &"view"
		_view_held = true
		GameManager.toggle_first_person()
		queue_redraw()
	elif pos.distance_to(look_center) <= look_radius * 1.25 and _look_index == -1:
		_touch_kind[i] = &"lookstick"
		_look_index = i
		_set_look_knob(pos)
	elif pos.x < size.x * 0.45 and pos.y > size.y * 0.35 and _stick_index == -1:
		_touch_kind[i] = &"stick"
		_stick_index = i
		_stick_base = pos
		_stick_knob = pos
	else:
		_touch_kind[i] = &"look"
		_touch_start[i] = pos
		_touch_time[i] = Time.get_ticks_msec() / 1000.0
	get_viewport().set_input_as_handled()
	queue_redraw()


func _on_drag(i: int, pos: Vector2, rel: Vector2) -> void:
	var kind: StringName = _touch_kind.get(i, &"")
	if kind == &"stick":
		var off := (pos - _stick_base).limit_length(_stick_r)
		_stick_knob = _stick_base + off
		var v := off / _stick_r
		InputRouter.set_touch_move(Vector2(v.x, -v.y))
		queue_redraw()
	elif kind == &"look":
		InputRouter.add_touch_look(rel * LOOK_GAIN)
	elif kind == &"lookstick":
		_set_look_knob(pos)
	elif kind == &"speed" or kind == &"released":
		pass
	elif kind != &"":
		# Slid off a button: release it.
		if pos.distance_to(_btn_pos[kind]) > float(_btn_r[kind]) * 1.6:
			_release_button(i, kind)
	if kind != &"":
		get_viewport().set_input_as_handled()


func _on_up(i: int, pos: Vector2) -> void:
	var kind: StringName = _touch_kind.get(i, &"")
	if kind == &"stick":
		_stick_index = -1
		InputRouter.set_touch_move(Vector2.ZERO)
	elif kind == &"lookstick":
		_look_index = -1
		_look_knob = look_center
		InputRouter.set_touch_look_stick(Vector2.ZERO)
	elif kind == &"speed":
		_speed_held = false
	elif kind == &"view":
		_view_held = false
	elif kind == &"look":
		var dt := Time.get_ticks_msec() / 1000.0 - float(_touch_time.get(i, 0.0))
		var start: Vector2 = _touch_start.get(i, pos)
		if dt <= TAP_TIME and pos.distance_to(start) <= TAP_MOVE:
			InputRouter.touch_aim(pos)
	elif kind != &"":
		_release_button(i, kind)
	_touch_kind.erase(i)
	_touch_start.erase(i)
	_touch_time.erase(i)
	queue_redraw()


func _set_look_knob(pos: Vector2) -> void:
	var off := (pos - look_center).limit_length(look_radius)
	_look_knob = look_center + off
	InputRouter.set_touch_look_stick(off / look_radius)
	queue_redraw()


func _release_button(i: int, kind: StringName) -> void:
	_held[kind] = false
	InputRouter.set_touch_action(kind, false)
	_touch_kind[i] = &"released"


func _draw() -> void:
	var base_col := Color(1, 1, 1, 0.10)
	var ring_col := Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.55)
	# Joystick (shows a hint where it appears when idle).
	if _stick_index >= 0:
		draw_circle(_stick_base, _stick_r, base_col)
		draw_arc(_stick_base, _stick_r, 0.0, TAU, 40, ring_col, 3.0)
		draw_circle(_stick_knob, _stick_r * 0.42, Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.6))
	else:
		var hint := Vector2(_stick_r + 24.0, size.y - _stick_r - 24.0)
		draw_arc(hint, _stick_r, 0.0, TAU, 40, Color(1, 1, 1, 0.12), 2.0)
		draw_circle(hint, _stick_r * 0.42, Color(1, 1, 1, 0.08))
	_draw_look_controls(ring_col)
	for k: StringName in ACTIONS:
		var p: Vector2 = _btn_pos[k]
		var r: float = _btn_r[k]
		var held := bool(_held.get(k, false))
		draw_circle(p, r, Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.75) if held else Color(0, 0, 0, 0.42))
		draw_arc(p, r, 0.0, TAU, 32, ring_col, 3.0)
		var text := String(_labels.get(String(k), String(k).capitalize()))
		var fs := int(clampf(r * 0.36, 13.0, 20.0))
		var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(_font, p + Vector2(-w * 0.5, fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			UIKit.INK if held else UIKit.TEXT)


func _draw_look_controls(ring_col: Color) -> void:
	var held := _look_index >= 0
	draw_circle(look_center, look_radius, Color(0, 0, 0, 0.28 if held else 0.22))
	draw_arc(look_center, look_radius, 0.0, TAU, 40, ring_col if held else Color(1, 1, 1, 0.55), 3.0)
	# Direction ticks so it reads as a look stick.
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var d := Vector2.from_angle(a)
		draw_line(look_center + d * look_radius * 0.72, look_center + d * look_radius * 0.88, Color(1, 1, 1, 0.5), 2.0)
	draw_circle(_look_knob, look_radius * 0.42, Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.7) if held else Color(1, 1, 1, 0.28))
	var fs := int(clampf(look_radius * 0.2, 12.0, 18.0))
	var label := "LOOK"
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(_font, _look_knob + Vector2(-w * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		UIKit.INK if held else UIKit.TEXT)
	# Look speed button: shows the current speed; tap to step it.
	draw_circle(speed_center, speed_radius, Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.75) if _speed_held else Color(0, 0, 0, 0.42))
	draw_arc(speed_center, speed_radius, 0.0, TAU, 32, ring_col, 3.0)
	var top := "SPEED"
	var val := speed_label(float(SaveSystem.get_setting("touch_look_sensitivity", 1.0)))
	var fs1 := int(clampf(speed_radius * 0.3, 10.0, 15.0))
	var fs2 := int(clampf(speed_radius * 0.48, 13.0, 22.0))
	var col := UIKit.INK if _speed_held else UIKit.TEXT
	var w1 := _font.get_string_size(top, HORIZONTAL_ALIGNMENT_CENTER, -1, fs1).x
	var w2 := _font.get_string_size(val, HORIZONTAL_ALIGNMENT_CENTER, -1, fs2).x
	draw_string(_font, speed_center + Vector2(-w1 * 0.5, -fs1 * 0.25), top, HORIZONTAL_ALIGNMENT_LEFT, -1, fs1, col)
	draw_string(_font, speed_center + Vector2(-w2 * 0.5, fs2 * 0.95), val, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, UIKit.GOLD if not _speed_held else col)
	# View button: behind the bug / through its eyes.
	var fp := bool(SaveSystem.get_setting("first_person", false))
	draw_circle(view_center, speed_radius, Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.75) if _view_held else Color(0, 0, 0, 0.42))
	draw_arc(view_center, speed_radius, 0.0, TAU, 32, ring_col, 3.0)
	# A little eye.
	var ew := speed_radius * 0.5
	var eye_pts := PackedVector2Array()
	for k in 17:
		var a := PI * k / 8.0
		eye_pts.append(view_center + Vector2(cos(a) * ew, sin(a) * ew * 0.45) + Vector2(0, -fs1 * 0.6))
	draw_polyline(eye_pts, UIKit.GOLD if fp else UIKit.TEXT, 2.0, true)
	draw_circle(view_center + Vector2(0, -fs1 * 0.6), ew * 0.22, UIKit.GOLD if fp else UIKit.TEXT)
	var vl := "EYES" if not fp else "BACK"
	var w3 := _font.get_string_size(vl, HORIZONTAL_ALIGNMENT_CENTER, -1, fs1).x
	draw_string(_font, view_center + Vector2(-w3 * 0.5, fs1 * 1.3), vl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs1, col)
	_draw_tools_button(ring_col, fs1)


## TOOLS: the loaded add-on's icon and uses left; tap to open the revolver.
func _draw_tools_button(ring_col: Color, fs: int) -> void:
	if revolver == null or revolver.level == null:
		return
	var lvl := revolver.level
	var id := lvl.selected_addon()
	draw_circle(tools_center, speed_radius, Color(0, 0, 0, 0.42))
	draw_arc(tools_center, speed_radius, 0.0, TAU, 32, AddOns.KIND_COLORS.get(AddOns.kind(id), ring_col) if id != &"" else ring_col, 3.0)
	# A little six-chamber cylinder behind the icon.
	for k in 6:
		var a := TAU * k / 6.0 - PI * 0.5
		draw_circle(tools_center + Vector2(cos(a), sin(a)) * speed_radius * 0.55 + Vector2(0, -fs * 0.4), speed_radius * 0.13, Color(1, 1, 1, 0.18))
	# The icon is a TextureRect child (renders the same on every GPU).
	if _tools_icon == null:
		_tools_icon = TextureRect.new()
		_tools_icon.name = "ToolsIcon"
		_tools_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_tools_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_tools_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tools_icon)
	_tools_icon.visible = id != &""
	if id != &"":
		var s := speed_radius * 0.8
		_tools_icon.texture = AddOns.icon(id)
		_tools_icon.modulate = AddOns.color(id)
		_tools_icon.position = tools_center - Vector2(s, s) * 0.5 + Vector2(0, -fs * 0.4)
		_tools_icon.size = Vector2(s, s)
	var t := "TOOLS" if id == &"" else "x%d" % lvl.charges_left(id)
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(_font, tools_center + Vector2(-w * 0.5, fs * 1.3), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UIKit.GOLD)
