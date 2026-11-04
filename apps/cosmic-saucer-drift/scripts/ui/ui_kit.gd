class_name UiKit
extends RefCounted
## Shared look for menus and HUD: colours, theme, and small builders.

const BG := Color(0.05, 0.03, 0.12)
const PANEL := Color(0.09, 0.06, 0.2, 0.92)
const CYAN := Color(0.3, 0.92, 1.0)
const PINK := Color(1.0, 0.35, 0.8)
const GOLD := Color(1.0, 0.84, 0.3)
const GREEN := Color(0.45, 1.0, 0.45)
const RED := Color(1.0, 0.3, 0.3)
const DIM := Color(0.62, 0.6, 0.78)

static var _theme: Theme = null
static var _bold: FontVariation = null


static func bold() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func box(c: Color, radius := 14, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = bold()
	t.default_font_size = 24
	t.set_stylebox("normal", "Button", box(Color(0.14, 0.1, 0.3), 16, CYAN.darkened(0.3), 2))
	t.set_stylebox("hover", "Button", box(Color(0.2, 0.14, 0.42), 16, CYAN, 3))
	t.set_stylebox("pressed", "Button", box(Color(0.3, 0.2, 0.55), 16, PINK, 3))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 16, GOLD, 3))
	t.set_stylebox("disabled", "Button", box(Color(0.1, 0.08, 0.16), 16, Color(0.3, 0.3, 0.4), 2))
	t.set_color("font_color", "Button", Color(0.95, 0.95, 1.0))
	t.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.6))
	t.set_color("font_outline_color", "Label", Color(0.02, 0.0, 0.06))
	t.set_constant("outline_size", "Label", 6)
	t.set_stylebox("panel", "PanelContainer", box(PANEL, 18, CYAN.darkened(0.5), 2))
	t.set_stylebox("panel", "Panel", box(PANEL, 18, CYAN.darkened(0.5), 2))
	var grab := box(CYAN, 10)
	t.set_stylebox("grabber_area", "HSlider", box(CYAN.darkened(0.2), 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(CYAN, 6))
	t.set_stylebox("slider", "HSlider", box(Color(0.2, 0.18, 0.35), 6))
	t.set_icon("grabber", "HSlider", _dot(26, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", _dot(28, GOLD))
	t.set_stylebox("panel", "TooltipPanel", grab)
	t.set_stylebox("scroll", "VScrollBar", box(Color(0.1, 0.08, 0.2), 6))
	t.set_stylebox("grabber", "VScrollBar", box(CYAN.darkened(0.3), 6))
	_theme = t
	return t


static func _dot(sz: int, c: Color) -> ImageTexture:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var r := sz * 0.5
	for x in sz:
		for y in sz:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(r - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Pin a control to an anchor point of its parent (0..1 each axis) with an
## offset and size in pixels. Works for free-floating HUD controls.
static func place(c: Control, anchor: Vector2, offset: Vector2, sz: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + sz.x
	c.offset_bottom = offset.y + sz.y


static func label(text: String, size := 24, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func button(text: String, cb: Callable, size := 26, min_w := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(min_w, 58)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(func() -> void:
		Audio.ui("click")
		cb.call())
	return b


static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func panel(child: Control, c := PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(c, 18, CYAN.darkened(0.5), 2))
	p.add_child(child)
	return p


static func ordinal(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "%dth" % n
	match n % 10:
		1:
			return "%dst" % n
		2:
			return "%dnd" % n
		3:
			return "%drd" % n
	return "%dth" % n


static func time_str(t: float) -> String:
	if t <= 0.0 or t > 5999.0:
		return "--:--.--"
	var m := int(t / 60.0)
	var s := t - float(m) * 60.0
	return "%d:%05.2f" % [m, s]
