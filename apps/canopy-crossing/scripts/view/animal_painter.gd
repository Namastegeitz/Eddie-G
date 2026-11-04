class_name AnimalPainter
extends RefCounted
## Draws any animal from its content file's "look" block: a friendly chibi
## figure standing on the board (2.5D: upright figure, top-down world).
## Body plans: mammal, bird, frog, snake, lizard, glider. Everything else
## (head shape, ears, snout, tail, eyes, pattern, extras, colours) is a
## parameter, so a new animal file reuses these parts. A file can instead
## name a "sprite" texture to draw.
##
## Origin = between the feet. `s` = full height in pixels.

static var _sprites := {}


static func col(look: Dictionary, key: String, fallback := "#888888") -> Color:
	return Color(String(look.get("colors", {}).get(key, fallback)))


static func with_skin(look: Dictionary, skin: Dictionary) -> Dictionary:
	if skin.is_empty():
		return look
	var l := look.duplicate(true)
	l.colors = (look.get("colors", {}) as Dictionary).merged(skin.get("colors", {}), true)
	return l


static func draw(ci: CanvasItem, animal: Dictionary, s: float, anim: Dictionary = {}, look_override: Dictionary = {}, pre := Transform2D.IDENTITY) -> void:
	var look: Dictionary = look_override if not look_override.is_empty() else animal.get("look", {})
	var sprite := String(animal.get("sprite", ""))
	var squash := float(anim.get("squash", 0.0))
	var shadow_a := float(anim.get("shadow", 0.28))
	var lift := float(anim.get("lift", 0.0))
	s *= 0.72 + 0.32 * float(look.get("size", 0.75))
	ci.draw_set_transform_matrix(pre)
	Draw.shadow(ci, Vector2(0, 0), s * 0.34 * (1.0 - lift * 0.4), s * 0.1 * (1.0 - lift * 0.4), shadow_a * (1.0 - lift * 0.5))
	var xf := Transform2D()
	xf = xf.scaled(Vector2((-1.0 if anim.get("flip", false) else 1.0) * (1.0 + squash * 0.18), 1.0 - squash * 0.2))
	xf.origin = Vector2(0, -lift * s * 0.9)
	ci.draw_set_transform_matrix(pre * xf)
	if sprite != "" and ResourceLoader.exists(sprite):
		if not _sprites.has(sprite):
			_sprites[sprite] = load(sprite)
		var tex: Texture2D = _sprites[sprite]
		var h := s * 1.05
		var w := h * tex.get_width() / maxf(1.0, tex.get_height())
		ci.draw_texture_rect(tex, Rect2(-w * 0.5, -h, w, h), false)
	else:
		match String(look.get("base", "mammal")):
			"frog":
				_frog(ci, look, s, anim)
			"bird":
				_bird(ci, look, s, anim)
			"snake":
				_snake(ci, look, s, anim)
			"lizard":
				_lizard(ci, look, s, anim)
			"glider":
				_glider(ci, look, s, anim)
			_:
				_mammal(ci, look, s, anim)
	ci.draw_set_transform_matrix(pre)


# ------------------------------------------------------------------ parts

static func _eyes(ci: CanvasItem, look: Dictionary, c: Vector2, gap: float, s: float, anim: Dictionary, kind := "") -> void:
	var e := col(look, "eye", "#1a120c")
	var size_k := String(look.get("eyes", kind))
	var blink := bool(anim.get("blink", false))
	for sx in [-1.0, 1.0]:
		var p := c + Vector2(sx * gap, 0)
		if blink:
			ci.draw_line(p + Vector2(-s * 0.045, 0), p + Vector2(s * 0.045, 0), Color("1a120c"), maxf(2.0, s * 0.018), true)
			continue
		match size_k:
			"huge":
				Draw.ellipse(ci, p, s * 0.1, s * 0.1, Color("fbf6ea"))
				Draw.ellipse(ci, p, s * 0.085, s * 0.085, e)
				Draw.ellipse(ci, p, s * 0.045, s * 0.05, Color("120c08"))
				Draw.ellipse(ci, p + Vector2(-s * 0.03, -s * 0.035), s * 0.022, s * 0.022, Color(1, 1, 1, 0.9))
			"big":
				Draw.ellipse(ci, p, s * 0.075, s * 0.078, Color("fbf6ea"))
				Draw.ellipse(ci, p + Vector2(0, s * 0.005), s * 0.058, s * 0.062, e)
				Draw.ellipse(ci, p + Vector2(0, s * 0.008), s * 0.03, s * 0.042, Color("120c08"))
				Draw.ellipse(ci, p + Vector2(-s * 0.022, -s * 0.026), s * 0.018, s * 0.018, Color(1, 1, 1, 0.95))
			_:
				Draw.ellipse(ci, p, s * 0.045, s * 0.055, e if e.get_luminance() < 0.35 else Color("1a120c"))
				if e.get_luminance() >= 0.35:
					Draw.ellipse(ci, p, s * 0.04, s * 0.05, e)
					Draw.ellipse(ci, p, s * 0.02, s * 0.034, Color("120c08"))
				Draw.ellipse(ci, p + Vector2(-s * 0.016, -s * 0.022), s * 0.016, s * 0.016, Color(1, 1, 1, 0.92))


