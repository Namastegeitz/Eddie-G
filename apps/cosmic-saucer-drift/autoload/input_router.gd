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
	var gas := 0.0           # gas actually pressed (pedal/key/trigger), without auto-drive
	var brake := 0.0
	var drift := false
	var item := false
	var look_back := false
	var glide := false       # unfold the energy wings while airborne (SHIFT / D-pad up; automatic on touch)
	var wonder := false      # fire the craft's Technical Wonder (R / right stick click / D-pad down)

## Auto-drive (touch) cruises a little below full power; hold GAS for 100%.
const AUTO_CRUISE := 0.92

var two_player := false
var touch_seen := false
## Written by the on-screen TouchControls.
var touch := {"steer": 0.0, "throttle": 0.0, "brake": 0.0, "drift": false, "item": false, "look_back": false, "wonder": false, "active": false}
var _tilt_zero := 0.0
var _c := [Controls.new(), Controls.new()]

## Mouse as a flight stick (player one, when Settings > Mouse controls is on):
## slide left/right to steer, push forward to open the throttle, pull back
## to brake; the stick stays where you leave it (like a real stick and a
## throttle lever) and MOUSE_RANGE px of movement is full travel. Left
## button drifts, right button fires the item, middle button looks back.
## A race can capture the pointer so the cursor never hits the screen edge.
const MOUSE_RANGE := 220.0
const MOUSE_IDLE := 0.12    # throttle lever band that means "cruise"
var mouse_stick := Vector2.ZERO       # x steer, y thrust (-1 brake .. 1 full gas)
var mouse_active := false             # a mouse has been moved during this race
const MOUSE_STEER_DEAD := 0.07         # tiny stick offsets never steer
const MOUSE_CENTRE_DELAY := 0.35       # seconds the mouse rests before the stick self-centres
const MOUSE_CENTRE_RATE := 1.6         # how fast it straightens (stick units per second)
var _mouse_rest := 0.0                 # seconds since the mouse last moved
var mouse_capture_wanted := false     # set by the race while racing with mouse controls

const DEAD := 0.15


## A flight stick you let go of straightens itself: once the mouse has
## rested for a moment the steering half of the stick eases back to centre,
## so a nudge never turns into a lean (the throttle lever stays where it is).
func _process(dt: float) -> void:
	if not mouse_active:
		return
	_mouse_rest += dt
	if _mouse_rest > MOUSE_CENTRE_DELAY and mouse_stick.x != 0.0:
		mouse_stick.x = move_toward(mouse_stick.x, 0.0, MOUSE_CENTRE_RATE * dt)


## Steering from the mouse stick with its dead zone taken out.
func mouse_steer() -> float:
	var x := mouse_stick.x
	if absf(x) < MOUSE_STEER_DEAD:
		return 0.0
	return signf(x) * (absf(x) - MOUSE_STEER_DEAD) / (1.0 - MOUSE_STEER_DEAD)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	touch_seen = DisplayServer.is_touchscreen_available()


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		touch_seen = true
	elif e is InputEventMouseMotion and mouse_on():
		# Relative motion (works captured or not; captured never hits an edge).
		var r: Vector2 = e.relative
		if r.length_squared() > 0.0 and (mouse_active or r.length() < 60.0):
			mouse_active = true
			_mouse_rest = 0.0
			mouse_stick.x = clampf(mouse_stick.x + r.x / MOUSE_RANGE, -1.0, 1.0)
			mouse_stick.y = clampf(mouse_stick.y - r.y / MOUSE_RANGE, -1.0, 1.0)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and mouse_capture_wanted and mouse_on():
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Mouse controls apply to player one with a mouse (never when a touchscreen
## is driving, nor in split-screen).
func mouse_on() -> bool:
	return bool(Save.setting("mouse_controls")) and not touch.active and not two_player


## Straighten the stick and close the throttle lever (race start, re-centre).
func mouse_recentre() -> void:
	mouse_stick = Vector2.ZERO


func release_mouse() -> void:
	mouse_capture_wanted = false
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	var glide := false
	var wonder := false
	var p1 := slot == 0
	var all_keys := not two_player
	# Keyboard.
	if p1 or all_keys:
		if _k(KEY_A): steer -= 1.0
		if _k(KEY_D): steer += 1.0
		if _k(KEY_W): thr = 1.0
		if _k(KEY_S): brk = 1.0
		if _k(KEY_SPACE): drift = true
		if _k(KEY_SHIFT): glide = true
		if _k(KEY_E) or (all_keys and (_k(KEY_CTRL) or _k(KEY_F))): item = true
		if _k(KEY_Q) or (all_keys and _k(KEY_C)): look = true
		if _k(KEY_R): wonder = true
	if not p1 or all_keys:
		if _k(KEY_LEFT): steer -= 1.0
		if _k(KEY_RIGHT): steer += 1.0
		if _k(KEY_UP): thr = 1.0
		if _k(KEY_DOWN): brk = 1.0
		if _k(KEY_SLASH) or _k(KEY_KP_0) or (not all_keys and _k(KEY_CTRL)): drift = true
		if _k(KEY_PERIOD) or _k(KEY_ENTER) or _k(KEY_KP_ENTER): item = true
		if _k(KEY_COMMA): look = true
		if _k(KEY_KP_ADD) or _k(KEY_END): glide = true
		if _k(KEY_SEMICOLON) or _k(KEY_KP_1): wonder = true
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
		if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_UP) or Input.is_joy_button_pressed(d, JOY_BUTTON_LEFT_STICK): glide = true
		if Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_DOWN) or Input.is_joy_button_pressed(d, JOY_BUTTON_RIGHT_STICK): wonder = true
	# Mouse flight stick (player one only).
	if p1 and mouse_on() and mouse_active:
		steer += mouse_steer()
		if mouse_stick.y > MOUSE_IDLE:
			thr = maxf(thr, (mouse_stick.y - MOUSE_IDLE) / (1.0 - MOUSE_IDLE))
		elif mouse_stick.y < -MOUSE_IDLE:
			brk = maxf(brk, (-mouse_stick.y - MOUSE_IDLE) / (1.0 - MOUSE_IDLE))
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): drift = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): item = true
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE): look = true
	# Touch + tilt (player one only).
	if p1 and touch.active:
		steer += touch.steer
		thr = maxf(thr, touch.throttle)
		brk = maxf(brk, touch.brake)
		drift = drift or touch.drift
		item = item or touch.item
		look = look or touch.look_back
		wonder = wonder or touch.wonder
		if Save.setting("steering") == "tilt":
			steer += tilt_steer()
	c.gas = clampf(thr, 0.0, 1.0)
	# Auto-drive: on touch, and with the mouse stick while the lever sits in
	# its cruise band (keys and pads drive themselves as before).
	var cruise: bool = bool(touch.active) or (touch_seen and not two_player) or (mouse_on() and mouse_active)
	if p1 and Save.setting("auto_accel") and cruise and brk < 0.5:
		thr = maxf(thr, AUTO_CRUISE)
	c.steer = clampf(steer, -1.0, 1.0)
	c.throttle = clampf(thr, 0.0, 1.0)
	c.glide = glide
	c.wonder = wonder
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
