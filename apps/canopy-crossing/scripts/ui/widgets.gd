class_name Widgets
extends RefCounted
## Small drawn controls shared by the screens.


## One finger tap reaches a control twice: as a touch and as the mouse click
## the engine emulates from it (a mouse click likewise also arrives as an
## emulated touch). Toggles such as the eye button must react once, or they
## switch on and straight back off. True for the first press of a tap.
static func tap(ctrl: Control, event: InputEvent) -> bool:
	var down: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if not down:
		return false
	var now := Time.get_ticks_msec()
	if now - int(ctrl.get_meta("last_tap_ms", -100000)) < 250:
		return false
	ctrl.set_meta("last_tap_ms", now)
	return true


## Any press or release from a finger or the mouse's left button.
static func is_pointer(event: InputEvent) -> bool:
	return event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)

class Portrait extends Control:
	## An animal drawn by AnimalPainter, optionally as a dark silhouette.
	var animal: Dictionary = {}
	var look: Dictionary = {}
	var silhouette := false
	var t := 0.0
	var animate := true
	var scale_k := 0.92

	func _init(a: Dictionary = {}, min_size := Vector2(200, 200)) -> void:
		animal = a
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_animal(a: Dictionary, l: Dictionary = {}) -> void:
		animal = a
		look = l
		queue_redraw()

	func _process(dt: float) -> void:
		if animate and is_visible_in_tree():
			t += dt
			queue_redraw()

	func _draw() -> void:
		if animal.is_empty():
			return
		var s := minf(size.x, size.y) * scale_k
		var pre := Transform2D(0.0, Vector2(size.x * 0.5, size.y * 0.95))
		if silhouette:
			var l: Dictionary = (look if not look.is_empty() else animal.get("look", {})).duplicate(true)
			var cols: Dictionary = {}
			for k in l.get("colors", {}):
				cols[k] = "#0f1f16"
			l.colors = cols
			AnimalPainter.draw(self, animal, s, {"t": t, "shadow": 0.0}, l, pre)
		else:
			AnimalPainter.draw(self, animal, s, {"t": t, "blink": animate and fposmod(t + 1.5, 3.7) < 0.12}, look, pre)
		draw_set_transform(Vector2.ZERO)


class Flag extends Control:
	## A small pennant in the region's colours with its code.
	var map_id := ""

	func _init(id := "", min_size := Vector2(64, 44)) -> void:
		map_id = id
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var m := Content.map(map_id)
		var f: Dictionary = m.get("flag", {})
		var cols: Array = f.get("colors", ["#2a6a3a", "#f6d43a"])
		var w := size.x
		var h := size.y
		draw_line(Vector2(3, 0), Vector2(3, h), Color("e8e0c8"), 4)
		var pts := PackedVector2Array([Vector2(5, 2), Vector2(w, h * 0.32), Vector2(5, h * 0.66)])
		draw_colored_polygon(pts, Color(String(cols[0])))
		if cols.size() > 1:
			draw_colored_polygon(PackedVector2Array([Vector2(5, h * 0.22), Vector2(w * 0.7, h * 0.32), Vector2(5, h * 0.44)]), Color(String(cols[1])))
		if cols.size() > 2:
			Draw.ellipse(self, Vector2(w * 0.28, h * 0.33), h * 0.08, h * 0.08, Color(String(cols[2])))


