class_name UI
extends RefCounted
## Shared look: colours, fonts, the theme, and small widget builders.

const BG := Color("0c2618")
const PANEL := Color("143a26")
const PANEL_2 := Color("1d5034")
const PANEL_3 := Color("27663f")
const ACCENT := Color("ffc933")
const TEXT := Color("f6f2e4")
const MUTED := Color("b8c9b4")
const DANGER := Color("ef5a3c")
const BLUE := Color("3aa6f0")
const BERRY := Color("e8343a")
const AMBER := Color("f2a01a")
const LOCK := Color("6a7a6e")

static var _font_bold: Font
static var _font: Font
static var _theme: Theme


static func font(bold := true) -> Font:
	if _font_bold == null:
		_font_bold = load("res://assets/fonts/fredoka-latin-700-normal.woff2")
		_font = load("res://assets/fonts/fredoka-latin-500-normal.woff2")
	return _font_bold if bold else _font


static func box(color: Color, radius := 22, border := 0, border_color := Color.TRANSPARENT, pad := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	s.border_color = border_color
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(false)
	t.default_font_size = 28
	t.set_color("font_color", "Label", TEXT)
	t.set_font("font", "Label", font(false))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var c := PANEL_3
		match state:
			"hover":
				c = PANEL_3.lightened(0.12)
			"pressed":
				c = PANEL_3.darkened(0.2)
			"disabled":
				c = Color(0.25, 0.3, 0.27)
		var sb := box(c, 26, 0, Color.TRANSPARENT, 22)
		if state == "focus":
			sb = box(Color.TRANSPARENT, 26, 3, ACCENT.lerp(Color.WHITE, 0.3), 22)
			sb.draw_center = false
		t.set_stylebox(state, "Button", sb)
	t.set_font("font", "Button", font(true))
	t.set_font_size("font_size", "Button", 30)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.45))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, 28, 0, Color.TRANSPARENT, 24))
	t.set_stylebox("panel", "Panel", box(PANEL, 28))
	var grab := box(ACCENT, 14, 0, Color.TRANSPARENT, 0)
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT.darkened(0.2), 10, 0, Color.TRANSPARENT, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT, 10, 0, Color.TRANSPARENT, 4))
	t.set_stylebox("slider", "HSlider", box(PANEL_2, 10, 0, Color.TRANSPARENT, 4))
	t.set_icon("grabber", "HSlider", _dot_icon(ACCENT, 34))
	t.set_icon("grabber_highlight", "HSlider", _dot_icon(ACCENT.lightened(0.2), 34))
	t.set_stylebox("scroll", "VScrollBar", box(Color(1, 1, 1, 0.05), 8, 0, Color.TRANSPARENT, 2))
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	t.set_stylebox("scroll", "HScrollBar", box(Color(1, 1, 1, 0.0), 8, 0, Color.TRANSPARENT, 0))
	t.set_stylebox("grabber", "HScrollBar", box(Color(1, 1, 1, 0.0), 8, 0, Color.TRANSPARENT, 0))
	t.set_stylebox("normal", "CheckButton", box(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, 4))
	t.set_stylebox("hover", "CheckButton", box(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, 4))
	t.set_stylebox("pressed", "CheckButton", box(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, 4))
	t.set_font_size("font_size", "CheckButton", 28)
	t.set_icon("checked", "CheckButton", _toggle_icon(true))
	t.set_icon("unchecked", "CheckButton", _toggle_icon(false))
	t.set_icon("checked_disabled", "CheckButton", _toggle_icon(true))
	t.set_icon("unchecked_disabled", "CheckButton", _toggle_icon(false))
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_pressed_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", TEXT)
	_theme = t
	return t


static func _toggle_icon(on: bool) -> Texture2D:
	var w := 92
	var h := 52
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := ACCENT if on else Color(0.3, 0.38, 0.33)
	var knob_x := w - h * 0.5 if on else h * 0.5
	for y in h:
		for x in w:
			var px := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(px.x, h * 0.5, w - h * 0.5)
			var d := (px - Vector2(cx, h * 0.5)).length()
			var a := clampf(h * 0.5 - d, 0.0, 1.0)
			var col := Color(track, a)
			var dk := (px - Vector2(knob_x, h * 0.5)).length()
			var ka := clampf(h * 0.5 - 5.0 - dk, 0.0, 1.0)
			col = col.lerp(Color(1, 1, 1, 1), ka)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func _dot_icon(c: Color, size: int) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ builders

static func label(text: String, size := 28, color := TEXT, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font(true))
	l.horizontal_alignment = align
	return l


static func wrap_label(text: String, size := 26, color := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size, color, false, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 120
	return l


static func button(text: String, cb: Callable, color := PANEL_3, size := 30, min_h := 88) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.add_theme_font_size_override("font_size", size)
	if color != PANEL_3:
		paint(b, color)
	b.pressed.connect(func():
		Sfx.play("tap")
		cb.call())
	return b


static func paint(b: Button, color: Color, radius := 26) -> void:
	b.add_theme_stylebox_override("normal", box(color, radius, 0, Color.TRANSPARENT, 22))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.1), radius, 0, Color.TRANSPARENT, 22))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.2), radius, 0, Color.TRANSPARENT, 22))
	b.add_theme_stylebox_override("disabled", box(color.darkened(0.45).lerp(Color(0.3, 0.3, 0.3), 0.5), radius, 0, Color.TRANSPARENT, 22))
	var dark := color.get_luminance() > 0.55
	b.add_theme_color_override("font_color", Color("1a2a1a") if dark else TEXT)
	b.add_theme_color_override("font_hover_color", Color("102010") if dark else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("102010") if dark else ACCENT)


static func panel(color := PANEL, radius := 28, pad := 24) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, 0, Color.TRANSPARENT, pad))
	return p


static func vbox(sep := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(h := 0, w := 0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	if h == 0 and w == 0:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func margin(child: Control, l := 24, t := 24, r := 24, b := 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


static func price_text(price: Dictionary) -> String:
	var parts := []
	for c in price:
		parts.append("%d %s" % [int(price[c]), "Berries" if c == "berries" else "Amber"])
	return " / ".join(parts)


static func rarity_color(r: String) -> Color:
	return Color(String(Content.rarities.get(r, {}).get("gem", "#ffffff")))


static func region_color(map_id: String) -> Color:
	return Color(String(Content.map(map_id).get("palette", {}).get("ui", "#2a6a3a")))


static func safe_top(control: Control) -> float:
	var vp := control.get_viewport_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0.0
	return float(safe.position.y) * vp.y / float(win.y)
