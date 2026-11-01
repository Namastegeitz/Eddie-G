class_name UIKit
## Shared look for every menu: gold on black, big touch-friendly controls.

const GOLD := Color(0.96, 0.76, 0.27)
const GOLD_DIM := Color(0.6, 0.47, 0.18)
const INK := Color(0.055, 0.048, 0.04)
const PANEL := Color(0.1, 0.088, 0.07, 0.94)
const TEXT := Color(0.96, 0.93, 0.86)
const DIM := Color(0.68, 0.64, 0.56)
const RED := Color(0.95, 0.3, 0.22)
const GREEN := Color(0.45, 0.85, 0.4)

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 24
	t.set_stylebox("normal", "Button", _box(PANEL, GOLD_DIM, 2))
	t.set_stylebox("hover", "Button", _box(Color(0.16, 0.14, 0.1), GOLD, 2))
	t.set_stylebox("pressed", "Button", _box(GOLD, GOLD, 2))
	t.set_stylebox("disabled", "Button", _box(Color(0.08, 0.075, 0.07, 0.8), Color(0.25, 0.23, 0.2), 2))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 3))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.38, 0.34))
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, GOLD_DIM, 2))
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_font_size("font_size", "CheckButton", 24)
	t.set_stylebox("normal", "OptionButton", _box(PANEL, GOLD_DIM, 2))
	t.set_stylebox("hover", "OptionButton", _box(Color(0.16, 0.14, 0.1), GOLD, 2))
	t.set_stylebox("pressed", "OptionButton", _box(Color(0.16, 0.14, 0.1), GOLD, 2))
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_stylebox("slider", "HSlider", _box(Color(0.2, 0.18, 0.15), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("grabber_area", "HSlider", _box(GOLD_DIM, Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(GOLD, Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("background", "ProgressBar", _box(Color(0.2, 0.18, 0.15), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("fill", "ProgressBar", _box(GOLD, Color(0, 0, 0, 0), 0, 6))
	t.set_color("font_color", "ProgressBar", Color(0, 0, 0, 0))
	_theme = t
	return t


static func _box(bg: Color, border: Color, width: int, radius: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func setup_root(root: Control) -> void:
	root.theme = theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)


static func background(parent: Control) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	return bg


## Scrollable, centered column that fits portrait phones and wide desktops.
static func column(parent: Control, max_width: float = 620.0, separation: int = 14) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	center.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	var vw := parent.get_viewport_rect().size.x if parent.is_inside_tree() else 720.0
	box.custom_minimum_size.x = minf(max_width, vw - 48.0)
	margin.add_child(box)
	return box


static func label(text: String, size: int = 24, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func title(text: String, size: int = 52) -> Label:
	var l := label(text, size, GOLD)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	return l


static func button(text: String, on_press: Callable, min_height: float = 64.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = min_height
	b.pressed.connect(func() -> void:
		AudioManager.play(&"ui_click", -4.0)
		on_press.call())
	return b


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func hbox(separation: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func vbox(separation: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func bar(value: float, color: Color = GOLD, height: float = 12.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0.0
	p.max_value = 1.0
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size.y = height
	var fill := _box(color, Color(0, 0, 0, 0), 0, 6)
	p.add_theme_stylebox_override("fill", fill)
	return p