class Pips extends Control:
	## Filled / empty dots for a level (skill upgrades).
	var value := 1
	var total := 5

	func _init(v := 1, n := 5) -> void:
		value = v
		total = n
		custom_minimum_size = Vector2(n * 26, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for i in total:
			var c := Vector2(11 + i * 26, size.y * 0.5)
			Draw.ellipse(self, c, 9, 9, Color(0, 0, 0, 0.35))
			Draw.ellipse(self, c, 7, 7, UI.ACCENT if i < value else Color(1, 1, 1, 0.14))


class Gem extends Control:
	var rarity := "common"

	func _init(r := "common", s := 34.0) -> void:
		rarity = r
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Draw.gem(self, size * 0.5, minf(size.x, size.y) * 0.45, UI.rarity_color(rarity))


class CurrencyIcon extends Control:
	var kind := "berries"

	func _init(k := "berries", s := 40.0) -> void:
		kind = k
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.42
		if kind == "amber":
			Draw.amber_icon(self, size * 0.5, r)
		elif kind == "heart":
			Draw.heart(self, size * 0.5, r, Color("ef4a5a"))
		elif kind == "shield":
			Draw.ellipse_line(self, size * 0.5, r, r * 1.1, Color(0.5, 0.85, 1.0), 4)
		else:
			Draw.berry_icon(self, size * 0.5 + Vector2(0, r * 0.1), r)


static func currency_chip(kind: String, value: String, size := 30) -> HBoxContainer:
	var h := UI.hbox(6)
	h.add_child(CurrencyIcon.new(kind, size + 10))
	var l := UI.label(value, size, UI.TEXT, true)
	l.name = "Value"
	h.add_child(l)
	return h


class HazardIcon extends Control:
	## Any hazard drawn small for intro cards: movers, platforms, predators,
	## tiles, lane effects and map events all have a pose.
	var hz: Dictionary = {}
	var t := 0.0

	func _init(h: Dictionary = {}, s := Vector2(150, 110)) -> void:
		hz = h
		custom_minimum_size = s
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _process(dt: float) -> void:
		if is_visible_in_tree():
			t += dt
			queue_redraw()

	func _draw() -> void:
		var T := minf(size.y * 0.8, 70.0)
		Draw.rrect(self, Rect2(Vector2.ZERO, size), 18, Color(1, 1, 1, 0.07))
		var c := size * 0.5
		var kind := String(hz.get("kind", ""))
		match kind:
			"mover", "platform":
				if kind == "platform":
					Draw.rrect(self, Rect2(4, c.y - T * 0.5, size.x - 8, T), 10, Color("3a6a8a"))
				var lens: Array = hz.get("length", [1.0, 1.0])
				var len := minf(float(lens[1]), (size.x - 16) / T) * T
				if hz.get("motion", "") in ["pendulum", "tidal"] and kind == "platform":
					len = minf(size.x - 16, T * 2.2)
				draw_set_transform(Vector2(c.x - len * 0.5 + sin(t * 1.5) * 6.0, c.y))
				HazardPainter.draw_entity(self, hz, len, T, {"dir": 1, "t": t, "speed": 1.0})
				draw_set_transform(Vector2.ZERO)
			"surfacer":
				Draw.rrect(self, Rect2(4, c.y - T * 0.5, size.x - 8, T), 10, Color("3a6a8a"))
				var ph := fposmod(t, 2.4)
				draw_set_transform(c)
				HazardPainter.draw_pred(self, hz, {"kind": "surfacer", "span": hz.get("span", 1.2)}, T, "warn" if ph < 1.2 else "active", fposmod(ph, 1.2) / 1.2, t, 1.0)
				draw_set_transform(Vector2.ZERO)
			"striker", "faller":
				var ph2 := fposmod(t, 2.0)
				draw_set_transform(Vector2(c.x - T * (1.0 if kind == "striker" else 0.5), c.y))
				HazardPainter.draw_pred(self, hz, {"kind": kind, "dir": 1, "span": 1, "col": 0}, T, "warn" if ph2 < 1.0 else "active", fposmod(ph2, 1.0), t, 1.0)
				draw_set_transform(Vector2.ZERO)
			"swooper":
				var y := lerpf(10.0, size.y - 10.0, fposmod(t * 0.6, 1.0))
				draw_rect(Rect2(c.x - T * 0.4, 0, T * 0.8, size.y), Color(0, 0, 0, 0.15))
				var cl: Dictionary = hz.get("art", {}).get("colors", {})
				var r := T * 0.7
				var p := Vector2(c.x, y)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(0, -r * 0.25), p + Vector2(r, 0), p + Vector2(0, r * 0.15)]), Color(String(cl.get("wing", "#333333"))))
				Draw.ellipse(self, p, r * 0.18, r * 0.3, Color(String(cl.get("body", "#555555"))))
			"quicksand", "gap", "brush":
				draw_set_transform(Vector2(c.x - T * 0.5, c.y))
				HazardPainter.draw_tile(self, hz, T, t, 3)
				draw_set_transform(Vector2.ZERO)
			"tide", "fire", "mudslide":
				var ph3 := fposmod(t, 3.0)
				draw_set_transform(Vector2(6, c.y))
				HazardPainter.draw_effect(self, hz, size.x - 12, T, "warn" if ph3 < 1.2 else "active", fposmod(ph3, 1.5) / 1.5, t)
				draw_set_transform(Vector2.ZERO)
			"gust":
				for i in 5:
					var x := fposmod(i * 37.0 + t * 160.0, size.x)
					Draw.leaf(self, Vector2(x, 20 + i * 16), Vector2(1, 0.2), 22, 8, Color(0.6, 0.85, 0.4))
			"downpour":
				for i in 18:
					var x2 := fposmod(i * 23.0 + t * 30.0, size.x)
					var y2 := fposmod(i * 41.0 + t * 260.0, size.y)
					draw_line(Vector2(x2, y2), Vector2(x2 - 4, y2 + 16), Color(0.75, 0.88, 1.0), 2)