static func _spots(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, n: int, r: float, salt: int, ring := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * 0.82
		var p := c + Vector2(cos(a) * rx * d, sin(a) * ry * d)
		var rr := r * rng.randf_range(0.7, 1.25)
		if ring:
			Draw.ellipse_line(ci, p, rr, rr * 0.85, color, maxf(1.5, rr * 0.4))
		else:
			Draw.ellipse(ci, p, rr, rr * rng.randf_range(0.75, 1.0), color, rng.randf() * PI)


static func _stripes(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, n: int, width: float, vertical := false) -> void:
	for i in n:
		var k := (float(i) + 0.5) / n * 2.0 - 1.0
		if vertical:
			var x := c.x + k * rx * 0.85
			var h := ry * sqrt(maxf(0.0, 1.0 - k * k)) * 0.9
			ci.draw_line(Vector2(x, c.y - h * 0.3), Vector2(x + k * width, c.y + h), color, width, true)
		else:
			var y := c.y + k * ry * 0.85
			var w := rx * sqrt(maxf(0.0, 1.0 - k * k))
			ci.draw_line(Vector2(c.x - w, y), Vector2(c.x - w * 0.45, y + width * 0.6), color, width, true)
			ci.draw_line(Vector2(c.x + w, y), Vector2(c.x + w * 0.45, y + width * 0.6), color, width, true)


static func _tail(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary, base: Vector2) -> void:
	var p := col(look, "primary")
	var sec := col(look, "secondary")
	var t := float(anim.get("t", 0.0))
	var sway := sin(t * 2.2) * 0.12
	match String(look.get("tail", "none")):
		"long", "thin", "long_banded":
			var pts := PackedVector2Array()
			for i in 9:
				var k := i / 8.0
				pts.append(base + Vector2(s * (0.12 + 0.3 * k), -s * (0.05 + 0.35 * k * k)) .rotated(sway))
			ci.draw_polyline(pts, p.darkened(0.08), s * (0.05 if look.get("tail") == "thin" else 0.075), true)
			if look.get("tail") == "long_banded":
				for i in range(2, 9, 2):
					Draw.ellipse(ci, pts[i], s * 0.04, s * 0.03, sec)
			Draw.ellipse(ci, pts[8], s * 0.045, s * 0.045, sec if look.get("tail") == "long_banded" else p.darkened(0.15))
		"long_curl":
			var pts2 := PackedVector2Array()
			for i in 16:
				var k2 := i / 15.0
				var r := s * (0.36 - 0.2 * k2)
				var a := -0.3 - k2 * 3.8 + sway
				pts2.append(base + Vector2(s * 0.2, -s * 0.3) + Vector2(cos(a), sin(a)) * r * Vector2(1.0, 1.05) - Vector2(cos(-0.3), sin(-0.3)) * s * 0.36)
			ci.draw_polyline(pts2, p.darkened(0.1), s * 0.06, true)
		"ringed", "ringed_brown":
			var a2 := sec if look.get("tail") == "ringed" else col(look, "secondary")
			var b2 := col(look, "accent") if look.get("tail") == "ringed" else col(look, "belly")
			var pts3 := PackedVector2Array()
			for i in 12:
				var k3 := i / 11.0
				pts3.append(base + Vector2(s * (0.14 + 0.2 * k3 + 0.08 * sin(k3 * 3.0)), -s * (0.05 + 0.75 * k3)).rotated(sway * 0.6))
			for i in range(pts3.size() - 1):
				ci.draw_line(pts3[i], pts3[i + 1], a2 if i % 2 == 0 else b2, s * 0.1, true)
			Draw.ellipse(ci, pts3[-1], s * 0.05, s * 0.05, a2)
		"bushy":
			Draw.ellipse(ci, base + Vector2(s * 0.3, -s * 0.28), s * 0.13, s * 0.28, p.darkened(0.1), 0.5 + sway)
		"flat":
			Draw.ellipse(ci, base + Vector2(0, s * 0.02), s * 0.13, s * 0.06, p.darkened(0.25))
		"stub":
			Draw.ellipse(ci, base + Vector2(s * 0.24, -s * 0.18), s * 0.05, s * 0.05, p.darkened(0.1))
		"scaly":
			for i in 5:
				Draw.ellipse(ci, base + Vector2(s * (0.18 + i * 0.06), -s * (0.02 + i * 0.02)), s * (0.08 - i * 0.01), s * 0.06, p.darkened(0.1 + 0.05 * (i % 2)))


static func _ears(ci: CanvasItem, look: Dictionary, h: Vector2, hr: float, s: float) -> void:
	var p := col(look, "primary")
	var inner := col(look, "belly").lerp(Color("e8a0a0"), 0.35)
	match String(look.get("ears", "small")):
		"small", "round", "round_big", "round_tipped":
			var r := s * (0.06 if look.get("ears") == "small" else (0.12 if look.get("ears") == "round_big" else 0.085))
			for sx in [-1.0, 1.0]:
				var c := h + Vector2(sx * hr * 0.78, -hr * 0.72)
				Draw.ellipse(ci, c, r, r, p.darkened(0.08))
				Draw.ellipse(ci, c + Vector2(0, r * 0.15), r * 0.55, r * 0.55, inner)
				if look.get("ears") == "round_tipped":
					Draw.ellipse_line(ci, c, r, r, Color.WHITE, maxf(1.5, s * 0.012))
		"big":
			for sx in [-1.0, 1.0]:
				var c2 := h + Vector2(sx * hr * 1.02, -hr * 0.05)
				Draw.ellipse(ci, c2, s * 0.085, s * 0.1, p.darkened(0.05))
				Draw.ellipse(ci, c2, s * 0.05, s * 0.065, col(look, "face", "#d9a888"))
		"tall":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.85, -hr * 0.85), s * 0.07, s * 0.15, p.darkened(0.05), sx * 0.6)
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.85, -hr * 0.85), s * 0.035, s * 0.1, inner, sx * 0.6)
		"pointed", "tufted":
			for sx in [-1.0, 1.0]:
				var b := h + Vector2(sx * hr * 0.6, -hr * 0.7)
				var pts := PackedVector2Array([b + Vector2(-s * 0.08, s * 0.04), b + Vector2(sx * s * 0.08, -s * 0.16), b + Vector2(s * 0.08, s * 0.02)])
				ci.draw_colored_polygon(pts, p.darkened(0.05))
				if look.get("ears") == "tufted":
					ci.draw_line(b + Vector2(sx * s * 0.08, -s * 0.16), b + Vector2(sx * s * 0.12, -s * 0.24), p.darkened(0.2), s * 0.025, true)
		"huge":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 1.0, -hr * 0.6), s * 0.15, s * 0.19, p.darkened(0.1), sx * 0.5)
				Draw.ellipse(ci, h + Vector2(sx * hr * 1.0, -hr * 0.6), s * 0.1, s * 0.14, Color("3a2a22"), sx * 0.5)
		"elephant":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 1.05, hr * 0.15), s * 0.2, s * 0.25, p.darkened(0.06), sx * 0.25)
				Draw.ellipse(ci, h + Vector2(sx * hr * 1.08, hr * 0.18), s * 0.14, s * 0.19, p.lerp(Color("c89a9a"), 0.25), sx * 0.25)


