class_name TouchControls
extends Control
## Multi-touch on-screen controls for player one, written into
## InputRouter.touch.
##
## Left side, by Settings > Steering:
##   joystick (default): a floating thumbstick. Touch anywhere in the lower
##     left of the screen and it appears under your thumb; slide left/right
##     to steer, as gently or as hard as you like.
##   buttons: ◀ ▶ buttons.   tilt: nothing (steer by tilting the phone).
##     Push the stick up for GAS, pull it straight down to BRAKE.
##   buttons: ◀ ▶ buttons.   tilt: nothing (steer by tilting the phone).
## Right side: DRIFT (becomes TRICK in the air), ITEM, and the GAS and BRAKE
## pedals. With auto-drive on the craft cruises by itself; hold GAS for full
## power (and on GO for a rocket start), BRAKE to slow down or reverse.

const STICK_DEAD := 0.08
const STICK_FULL := 0.85      # full lock before the edge, so it never feels short
const STICK_GAS := 0.55       # push up this far for gas
const STICK_BRAKE := 0.7      # pull down this far (and mostly straight) to brake

var racer: Racer
var _touches := {}   # index -> position
var _buttons := {}   # name -> Rect2
var _stick_id := -1
var _stick_base := Vector2.ZERO
var _stick_knob := Vector2.ZERO
var _pedal_box: StyleBoxFlat
var _stick_gas := false
var _stick_brake := false
var _was_pressed := {}     # button -> pressed last refresh (for haptic ticks)
var _sig := ""             # what was drawn last frame; redraw only on change
var blockers: Array[Control] = []   # e.g. the COCKPIT tab: touches there aren't the joystick


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	InputRouter.touch.active = true
	_pedal_box = StyleBoxFlat.new()
	_pedal_box.set_corner_radius_all(22)
	_pedal_box.set_border_width_all(4)


func _exit_tree() -> void:
	InputRouter.touch.active = false
	InputRouter.touch.steer = 0.0
	InputRouter.touch.drift = false
	InputRouter.touch.item = false
	InputRouter.touch.brake = 0.0
	InputRouter.touch.throttle = 0.0


## 1.0 on the design canvas (1280x720, or 720x1280 in portrait): a button
## is about a fifth of the shorter screen side, roughly 80 pt on a phone.
func _unit() -> float:
	return minf(minf(size.x, size.y) / 720.0, maxf(size.x, size.y) / 1280.0)


func _mode() -> String:
	return String(Save.setting("steering"))


func stick_radius() -> float:
	return 72.0 * _unit()


## Where the stick rests when no thumb is on it.
func stick_home() -> Vector2:
	var r := stick_radius()
	return Vector2(r + 60.0 * _unit(), size.y - r - 50.0 * _unit())


## Touches that start here grab the joystick.
func stick_zone() -> Rect2:
	return Rect2(0, size.y * 0.32, size.x * 0.45, size.y * 0.68)