class AbilityButton extends Control:
	## Round in-run button with a cooldown ring and a count badge.
	signal pressed

	var text := ""
	var progress := 1.0
	var is_ready := true
	var active := false
	var badge := ""
	var tint := UI.ACCENT

	func _init(label := "", s := 150.0, color := UI.ACCENT) -> void:
		text = label
		tint = color
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_state(p: float, is_ready: bool, is_active: bool, b: String) -> void:
		if not is_equal_approx(p, progress) or is_ready != self.is_ready or is_active != active or b != badge:
			progress = p
			self.is_ready = is_ready
			active = is_active
			badge = b
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if Widgets.is_pointer(event):
			accept_event()
			if Widgets.tap(self, event):
				pressed.emit()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		Draw.ellipse(self, c + Vector2(0, 5), r, r, Color(0, 0, 0, 0.3))
		Draw.ellipse(self, c, r, r, (tint if is_ready else Color(0.25, 0.3, 0.28)).darkened(0.1 if is_ready else 0.0))
		Draw.ellipse(self, c, r * 0.84, r * 0.84, tint.lightened(0.1) if is_ready else Color(0.3, 0.35, 0.32))
		if not is_ready:
			draw_arc(c, r * 0.92, -PI / 2, -PI / 2 + TAU * progress, 40, tint, r * 0.12, true)
		if active:
			draw_arc(c, r * 1.02, 0, TAU, 40, Color(1, 1, 1, 0.8), 4, true)
		var font := UI.font(true)
		var fs := int(r * 0.34)
		var words := text.split(" ")
		var lines := []
		if words.size() >= 2 and text.length() > 8:
			lines = [words[0], " ".join(words.slice(1))]
		else:
			lines = [text]
		for i in lines.size():
			var w := font.get_string_size(String(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var y := c.y + fs * 0.35 + (i - (lines.size() - 1) * 0.5) * fs * 1.05
			draw_string(font, Vector2(c.x - w * 0.5, y), String(lines[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("1a2a1a") if is_ready else Color(1, 1, 1, 0.6))
		if badge != "":
			Draw.ellipse(self, c + Vector2(r * 0.72, -r * 0.72), r * 0.3, r * 0.3, UI.DANGER)
			var bw := font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.32)).x
			draw_string(font, c + Vector2(r * 0.72 - bw * 0.5, -r * 0.6), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.32), Color.WHITE)


class Globe extends Control:
	## The world map's digital globe. The sphere is a shader
	## (assets/shaders/globe.gdshader: LED dots for land, glowing coasts,
	## borders, a grid and a scanning sweep); this widget draws the region
	## beacons, a flight-path arc to the region you pick, and an orbit ring on
	## top, and spins to the selected region. Drag sideways to spin it; tap a
	## beacon to pick it. Beacons: owned (gold), locked (cyan, padlock),
	## coming soon (dim).
	signal pin_pressed(map_id: String)

	const RADIUS := 0.46            # of the widget's shorter side (matches the shader's 0.92)
	static var _shader: Shader
	static var _map: Texture2D

	var lon := -60.0
	var lat := 0.0
	var target_lon := -60.0
	var target_lat := 0.0
	var selected := ""
	var t := 0.0
	var _pins := {}
	var _sphere: ColorRect
	var _mat: ShaderMaterial
	var _over: Control
	var _arc_from := ""
	var _arc_t := 9.0
	var _drag := {}
	var _spin := 0.0                # degrees / s of fling after a drag
	var _idle := 9.0                # seconds since the last drag

	func _init(min_size := Vector2(560, 560)) -> void:
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_PASS
		if _shader == null:
			_shader = load("res://assets/shaders/globe.gdshader")
			_map = load("res://assets/world/globe_map.png")
		_sphere = ColorRect.new()
		_sphere.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mat = ShaderMaterial.new()
		_mat.shader = _shader
		_mat.set_shader_parameter("map_tex", _map)
		_mat.set_shader_parameter("radius", RADIUS * 2.0)
		_mat.set_shader_parameter("detail", 1.0 if Draw.detail > 0 else 0.0)
		_sphere.material = _mat
		add_child(_sphere)
		_over = Control.new()
		_over.set_anchors_preset(Control.PRESET_FULL_RECT)
		_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_over.draw.connect(_draw_over)
		add_child(_over)

	func focus(map_id: String) -> void:
		if selected != "" and selected != map_id:
			_arc_from = selected
			_arc_t = 0.0
		selected = map_id
		var m := Content.map(map_id)
		target_lon = float(m.get("lon", 0.0))
		target_lat = clampf(float(m.get("lat", 0.0)), -35.0, 35.0)
		_idle = 9.0

	func _process(dt: float) -> void:
		if not is_visible_in_tree():
			return
		t += dt
		_arc_t += dt
		_idle += dt
		if not _drag.get("spinning", false):
			if absf(_spin) > 0.5:
				lon += _spin * dt
				target_lon = lon
				_spin *= exp(-dt * 2.5)
			elif _idle > 2.5:
				var d := wrapf(target_lon - lon, -180.0, 180.0)
				lon += d * (1.0 - exp(-dt * 3.0))
				lat = lerpf(lat, target_lat, 1.0 - exp(-dt * 3.0))
				if absf(d) < 0.5:
					target_lon += dt * 2.0
		_mat.set_shader_parameter("lon0", deg_to_rad(lon))
		_mat.set_shader_parameter("tilt", deg_to_rad(lat))
		_mat.set_shader_parameter("time", t)
		_mat.set_shader_parameter("rect_size", size)
		queue_redraw()
		_over.queue_redraw()

	func _project(la: float, lo: float) -> Vector3:
		var r := minf(size.x, size.y) * RADIUS
		var phi := deg_to_rad(la)
		var lam := deg_to_rad(lo - lon)
		var x := cos(phi) * sin(lam)
		var y := sin(phi)
		var z := cos(phi) * cos(lam)
		var tilt := deg_to_rad(lat)
		var y2 := y * cos(tilt) - z * sin(tilt)
		var z2 := y * sin(tilt) + z * cos(tilt)
		return Vector3(size.x * 0.5 + x * r, size.y * 0.5 - y2 * r, z2)

	## Behind the sphere: soft shadow and the far half of the orbit ring.
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * RADIUS
		Draw.ellipse(self, c + Vector2(0, r * 0.06), r * 1.04, r * 1.04, Color(0, 0, 0, 0.28), 0.0, 64)
		_orbit(self, c, r, true)

	func _orbit(ci: CanvasItem, c: Vector2, r: float, back: bool) -> void:
		if Draw.detail <= 0:
			return
		var rx := r * 1.32
		var ry := r * 0.3
		var rot := -0.32
		var pts := PackedVector2Array()
		for i in 49:
			var a := (PI if back else 0.0) + PI * i / 48.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
		ci.draw_polyline(pts, Color(0.45, 0.9, 1.0, 0.22 if back else 0.4), 2.0, true)
		for k in 3:
			var a2 := fposmod(t * 0.35 + k * TAU / 3.0, TAU)
			var behind := a2 > PI
			if behind != back:
				continue
			var sp := c + Vector2(cos(a2) * rx, sin(a2) * ry).rotated(rot)
			Draw.ellipse(ci, sp, 9.0, 9.0, Color(0.45, 0.9, 1.0, 0.18))
			Draw.ellipse(ci, sp, 3.5, 3.5, Color(0.8, 1.0, 1.0, 0.9 if not back else 0.4))

	## In front of the sphere: flight-path arc, beacons, the selected tag.
	func _draw_over() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * RADIUS
		var font := UI.font(true)
		if _arc_from != "" and _arc_t < 2.2:
			_flight_arc(Content.map(_arc_from), Content.map(selected), r)
		_pins.clear()
		var order: Array = Content.map_order.duplicate()
		order.erase(selected)
		order.append(selected)
		for id in order:
			if id == "":
				continue
			var m := Content.map(id)
			var p2 := _project(float(m.get("lat", 0)), float(m.get("lon", 0)))
			if p2.z <= 0.05:
				continue
			var pos := Vector2(p2.x, p2.y)
			_pins[id] = pos
			_beacon(pos, p2.z, id, m, r)
		_orbit(_over, c, r, false)
		if selected != "" and _pins.has(selected):
			var sm := Content.map(selected)
			var la := float(sm.get("lat", 0.0))
			var lo := float(sm.get("lon", 0.0))
			var text := String(sm.get("name", "")).to_upper()
			var coords := "%.1f°%s  %.1f°%s" % [absf(la), "S" if la < 0.0 else "N", absf(lo), "W" if lo < 0.0 else "E"]
			var pos2: Vector2 = _pins[selected]
			var tw := maxf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, font.get_string_size(coords, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
			var right := pos2.x < size.x * 0.62
			var box := Rect2(pos2.x + (34.0 if right else -34.0 - tw - 24.0), pos2.y - 92.0, tw + 24.0, 52.0)
			box.position.x = clampf(box.position.x, 4.0, size.x - box.size.x - 4.0)
			var anchor := Vector2(box.position.x if right else box.end.x, box.end.y)
			_over.draw_line(pos2 - Vector2(0, 52), anchor, Color(0.45, 0.9, 1.0, 0.7), 2.0, true)
			Draw.rrect(_over, box, 8, Color(0.02, 0.1, 0.16, 0.85))
			_over.draw_rect(box, Color(0.45, 0.9, 1.0, 0.6), false, 1.5)
			_over.draw_string(font, box.position + Vector2(12, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.85, 1.0, 1.0))
			_over.draw_string(font, box.position + Vector2(12, 43), coords, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.45, 0.9, 1.0, 0.85))

	func _beacon(pos: Vector2, z: float, id: String, m: Dictionary, r: float) -> void:
		var owned := Save.owns_map(id)
		var soon: bool = m.get("status", "available") != "available"
		var sel := id == selected
		var col := UI.ACCENT if owned else (Color(0.45, 0.9, 1.0) if not soon else Color(0.6, 0.7, 0.75, 0.5))
		var k := 0.55 + 0.45 * z
		# the ring on the ground, squashed by the curve of the globe
		var sq := clampf(z, 0.2, 1.0)
		var pulse := fposmod(t * 0.8 + float(hash(id) % 100) * 0.01, 1.0)
		Draw.ellipse_line(_over, pos, (8.0 + pulse * (26.0 if sel else 14.0)) * k, (8.0 + pulse * (26.0 if sel else 14.0)) * k * sq, Color(col, (1.0 - pulse) * 0.7), 2.0)
		Draw.ellipse(_over, pos, 4.0 * k, 4.0 * k * sq, Color(col, 0.9))
		# a beam of light up from the surface
		var h := (64.0 if sel else 36.0) * k
		var top := pos - Vector2(0, h)
		for i in 4:
			var a0 := float(i) / 4.0
			_over.draw_line(pos.lerp(top, a0), pos.lerp(top, a0 + 0.25), Color(col, (0.75 - a0 * 0.5) * (1.0 if not soon else 0.5)), (4.0 if sel else 2.5) * k, true)
		var hr := (15.0 if sel else 10.0) * k + (sin(t * 4.0) * 1.5 if sel else 0.0)
		Draw.ellipse(_over, top, hr * 1.7, hr * 1.7, Color(col, 0.16))
		if owned:
			var flag: Array = m.get("flag", {}).get("colors", ["#f6d43a", "#1f8a3a"])
			Draw.ellipse(_over, top, hr, hr, col)
			Draw.ellipse(_over, top, hr * 0.62, hr * 0.62, Color(String(flag[0])))
			Draw.ellipse(_over, top, hr * 0.3, hr * 0.3, Color(String(flag[1] if flag.size() > 1 else flag[0])))
		elif soon:
			Draw.ellipse_line(_over, top, hr, hr, col, 2.0)
			for j in 3:
				Draw.ellipse(_over, top + Vector2((j - 1) * hr * 0.45, 0), hr * 0.12, hr * 0.12, col)
		else:
			Draw.ellipse(_over, top, hr, hr, Color(0.03, 0.12, 0.18, 0.92))
			Draw.ellipse_line(_over, top, hr, hr, col, 2.0)
			# padlock: shackle and body
			_over.draw_arc(top + Vector2(0, -hr * 0.12), hr * 0.3, PI, TAU, 10, col, maxf(1.5, hr * 0.12), true)
			Draw.rrect(_over, Rect2(top.x - hr * 0.42, top.y - hr * 0.12, hr * 0.84, hr * 0.6), hr * 0.12, col)
			Draw.ellipse(_over, top + Vector2(0, hr * 0.16), hr * 0.09, hr * 0.09, Color(0.03, 0.12, 0.18))
		if sel:
			Draw.ellipse_line(_over, top, hr * 1.35, hr * 1.35, Color(1, 1, 1, 0.75), 2.0)

	## A great-circle path from the last region to the new one, drawn on the
	## near side of the globe and fading out.
	func _flight_arc(a: Dictionary, b: Dictionary, r: float) -> void:
		var pa := _vec(float(a.get("lat", 0)), float(a.get("lon", 0)))
		var pb := _vec(float(b.get("lat", 0)), float(b.get("lon", 0)))
		var fade := clampf(2.2 - _arc_t, 0.0, 1.0)
		var grow := clampf(_arc_t / 0.7, 0.0, 1.0)
		var prev := Vector2.INF
		var n := 40
		for i in n + 1:
			var f := float(i) / n
			if f > grow:
				break
			var v := pa.slerp(pb, f).normalized() * (1.0 + sin(f * PI) * 0.12)
			var la := rad_to_deg(asin(clampf(v.normalized().y, -1.0, 1.0)))
			var lo := rad_to_deg(atan2(v.x, v.z))
			var s := _project(la, lo)
			var lift := sin(f * PI) * 0.12 * r
			var sp := Vector2(s.x, s.y) - Vector2(0, lift)
			if s.z > -0.1 and prev != Vector2.INF and i % 2 == 0:
				_over.draw_line(prev, sp, Color(1.0, 0.85, 0.35, 0.85 * fade), 3.0, true)
			prev = sp
		if grow < 1.0 and prev != Vector2.INF:
			Draw.ellipse(_over, prev, 5.0, 5.0, Color(1, 0.95, 0.6, fade))

	static func _vec(la: float, lo: float) -> Vector3:
		var phi := deg_to_rad(la)
		var lam := deg_to_rad(lo)
		return Vector3(cos(phi) * sin(lam), sin(phi), cos(phi) * cos(lam))

	## Sideways drags spin the globe (with a fling); taps pick a beacon.
	## Up/down drags are left to the page so it still scrolls. Touch only:
	## mouse clicks arrive as touches too (input_devices/pointing), so no
	## event is handled twice.
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed:
				_drag = {"start": event.position, "moved": false, "spinning": false, "t": Time.get_ticks_msec()}
			elif not _drag.is_empty():
				if not _drag.moved:
					_pick(event.position)
				elif _drag.spinning:
					accept_event()
				_drag = {}
		elif event is InputEventScreenDrag and not _drag.is_empty():
			var d: Vector2 = event.position - _drag.start
			if not _drag.moved and d.length() > 12.0:
				_drag.moved = true
				_drag.spinning = absf(d.x) >= absf(d.y)
			if _drag.spinning:
				accept_event()
				var r := minf(size.x, size.y) * RADIUS
				var dlon := -rad_to_deg(event.relative.x / r)
				lon += dlon
				target_lon = lon
				var dt := maxf(0.001, (Time.get_ticks_msec() - int(_drag.t)) / 1000.0)
				_drag.t = Time.get_ticks_msec()
				_spin = clampf(dlon / dt, -240.0, 240.0)
				_idle = 0.0

	func _pick(pos: Vector2) -> void:
		var best := ""
		var bd := 46.0
		for id in _pins:
			var p: Vector2 = _pins[id]
			var d := minf((p - pos).length(), (p - Vector2(0, 40) - pos).length())
			if d < bd:
				bd = d
				best = id
		if best != "":
			accept_event()
			pin_pressed.emit(best)


class EyeButton extends Control:
	## Switches between bird's-eye and first-person view. Shows what you
	## switch TO: an eye for first person, a bird for bird's-eye. Pulses when
	## dense canopy is ahead.
	signal pressed

	var fpv := false
	var pulse := false
	var t := 0.0

	func _init(s := 124.0) -> void:
		custom_minimum_size = Vector2(s, s)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if Widgets.is_pointer(event):
			accept_event()
			if Widgets.tap(self, event):
				pressed.emit()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.42)
		var r := minf(size.x, size.y) * 0.36
		if pulse and not fpv:
			var k := fposmod(t * 1.4, 1.0)
			Draw.ellipse_line(self, c, r * (1.0 + k * 0.5), r * (1.0 + k * 0.5), Color(1, 0.85, 0.3, 1.0 - k), 5)
		Draw.ellipse(self, c + Vector2(0, 4), r, r, Color(0, 0, 0, 0.3))
		Draw.ellipse(self, c, r, r, Color("2a6fe0") if not fpv else Color("2a8a5a"))
		if not fpv:
			var pts := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				pts.append(c + Vector2(-cos(a) * r * 0.7, -sin(a) * r * 0.42))
			for i in range(1, 12):
				var a2 := PI * i / 12.0
				pts.append(c + Vector2(cos(a2) * r * 0.7, sin(a2) * r * 0.42))
			draw_colored_polygon(pts, Color.WHITE)
			Draw.ellipse(self, c, r * 0.26, r * 0.26, Color("1a3a6a"))
			Draw.ellipse(self, c + Vector2(-r * 0.08, -r * 0.08), r * 0.08, r * 0.08, Color.WHITE)
		else:
			var wing := Color.WHITE
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.75, -r * 0.05), c + Vector2(-r * 0.2, -r * 0.3), c + Vector2(0, -r * 0.08),
				c + Vector2(r * 0.2, -r * 0.3), c + Vector2(r * 0.75, -r * 0.05), c + Vector2(0, r * 0.22)]), wing)
		var font := UI.font(true)
		var label := "First person" if not fpv else "Bird's-eye"
		var fs := int(size.y * 0.15)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := Vector2(size.x * 0.5 - w * 0.5, size.y - 6)
		draw_string_outline(font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.6))
		draw_string(font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