static func _snout(ci: CanvasItem, look: Dictionary, h: Vector2, hr: float, s: float) -> void:
	var p := col(look, "primary")
	var b := col(look, "belly")
	var face := col(look, "face", look.get("colors", {}).get("belly", "#e8d8c0"))
	var nose := Color("2a1a14")
	match String(look.get("snout", "short")):
		"short":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.42), hr * 0.42, hr * 0.3, face.lightened(0.1))
			Draw.ellipse(ci, h + Vector2(0, hr * 0.3), s * 0.03, s * 0.022, nose)
		"broad":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.42), hr * 0.62, hr * 0.38, p.lightened(0.12))
			Draw.ellipse(ci, h + Vector2(-hr * 0.2, hr * 0.32), s * 0.022, s * 0.016, nose)
			Draw.ellipse(ci, h + Vector2(hr * 0.2, hr * 0.32), s * 0.022, s * 0.016, nose)
		"cat":
			Draw.ellipse(ci, h + Vector2(-hr * 0.17, hr * 0.48), hr * 0.25, hr * 0.2, b)
			Draw.ellipse(ci, h + Vector2(hr * 0.17, hr * 0.48), hr * 0.25, hr * 0.2, b)
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-s * 0.035, hr * 0.28), h + Vector2(s * 0.035, hr * 0.28), h + Vector2(0, hr * 0.4)]), Color("d07a7a"))
		"ape":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.28), hr * 0.62, hr * 0.62, face)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.55), hr * 0.38, hr * 0.26, face.lightened(0.08))
			Draw.ellipse(ci, h + Vector2(-s * 0.02, hr * 0.42), s * 0.014, s * 0.01, nose)
			Draw.ellipse(ci, h + Vector2(s * 0.02, hr * 0.42), s * 0.014, s * 0.01, nose)
		"long":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.62), hr * 0.38, hr * 0.42, face)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.9), s * 0.04, s * 0.028, nose)
		"fox":
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.55, hr * 0.15), h + Vector2(hr * 0.55, hr * 0.15), h + Vector2(0, hr * 0.85)]), face)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.8), s * 0.03, s * 0.024, nose)
		"bear":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.45), hr * 0.45, hr * 0.32, face)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.32), s * 0.04, s * 0.03, nose)
		"otter":
			Draw.ellipse(ci, h + Vector2(-hr * 0.2, hr * 0.45), hr * 0.28, hr * 0.22, b)
			Draw.ellipse(ci, h + Vector2(hr * 0.2, hr * 0.45), hr * 0.28, hr * 0.22, b)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.32), s * 0.035, s * 0.025, nose)
		"trunk", "tapir":
			var long := String(look.get("snout")) == "trunk"
			var pts := PackedVector2Array()
			var steps := 8
			for i in steps + 1:
				var k := float(i) / steps
				pts.append(h + Vector2(sin(k * 2.2) * s * 0.06, hr * 0.2 + k * s * (0.42 if long else 0.16)))
			ci.draw_polyline(pts, p.darkened(0.06), s * (0.11 - 0.0), true)
			Draw.ellipse(ci, pts[-1], s * 0.055, s * 0.035, p.darkened(0.15))
			if long:
				for sx in [-1.0, 1.0]:
					ci.draw_line(h + Vector2(sx * hr * 0.35, hr * 0.55), h + Vector2(sx * hr * 0.42, hr * 0.95), col(look, "accent", "#f2ece0"), s * 0.035, true)
		"proboscis":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.5), hr * 0.5, hr * 0.32, face)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.62), hr * 0.32, hr * 0.42, Color("e88a6a"))
		"bill":
			Draw.rrect(ci, Rect2(h + Vector2(-hr * 0.55, hr * 0.25), Vector2(hr * 1.1, hr * 0.6)), hr * 0.3, col(look, "accent", "#3a3e44"))
			Draw.ellipse(ci, h + Vector2(-hr * 0.15, hr * 0.38), s * 0.012, s * 0.01, Color("111111"))
			Draw.ellipse(ci, h + Vector2(hr * 0.15, hr * 0.38), s * 0.012, s * 0.01, Color("111111"))
		"beak_long":
			ci.draw_line(h + Vector2(0, hr * 0.2), h + Vector2(0, hr * 1.25), col(look, "accent", "#2a2a2a"), s * 0.05, true)
		"mandrill":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.45), hr * 0.42, hr * 0.62, col(look, "ridge", "#3a7be0"))
			Draw.ellipse(ci, h + Vector2(0, hr * 0.42), hr * 0.17, hr * 0.62, col(look, "face", "#e8392f"))
			Draw.ellipse(ci, h + Vector2(0, hr * 0.98), hr * 0.25, hr * 0.12, Color("e8392f"))
		"coati":
			var tip := h + Vector2(0, hr * 1.05)
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.35, hr * 0.2), h + Vector2(hr * 0.35, hr * 0.2), tip + Vector2(s * 0.03, 0), tip - Vector2(s * 0.03, 0)]), p.darkened(0.2))
			Draw.ellipse(ci, tip, s * 0.035, s * 0.025, nose)
	if look.get("snout", "short") not in ["beak_long", "trunk", "bill", "mandrill"]:
		ci.draw_arc(h + Vector2(0, hr * 0.5), hr * 0.16, 0.3, PI - 0.3, 8, Color(0.1, 0.06, 0.04, 0.6), maxf(1.0, s * 0.012), true)


