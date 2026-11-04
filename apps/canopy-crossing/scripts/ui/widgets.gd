class_name Widgets
extends RefCounted
## Small drawn controls shared by the screens.


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
		var down := false
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			down = true
		elif event is InputEventScreenTouch and event.pressed:
			down = true
		if down:
			accept_event()
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
	## Dot-matrix globe that spins to a region's pin. Pins: owned (gold),
	## locked (grey with a lock), coming soon (dim).
	signal pin_pressed(map_id: String)

	var lon := -60.0
	var lat := 0.0
	var target_lon := -60.0
	var target_lat := 0.0
	var selected := ""
	var t := 0.0
	var _pins := {}

	func _init(min_size := Vector2(560, 560)) -> void:
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_STOP

	func focus(map_id: String) -> void:
		selected = map_id
		var m := Content.map(map_id)
		target_lon = float(m.get("lon", 0.0))
		target_lat = clampf(float(m.get("lat", 0.0)), -35.0, 35.0)

	func _process(dt: float) -> void:
		if not is_visible_in_tree():
			return
		t += dt
		var d := wrapf(target_lon - lon, -180.0, 180.0)
		lon += d * (1.0 - exp(-dt * 3.0))
		lat = lerpf(lat, target_lat, 1.0 - exp(-dt * 3.0))
		if absf(d) < 0.5:
			target_lon += dt * 2.0
		queue_redraw()

	func _project(la: float, lo: float) -> Vector3:
		var r := minf(size.x, size.y) * 0.46
		var phi := deg_to_rad(la)
		var lam := deg_to_rad(lo - lon)
		var x := cos(phi) * sin(lam)
		var y := sin(phi)
		var z := cos(phi) * cos(lam)
		var tilt := deg_to_rad(lat)
		var y2 := y * cos(tilt) - z * sin(tilt)
		var z2 := y * sin(tilt) + z * cos(tilt)
		return Vector3(size.x * 0.5 + x * r, size.y * 0.5 - y2 * r, z2)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		Draw.ellipse(self, c + Vector2(0, 8), r * 1.02, r * 1.02, Color(0, 0, 0, 0.25), 0.0, 64)
		Draw.ellipse(self, c, r, r, Color("12385a"), 0.0, 64)
		Draw.ellipse(self, c + Vector2(-r * 0.25, -r * 0.3), r * 0.7, r * 0.6, Color(1, 1, 1, 0.04), 0.0, 48)
		for d in Content.globe_dots:
			var p := _project(d.x, d.y)
			if p.z <= 0.0:
				continue
			var k := 0.35 + 0.65 * p.z
			draw_rect(Rect2(p.x - 2.6 * k, p.y - 2.6 * k, 5.2 * k, 5.2 * k), Color(0.36, 0.72, 0.42, 0.45 + 0.55 * p.z))
		draw_arc(c, r, 0, TAU, 64, Color(0.6, 0.85, 1.0, 0.35), 3, true)
		_pins.clear()
		for id in Content.map_order:
			var m := Content.map(id)
			var p2 := _project(float(m.get("lat", 0)), float(m.get("lon", 0)))
			if p2.z <= 0.05:
				continue
			var pos := Vector2(p2.x, p2.y)
			_pins[id] = pos
			var owned := Save.owns_map(id)
			var soon: bool = m.get("status", "available") != "available"
			var col := UI.ACCENT if owned else (Color(0.6, 0.6, 0.6) if not soon else Color(0.5, 0.5, 0.5, 0.5))
			var sel := id == selected
			var pr := (14.0 if sel else 9.0) + (sin(t * 4.0) * 2.0 if sel else 0.0)
			draw_line(pos, pos - Vector2(0, pr * 2.2), col.darkened(0.3), 3)
			Draw.ellipse(self, pos - Vector2(0, pr * 2.2), pr, pr, col)
			if not owned and not soon:
				draw_rect(Rect2(pos.x - pr * 0.4, pos.y - pr * 2.3, pr * 0.8, pr * 0.6), Color("2a2a2a"))
			if sel:
				Draw.ellipse_line(self, pos, pr * 1.6, pr * 0.6, Color(1, 1, 1, 0.7), 2)

	func _gui_input(event: InputEvent) -> void:
		var pos := Vector2.INF
		if event is InputEventMouseButton and event.pressed:
			pos = event.position
		elif event is InputEventScreenTouch and event.pressed:
			pos = event.position
		if pos == Vector2.INF:
			return
		var best := ""
		var bd := 46.0
		for id in _pins:
			var d: float = (_pins[id] - Vector2(0, 20) - pos).length()
			if d < bd:
				bd = d
				best = id
		if best != "":
			accept_event()
			pin_pressed.emit(best)