func _layout() -> void:
	var s := size
	var u := _unit()
	var b := 150.0 * u
	var m := 24.0 * u
	_buttons.clear()
	if _mode() == "buttons":
		_buttons["left"] = Rect2(m, s.y - b - m, b, b)
		_buttons["right"] = Rect2(m * 2.0 + b, s.y - b - m, b, b)
	_buttons["drift"] = Rect2(s.x - b * 1.25 - m, s.y - b * 1.25 - m, b * 1.25, b * 1.25)
	_buttons["item"] = Rect2(s.x - b * 1.25 - m * 2.0 - b * 0.85, s.y - b * 0.85 - m, b * 0.85, b * 0.85)
	# Pedals: GAS tall on the right edge above DRIFT, BRAKE beside it.
	_buttons["gas"] = Rect2(s.x - b * 0.8 - m, s.y - b * 1.25 - m * 2.0 - b * 1.05, b * 0.8, b * 1.05)
	_buttons["brake"] = Rect2(s.x - b * 0.8 - m * 2.0 - b * 0.72, s.y - b * 1.25 - m * 2.0 - b * 0.8, b * 0.72, b * 0.8)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _mode() == "joystick" and _stick_id < 0 and stick_zone().has_point(e.position) and not _on_button(e.position) and not _blocked(e.position):
				_stick_id = e.index
				var r := stick_radius()
				_stick_base = Vector2(clampf(e.position.x, r, size.x - r), clampf(e.position.y, r, size.y - r))
				_stick_knob = e.position
		else:
			_touches.erase(e.index)
			if e.index == _stick_id:
				_stick_id = -1
		_refresh()
	elif e is InputEventScreenDrag:
		_touches[e.index] = e.position
		if e.index == _stick_id:
			_stick_knob = e.position
			# Slide the base along if the thumb wanders past the edge, so the
			# stick never feels stuck at full lock.
			var r := stick_radius() * 1.15
			var d := _stick_knob - _stick_base
			if d.length() > r:
				_stick_base = _stick_knob - d.normalized() * r
		_refresh()


func _blocked(p: Vector2) -> bool:
	for b in blockers:
		if is_instance_valid(b) and b.is_visible_in_tree() and b.get_global_rect().grow(8.0).has_point(p):
			return true
	return false


func _on_button(p: Vector2) -> bool:
	_layout()
	for n in _buttons:
		if (_buttons[n] as Rect2).grow(18.0).has_point(p):
			return true
	return false


## Joystick deflection, -1..1 on each axis (y down is positive).
func stick_vec() -> Vector2:
	if _stick_id < 0:
		return Vector2.ZERO
	return ((_stick_knob - _stick_base) / stick_radius()).limit_length(1.0)


## Joystick steer: -1..1 with a small dead zone and full lock a little before
## the edge; gentle near the centre for small corrections.
func stick_steer() -> float:
	var x := stick_vec().x
	if absf(x) < STICK_DEAD:
		return 0.0
	var s := clampf((absf(x) - STICK_DEAD) / (STICK_FULL - STICK_DEAD), 0.0, 1.0)
	return signf(x) * lerpf(s, s * s, 0.35)


func _refresh() -> void:
	_layout()
	var st := 0.0
	var dr := false
	var it := false
	var br := 0.0
	var gas := 0.0
	for k in _touches:
		if k == _stick_id:
			continue
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
	st += stick_steer()
	var sv := stick_vec()
	_stick_gas = sv.y < -STICK_GAS and absf(sv.y) > absf(sv.x) * 0.9
	_stick_brake = sv.y > STICK_BRAKE and sv.y > absf(sv.x) * 1.4
	if _stick_gas:
		gas = 1.0
	if _stick_brake:
		br = 1.0
	InputRouter.touch.steer = clampf(st, -1.0, 1.0)
	InputRouter.touch.drift = dr
	InputRouter.touch.item = it
	InputRouter.touch.brake = br
	InputRouter.touch.throttle = gas
	# A short buzz when a button goes down, so presses can be felt.
	var now := {"drift": dr, "item": it, "brake": br > 0.0, "gas": gas > 0.0}
	for k in now:
		if now[k] and not _was_pressed.get(k, false):
			InputRouter.rumble(0, 0.35, 0.018)
	_was_pressed = now
	queue_redraw()


func _process(_dt: float) -> void:
	# Redraw only when something on the controls changed (cheaper on phones).
	var sig := "%d|%s|%s|%d|%d|%s" % [_stick_id, _stick_knob.round(), _touches.size(), racer.drift_tier if racer else 0,
		1 if (racer and not racer.grounded and racer.air_time > 0.15) else 0, racer.item if racer else ""]
	for k in _touches:
		sig += str(_touches[k].round())
	if sig != _sig:
		_sig = sig
		queue_redraw()


func _held(r: Rect2) -> bool:
	for k in _touches:
		if k != _stick_id and r.grow(18.0).has_point(_touches[k]):
			return true
	return false