static func _pattern_body(ci: CanvasItem, look: Dictionary, c: Vector2, rx: float, ry: float, s: float) -> void:
	var sec := col(look, "secondary")
	var acc := col(look, "accent")
	match String(look.get("pattern", "")):
		"spots":
			_spots(ci, c, rx, ry, sec, 7, s * 0.035, 3)
		"rosettes":
			_spots(ci, c, rx, ry, sec, 6, s * 0.035, 5, true)
		"rosettes_small":
			_spots(ci, c, rx, ry, sec, 8, s * 0.025, 9, true)
		"clouds":
			_spots(ci, c, rx, ry, sec.lerp(col(look, "primary"), 0.3), 4, s * 0.06, 11)
			_spots(ci, c, rx, ry, sec, 4, s * 0.06, 11, true)
		"stripes":
			_stripes(ci, c, rx, ry, sec, 4, s * 0.03)
		"scales", "spines":
			var rows := 4
			for r in rows:
				for k in range(-2, 3):
					var p := c + Vector2(k * rx * 0.36 + (r % 2) * rx * 0.18, -ry * 0.7 + r * ry * 0.45)
					if (p - c).length() > maxf(rx, ry) * 0.95:
						continue
					if look.get("pattern") == "scales":
						ci.draw_arc(p, s * 0.06, 0.2, PI - 0.2, 8, col(look, "secondary"), s * 0.018, true)
					else:
						ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.025, s * 0.03), p + Vector2(0, -s * 0.06), p + Vector2(s * 0.025, s * 0.03)]), sec)
		"chest_crescent":
			ci.draw_arc(c + Vector2(0, -ry * 0.3), rx * 0.5, 0.2, PI - 0.2, 12, acc, s * 0.045, true)
		"throat_patch":
			Draw.ellipse(ci, c + Vector2(0, -ry * 0.55), rx * 0.4, ry * 0.25, acc)
		"leg_stripes":
			for sx in [-1.0, 1.0]:
				for i in 3:
					ci.draw_line(c + Vector2(sx * rx * 0.55, ry * (0.3 + i * 0.2)), c + Vector2(sx * rx * 0.95, ry * (0.25 + i * 0.2)), sec, s * 0.022, true)
		"side_bars":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, c + Vector2(sx * rx * 0.75, 0), rx * 0.25, ry * 0.7, sec)
				for i in 3:
					ci.draw_line(c + Vector2(sx * rx * 0.6, -ry * 0.4 + i * ry * 0.35), c + Vector2(sx * rx * 0.95, -ry * 0.35 + i * ry * 0.35), Color("f2f2e6"), s * 0.012, true)
		"mottled":
			_spots(ci, c, rx, ry, sec, 6, s * 0.04, 13)
			_spots(ci, c, rx, ry, acc, 4, s * 0.025, 17)
		"dorsal_stripe":
			ci.draw_line(c + Vector2(0, -ry), c + Vector2(0, ry * 0.6), sec, s * 0.03, true)
		"scallops":
			for r2 in 3:
				for k2 in range(-2, 3):
					ci.draw_arc(c + Vector2(k2 * rx * 0.3, -ry * 0.4 + r2 * ry * 0.35), s * 0.04, 0.3, PI - 0.3, 6, col(look, "primary").darkened(0.18), s * 0.012, true)
		"bands":
			_stripes(ci, c, rx, ry, sec, 3, s * 0.04, true)
		"dots":
			_spots(ci, c, rx, ry, sec, 6, s * 0.018, 21)


static func _extras_head(ci: CanvasItem, look: Dictionary, h: Vector2, hr: float, s: float) -> void:
	var p := col(look, "primary")
	var extras: Array = look.get("extras", [])
	if "brow" in extras:
		Draw.ellipse(ci, h + Vector2(0, -hr * 0.18), hr * 0.66, hr * 0.17, p.darkened(0.3))
	if "cheek_pads" in extras:
		for sx in [-1.0, 1.0]:
			Draw.ellipse(ci, h + Vector2(sx * hr * 0.98, hr * 0.15), hr * 0.32, hr * 0.48, col(look, "face").lightened(0.12))
	if "beard" in extras:
		var bc := p.lightened(0.15) if look.get("snout") != "mandrill" else Color("e8c84a")
		ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.55, hr * 0.62), h + Vector2(hr * 0.55, hr * 0.62), h + Vector2(hr * 0.2, hr * 1.15), h + Vector2(0, hr * 1.25), h + Vector2(-hr * 0.2, hr * 1.15)]), bc)
	if "whiskers" in extras:
		for sx in [-1.0, 1.0]:
			for i in 3:
				ci.draw_line(h + Vector2(sx * hr * 0.35, hr * 0.45), h + Vector2(sx * hr * 1.15, hr * (0.25 + 0.15 * i)), Color(1, 1, 1, 0.85), maxf(1.0, s * 0.008), true)
	if "cheek_ruff" in extras:
		for sx in [-1.0, 1.0]:
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(sx * hr * 0.7, -hr * 0.1), h + Vector2(sx * hr * 1.22, hr * 0.35), h + Vector2(sx * hr * 0.75, hr * 0.7)]), col(look, "accent", "#fbf2e2"))
	if "part" in extras:
		ci.draw_line(h + Vector2(0, -hr * 0.95), h + Vector2(0, -hr * 0.5), p.lightened(0.25), s * 0.012, true)
	if "crest" in extras:
		for i in 3:
			Draw.leaf(ci, h + Vector2((i - 1) * hr * 0.25, -hr * 0.8), Vector2((i - 1) * 0.5, -1), hr * 0.65, hr * 0.12, col(look, "secondary"))


