class_name Revolver
extends Control
## The add-on revolver. Open it (Tab, D-pad up, or the TOOLS button) and the
## cylinder swings out while the game holds still: six chambers, each loaded
## with an add-on and its uses left. Turn it (tap a chamber, arrow keys,
## mouse wheel, D-pad, 1-6) to bring one to the top, then press USE in the
## middle (Enter / Space / F / A) to fire it. G (D-pad down) fires the loaded
## chamber without opening.

signal opened_changed(open: bool)

const OPEN_TIME := 0.22
const TURN_TIME := 0.18

var level: Level
var is_open := false
## 0 = closed, 1 = fully out (animates).
var swing := 0.0
## Cylinder angle (radians): chamber i sits at the top when angle = -i * TAU / 6.
var angle := 0.0
var _target_angle := 0.0
var _was_paused := false
var _font: Font
var _closing := false
## The chamber icons (TextureRects: they render the same on every GPU).
var _icons: Array[TextureRect] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_font = get_theme_default_font()
	for i in AddOns.CHAMBERS:
		var t := TextureRect.new()
		t.name = "Icon%d" % (i + 1)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(t)
		_icons.append(t)


func bind(lvl: Level) -> void:
	level = lvl
	angle = -level.chamber * TAU / AddOns.CHAMBERS
	_target_angle = angle


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open or level == null or level.finished or GameManager.state != GameManager.State.PLAYING:
		return
	is_open = true
	_closing = false
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_was_paused = get_tree().paused
	get_tree().paused = true
	InputRouter.set_enabled(false)
	AudioManager.play(&"revolver_spin", -4.0)
	opened_changed.emit(true)
	queue_redraw()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().paused = _was_paused
	if GameManager.state == GameManager.State.PLAYING:
		InputRouter.set_enabled(true)
	AudioManager.play(&"revolver_click", -6.0, 0.8)
	opened_changed.emit(false)


## Turns chamber `i` to the top (the shortest way round).
func select(i: int) -> void:
	if level == null:
		return
	var n := AddOns.CHAMBERS
	i = posmod(i, n)
	var want := -i * TAU / n
	var diff := wrapf(want - _target_angle, -PI, PI)
	_target_angle += diff
	level.select_chamber(i)
	queue_redraw()


func turn(step: int) -> void:
	if level:
		select(level.chamber + step)


## Fires the chamber at the top (closing the revolver first).
func fire() -> bool:
	if level == null:
		return false
	if is_open:
		close()
	return level.fire_selected()


