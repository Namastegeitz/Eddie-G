extends Node
## The ONE place raw input is read. Touch, keyboard/mouse and gamepad all feed
## the same game actions; gameplay code only ever talks to this router.

signal action_pressed(action: StringName)
signal action_released(action: StringName)
## A tap on open screen space while touch controls are active (spider web aim).
signal aim_at_screen(screen_pos: Vector2)
signal pause_requested
signal touch_mode_changed(enabled: bool)

const PREFIX := "bev_"
const GAME_ACTIONS: Array[StringName] = [&"jump", &"primary", &"secondary", &"interact", &"dodge", &"sense"]
## Actions the settings screen lets players rebind (keyboard/mouse only).
const REBINDABLE: Array[String] = ["move_forward", "move_back", "move_left", "move_right",
	"jump", "primary", "secondary", "interact", "dodge", "sense", "creep", "revolver", "fire_addon"]
const MOUSE_LOOK_SCALE := 1.0
const STICK_LOOK_SPEED := 900.0
## The on-screen look stick at full tilt (gentler than a gamepad; the camera
## eases it in). Scaled by "Touch look speed".
const TOUCH_STICK_LOOK_SPEED := 520.0
const CREEP_SCALE := 0.4
## Browsers can report one huge jump right after pointer lock; ignore it.
const CAPTURE_GRACE := 0.25
const MAX_MOUSE_STEP := 250.0

var enabled: bool = false
var look_sensitivity: float = 1.0
## Separate from mouse/stick: how fast dragging on the touch screen turns the view.
var touch_look_sensitivity: float = 1.0
var invert_y: bool = false

var _touch_mode: bool = false
var _touch_move: Vector2 = Vector2.ZERO
var _look_accum: Vector2 = Vector2.ZERO
var _touch_look_accum: Vector2 = Vector2.ZERO
var _touch_look_stick: Vector2 = Vector2.ZERO
var _touch_held: Dictionary = {}
var _capture_grace := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_default_actions()
	apply_saved_bindings()
	SaveSystem.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


# --- Setup ------------------------------------------------------------------