static func _shaggy(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color, s: float) -> void:
	var pts := PackedVector2Array()
	var n := 22
	for i in n:
		var a := TAU * i / n
		var r := 1.0 + (0.12 if i % 2 == 0 else 0.0)
		pts.append(c + Vector2(cos(a) * rx * r, sin(a) * ry * r))
	ci.draw_colored_polygon(pts, color)


# ------------------------------------------------------------------ body plans

static func _mammal(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var b := col(look, "belly")
	var extras: Array = look.get("extras", [])
	var head_k := String(look.get("head", "round"))
	var wide := 1.15 if head_k in ["elephant", "ape", "blocky", "bear"] else 1.0
	var body := Vector2(0, -s * 0.3)
	var brx := s * 0.29 * wide
	var bry := s * 0.27
	_tail(ci, look, s, anim, Vector2(0, -s * 0.12))
	# legs
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(sx * s * 0.15, -s * 0.05), s * 0.1, s * 0.07, p.darkened(0.2))
	if "shaggy" in extras:
		_shaggy(ci, body, brx * 1.04, bry * 1.04, p.darkened(0.1), s)
	Draw.ellipse(ci, body, brx, bry, p)
	Draw.ellipse(ci, body + Vector2(0, s * 0.04), brx * 0.6, bry * 0.66, b)
	_pattern_body(ci, look, body, brx, bry, s)
	# arms
	var long_arms := "long_arms" in extras
	for sx in [-1.0, 1.0]:
		var ap := Vector2(sx * brx * 0.95, -s * (0.26 if long_arms else 0.32))
		Draw.ellipse(ci, ap, s * 0.07, s * (0.17 if long_arms else 0.1), p.darkened(0.08), sx * 0.35)
		var hand := ap + Vector2(sx * s * 0.04, s * (0.15 if long_arms else 0.08))
		Draw.ellipse(ci, hand, s * 0.05, s * 0.04, col(look, "secondary") if "dark_hands" in extras else p.darkened(0.18))
	# head
	var h := Vector2(0, -s * 0.7)
	var hr := s * 0.29
	_ears(ci, look, h, hr, s)
	if "shaggy" in extras:
		_shaggy(ci, h, hr * 1.06, hr * 1.0, p.darkened(0.1), s)
	match head_k:
		"long", "fox", "pointy":
			Draw.ellipse(ci, h, hr * 0.9, hr * 0.96, p)
		"blocky":
			Draw.rrect(ci, Rect2(h - Vector2(hr * 1.0, hr * 0.85), Vector2(hr * 2.0, hr * 1.75)), hr * 0.6, p)
		"otter", "civet":
			Draw.ellipse(ci, h, hr * 1.0, hr * 0.88, p)
		_:
			Draw.ellipse(ci, h, hr * 1.0 * (1.05 if head_k == "elephant" else 1.0), hr * 0.95, p)
	match String(look.get("pattern", "")):
		"cap":
			Draw.ellipse(ci, h + Vector2(0, -hr * 0.55), hr * 0.62, hr * 0.42, col(look, "secondary"))
		"eye_mask":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.42, -hr * 0.02), hr * 0.38, hr * 0.13, col(look, "accent"), sx * -0.25)
		"eye_rings":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.38, -hr * 0.05), hr * 0.36, hr * 0.38, col(look, "secondary"))
			ci.draw_line(h + Vector2(0, -hr * 0.9), h + Vector2(0, -hr * 0.2), col(look, "secondary"), s * 0.02, true)
		"eye_patches":
			Draw.ellipse(ci, h + Vector2(0, hr * 0.1), hr * 0.85, hr * 0.7, col(look, "face", "#f2f0ec"))
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.38, -hr * 0.02), hr * 0.25, hr * 0.27, col(look, "secondary"), sx * 0.4)
		"face_marks":
			for sx in [-1.0, 1.0]:
				Draw.ellipse(ci, h + Vector2(sx * hr * 0.38, hr * 0.15), hr * 0.18, hr * 0.12, col(look, "accent"))
		"stripes":
			_stripes(ci, h + Vector2(0, -hr * 0.2), hr * 0.85, hr * 0.6, col(look, "secondary"), 3, s * 0.022)
		"rosettes", "rosettes_small":
			_spots(ci, h + Vector2(0, -hr * 0.45), hr * 0.6, hr * 0.32, col(look, "secondary"), 4, s * 0.016, 31)
		"spots":
			_spots(ci, h + Vector2(0, -hr * 0.45), hr * 0.6, hr * 0.32, col(look, "secondary"), 3, s * 0.02, 37)
		"scales":
			for k in range(-1, 2):
				ci.draw_arc(h + Vector2(k * hr * 0.4, -hr * 0.5), s * 0.05, 0.2, PI - 0.2, 8, col(look, "secondary"), s * 0.016, true)
		"spines":
			for k2 in range(-3, 4):
				var bp := h + Vector2(k2 * hr * 0.25, -hr * 0.75 + absf(k2) * hr * 0.1)
				ci.draw_colored_polygon(PackedVector2Array([bp + Vector2(-s * 0.02, s * 0.03), bp + Vector2(k2 * s * 0.01, -s * 0.07), bp + Vector2(s * 0.02, s * 0.03)]), col(look, "secondary"))
	_snout(ci, look, h, hr, s)
	_eyes(ci, look, h + Vector2(0, -hr * 0.05), hr * 0.4, s, anim)
	_extras_head(ci, look, h, hr, s)


