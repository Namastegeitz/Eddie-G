extends Control
## Volume, haptics, graphics quality, touch controls, look sensitivity,
## invert Y, key rebinding and progress reset. Works as a full screen or as
## an overlay on top of the pause menu (overlay = true).

var overlay := false
var _waiting_action := ""
var _bind_buttons: Dictionary = {}
var _confirm_reset := false
var _reset_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.setup_root(self)
	UIKit.background(self)
	var col := UIKit.column(self, 600.0, 12)
	col.add_child(UIKit.title("SETTINGS", 44))
	col.add_child(_section("Audio"))
	col.add_child(_slider("Master", "master_volume"))
	col.add_child(_slider("Music", "music_volume"))
	col.add_child(_slider("Effects", "sfx_volume"))
	col.add_child(_section("Feel"))
	col.add_child(_toggle("Vibration / rumble", "haptics"))
	col.add_child(_toggle("Invert look Y", "invert_y"))
	col.add_child(_toggle("Fly where you look", "fly_follow_look"))
	col.add_child(_toggle("Bug's-eye view (see through the bug's eyes)", "first_person"))
	col.add_child(_slider("Look sensitivity", "look_sensitivity", 0.3, 2.5))
	col.add_child(_slider("Touch look speed", "touch_look_sensitivity", 0.2, 2.0))
	col.add_child(_section("Display"))
	col.add_child(_options("Quality", "quality", ["low", "medium", "high"]))
	col.add_child(_toggle("Auto quality (drops it if the game runs slowly)", "auto_quality"))
	col.add_child(_options("Touch controls", "touch_controls", ["auto", "on", "off"]))
	col.add_child(_section("Keyboard & mouse"))
	for a in InputRouter.REBINDABLE:
		col.add_child(_bind_row(a))
	col.add_child(UIKit.button("Reset key bindings", func() -> void:
		InputRouter.reset_bindings()
		_refresh_binds()))
	col.add_child(_section("Progress"))
	_reset_button = UIKit.button("Reset all progress", _on_reset)
	col.add_child(_reset_button)
	col.add_child(UIKit.button("Back", _back))


func _section(text: String) -> Label:
	return UIKit.label(text.to_upper(), 22, UIKit.GOLD)


func _slider(text: String, key: String, mn: float = 0.0, mx: float = 1.0) -> Control:
	var row := UIKit.hbox(12)
	var l := UIKit.label(text, 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 200
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = 0.05
	s.value = float(SaveSystem.get_setting(key, 1.0))
	s.custom_minimum_size = Vector2(220, 44)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float) -> void:
		SaveSystem.set_setting(key, v))
	s.drag_ended.connect(func(_c: bool) -> void: SaveSystem.save_game())
	row.add_child(s)
	return row


func _toggle(text: String, key: String) -> Control:
	var c := CheckButton.new()
	c.text = text
	c.button_pressed = bool(SaveSystem.get_setting(key, false))
	c.custom_minimum_size.y = 52
	c.toggled.connect(func(on: bool) -> void:
		SaveSystem.set_setting(key, on)
		SaveSystem.save_game()
		if key == "haptics" and on:
			Feedback.rumble(0.6, 0.15)
		if key == "first_person" and Level.current and is_instance_valid(Level.current) and Level.current.camera:
			Level.current.camera.set_first_person(on))
	return c


func _options(text: String, key: String, values: Array) -> Control:
	var row := UIKit.hbox(12)
	var l := UIKit.label(text, 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 200
	row.add_child(l)
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(200, 52)
	o.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur := String(SaveSystem.get_setting(key, values[0]))
	for i in values.size():
		o.add_item(String(values[i]).capitalize(), i)
		if values[i] == cur:
			o.select(i)
	o.item_selected.connect(func(i: int) -> void:
		SaveSystem.set_setting(key, values[i])
		SaveSystem.save_game())
	row.add_child(o)
	return row


func _bind_row(action: String) -> Control:
	var row := UIKit.hbox(12)
	var l := UIKit.label(action.capitalize(), 20, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 200
	row.add_child(l)
	var b := Button.new()
	b.text = InputRouter.binding_text(action)
	b.custom_minimum_size = Vector2(200, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func() -> void:
		_waiting_action = action
		b.text = "Press a key...")
	_bind_buttons[action] = b
	row.add_child(b)
	return row


func _refresh_binds() -> void:
	for a: String in _bind_buttons.keys():
		(_bind_buttons[a] as Button).text = InputRouter.binding_text(a)


func _input(event: InputEvent) -> void:
	if _waiting_action == "":
		return
	if (event is InputEventKey and event.pressed and not event.is_echo()) \
			or (event is InputEventMouseButton and event.pressed):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
			_waiting_action = ""
			_refresh_binds()
		else:
			InputRouter.rebind(_waiting_action, event)
			_waiting_action = ""
			_refresh_binds()
		get_viewport().set_input_as_handled()


func _on_reset() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		_reset_button.text = "Tap again to erase all progress"
		return
	SaveSystem.reset_progress()
	_confirm_reset = false
	_reset_button.text = "Progress reset"


func _back() -> void:
	SaveSystem.save_game()
	if overlay:
		queue_free()
	else:
		GameManager.goto("main_menu")
