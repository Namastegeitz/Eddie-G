class_name TouchControls
extends Control
## On-screen controls for phones: a floating joystick (left), context action
## buttons (right) labelled for the current bug, drag anywhere else to look,
## and quick taps aim (spider web). Multi-touch safe; everything goes to
## InputRouter. Auto-shown on touchscreens.

const ACTIONS: Array[StringName] = [&"primary", &"jump", &"secondary", &"dodge", &"interact", &"sense"]
const TAP_TIME := 0.25
const TAP_MOVE := 14.0
const LOOK_GAIN := 1.4

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
	_labels = p.get_action_labels()


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
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_label_timer -= delta
	if _label_timer <= 0.0 and player and is_instance_valid(player):
		_label_timer = 0.5
		_labels = player.get_action_labels()
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