static func _bird(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var sec := col(look, "secondary")
	var b := col(look, "belly")
	var acc := col(look, "accent")
	var extras: Array = look.get("extras", [])
	var t := float(anim.get("t", 0.0))
	var flightless := bool(look.get("flightless", false))
	var body := Vector2(0, -s * (0.42 if flightless else 0.36))
	# tail behind
	match String(look.get("tail", "short")):
		"long":
			ci.draw_colored_polygon(PackedVector2Array([body + Vector2(-s * 0.08, s * 0.1), body + Vector2(s * 0.08, s * 0.1), body + Vector2(s * 0.03, s * 0.62), body + Vector2(-s * 0.03, s * 0.62)]), p.darkened(0.05))
			ci.draw_line(body + Vector2(0, s * 0.2), body + Vector2(0, s * 0.6), col(look, "wing2", "#2a6fe0"), s * 0.03, true)
		"streamers":
			for sx in [-1.0, 1.0]:
				var pts := PackedVector2Array()
				for i in 10:
					var k := i / 9.0
					pts.append(body + Vector2(sx * (s * 0.04 + k * s * 0.32 + sin(t * 2.0 + k * 3.0) * s * 0.03), s * 0.1 + k * s * 0.36))
				ci.draw_polyline(pts, sec, s * 0.045, true)
		"plumes":
			for i in 7:
				var a := -0.3 + i * 0.1
				Draw.leaf(ci, body + Vector2(0, s * 0.1), Vector2(sin(a * 4.0), 1.0), s * 0.45, s * 0.05, Color("f6d43a").lerp(Color("f2a03a"), i / 7.0))
		"banded", "short", "red", "shaggy":
			var tc := p.darkened(0.1)
			if look.get("tail") == "red":
				tc = acc
			Draw.ellipse(ci, body + Vector2(0, s * 0.28), s * 0.11, s * 0.14, tc)
			if look.get("tail") == "banded":
				Draw.ellipse(ci, body + Vector2(0, s * 0.3), s * 0.1, s * 0.04, Color("f5f5f0"))
	if "plumes" in extras:
		for sx in [-1.0, 1.0]:
			for i in 5:
				Draw.leaf(ci, body + Vector2(sx * s * 0.15, s * 0.05), Vector2(sx * (0.8 + i * 0.15), 0.4 - i * 0.25), s * 0.36, s * 0.04, acc.lerp(Color("f2a03a"), i / 5.0))
	# legs
	if flightless:
		for sx in [-1.0, 1.0]:
			ci.draw_line(Vector2(sx * s * 0.1, -s * 0.2), Vector2(sx * s * 0.12, -s * 0.02), Color("6a6a5a"), s * 0.045, true)
			Draw.ellipse(ci, Vector2(sx * s * 0.13, -s * 0.02), s * 0.07, s * 0.03, Color("5a5a4a"))
	else:
		for sx in [-1.0, 1.0]:
			Draw.ellipse(ci, Vector2(sx * s * 0.09, -s * 0.05), s * 0.06, s * 0.035, Color("4a3a2a"))
	Draw.ellipse(ci, body, s * (0.3 if flightless else 0.26), s * (0.3 if flightless else 0.31), p)
	Draw.ellipse(ci, body + Vector2(0, s * 0.06), s * 0.17, s * 0.22, b)
	if "chest_band" in extras:
		Draw.ellipse(ci, body + Vector2(0, -s * 0.12), s * 0.2, s * 0.06, sec)
	_pattern_body(ci, look, body, s * 0.22, s * 0.26, s)
	# wings
	var flap := sin(t * 3.0) * 0.08 if not flightless else 0.0
	for sx in [-1.0, 1.0]:
		var wc := body + Vector2(sx * s * 0.25, -s * 0.02)
		Draw.ellipse(ci, wc, s * 0.09, s * 0.22, sec if not flightless else p.darkened(0.1), sx * (0.25 + flap))
		if look.get("colors", {}).has("wing2"):
			Draw.ellipse(ci, wc + Vector2(0, s * 0.1), s * 0.07, s * 0.1, col(look, "wing2"), sx * (0.25 + flap))
	# head
	var h := Vector2(0, -s * (0.84 if flightless else 0.72))
	var hr := s * (0.17 if flightless else 0.2)
	if flightless:
		ci.draw_line(h + Vector2(0, hr * 0.5), body + Vector2(0, -s * 0.2), acc, s * 0.13, true)
		for sx in [-1.0, 1.0]:
			Draw.ellipse(ci, body + Vector2(sx * s * 0.05, -s * 0.24), s * 0.035, s * 0.08, col(look, "wattle", "#e0242c"))
	Draw.ellipse(ci, h, hr, hr * 1.0, p if not look.get("colors", {}).has("throat") else acc)
	if look.get("colors", {}).has("throat"):
		Draw.ellipse(ci, h + Vector2(0, hr * 0.6), hr * 0.8, hr * 0.45, col(look, "throat"))
	if "blue_neck" in extras:
		Draw.ellipse(ci, h + Vector2(0, hr * 0.3), hr * 0.85, hr * 0.7, acc)
	if String(look.get("pattern", "")) == "eye_stripe":
		Draw.ellipse(ci, h + Vector2(0, -hr * 0.05), hr * 1.0, hr * 0.18, col(look, "accent"))
	if look.get("beak", "") in ["huge", "huge_curved"]:
		Draw.ellipse(ci, h + Vector2(0, -hr * 0.05), hr * 0.85, hr * 0.85, b if look.get("beak") == "huge" else p)
	_eyes(ci, look, h + Vector2(0, -hr * 0.12), hr * 0.5, s * 0.9, anim)
	match String(look.get("beak", "short")):
		"huge":
			var tip := h + Vector2(s * 0.02, hr * 2.0)
			Draw.ellipse(ci, h + Vector2(0, hr * 1.1), hr * 0.42, hr * 1.05, acc)
			Draw.ellipse(ci, tip, hr * 0.22, hr * 0.22, col(look, "beak_tip", "#111111"))
		"huge_curved":
			Draw.ellipse(ci, h + Vector2(0, hr * 1.0), hr * 0.36, hr * 0.95, acc)
			Draw.ellipse(ci, h + Vector2(0, hr * 0.2), hr * 0.42, hr * 0.5, col(look, "casque", "#f05a1e"))
		"hooked":
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.3, hr * 0.2), h + Vector2(hr * 0.3, hr * 0.2), h + Vector2(hr * 0.1, hr * 0.85), h + Vector2(0, hr * 0.95), h + Vector2(-hr * 0.05, hr * 0.7)]), col(look, "beak_tip", "#1a1a1a"))
		"dagger":
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.25, hr * 0.15), h + Vector2(hr * 0.25, hr * 0.15), h + Vector2(0, hr * 1.2)]), Color("3a3a32"))
		_:
			ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-hr * 0.25, hr * 0.2), h + Vector2(hr * 0.25, hr * 0.2), h + Vector2(0, hr * 0.7)]), col(look, "beak_tip", "#d8c060"))
	if "casque" in extras and look.get("beak") != "huge_curved":
		Draw.ellipse(ci, h + Vector2(0, -hr * 1.0), hr * 0.42, hr * 0.5, col(look, "casque", "#8a6a3a"))
	if "crest" in extras:
		for i in 3:
			Draw.leaf(ci, h + Vector2((i - 1) * hr * 0.3, -hr * 0.7), Vector2((i - 1) * 0.4, -1), hr * 0.8, hr * 0.15, sec)


