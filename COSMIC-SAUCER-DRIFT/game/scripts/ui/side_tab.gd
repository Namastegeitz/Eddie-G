class_name SideTab
extends Control
## A pull-tab stuck to the left edge of the race screen ("COCKPIT"). Tap or
## click it to switch between the chase camera and first-person. Lit when on.

signal pressed

var text := "COCKPIT"
var on := false
var k := 1.0          # size factor (smaller in split-screen)
var _press_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _gui_input(e: InputEvent) -> void:
	# Phones send the tap as an emulated mouse click too; only the mouse
	# event is used so one tap toggles once.
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
		_press_t = 0.15
		pressed.emit()
		accept_event()


func set_on(v: bool) -> void:
	on = v
	queue_redraw()


func _process(dt: float) -> void:
	if _press_t > 0.0:
		_press_t = maxf(0.0, _press_t - dt)
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var box := StyleBoxFlat.new()
	box.corner_radius_top_right = int(16 * k)
	box.corner_radius_bottom_right = int(16 * k)
	box.border_width_right = int(3 * k)
	box.border_width_top = int(3 * k)
	box.border_width_bottom = int(3 * k)
	var lit := Color(0.3, 0.92, 1.0)
	box.bg_color = Color(0.05, 0.12, 0.2, 0.85) if on else Color(0.05, 0.03, 0.12, 0.6)
	if _press_t > 0.0:
		box.bg_color = box.bg_color.lightened(0.25)
	box.border_color = Color(lit.r, lit.g, lit.b, 0.95 if on else 0.45)
	draw_style_box(box, r)
	# Little visor icon at the top: a dome over a bar, glowing when on.
	var c := Vector2(size.x * 0.5, size.y * 0.16)
	var ic := Color(lit.r, lit.g, lit.b, 1.0 if on else 0.55)
	draw_arc(c + Vector2(0, 4 * k), size.x * 0.28, PI, TAU, 16, ic, 3.0 * k)
	draw_line(c + Vector2(-size.x * 0.32, 4 * k), c + Vector2(size.x * 0.32, 4 * k), ic, 3.0 * k)
	# Text running up the tab.
	var font := UiKit.bold()
	var fs := int(17 * k)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_set_transform(Vector2(size.x * 0.5 + fs * 0.36, size.y * 0.6 + tw * 0.5), -PI * 0.5)
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95 if on else 0.7))
	draw_set_transform(Vector2.ZERO)
	# On/off lamp at the bottom.
	draw_circle(Vector2(size.x * 0.5, size.y - 14 * k), 5.0 * k, Color(0.35, 1.0, 0.5) if on else Color(0.4, 0.4, 0.5, 0.8))