func _default_events() -> Dictionary:
	return {
		"move_forward": [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_back": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)],
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)],
		"look_left": [_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"look_right": [_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"look_up": [_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"look_down": [_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"creep": [_key(KEY_C), _joy(JOY_BUTTON_LEFT_STICK)],
		"jump": [_key(KEY_SPACE), _joy(JOY_BUTTON_A)],
		"primary": [_mouse(MOUSE_BUTTON_LEFT), _key(KEY_F), _joy(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"secondary": [_mouse(MOUSE_BUTTON_RIGHT), _key(KEY_Q), _joy(JOY_BUTTON_Y), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"interact": [_key(KEY_E), _joy(JOY_BUTTON_B)],
		"dodge": [_key(KEY_SHIFT), _joy(JOY_BUTTON_RIGHT_SHOULDER)],
		"sense": [_key(KEY_R), _joy(JOY_BUTTON_LEFT_SHOULDER)],
		"pause": [_key(KEY_ESCAPE), _key(KEY_P), _joy(JOY_BUTTON_START)],
		"toggle_view": [_key(KEY_V), _joy(JOY_BUTTON_BACK)],
		"revolver": [_key(KEY_TAB), _joy(JOY_BUTTON_DPAD_UP)],
		"fire_addon": [_key(KEY_G), _joy(JOY_BUTTON_DPAD_DOWN)],
	}


func _register_default_actions() -> void:
	var defaults := _default_events()
	for action_name: String in defaults.keys():
		var action := PREFIX + action_name
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action, 0.25)
		for ev: InputEvent in defaults[action_name]:
			InputMap.action_add_event(action, ev)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


func _joy(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


func _on_settings_changed() -> void:
	look_sensitivity = float(SaveSystem.get_setting("look_sensitivity", 1.0))
	touch_look_sensitivity = float(SaveSystem.get_setting("touch_look_sensitivity", 1.0))
	invert_y = bool(SaveSystem.get_setting("invert_y", false))
	refresh_touch_mode()


# --- Rebinding --------------------------------------------------------------

## Serializes keyboard/mouse events of an action for the save file.
func _event_to_dict(e: InputEvent) -> Dictionary:
	if e is InputEventKey:
		return {"t": "key", "c": int((e as InputEventKey).physical_keycode)}
	if e is InputEventMouseButton:
		return {"t": "mouse", "c": int((e as InputEventMouseButton).button_index)}
	return {}


func _dict_to_event(d: Dictionary) -> InputEvent:
	match String(d.get("t", "")):
		"key":
			return _key(int(d["c"]) as Key)
		"mouse":
			return _mouse(int(d["c"]) as MouseButton)
	return null


func apply_saved_bindings() -> void:
	var saved := SaveSystem.get_bindings()
	for action_name: String in saved.keys():
		var action := PREFIX + action_name
		if not InputMap.has_action(action):
			continue
		for e: InputEvent in InputMap.action_get_events(action):
			if e is InputEventKey or e is InputEventMouseButton:
				InputMap.action_erase_event(action, e)
		for d: Variant in saved[action_name]:
			if d is Dictionary:
				var ev := _dict_to_event(d)
				if ev:
					InputMap.action_add_event(action, ev)


## Replaces the keyboard/mouse binding of an action, keeping gamepad events.
func rebind(action_name: String, event: InputEvent) -> void:
	var action := PREFIX + action_name
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey or e is InputEventMouseButton:
			InputMap.action_erase_event(action, e)
	var clean: InputEvent = event
	if event is InputEventKey:
		clean = _key((event as InputEventKey).physical_keycode)
	elif event is InputEventMouseButton:
		clean = _mouse((event as InputEventMouseButton).button_index)
	InputMap.action_add_event(action, clean)
	SaveSystem.set_binding(action_name, [_event_to_dict(clean)])
	SaveSystem.save_game()


func reset_bindings() -> void:
	SaveSystem.get_bindings().clear()
	SaveSystem.save_game()
	_register_default_actions()


func binding_text(action_name: String) -> String:
	var parts: PackedStringArray = []
	for e: InputEvent in InputMap.action_get_events(PREFIX + action_name):
		if e is InputEventKey:
			parts.append(OS.get_keycode_string((e as InputEventKey).physical_keycode))
		elif e is InputEventMouseButton:
			parts.append("Mouse %d" % int((e as InputEventMouseButton).button_index))
	return ", ".join(parts) if not parts.is_empty() else "-"


# --- Modes ----------------------------------------------------------------

func refresh_touch_mode() -> void:
	var mode := String(SaveSystem.get_setting("touch_controls", "auto"))
	var on := DisplayServer.is_touchscreen_available()
	if mode == "on":
		on = true
	elif mode == "off":
		on = false
	if on != _touch_mode:
		_touch_mode = on
		touch_mode_changed.emit(on)
	_update_mouse_mode()


func is_touch_mode() -> bool:
	return _touch_mode


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		_touch_move = Vector2.ZERO
		_look_accum = Vector2.ZERO
		_touch_look_accum = Vector2.ZERO
		_touch_look_stick = Vector2.ZERO
		for a: StringName in _touch_held.keys():
			if _touch_held[a]:
				action_released.emit(a)
		_touch_held.clear()
	_update_mouse_mode()


func _update_mouse_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if enabled and not _touch_mode:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_capture_grace = CAPTURE_GRACE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if _capture_grace > 0.0:
		_capture_grace -= delta
		_look_accum = Vector2.ZERO


# --- Raw input ------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PREFIX + "pause", false):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return
	if not enabled:
		return
	# In touch mode, mouse events are only emulated from touches: TouchControls
	# handles those touches directly, so ignore the emulated copies.
	if _touch_mode and event is InputEventMouse:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel := (event as InputEventMouseMotion).relative
		if _capture_grace <= 0.0 and rel.length() < MAX_MOUSE_STEP:
			_look_accum += rel * MOUSE_LOOK_SCALE
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and not _touch_mode and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and DisplayServer.get_name() != "headless":
		# First click only re-captures the mouse; it is not an attack.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_capture_grace = CAPTURE_GRACE
		return
	for a: StringName in GAME_ACTIONS:
		var action := PREFIX + String(a)
		if event.is_action_pressed(action, false):
			action_pressed.emit(a)
		elif event.is_action_released(action):
			action_released.emit(a)


# --- Polling API (gameplay) -------------------------------------------------

## x = strafe right, y = forward. Length is 0..1 (analog-aware).
func get_move_vector() -> Vector2:
	if not enabled:
		return Vector2.ZERO
	var v := Input.get_vector(PREFIX + "move_left", PREFIX + "move_right",
		PREFIX + "move_back", PREFIX + "move_forward")
	v += _touch_move
	if v.length() > 1.0:
		v = v.normalized()
	if Input.is_action_pressed(PREFIX + "creep"):
		v *= CREEP_SCALE
	return v


## Accumulated camera look since last call, in screen-pixel-like units.
func get_look_delta(delta: float) -> Vector2:
	var d := _look_accum
	_look_accum = Vector2.ZERO
	if not enabled:
		return Vector2.ZERO
	var stick := Input.get_vector(PREFIX + "look_left", PREFIX + "look_right",
		PREFIX + "look_up", PREFIX + "look_down")
	d += stick * STICK_LOOK_SPEED * delta
	d *= look_sensitivity
	if invert_y:
		d.y = -d.y
	return d


func is_held(action: StringName) -> bool:
	if not enabled:
		return false
	return Input.is_action_pressed(PREFIX + String(action)) or bool(_touch_held.get(action, false))


# --- Touch feed (from TouchControls) ----------------------------------------

func set_touch_move(v: Vector2) -> void:
	_touch_move = v.limit_length(1.0)


func add_touch_look(d: Vector2) -> void:
	_touch_look_accum += d


## On-screen look stick deflection (-1..1 each axis), from TouchControls.
func set_touch_look_stick(v: Vector2) -> void:
	_touch_look_stick = v.limit_length(1.0)


func get_touch_look_stick() -> Vector2:
	return _touch_look_stick


## Turn from the look stick this frame. Squared response: small pushes turn
## gently for aiming, a full push turns quickly.
func get_touch_stick_look(delta: float) -> Vector2:
	if not enabled or _touch_look_stick == Vector2.ZERO:
		return Vector2.ZERO
	var v := _touch_look_stick * _touch_look_stick.length()
	var d := v * TOUCH_STICK_LOOK_SPEED * delta * touch_look_sensitivity
	if invert_y:
		d.y = -d.y
	return d


## Touch-drag look since last call (the camera eases it in; see FollowCamera).
func get_touch_look_delta() -> Vector2:
	var d := _touch_look_accum * touch_look_sensitivity
	_touch_look_accum = Vector2.ZERO
	if not enabled:
		return Vector2.ZERO
	if invert_y:
		d.y = -d.y
	return d


func set_touch_action(action: StringName, pressed: bool) -> void:
	if not enabled:
		return
	var was := bool(_touch_held.get(action, false))
	_touch_held[action] = pressed
	if pressed and not was:
		action_pressed.emit(action)
	elif was and not pressed:
		action_released.emit(action)


func touch_aim(screen_pos: Vector2) -> void:
	if enabled:
		aim_at_screen.emit(screen_pos)
