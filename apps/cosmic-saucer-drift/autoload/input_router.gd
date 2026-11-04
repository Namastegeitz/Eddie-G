extends Node
## Turns keyboard, gamepads, touch buttons and tilt into per-player driving
## controls. Gameplay only calls controls(slot).
##
## One player: every keyboard key, every gamepad, touch and tilt drive P1.
## Two players: P1 = WASD + Space (drift) + E (item) + Q (look back) and the
## first gamepad when two are connected; P2 = arrows + / or Right Ctrl
## (drift) + . or Enter (item) + , (look back) and the last gamepad.

class Controls:
	var steer := 0.0
	var throttle := 0.0
	var brake := 0.0
	var drift := false
	var item := false
	var look_back := false

var two_player := false
var touch_seen := false
## Written by the on-screen TouchControls.
var touch := {"steer": 0.0, "throttle": 0.0, "brake": 0.0, "drift": false, "item": false, "look_back": false, "active": false}
var _tilt_zero := 0.0
var _c := [Controls.new(), Controls.new()]

const DEAD := 0.15


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_seen = DisplayServer.is_touchscreen_available()


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		touch_seen = true


func pads() -> Array[int]:
	return Input.get_connected_joypads()


func _pad_for(slot: int) -> Array[int]:
	var p := pads()
	if not two_player:
		return p
	if p.size() >= 2:
		return [p[0]] if slot == 0 else [p[p.size() - 1]]
	if p.size() == 1 and slot == 1:
		return [p[0]]
	return []


func _k(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)


func controls(slot: int) -> Controls:
	var c: Controls = _c[slot]
	var steer := 0.0
	var thr := 0.0
	var brk := 0.0
	var drift := false
	var item := false
	var look := false
	var p1 := slot == 0
	var all_keys := not two_player
	# Keyboard.
	if p1 or all_keys:
		if _k(KEY_A): steer -= 1.0
		if _k(KEY_D): steer += 1.0
		if _k(KEY_W): thr = 1.0
		if _k(KEY_S): brk = 1.0
		if _k(KEY_SPACE) or (all_keys and _k(KEY_SHIFT)): drift = true
		if _k(KEY_E) or (all_keys and (_k(KEY_CTRL) or _k(KEY_F))): item = true
		if _k(KEY_Q) or (all_keys and _k(KEY_C)): look = true
	if not p1 or all_keys:
		if _k(KEY_LEFT): steer -= 1.0
		if _k(KEY_RIGHT): steer += 1.0
		if _k(KEY_UP): thr = 1.0
		if _k(KEY_DOWN): brk = 1.0
		if _k(KEY_SLASH) or _k(KEY_KP_0) or (not all_keys and _k(KEY_CTRL)): drift = true
		if _k(KEY_PERIOD) or _k(KEY_ENTER) or _k(KEY_KP_ENTER): item = true
		if _k(KEY_COMMA): look = true
	# Gamepads.
	for d in _pad_for(slot):
		var x := Input.get_joy_axis(d, JOY_AXIS_LEFT_X)
		if absf(x) > DEAD:
			steer += signf(x) * (absf(x) - DEAD) / (1.0 - DEAD)
		if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_LEFT): steer -= 1.0
		if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_RIGHT): steer += 1.0
		var rt := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_RIGHT)
		var lt := Input.get_joy_axis(d, JOY_AXIS_TRIGGER_LEFT)
		thr = maxf(thr, rt)
		if Input.is_joy_button_pressed(d, JOY_BUTTON_A): thr = 1.0
		brk = maxf(brk, lt)
		if Input.is_joy_button_pressed(d, JOY_BUTTON_B): brk = 1.0
		if Input.is_joy_button_pressed(d, JOY_BUTTON_RIGHT_SHOULDER): drift = true
		if Input.is_joy_button_pressed(d, JOY_BUTTON_X) or Input.is_joy_button_pressed(d, JOY_BUTTON_LEFT_SHOULDER): item = true
		if Input.is_joy_button_pressed(d, JOY_BUTTON_Y): look = true
	# Touch + tilt (player one only).
	if p1 and touch.active:
		steer += touch.steer
		thr = maxf(thr, touch.throttle)
		brk = maxf(brk, touch.brake)
		drift = drift or touch.drift
		item = item or touch.item
		look = look or touch.look_back
		if Save.setting("steering") == "tilt":
			steer += tilt_steer()
	if p1 and Save.setting("auto_accel") and (touch.active or touch_seen) and brk < 0.5:
		thr = 1.0
	c.steer = clampf(steer, -1.0, 1.0)
	c.throttle = clampf(thr, 0.0, 1.0)
	c.brake = clampf(brk, 0.0, 1.0)
	c.drift = drift
	c.item = item
	c.look_back = look
	return c


## Tilt steering from the accelerometer, relative to how the phone was held
## at the start of the race.
func tilt_steer() -> float:
	var a := Input.get_accelerometer()
	if a == Vector3.ZERO:
		return 0.0
	var raw := _tilt_axis(a) - _tilt_zero
	var sens: float = Save.setting("tilt_sensitivity")
	var v := clampf(raw / (4.2 / maxf(sens, 0.2)), -1.0, 1.0)
	if absf(v) < 0.06:
		v = 0.0
	return -v if Save.setting("tilt_invert") else v


func _tilt_axis(a: Vector3) -> float:
	# In landscape the steering tilt shows up on the device's long axis.
	var o := DisplayServer.screen_get_orientation()
	if o == DisplayServer.SCREEN_REVERSE_LANDSCAPE:
		return -a.y
	return a.y


func calibrate_tilt() -> void:
	var a := Input.get_accelerometer()
	_tilt_zero = _tilt_axis(a) if a != Vector3.ZERO else 0.0


func any_menu_pressed() -> bool:
	return Input.is_action_just_pressed("ui_accept")


## Short vibration on the phone, rumble on the player's gamepad.
func rumble(slot: int, strength: float, seconds: float) -> void:
	if not Save.setting("haptics"):
		return
	strength = clampf(strength, 0.0, 1.0)
	if slot == 0 and touch_seen and OS.has_feature("mobile"):
		Input.vibrate_handheld(int(seconds * 1000.0), strength)
	for d in _pad_for(slot):
		Input.start_joy_vibration(d, strength * 0.6, strength, seconds)
