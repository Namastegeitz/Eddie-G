class_name PromptCard
extends Control
## A short, dismissible card over a dimmed screen: title, a line or two,
## up to three buttons. Used for every store prompt, nudge and confirmation.

signal closed(choice: String)

var _panel: PanelContainer
var _box: VBoxContainer


static func make(title: String, text: String, buttons: Array, art: Control = null, accent := UI.ACCENT) -> PromptCard:
	var c := PromptCard.new()
	c._build(title, text, buttons, art, accent)
	return c


func _build(title: String, text: String, buttons: Array, art: Control, accent: Color) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = UI.panel(UI.PANEL, 30, 32)
	_panel.custom_minimum_size = Vector2(600, 0)
	_panel.add_theme_stylebox_override("panel", UI.box(UI.PANEL, 30, 4, accent.darkened(0.1), 32))
	center.add_child(_panel)
	_box = UI.vbox(20)
	_panel.add_child(_box)
	if art:
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_box.add_child(art)
	if title != "":
		var t := UI.label(title, 40, accent, true, HORIZONTAL_ALIGNMENT_CENTER)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size.x = 520
		_box.add_child(t)
	if text != "":
		var l := UI.wrap_label(text, 28, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.custom_minimum_size.x = 520
		_box.add_child(l)
	for b in buttons:
		var id := String(b.get("id", b.get("text", "")))
		var btn := UI.button(String(b.text), func(): close(id), b.get("color", UI.PANEL_3), 30, 88)
		if b.has("disabled"):
			btn.disabled = bool(b.disabled)
		_box.add_child(btn)
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	_panel.pivot_offset = Vector2(300, 150)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)


func add_extra(c: Control) -> void:
	_box.add_child(c)
	_box.move_child(c, _box.get_child_count() - 1)


func close(choice: String) -> void:
	closed.emit(choice)
	queue_free()


func _gui_input(event: InputEvent) -> void:
	accept_event()