func _draw() -> void:
	_layout()
	var font := UiKit.bold()
	if _mode() == "joystick":
		_draw_stick(font)
	for n in _buttons:
		var r: Rect2 = _buttons[n]
		var held := _held(r)
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
			"brake":
				_draw_pedal(r, "BRAKE", Color(1.0, 0.35, 0.3), held, font)
				continue
			"gas":
				_draw_pedal(r, "GAS", Color(0.35, 1.0, 0.5), held, font)
				continue
		var center := r.get_center()
		var rad := minf(r.size.x, r.size.y) * 0.5
		draw_circle(center, rad, c)
		draw_arc(center, rad, 0, TAU, 40, edge, 4.0)
		var fs := int(rad * (0.7 if label.length() <= 1 else 0.36))
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, center + Vector2(-tw * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.85))


func _draw_pedal(r: Rect2, label: String, col: Color, held: bool, font: Font) -> void:
	_pedal_box.bg_color = Color(col.r, col.g, col.b, 0.32 if held else 0.14)
	_pedal_box.border_color = Color(col.r, col.g, col.b, 0.95 if held else 0.6)
	draw_style_box(_pedal_box, r)
	# Tread lines like a pedal.
	for k in 3:
		var y := r.position.y + r.size.y * (0.22 + 0.11 * float(k))
		draw_line(Vector2(r.position.x + r.size.x * 0.22, y), Vector2(r.end.x - r.size.x * 0.22, y), Color(1, 1, 1, 0.22), 3.0)
	var fs := int(r.size.x * 0.24)
	var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(r.get_center().x - tw * 0.5, r.end.y - r.size.y * 0.18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
	if label == "GAS" and Save.setting("auto_accel"):
		var hint := "AUTO"
		var hs := int(r.size.x * 0.15)
		var hw := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs).x
		draw_string(font, Vector2(r.get_center().x - hw * 0.5, r.position.y + r.size.y * 0.16), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Color(col.r, col.g, col.b, 0.8))


func _draw_stick(font: Font) -> void:
	var r := stick_radius()
	var active := _stick_id >= 0
	var base := _stick_base if active else stick_home()
	var knob := base
	if active:
		var d := _stick_knob - _stick_base
		knob = base + d.limit_length(r)
	draw_circle(base, r, Color(1, 1, 1, 0.08 if not active else 0.14))
	draw_arc(base, r, 0, TAU, 48, Color(0.3, 0.92, 1.0, 0.45 if not active else 0.8), 4.0)
	# Arrows hint left/right steering.
	var fs := int(r * 0.32)
	for sx: float in [-1.0, 1.0]:
		var t := "◀" if sx < 0.0 else "▶"
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, base + Vector2(sx * r * 0.7 - tw * 0.5, fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.35))
	# Up = gas, down = brake markers on the ring.
	var gs := int(r * 0.2)
	for g in [["GAS", -1.0, _stick_gas, Color(0.35, 1.0, 0.5)], ["BRAKE", 1.0, _stick_brake, Color(1.0, 0.35, 0.3)]]:
		var gt: String = g[0]
		var gw := font.get_string_size(gt, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
		var gc: Color = g[3]
		gc.a = 0.95 if g[2] else 0.35
		draw_string(font, base + Vector2(-gw * 0.5, float(g[1]) * r * 0.72 + gs * 0.35), gt, HORIZONTAL_ALIGNMENT_LEFT, -1, gs, gc)
	draw_circle(knob, r * 0.44, Color(0.3, 0.92, 1.0, 0.35 if active else 0.22))
	draw_arc(knob, r * 0.44, 0, TAU, 32, Color(1, 1, 1, 0.7 if active else 0.4), 3.0)
	if not active:
		var t := "STEER"
		var ts := int(r * 0.2)
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		draw_string(font, base + Vector2(-tw * 0.5, ts * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color(1, 1, 1, 0.55))