static func _frog(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var b := col(look, "belly")
	var extras: Array = look.get("extras", [])
	var puffy := "puffy" in extras
	var k := 1.12 if puffy else 1.0
	# back legs
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(sx * s * 0.28 * k, -s * 0.1), s * 0.15, s * 0.09, p.darkened(0.12), sx * 0.3)
		var foot := Vector2(sx * s * 0.4 * k, -s * 0.03)
		if "webbed_feet" in extras:
			for i in 4:
				Draw.leaf(ci, foot, Vector2(sx * (0.4 + i * 0.25), 0.4 - i * 0.35), s * 0.16, s * 0.06, col(look, "secondary") if i % 2 == 0 else col(look, "accent"))
		else:
			Draw.ellipse(ci, foot, s * 0.07, s * 0.035, p.darkened(0.22))
	var body := Vector2(0, -s * 0.28)
	Draw.ellipse(ci, body, s * 0.34 * k, s * 0.27 * k, p)
	Draw.ellipse(ci, body + Vector2(0, s * 0.07), s * 0.22 * k, s * 0.16 * k, b)
	_pattern_body(ci, look, body + Vector2(0, -s * 0.03), s * 0.3 * k, s * 0.22 * k, s)
	# front legs
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(sx * s * 0.17, -s * 0.06), s * 0.05, s * 0.07, p.darkened(0.1))
		Draw.ellipse(ci, Vector2(sx * s * 0.19, -s * 0.02), s * 0.05, s * 0.025, col(look, "accent") if look.get("pattern") == "side_bars" else p.darkened(0.25))
	# head
	var h := Vector2(0, -s * 0.5 * k)
	Draw.ellipse(ci, h, s * 0.3 * k, s * 0.18, p)
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, h + Vector2(sx * s * 0.18, -s * 0.12), s * 0.1, s * 0.1, p)
	_eyes(ci, look, h + Vector2(0, -s * 0.12), s * 0.18, s * 1.05, anim, "big" if look.get("eyes", "") == "" and col(look, "eye").get_luminance() > 0.2 else "")
	ci.draw_arc(h + Vector2(0, s * 0.0), s * 0.16, 0.35, PI - 0.35, 10, p.darkened(0.45), maxf(1.5, s * 0.016), true)
	if look.get("pattern") == "spots":
		_spots(ci, h + Vector2(0, -s * 0.02), s * 0.22, s * 0.08, col(look, "secondary"), 3, s * 0.025, 41)