func _process(delta: float) -> void:
	var want := 1.0 if is_open else 0.0
	if not is_equal_approx(swing, want):
		swing = move_toward(swing, want, delta / OPEN_TIME)
		queue_redraw()
	elif _closing and swing <= 0.0:
		_closing = false
		visible = false
	if not is_equal_approx(angle, _target_angle):
		angle = move_toward(angle, _target_angle, absf(_target_angle - angle) * delta / TURN_TIME * 3.0 + delta * 2.0)
		queue_redraw()
	# Open / quick-fire from the keyboard or gamepad while playing.
	if not is_open and level and not level.finished and GameManager.state == GameManager.State.PLAYING:
		if Input.is_action_just_pressed(InputRouter.PREFIX + "revolver"):
			open()
		elif Input.is_action_just_pressed(InputRouter.PREFIX + "fire_addon"):
			level.fire_selected()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		match k:
			KEY_TAB, KEY_ESCAPE, KEY_BACKSPACE:
				close()
			KEY_LEFT, KEY_A, KEY_Q:
				turn(-1)
			KEY_RIGHT, KEY_D, KEY_E:
				turn(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F:
				fire()
			_:
				if k >= KEY_1 and k <= KEY_6:
					select(k - KEY_1)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		match (event as InputEventJoypadButton).button_index:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_LEFT_SHOULDER:
				turn(-1)
			JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_RIGHT_SHOULDER:
				turn(1)
			JOY_BUTTON_A:
				fire()
			JOY_BUTTON_B, JOY_BUTTON_DPAD_UP, JOY_BUTTON_START:
				close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			turn(-1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			turn(1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			press_at(mb.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		press_at((event as InputEventScreenTouch).position)
		get_viewport().set_input_as_handled()


## A tap or click while open: USE in the middle fires, a chamber turns to
## it, anywhere outside the cylinder closes. Returns what it did.
func press_at(pos: Vector2) -> String:
	var c := _center()
	var r := _radius()
	if pos.distance_to(c) <= r * 0.24:
		fire()
		return "fire"
	for i in AddOns.CHAMBERS:
		if pos.distance_to(chamber_pos(i)) <= r * 0.3:
			if i == level.chamber:
				fire()
				return "fire"
			select(i)
			return "select"
	if pos.distance_to(c) > r * 1.15:
		close()
		return "close"
	return ""


func _center() -> Vector2:
	var s := size
	# Swings in from the right edge as it opens.
	var e := 1.0 - pow(1.0 - swing, 3.0)
	return Vector2(lerpf(s.x + _radius(), s.x * 0.5, e), s.y * 0.46)


func _radius() -> float:
	return minf(size.x, size.y) * 0.3


## Screen position of chamber i (top = the one that fires).
func chamber_pos(i: int) -> Vector2:
	var a := angle + i * TAU / AddOns.CHAMBERS - PI * 0.5
	return _center() + Vector2(cos(a), sin(a)) * _radius() * 0.58


## Puts each chamber's icon over its chamber (follows the turning cylinder).
func _place_icons() -> void:
	for i in _icons.size():
		var t := _icons[i]
		var id: StringName = level.loadout[i] if level and i < level.loadout.size() else &""
		t.visible = swing > 0.0 and id != &""
		if not t.visible:
			continue
		var r := _radius() * 0.25
		var s := r * 1.25
		t.texture = AddOns.icon(id)
		t.modulate = AddOns.color(id) if level.charges_left(id) > 0 else Color(0.4, 0.4, 0.4)
		t.position = chamber_pos(i) - Vector2(s, s) * 0.5 + Vector2(0, -r * 0.08)
		t.size = Vector2(s, s)


func _draw() -> void:
	_place_icons()
	if swing <= 0.0 or level == null:
		return
	var c := _center()
	var r := _radius()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5 * swing))
	# The cylinder: dark steel with flutes between the chambers.
	draw_circle(c, r * 1.04, Color(0.08, 0.08, 0.09))
	draw_circle(c, r, Color(0.32, 0.33, 0.36))
	draw_circle(c, r * 0.94, Color(0.24, 0.25, 0.28))
	for i in AddOns.CHAMBERS:
		var a := angle + (i + 0.5) * TAU / AddOns.CHAMBERS - PI * 0.5
		draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.9, r * 0.09, Color(0.12, 0.12, 0.14))
	draw_arc(c, r, 0.0, TAU, 64, Color(0.6, 0.62, 0.66), 3.0)
	# The sight at the top: the chamber under it is the one that fires.
	var top := c + Vector2(0, -r * 1.12)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-r * 0.09, -r * 0.1), top + Vector2(r * 0.09, -r * 0.1), top + Vector2(0, r * 0.05)]), UIKit.GOLD)
	for i in AddOns.CHAMBERS:
		_draw_chamber(i)
	# The hub: USE.
	var id := level.selected_addon()
	var can := id != &"" and level.charges_left(id) > 0
	draw_circle(c, r * 0.24, UIKit.GOLD if can else Color(0.3, 0.28, 0.24))
	draw_arc(c, r * 0.24, 0.0, TAU, 40, Color(0.1, 0.08, 0.05), 3.0)
	var fs := int(clampf(r * 0.12, 14.0, 34.0))
	var use_w := _font.get_string_size("USE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_font, c + Vector2(-use_w * 0.5, fs * 0.35), "USE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.08, 0.06, 0.03) if can else UIKit.DIM)
	# What's loaded at the top.
	var y := c.y + r * 1.18
	var title := "Empty chamber" if id == &"" else "%s  -  Lv %d  -  %d left" % [AddOns.display_name(id), SaveSystem.addon_level(id), level.charges_left(id)]
	_text_center(title, y, int(fs * 0.85), UIKit.GOLD if id != &"" else UIKit.DIM)
	var sub := "Load add-ons in the Armory (main menu)" if id == &"" else "%s: %s" % [AddOns.KIND_NAMES[AddOns.kind(id)], AddOns.detail(id, SaveSystem.addon_level(id))]
	_text_center(sub, y + fs * 1.1, int(fs * 0.62), UIKit.TEXT)
	var help := "Tap a chamber to turn it to the top  -  tap USE to fire  -  tap outside to close" if InputRouter.is_touch_mode() \
		else "Turn: arrows / wheel / 1-6   Fire: Enter, Space or click USE   Close: Tab or Esc"
	_text_center(help, y + fs * 2.1, int(fs * 0.5), UIKit.DIM)


func _draw_chamber(i: int) -> void:
	var p := chamber_pos(i)
	var r := _radius() * 0.25
	var id: StringName = level.loadout[i] if i < level.loadout.size() else &""
	var selected := i == level.chamber
	draw_circle(p, r, Color(0.05, 0.05, 0.06))
	var ring := Color(0.45, 0.45, 0.48)
	if id != &"":
		ring = AddOns.KIND_COLORS[AddOns.kind(id)]
	draw_arc(p, r, 0.0, TAU, 32, UIKit.GOLD if selected else ring, 5.0 if selected else 3.0)
	if id == &"":
		return
	var left := level.charges_left(id)
	# Uses left: little brass pips along the bottom of the chamber.
	var total := AddOns.charges(SaveSystem.addon_level(id))
	for k in total:
		var px := p + Vector2((k - (total - 1) * 0.5) * r * 0.26, r * 0.72)
		draw_circle(px, r * 0.09, UIKit.GOLD if k < left else Color(0.25, 0.22, 0.18))


func _text_center(t: String, y: float, fs: int, col: Color) -> void:
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_font, Vector2(size.x * 0.5 - w * 0.5, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
