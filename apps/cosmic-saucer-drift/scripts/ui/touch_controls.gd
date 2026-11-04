class_name TouchControls
extends Control
## Multi-touch on-screen buttons for player one. Left side: steer left /
## right (hidden in tilt mode). Right side: DRIFT (becomes TRICK in the air),
## ITEM and BRAKE. Writes into InputRouter.touch.

var racer: Racer
var _touches := {}   # index -> position
var _buttons := {}   # name -> Rect2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	InputRouter.touch.active = true


func _exit_tree() -> void:
	InputRouter.touch.active = false
	InputRouter.touch.steer = 0.0
	InputRouter.touch.drift = false
	InputRouter.touch.item = false
	InputRouter.touch.brake = 0.0


func _layout() -> void:
	var s := size
	var u := minf(s.y / 720.0, s.x / 1280.0) * 1.0
	var b := 150.0 * u
	var m := 24.0 * u
	_buttons.clear()
	if Save.setting("steering") != "tilt":
		_buttons["left"] = Rect2(m, s.y - b - m, b, b)
		_buttons["right"] = Rect2(m * 2.0 + b, s.y - b - m, b, b)
	_buttons["drift"] = Rect2(s.x - b * 1.25 - m, s.y - b * 1.25 - m, b * 1.25, b * 1.25)
	_buttons["item"] = Rect2(s.x - b * 1.25 - m * 2.0 - b * 0.85, s.y - b * 0.85 - m, b * 0.85, b * 0.85)
	_buttons["brake"] = Rect2(s.x - b * 0.8 - m, s.y - b * 1.25 - m * 2.0 - b * 0.7, b * 0.8, b * 0.7)
	if not Save.setting("auto_accel"):
		_buttons["gas"] = Rect2(s.x - b * 1.25 - m * 2.0 - b * 0.85, s.y - b * 0.85 * 2.0 - m * 2.0, b * 0.85, b * 0.85)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_refresh()
	elif e is InputEventScreenDrag:
		_touches[e.index] = e.position
		_refresh()


func _refresh() -> void:
	_layout()
	var st := 0.0
	var dr := false
	var it := false
	var br := 0.0
	var gas := 0.0
	for k in _touches:
		var p: Vector2 = _touches[k]
		for n in _buttons:
			var r: Rect2 = _buttons[n].grow(18.0)
			if r.has_point(p):
				match n:
					"left": st -= 1.0
					"right": st += 1.0
					"drift": dr = true
					"item": it = true
					"brake": br = 1.0
					"gas": gas = 1.0
	InputRouter.touch.steer = clampf(st, -1.0, 1.0)
	InputRouter.touch.drift = dr
	InputRouter.touch.item = it
	InputRouter.touch.brake = br
	InputRouter.touch.throttle = gas
	queue_redraw()


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	_layout()
	var font := UiKit.bold()
	for n in _buttons:
		var r: Rect2 = _buttons[n]
		var held := false
		for k in _touches:
			if r.grow(18.0).has_point(_touches[k]):
				held = true
		var c := Color(1, 1, 1, 0.16 if not held else 0.34)
		var edge := Color(0.3, 0.92, 1.0, 0.55)
		var label := ""
		match n:
			"left": label = "◀"
			"right": label = "▶"
			"drift":
				label = "DRIFT"
				if racer and not racer.grounded and racer.air_time > 0.15:
					label = "TRICK"
					edge = Color(1.0, 0.85, 0.3, 0.9)
				elif racer and racer.drift_tier > 0:
					edge = SaucerModel.SPARK_COLORS[racer.drift_tier - 1]
			"item":
				label = "ITEM"
				if racer and racer.item != "" and racer.item_roll <= 0.0:
					edge = Catalog.ITEMS[racer.item].color
					c.a += 0.1
			"brake": label = "BRAKE"
			"gas": label = "GAS"
		var center := r.get_center()
		var rad := minf(r.size.x, r.size.y) * 0.5
		draw_circle(center, rad, c)
		draw_arc(center, rad, 0, TAU, 40, edge, 4.0)
		var fs := int(rad * (0.7 if label.length() <= 1 else 0.36))
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, center + Vector2(-tw * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.85))