static func _snake(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var sec := col(look, "secondary")
	var b := col(look, "belly")
	var t := float(anim.get("t", 0.0))
	var w := s * 0.13
	# coils
	for i in 3:
		var c := Vector2(0, -s * (0.1 + i * 0.12))
		var rx := s * (0.36 - i * 0.07)
		var ry := s * (0.12 - i * 0.015)
		var pts := Draw.ellipse_points(c, rx, ry, 0.0, 28)
		pts.append(pts[0])
		ci.draw_polyline(pts, p.darkened(0.2), w * 1.15, true)
		ci.draw_polyline(pts, p, w, true)
		if look.get("pattern") == "spots":
			for k in 6:
				var a := TAU * k / 6.0 + i
				Draw.ellipse(ci, c + Vector2(cos(a) * rx, sin(a) * ry), w * 0.3, w * 0.22, sec)
		elif look.get("pattern") == "dots":
			for k2 in 7:
				var a2 := TAU * k2 / 7.0 + i * 0.5
				Draw.ellipse(ci, c + Vector2(cos(a2) * rx, sin(a2) * ry - w * 0.15), w * 0.12, w * 0.12, sec)
	# neck + head
	var sway := sin(t * 2.0) * s * 0.03
	var neck := PackedVector2Array([Vector2(s * 0.12, -s * 0.36), Vector2(s * 0.06 + sway, -s * 0.5), Vector2(sway, -s * 0.62)])
	ci.draw_polyline(neck, p, w, true)
	ci.draw_line(neck[0], neck[2], b, w * 0.4, true)
	var h := Vector2(sway, -s * 0.72)
	Draw.ellipse(ci, h, s * 0.17, s * 0.13, p)
	Draw.ellipse(ci, h + Vector2(0, s * 0.06), s * 0.12, s * 0.06, p.lightened(0.1))
	_eyes(ci, look, h + Vector2(0, -s * 0.03), s * 0.1, s, anim)
	if int(t * 1.3) % 3 == 0:
		ci.draw_line(h + Vector2(0, s * 0.11), h + Vector2(0, s * 0.19), Color("d8242a"), s * 0.015, true)


static func _lizard(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var sec := col(look, "secondary")
	var acc := col(look, "accent")
	# curled tail
	var pts := PackedVector2Array()
	for i in 18:
		var k := i / 17.0
		var r := s * (0.2 - 0.15 * k)
		var a := k * 4.5
		pts.append(Vector2(s * 0.2, -s * 0.12) + Vector2(cos(a), sin(a)) * r)
	ci.draw_polyline(pts, p.darkened(0.08), s * 0.07, true)
	var body := Vector2(0, -s * 0.34)
	Draw.ellipse(ci, body, s * 0.25, s * 0.26, p)
	_stripes(ci, body, s * 0.25, s * 0.26, sec, 3, s * 0.05, true)
	Draw.ellipse(ci, body + Vector2(0, s * 0.12), s * 0.14, s * 0.08, acc)
	for sx in [-1.0, 1.0]:
		ci.draw_line(Vector2(sx * s * 0.15, -s * 0.2), Vector2(sx * s * 0.22, -s * 0.03), p.darkened(0.15), s * 0.05, true)
	var h := Vector2(0, -s * 0.68)
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-s * 0.18, s * 0.06), h + Vector2(0, -s * 0.26), h + Vector2(s * 0.18, s * 0.06), h + Vector2(0, s * 0.16)]), p)
	Draw.ellipse(ci, h + Vector2(0, s * 0.03), s * 0.18, s * 0.13, p)
	for sx in [-1.0, 1.0]:
		var e := h + Vector2(sx * s * 0.14, -s * 0.0)
		Draw.ellipse(ci, e, s * 0.075, s * 0.075, acc)
		var look_dir := sin(float(anim.get("t", 0.0)) * 1.3 + sx) * s * 0.02
		Draw.ellipse(ci, e + Vector2(look_dir, 0), s * 0.03, s * 0.03, Color("111111"))
	ci.draw_arc(h + Vector2(0, s * 0.06), s * 0.08, 0.3, PI - 0.3, 8, p.darkened(0.4), maxf(1.0, s * 0.012), true)


static func _glider(ci: CanvasItem, look: Dictionary, s: float, anim: Dictionary) -> void:
	var p := col(look, "primary")
	var b := col(look, "belly")
	var t := float(anim.get("t", 0.0))
	var spread := 1.0 + sin(t * 2.0) * 0.04
	var c := Vector2(0, -s * 0.36)
	var pts := PackedVector2Array([c + Vector2(-s * 0.42 * spread, -s * 0.2), c + Vector2(s * 0.42 * spread, -s * 0.2),
		c + Vector2(s * 0.38 * spread, s * 0.28), c + Vector2(0, s * 0.36), c + Vector2(-s * 0.38 * spread, s * 0.28)])
	ci.draw_colored_polygon(pts, p.darkened(0.12))
	var edge := pts.duplicate()
	edge.append(pts[0])
	ci.draw_polyline(edge, p.darkened(0.3), s * 0.02, true)
	Draw.ellipse(ci, c, s * 0.18, s * 0.27, p)
	Draw.ellipse(ci, c + Vector2(0, s * 0.05), s * 0.1, s * 0.17, b)
	_pattern_body(ci, look, c, s * 0.18, s * 0.27, s)
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, c + Vector2(sx * s * 0.4 * spread, -s * 0.2), s * 0.04, s * 0.04, p.darkened(0.3))
		Draw.ellipse(ci, Vector2(sx * s * 0.12, -s * 0.04), s * 0.06, s * 0.04, p.darkened(0.25))
	var h := Vector2(0, -s * 0.72)
	for sx in [-1.0, 1.0]:
		Draw.ellipse(ci, h + Vector2(sx * s * 0.13, -s * 0.12), s * 0.06, s * 0.07, p.darkened(0.05))
	Draw.ellipse(ci, h, s * 0.2, s * 0.18, p)
	Draw.ellipse(ci, h + Vector2(0, s * 0.08), s * 0.1, s * 0.07, b)
	_eyes(ci, look, h + Vector2(0, -s * 0.02), s * 0.09, s, anim)
	Draw.ellipse(ci, h + Vector2(0, s * 0.06), s * 0.022, s * 0.016, Color("2a1a14"))
