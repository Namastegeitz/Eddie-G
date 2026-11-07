class_name HazardPainter
extends RefCounted
## Draws every hazard, tile, lane effect and collectible from its content
## file's "art" block: {"painter": id, "colors": {...}}. Painters are shared,
## so a new hazard file can reuse one with new colours, or name a "sprite".
##
## Entities: origin at the entity's left edge, lane centre at y = 0.

const ANIMATED := ["roll_log", "boulder", "ants", "soldier_ant", "herd", "runner", "vine", "caiman_back", "lilypad", "boat", "bridge", "lizard", "crab"]

static var _sprites := {}


static func c(colors: Dictionary, key: String, fallback := "#888888") -> Color:
	return Color(String(colors.get(key, fallback)))


static func animated(painter: String) -> bool:
	return painter in ANIMATED


static func draw_entity(ci: CanvasItem, hz: Dictionary, len_px: float, T: float, o: Dictionary) -> void:
	var art: Dictionary = hz.get("art", {})
	var cl: Dictionary = art.get("colors", {})
	var dir := int(o.get("dir", 1))
	var t := float(o.get("t", 0.0))
	var sprite := String(hz.get("sprite", ""))
	if sprite != "" and ResourceLoader.exists(sprite):
		if not _sprites.has(sprite):
			_sprites[sprite] = load(sprite)
		var tex: Texture2D = _sprites[sprite]
		ci.draw_texture_rect(tex, Rect2(0, -T * 0.45, len_px, T * 0.9), false)
		return
	if Draw.detail > 0 and Draw.outline == 0.0:
		Draw.begin_outline(maxf(1.2, T * 0.028))
		draw_entity(ci, hz, len_px, T, o)
		Draw.end_outline()
	var L := len_px
	if String(hz.get("kind", "")) == "platform" and Draw.outline == 0.0:
		_ripple(ci, L, T, t)
	match String(art.get("painter", "")):
		"truck":
			_truck(ci, cl, L, T, dir)
		"jeep":
			_jeep(ci, cl, L, T, dir)
		"tractor":
			_tractor(ci, cl, L, T, dir)
		"cart":
			_cart(ci, cl, L, T, dir)
		"scooter":
			_scooter(ci, cl, L, T, dir)
		"herd":
			_beast(ci, cl, L, T, dir, t)
		"ants":
			_ant(ci, cl, L, T, dir, t)
		"crab":
			_crab(ci, cl, L, T, dir, t)
		"soldier_ant":
			_soldier_ant(ci, cl, L, T, dir, t)
		"roll_log":
			_roll_log(ci, cl, L, T, t * float(o.get("speed", 1.0)))
		"elephant":
			_elephant(ci, cl, L, T, dir, t)
		"runner":
			_runner(ci, cl, L, T, dir, t)
		"vine":
			_vine(ci, cl, L, T, t)
		"boulder":
			_boulder(ci, cl, L, T, t * float(o.get("speed", 1.0)))
		"lizard":
			_lizard(ci, cl, L, T, dir, t)
		"log":
			_log(ci, cl, L, T)
		"lilypad":
			_lilypad(ci, cl, L, T, t)
		"caiman_back":
			_caiman_back(ci, cl, L, T, dir, t)
		"branch":
			_branch(ci, cl, L, T)
		"boat":
			_boat(ci, cl, L, T, dir, t)
		"bridge":
			_bridge(ci, cl, L, T, t)
		"stones":
			_stone(ci, cl, L, T)
		_:
			Draw.slab(ci, Rect2(0, -T * 0.3, L, T * 0.6), T * 0.15, c(cl, "body"))
	if o.get("colorblind", false) and Draw.outline == 0.0:
		if hz.get("kind", "") == "platform":
			var pts := Draw.rrect_points(Rect2(2, -T * 0.36, L - 4, T * 0.72), T * 0.2)
			pts.append(pts[0])
			Draw.polyline(ci, pts, Color.WHITE, 3.0, true)
		else:
			_hazard_marker(ci, Vector2(L * 0.5, -T * 0.05), T * 0.16)


## Soft rings in the water around anything floating.
static func _ripple(ci: CanvasItem, L: float, T: float, t: float) -> void:
	if Draw.detail < 1:
		return
	var k := fposmod(t * 0.6 + L * 0.01, 1.0)
	Draw.ellipse_line(ci, Vector2(L * 0.5, T * 0.04), L * 0.5 + T * (0.06 + k * 0.14), T * (0.36 + k * 0.1), Color(1, 1, 1, 0.22 * (1.0 - k)), 2.0)
	Draw.ellipse_line(ci, Vector2(L * 0.5, T * 0.06), L * 0.5 + T * 0.04, T * 0.36, Color(1, 1, 1, 0.16), 3.0)


static func _headlights(ci: CanvasItem, L: float, T: float, dir: int, spread := 0.2) -> void:
	var fx := L - T * 0.05 if dir > 0 else T * 0.05
	for sy in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(fx, sy * T * spread), T * 0.05, T * 0.07, Color("fff3b0"))
		if Draw.outline == 0.0 and Draw.detail > 1:
			Draw.ellipse(ci, Vector2(fx + dir * T * 0.12, sy * T * spread), T * 0.14, T * 0.09, Color(1, 0.95, 0.6, 0.12))


static func _glare(ci: CanvasItem, r: Rect2) -> void:
	if Draw.outline > 0.0 or Draw.detail < 2:
		return
	Draw.line(ci, r.position + Vector2(r.size.x * 0.25, r.size.y * 0.8), r.position + Vector2(r.size.x * 0.7, r.size.y * 0.15), Color(1, 1, 1, 0.45), maxf(2.0, r.size.x * 0.12), true)


static func _dot_eye(ci: CanvasItem, p: Vector2, r: float) -> void:
	Draw.ellipse(ci, p, r, r, Color("140d08"))
	if Draw.outline == 0.0:
		Draw.ellipse(ci, p + Vector2(-r * 0.3, -r * 0.35), r * 0.38, r * 0.38, Color(1, 1, 1, 0.9))


static func _hazard_marker(ci: CanvasItem, p: Vector2, r: float) -> void:
	var tri := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.95, r * 0.7), p + Vector2(-r * 0.95, r * 0.7)])
	Draw.poly(ci, tri, Color.BLACK)
	var inner := PackedVector2Array([p + Vector2(0, -r * 0.62), p + Vector2(r * 0.6, r * 0.48), p + Vector2(-r * 0.6, r * 0.48)])
	Draw.poly(ci, inner, Color("ffd400"))
	Draw.line(ci, p + Vector2(0, -r * 0.3), p + Vector2(0, r * 0.1), Color.BLACK, r * 0.18)
	Draw.ellipse(ci, p + Vector2(0, r * 0.3), r * 0.1, r * 0.1, Color.BLACK)


# ------------------------------------------------------------------ movers

static func _front(L: float, dir: int, w: float) -> Rect2:
	return Rect2(L - w if dir > 0 else 0.0, 0, w, 0)


static func _truck(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int) -> void:
	var cab_w := minf(T * 0.7, L * 0.28)
	var bed := Rect2(0 if dir > 0 else cab_w + 4, -T * 0.34, L - cab_w - 4, T * 0.62)
	var cab := Rect2(L - cab_w if dir > 0 else 0, -T * 0.3, cab_w, T * 0.56)
	Draw.slab(ci, bed, 8, c(cl, "body"), 9)
	var cargo := c(cl, "cargo")
	var n := maxi(2, int(bed.size.x / (T * 0.3)))
	for i in 3:
		var y := bed.position.y + T * 0.1 + i * T * 0.15
		Draw.rrect(ci, Rect2(bed.position.x + 6, y - 2, bed.size.x - 12, T * 0.15), 6, cargo.darkened(0.05 * i))
		Draw.ellipse(ci, Vector2(bed.position.x + (bed.size.x - 8 if dir > 0 else 8), y + T * 0.06), T * 0.06, T * 0.06, cargo.lightened(0.35))
	Draw.slab(ci, cab, 10, c(cl, "cab"), 11)
	var ws := Rect2(cab.position.x + (cab.size.x * 0.55 if dir > 0 else cab.size.x * 0.1), cab.position.y + 6, cab.size.x * 0.32, cab.size.y - 12)
	Draw.rrect(ci, ws, 5, Color("9fd0e8"))
	_glare(ci, ws)
	_headlights(ci, L, T, dir)
	for wx in [bed.position.x + T * 0.3, bed.position.x + bed.size.x - T * 0.3]:
		for wy in [-T * 0.38, T * 0.3]:
			Draw.rrect(ci, Rect2(wx - T * 0.12, wy, T * 0.24, T * 0.1), 4, Color("1e1e1e"))
	var _n := n


static func _jeep(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int) -> void:
	Draw.slab(ci, Rect2(0, -T * 0.32, L, T * 0.6), 14, c(cl, "body"), 9)
	Draw.rrect(ci, Rect2(L * 0.22, -T * 0.26, L * 0.5, T * 0.48), 10, c(cl, "roof"))
	var wx := L * 0.74 if dir > 0 else L * 0.08
	Draw.rrect(ci, Rect2(wx, -T * 0.24, L * 0.16, T * 0.44), 6, Color("9fd0e8"))
	_glare(ci, Rect2(wx, -T * 0.24, L * 0.16, T * 0.44))
	for k in 3:
		var rx := L * (0.3 + k * 0.14)
		Draw.line(ci, Vector2(rx, -T * 0.22), Vector2(rx, T * 0.18), c(cl, "roof").darkened(0.2), 2.0)
	_headlights(ci, L, T, dir, 0.24)
	var sp := L * 0.04 if dir > 0 else L * 0.86
	Draw.ellipse(ci, Vector2(sp + L * 0.05, 0), T * 0.12, T * 0.16, Color("222222"))
	for x in [L * 0.2, L * 0.8]:
		for y in [-T * 0.38, T * 0.28]:
			Draw.rrect(ci, Rect2(x - T * 0.11, y, T * 0.22, T * 0.1), 4, Color("1e1e1e"))


static func _tractor(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int) -> void:
	var cab_w := L * 0.38
	var trailer := Rect2(0 if dir > 0 else cab_w + 6, -T * 0.32, L - cab_w - 6, T * 0.6)
	Draw.slab(ci, trailer, 8, c(cl, "cargo").darkened(0.35), 8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 18:
		Draw.ellipse(ci, trailer.position + Vector2(rng.randf_range(8, trailer.size.x - 8), rng.randf_range(8, trailer.size.y - 10)), T * 0.07, T * 0.07, c(cl, "cargo").lerp(Color("c83a1a"), rng.randf() * 0.5))
	var cx := L - cab_w if dir > 0 else 0.0
	for wy in [-T * 0.42, T * 0.26]:
		Draw.rrect(ci, Rect2(cx + cab_w * 0.1, wy, cab_w * 0.45, T * 0.18), 6, Color("1a1a1a"))
	Draw.slab(ci, Rect2(cx, -T * 0.26, cab_w, T * 0.5), 10, c(cl, "body"), 9)
	Draw.rrect(ci, Rect2(cx + cab_w * 0.15, -T * 0.18, cab_w * 0.4, T * 0.34), 6, c(cl, "cab"))
	_glare(ci, Rect2(cx + cab_w * 0.15, -T * 0.18, cab_w * 0.4, T * 0.34))
	Draw.ellipse(ci, Vector2(cx + cab_w * (0.75 if dir > 0 else 0.25), -T * 0.12), T * 0.05, T * 0.05, Color("2a2a2a"))


static func _cart(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int) -> void:
	var cart := Rect2(0 if dir > 0 else L * 0.45, -T * 0.3, L * 0.55, T * 0.56)
	Draw.slab(ci, cart, 6, c(cl, "body"), 7)
	for i in 4:
		Draw.line(ci, cart.position + Vector2(0, 6 + i * cart.size.y / 4.0), cart.position + Vector2(cart.size.x, 6 + i * cart.size.y / 4.0), c(cl, "body").darkened(0.25), 2)
	for wy in [-T * 0.4, T * 0.28]:
		Draw.ellipse(ci, Vector2(cart.get_center().x, wy + T * 0.05), T * 0.16, T * 0.05, Color("3a2a1a"))
	var bx := L * 0.78 if dir > 0 else L * 0.22
	var a := c(cl, "animal")
	Draw.shadow(ci, Vector2(bx + 4, 6), T * 0.36, T * 0.24, 0.2)
	Draw.ellipse(ci, Vector2(bx, 0), T * 0.34, T * 0.22, a)
	Draw.ellipse(ci, Vector2(bx - dir * T * 0.05, -T * 0.02), T * 0.12, T * 0.1, a.darkened(0.08))
	Draw.ellipse(ci, Vector2(bx + dir * T * 0.36, 0), T * 0.13, T * 0.11, a.darkened(0.05))
	for sy in [-1.0, 1.0]:
		Draw.line(ci, Vector2(bx + dir * T * 0.38, sy * T * 0.08), Vector2(bx + dir * T * 0.44, sy * T * 0.18), Color("e8e0c0"), 4, true)
	Draw.line(ci, Vector2(cart.get_center().x + dir * cart.size.x * 0.5, 0), Vector2(bx - dir * T * 0.3, 0), Color("5a3a1a"), 4)


static func _scooter(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int) -> void:
	Draw.slab(ci, Rect2(L * 0.05, -T * 0.13, L * 0.9, T * 0.26), 10, c(cl, "body"), 6)
	var hx := L * 0.82 if dir > 0 else L * 0.18
	Draw.line(ci, Vector2(hx, -T * 0.22), Vector2(hx, T * 0.22), Color("333333"), 5, true)
	Draw.ellipse(ci, Vector2(L * 0.45, 0), T * 0.17, T * 0.17, c(cl, "rider"))
	Draw.ellipse(ci, Vector2(L * 0.45 + dir * T * 0.03, 0), T * 0.1, T * 0.1, c(cl, "rider").darkened(0.25))
	Draw.ellipse(ci, Vector2(L * 0.45 + dir * T * 0.1, 0), T * 0.04, T * 0.08, Color("1c2a36"))
	_headlights(ci, L, T, dir, 0.0)


static func _beast(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var a := c(cl, "accent")
	var cx := L * 0.5
	var step := sin(t * 14.0) * T * 0.04
	Draw.shadow(ci, Vector2(cx + 4, 8), L * 0.48, T * 0.24, 0.22)
	for lx in [-0.25, 0.25]:
		for ly in [-1.0, 1.0]:
			Draw.ellipse(ci, Vector2(cx + lx * L + step * ly, ly * T * 0.2), T * 0.06, T * 0.05, b.darkened(0.3))
	Draw.shaded(ci, Vector2(cx, 0), L * 0.42, T * 0.22, b)
	Draw.line(ci, Vector2(cx - L * 0.3, -T * 0.02), Vector2(cx + L * 0.25, -T * 0.02), b.darkened(0.25), 3, true)
	var hx := cx + dir * L * 0.42
	Draw.ellipse(ci, Vector2(hx, 0), T * 0.15, T * 0.13, b.darkened(0.08))
	Draw.ellipse(ci, Vector2(hx + dir * T * 0.13, 0), T * 0.07, T * 0.06, b.lightened(0.2))
	for sy in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(hx - dir * T * 0.05, sy * T * 0.1), T * 0.05, T * 0.035, a)
		_dot_eye(ci, Vector2(hx + dir * T * 0.03, sy * T * 0.075), T * 0.028)
	Draw.ellipse(ci, Vector2(cx - dir * L * 0.44, 0), T * 0.05, T * 0.03, b.darkened(0.3))


static func _ant(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var cx := L * 0.5
	var wig := sin(t * 20.0 + L) * 2.0
	for i in 3:
		var lx := cx + (i - 1) * L * 0.18
		Draw.line(ci, Vector2(lx, 0), Vector2(lx + wig, -T * 0.13), b.darkened(0.3), 2, true)
		Draw.line(ci, Vector2(lx, 0), Vector2(lx - wig, T * 0.13), b.darkened(0.3), 2, true)
	Draw.ellipse(ci, Vector2(cx - dir * L * 0.25, 0), L * 0.2, T * 0.07, b)
	Draw.ellipse(ci, Vector2(cx, 0), L * 0.12, T * 0.05, b.darkened(0.1))
	Draw.ellipse(ci, Vector2(cx + dir * L * 0.25, 0), L * 0.14, T * 0.065, b)
	if Draw.outline == 0.0 and Draw.detail > 1:
		Draw.ellipse(ci, Vector2(cx - dir * L * 0.28, -T * 0.025), L * 0.07, T * 0.022, Color(1, 1, 1, 0.35))
	var leaf := c(cl, "leaf")
	Draw.leaf(ci, Vector2(cx + dir * L * 0.2, -T * 0.06), Vector2(dir * 0.3, -1), T * 0.24, T * 0.09, leaf)


## A giant red soldier ant seen from above, hauling a wedge of cheese:
## glossy segmented body, big head with curved mandibles, elbowed antennae,
## six legs walking in a tripod gait.
static func _soldier_ant(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var red := c(cl, "body", "#c8281e")
	var dark := red.darkened(0.5)
	var cheese := c(cl, "cheese", "#f6c83a")
	var rind := c(cl, "rind", "#d88a2a")
	var cx := L * 0.5
	var d := float(dir)
	var step := t * 14.0 + L
	Draw.shadow(ci, Vector2(cx + 4, T * 0.12), L * 0.5, T * 0.2, 0.22)
	# legs, from the thorax: middle pair swings opposite the front and back
	for i in 3:
		for sy in [-1.0, 1.0]:
			var ph := step + (PI if (i + (1 if sy > 0.0 else 0)) % 2 == 1 else 0.0)
			var sw := sin(ph) * T * 0.07
			var hip := Vector2(cx + d * (0.02 + (i - 1) * 0.06) * L, sy * T * 0.05)
			var knee := Vector2(hip.x + d * ((i - 1) * 0.13 * L + sw), sy * T * 0.25)
			var foot := Vector2(knee.x + d * ((i - 1) * 0.1 * L + sw * 0.6), sy * T * 0.37)
			Draw.polyline(ci, PackedVector2Array([hip, knee, foot]), dark, maxf(2.5, T * 0.035), true)
			Draw.ellipse(ci, knee, T * 0.022, T * 0.022, dark)
	# gaster with dark bands, two petiole nodes, thorax
	var g := Vector2(cx - d * L * 0.27, 0)
	Draw.shaded(ci, g, L * 0.21, T * 0.17, red)
	if Draw.outline == 0.0:
		for b in 3:
			var bx := g.x + d * (L * 0.05 - b * L * 0.06)
			var hh := T * 0.15 * sqrt(maxf(0.0, 1.0 - pow((bx - g.x) / (L * 0.21), 2.0)))
			Draw.line(ci, Vector2(bx, -hh), Vector2(bx - d * T * 0.02, hh), Color(dark, 0.7), maxf(1.5, T * 0.025), true)
	Draw.ellipse(ci, Vector2(cx - d * L * 0.08, 0), L * 0.045, T * 0.05, red.darkened(0.12))
	Draw.ellipse(ci, Vector2(cx - d * L * 0.02, 0), L * 0.04, T * 0.045, red.darkened(0.12))
	Draw.shaded(ci, Vector2(cx + d * L * 0.08, 0), L * 0.12, T * 0.085, red.darkened(0.05))
	# head: big and square-ish, eyes, curved mandibles, antennae
	var h := Vector2(cx + d * L * 0.27, 0)
	var wave := sin(t * 5.0 + L) * T * 0.03
	for sy2 in [-1.0, 1.0]:
		var ab := h + Vector2(d * L * 0.06, sy2 * T * 0.06)
		Draw.polyline(ci, PackedVector2Array([ab, ab + Vector2(d * L * 0.05, sy2 * T * 0.14), ab + Vector2(d * L * 0.18, sy2 * T * 0.2 + wave * sy2)]), dark, maxf(1.5, T * 0.022), true)
		var mb := h + Vector2(d * L * 0.1, sy2 * T * 0.075)
		Draw.polyline(ci, PackedVector2Array([mb, mb + Vector2(d * L * 0.08, sy2 * T * 0.02), mb + Vector2(d * L * 0.14, -sy2 * T * 0.05)]), dark.darkened(0.2), maxf(2.5, T * 0.045), true)
	Draw.shaded(ci, h, L * 0.13, T * 0.15, red.darkened(0.08))
	for sy3 in [-1.0, 1.0]:
		Draw.ellipse(ci, h + Vector2(d * L * 0.03, sy3 * T * 0.115), T * 0.03, T * 0.025, Color("140a08"))
		if Draw.outline == 0.0:
			Draw.ellipse(ci, h + Vector2(d * L * 0.02, sy3 * T * 0.11), T * 0.01, T * 0.01, Color(1, 1, 1, 0.8))
	# the cheese, held up over the thorax: rind along the back, holes on top
	var bob := sin(step * 2.0) * T * 0.01
	var tip := Vector2(cx + d * L * 0.17, bob)
	var bl := Vector2(cx - d * L * 0.15, -T * 0.2 + bob)
	var br := Vector2(cx - d * L * 0.15, T * 0.2 + bob)
	if Draw.outline == 0.0:
		Draw.poly(ci, PackedVector2Array([tip + Vector2(5, 7), bl + Vector2(5, 7), br + Vector2(5, 7)]), Color(0, 0, 0, 0.22))
	Draw.poly(ci, PackedVector2Array([tip, bl, br]), cheese)
	Draw.line(ci, bl, br, rind, maxf(4.0, T * 0.06), true)
	if Draw.outline == 0.0:
		Draw.poly(ci, PackedVector2Array([tip, bl.lerp(tip, 0.1) + Vector2(0, T * 0.02), bl.lerp(br, 0.35)]), Color(1, 1, 1, 0.16))
		var holes := [Vector2(0.45, -0.25), Vector2(0.25, 0.3), Vector2(0.62, 0.12), Vector2(0.2, -0.05)]
		for hp in holes:
			var p := bl.lerp(br, 0.5).lerp(tip, hp.x) + Vector2(0, hp.y * T * 0.2 * (1.0 - hp.x))
			Draw.ellipse(ci, p, T * 0.032, T * 0.026, cheese.darkened(0.3))


static func _roll_log(ci: CanvasItem, cl: Dictionary, L: float, T: float, roll: float) -> void:
	var b := c(cl, "body")
	Draw.shadow(ci, Vector2(L * 0.5 + 4, T * 0.3), L * 0.5, T * 0.14, 0.25)
	Draw.rrect(ci, Rect2(0, -T * 0.32, L, T * 0.64), T * 0.3, b)
	Draw.rrect(ci, Rect2(0, -T * 0.32, L, T * 0.18), T * 0.12, b.lightened(0.12))
	var off := fposmod(roll * T * 0.6, T * 0.32)
	var x := off
	while x < L - 4:
		Draw.line(ci, Vector2(x, -T * 0.3), Vector2(x - T * 0.08, T * 0.3), b.darkened(0.25), 3, true)
		x += T * 0.32
	for ex in [T * 0.08, L - T * 0.08]:
		Draw.ellipse(ci, Vector2(ex, 0), T * 0.08, T * 0.3, c(cl, "ring"))
		Draw.ellipse_line(ci, Vector2(ex, 0), T * 0.05, T * 0.19, b.darkened(0.2), 2)
		if Draw.detail > 1:
			Draw.ellipse_line(ci, Vector2(ex, 0), T * 0.025, T * 0.09, b.darkened(0.2), 1.5)


static func _elephant(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var cx := L * 0.45 if dir > 0 else L * 0.55
	var step := sin(t * 6.0) * T * 0.04
	Draw.shadow(ci, Vector2(cx + 6, 10), L * 0.45, T * 0.42, 0.25)
	for lx in [-0.25, 0.22]:
		for ly in [-1.0, 1.0]:
			Draw.ellipse(ci, Vector2(cx + lx * L + step * ly, ly * T * 0.36), T * 0.1, T * 0.08, b.darkened(0.3))
	Draw.shaded(ci, Vector2(cx, 0), L * 0.38, T * 0.4, b)
	Draw.ellipse(ci, Vector2(cx - dir * L * 0.05, -T * 0.06), L * 0.26, T * 0.24, b.lightened(0.07))
	var hx := cx + dir * L * 0.36
	for sy in [-1.0, 1.0]:
		Draw.ellipse(ci, Vector2(hx - dir * T * 0.05, sy * T * 0.26), T * 0.22, T * 0.2, c(cl, "ear"), sy * 0.3)
	Draw.ellipse(ci, Vector2(hx, 0), T * 0.24, T * 0.22, b.darkened(0.05))
	var trunk := PackedVector2Array()
	for i in 6:
		var k := i / 5.0
		trunk.append(Vector2(hx + dir * (T * 0.18 + k * T * 0.32), sin(t * 3.0 + k * 2.0) * T * 0.06))
	Draw.polyline(ci, trunk, b.darkened(0.1), T * 0.11, true)
	for sy in [-1.0, 1.0]:
		_dot_eye(ci, Vector2(hx + dir * T * 0.06, sy * T * 0.12), T * 0.035)
	for sy in [-1.0, 1.0]:
		Draw.line(ci, Vector2(hx + dir * T * 0.15, sy * T * 0.08), Vector2(hx + dir * T * 0.32, sy * T * 0.12), Color("f2ece0"), 4, true)


static func _runner(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var cx := L * 0.45 if dir > 0 else L * 0.55
	var step := sin(t * 16.0) * T * 0.08
	Draw.shadow(ci, Vector2(cx + 4, 8), L * 0.42, T * 0.26, 0.22)
	for ly in [-1.0, 1.0]:
		Draw.line(ci, Vector2(cx, ly * T * 0.08), Vector2(cx + step * ly, ly * T * 0.26), Color("5a5a4a"), 4, true)
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(Vector2(cx, 0) + Vector2(cos(a) * L * 0.38, sin(a) * T * 0.26) * (1.0 + 0.1 * (i % 2)))
	Draw.poly(ci, pts, b)
	var nx := cx + dir * L * 0.32
	Draw.line(ci, Vector2(nx, 0), Vector2(nx + dir * T * 0.3, 0), c(cl, "neck"), T * 0.1, true)
	Draw.ellipse(ci, Vector2(nx + dir * T * 0.08, T * 0.06), T * 0.04, T * 0.06, c(cl, "wattle"))
	Draw.ellipse(ci, Vector2(nx + dir * T * 0.34, 0), T * 0.1, T * 0.08, c(cl, "neck"))
	Draw.ellipse(ci, Vector2(nx + dir * T * 0.3, 0), T * 0.07, T * 0.05, Color("8a6a3a"))
	_dot_eye(ci, Vector2(nx + dir * T * 0.36, -T * 0.035), T * 0.025)


static func _vine(ci: CanvasItem, cl: Dictionary, L: float, T: float, t: float) -> void:
	var cx := L * 0.5
	Draw.line(ci, Vector2(cx, -T * 0.5), Vector2(cx, 0), c(cl, "body"), 5, true)
	Draw.shadow(ci, Vector2(cx + 6, T * 0.18), T * 0.3, T * 0.12, 0.25)
	for i in 7:
		var a := TAU * i / 7.0 + t * 0.5
		Draw.leaf(ci, Vector2(cx, 0), Vector2(cos(a), sin(a)), T * 0.32, T * 0.11, c(cl, "leaf").darkened(0.08 * (i % 3)))
	Draw.ellipse(ci, Vector2(cx, 0), T * 0.1, T * 0.1, c(cl, "body"))


static func _boulder(ci: CanvasItem, cl: Dictionary, L: float, T: float, roll: float) -> void:
	var cx := L * 0.5
	var r := minf(L, T) * 0.45
	Draw.shadow(ci, Vector2(cx + 5, r * 0.6), r, r * 0.4, 0.28)
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 + roll
		var rr := r * (0.88 + 0.12 * sin(i * 2.7))
		pts.append(Vector2(cx, 0) + Vector2(cos(a), sin(a)) * rr)
	Draw.poly(ci, pts, c(cl, "body"))
	Draw.ellipse(ci, Vector2(cx - r * 0.25, -r * 0.3), r * 0.35, r * 0.22, c(cl, "body").lightened(0.2), roll)
	Draw.line(ci, Vector2(cx, 0) + Vector2(cos(roll), sin(roll)) * r * 0.2, Vector2(cx, 0) + Vector2(cos(roll + 0.6), sin(roll + 0.6)) * r * 0.8, c(cl, "shade"), 3, true)
	if Draw.detail > 1 and Draw.outline == 0.0:
		Draw.line(ci, Vector2(cx, 0) + Vector2(cos(roll + 2.4), sin(roll + 2.4)) * r * 0.3, Vector2(cx, 0) + Vector2(cos(roll + 2.0), sin(roll + 2.0)) * r * 0.75, c(cl, "shade"), 2, true)
		for i in 4:
			var a2 := roll + i * 1.7
			Draw.ellipse(ci, Vector2(cx, 0) + Vector2(cos(a2), sin(a2)) * r * 0.55, r * 0.06, r * 0.05, c(cl, "body").darkened(0.18))


static func _lizard(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var cx := L * 0.5
	var sway := sin(t * 8.0) * T * 0.05
	Draw.shadow(ci, Vector2(cx + 4, 6), L * 0.45, T * 0.16, 0.2)
	Draw.polyline(ci, PackedVector2Array([Vector2(cx - dir * L * 0.15, 0), Vector2(cx - dir * L * 0.32, sway), Vector2(cx - dir * L * 0.5, -sway)]), b.darkened(0.1), T * 0.08, true)
	for lx in [-0.12, 0.12]:
		for ly in [-1.0, 1.0]:
			Draw.line(ci, Vector2(cx + lx * L, 0), Vector2(cx + lx * L + dir * T * 0.08, ly * T * 0.2 + sway * ly), b.darkened(0.2), 4, true)
	Draw.ellipse(ci, Vector2(cx, 0), L * 0.24, T * 0.13, b)
	_spot_row(ci, Vector2(cx, 0), L * 0.2, T * 0.08, c(cl, "spots"))
	Draw.ellipse(ci, Vector2(cx + dir * L * 0.3, 0), T * 0.13, T * 0.09, b.darkened(0.05))
	Draw.line(ci, Vector2(cx + dir * L * 0.4, 0), Vector2(cx + dir * L * 0.47, 0), Color("d8242a"), 2, true)
	for sy in [-1.0, 1.0]:
		_dot_eye(ci, Vector2(cx + dir * L * 0.33, sy * T * 0.05), T * 0.022)


static func _spot_row(ci: CanvasItem, c0: Vector2, rx: float, ry: float, color: Color) -> void:
	for i in 5:
		var k := (i / 4.0) * 2.0 - 1.0
		Draw.ellipse(ci, c0 + Vector2(k * rx * 0.8, (i % 2 - 0.5) * ry), ry * 0.35, ry * 0.3, color)


# ------------------------------------------------------------------ platforms

static func _log(ci: CanvasItem, cl: Dictionary, L: float, T: float) -> void:
	var b := c(cl, "body")
	Draw.shadow(ci, Vector2(L * 0.5 + 4, T * 0.22), L * 0.5, T * 0.16, 0.25)
	Draw.rrect(ci, Rect2(0, -T * 0.34, L, T * 0.66), T * 0.3, b)
	Draw.rrect(ci, Rect2(T * 0.1, -T * 0.32, L - T * 0.2, T * 0.2), T * 0.1, b.lightened(0.14))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(L * 13.0)
	var x := T * 0.3
	while x < L - T * 0.3:
		var w := rng.randf_range(T * 0.25, T * 0.6)
		Draw.line(ci, Vector2(x, rng.randf_range(-T * 0.2, T * 0.15)), Vector2(minf(L - T * 0.2, x + w), rng.randf_range(-T * 0.2, T * 0.15)), b.darkened(0.22), 3, true)
		x += w + rng.randf_range(T * 0.1, T * 0.3)
	# knots and a broken branch stub
	for i in maxi(1, int(L / T)):
		var kp := Vector2(rng.randf_range(T * 0.5, L - T * 0.5), rng.randf_range(-T * 0.15, T * 0.15))
		Draw.ellipse(ci, kp, T * 0.07, T * 0.05, b.darkened(0.4))
		if Draw.outline == 0.0:
			Draw.ellipse(ci, kp, T * 0.035, T * 0.025, c(cl, "ring").darkened(0.15))
	var sx := rng.randf_range(T * 0.6, L - T * 0.6)
	Draw.line(ci, Vector2(sx, -T * 0.28), Vector2(sx + T * 0.08, -T * 0.44), b.darkened(0.1), T * 0.1, true)
	Draw.ellipse(ci, Vector2(sx + T * 0.08, -T * 0.44), T * 0.05, T * 0.04, c(cl, "ring"))
	for i in int(L / T):
		Draw.ellipse(ci, Vector2(rng.randf_range(T * 0.4, L - T * 0.4), rng.randf_range(-T * 0.22, T * 0.1)), T * 0.12, T * 0.07, c(cl, "moss"))
	Draw.ellipse(ci, Vector2(L - T * 0.12, 0), T * 0.12, T * 0.32, c(cl, "ring"))
	Draw.ellipse_line(ci, Vector2(L - T * 0.12, 0), T * 0.07, T * 0.2, b.darkened(0.15), 2)
	if Draw.detail > 1:
		Draw.ellipse_line(ci, Vector2(L - T * 0.12, 0), T * 0.035, T * 0.1, b.darkened(0.15), 1.5)
	Draw.ellipse(ci, Vector2(T * 0.12, 0), T * 0.12, T * 0.32, c(cl, "ring").darkened(0.1))


static func _lilypad(ci: CanvasItem, cl: Dictionary, L: float, T: float, t: float) -> void:
	var r := minf(L, T) * 0.46
	var cx := L * 0.5
	var bob := sin(t * 2.0 + L) * 1.5
	Draw.ellipse(ci, Vector2(cx + 3, 5), r, r * 0.9, Color(0, 0, 0, 0.18))
	var pts := PackedVector2Array([Vector2(cx, bob)])
	for i in 21:
		var a := 0.35 + (TAU - 0.7) * i / 20.0
		pts.append(Vector2(cx, bob) + Vector2(cos(a), sin(a)) * r)
	Draw.poly(ci, pts, c(cl, "body"))
	for i in 5:
		var a2 := 0.6 + i * 1.1
		Draw.line(ci, Vector2(cx, bob), Vector2(cx, bob) + Vector2(cos(a2), sin(a2)) * r * 0.85, c(cl, "vein"), 2, true)
	if int(L * 10) % 3 == 0:
		Draw.star(ci, Vector2(cx - r * 0.3, bob - r * 0.3), r * 0.35, c(cl, "flower"), 6, 0.45)
		Draw.ellipse(ci, Vector2(cx - r * 0.3, bob - r * 0.3), r * 0.1, r * 0.1, Color("f6e05a"))


## A caiman floating low: tapering tail, armoured back (rows of keeled
## scutes, a double crest down the tail), splayed legs, a long snout with
## raised eyes (slit pupils) and nostrils at the tip.
static func _caiman_back(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var ridge := c(cl, "ridge", "#3a4a26")
	var eye := c(cl, "eye", "#e8c83a")
	var d := float(dir)
	var x0 := 0.0 if dir > 0 else L
	var ax := func(f: float) -> float: return x0 + d * f * L
	# outline from tail tip round the snout and back: half-widths along the length
	var prof := [[0.0, 0.01], [0.12, 0.05], [0.3, 0.12], [0.45, 0.24], [0.6, 0.27], [0.7, 0.24], [0.76, 0.17], [0.82, 0.15], [0.92, 0.11], [0.99, 0.07], [1.0, 0.0]]
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for pr in prof:
		var x: float = ax.call(float(pr[0]))
		top.append(Vector2(x, -float(pr[1]) * T))
		bot.append(Vector2(x, float(pr[1]) * T))
	var outline := top.duplicate()
	for i in range(bot.size() - 2, 0, -1):
		outline.append(bot[i])
	Draw.shadow(ci, Vector2(L * 0.5 + 4, T * 0.12), L * 0.5, T * 0.2, 0.2)
	# legs, splayed just under the surface
	for f in [0.42, 0.66]:
		for sy in [-1.0, 1.0]:
			var hip := Vector2(ax.call(f), sy * T * 0.2)
			var sw := sin(t * 3.0 + f * 9.0) * T * 0.03
			Draw.polyline(ci, PackedVector2Array([hip, hip + Vector2(-d * T * 0.05 + sw, sy * T * 0.14), hip + Vector2(d * T * 0.04 + sw, sy * T * 0.2)]), b.darkened(0.15), maxf(3.0, T * 0.05), true)
	Draw.poly(ci, outline, b)
	if Draw.outline > 0.0:
		return
	# lighter flanks, darker spine
	Draw.polyline(ci, PackedVector2Array([Vector2(ax.call(0.05), 0), Vector2(ax.call(0.7), 0)]), b.darkened(0.15), T * 0.14, true)
	# scutes: four rows on the body, a double crest down the tail
	for row in [-0.15, -0.055, 0.055, 0.15]:
		var n := 7
		for i in n:
			var f2 := lerpf(0.42, 0.7, float(i) / (n - 1))
			var w := T * 0.036
			var p := Vector2(ax.call(f2), float(row) * T * (0.85 if absf(row) > 0.1 else 1.0))
			Draw.rrect(ci, Rect2(p.x - w, p.y - w * 0.7, w * 2.0, w * 1.4), w * 0.4, ridge.darkened(0.08 * (i % 2)))
			Draw.line(ci, p - Vector2(w * 0.6, 0), p + Vector2(w * 0.6, 0), ridge.darkened(0.35), 1.5, true)
	for i in 9:
		var f3 := lerpf(0.06, 0.4, i / 8.0)
		var off := lerpf(0.012, 0.05, i / 8.0) * T
		for sy2 in [-1.0, 1.0]:
			Draw.ellipse(ci, Vector2(ax.call(f3), sy2 * off), T * 0.03, T * 0.018, ridge.darkened(0.15))
	# head: eye bumps, eyes with slit pupils, nostrils
	for sy3 in [-1.0, 1.0]:
		var ep := Vector2(ax.call(0.8), sy3 * T * 0.09)
		Draw.ellipse(ci, ep, T * 0.06, T * 0.05, b.darkened(0.1))
		Draw.ellipse(ci, ep + Vector2(d * T * 0.01, 0), T * 0.04, T * 0.034, eye)
		Draw.ellipse(ci, ep + Vector2(d * T * 0.015, 0), T * 0.008, T * 0.028, Color("111111"))
		Draw.ellipse(ci, ep + Vector2(0, -T * 0.012), T * 0.012, T * 0.01, Color(1, 1, 1, 0.7))
		Draw.ellipse(ci, Vector2(ax.call(0.97), sy3 * T * 0.025), T * 0.016, T * 0.013, b.darkened(0.35))
	Draw.ellipse(ci, Vector2(ax.call(0.97), 0), T * 0.05, T * 0.04, b.darkened(0.08))
	var _tt := t


static func _branch(ci: CanvasItem, cl: Dictionary, L: float, T: float) -> void:
	var b := c(cl, "body")
	Draw.shadow(ci, Vector2(L * 0.5 + 4, T * 0.2), L * 0.5, T * 0.15, 0.2)
	Draw.rrect(ci, Rect2(0, -T * 0.16, L, T * 0.32), T * 0.15, b)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(L * 31.0)
	for i in int(L / (T * 0.4)) + 1:
		var x := rng.randf_range(T * 0.2, L - T * 0.2)
		var sy := -1.0 if i % 2 == 0 else 1.0
		var tip := Vector2(x + rng.randf_range(-T * 0.2, T * 0.2), sy * T * 0.38)
		Draw.line(ci, Vector2(x, 0), tip, b.darkened(0.1), 4, true)
		Draw.leaf(ci, tip, Vector2(rng.randf_range(-1, 1), sy), T * 0.2, T * 0.08, c(cl, "leaf"))
	Draw.rrect(ci, Rect2(T * 0.1, -T * 0.14, L - T * 0.2, T * 0.08), T * 0.04, b.lightened(0.15))


static func _boat(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body")
	var hull := PackedVector2Array([Vector2(0, 0), Vector2(T * 0.4, -T * 0.34), Vector2(L - T * 0.4, -T * 0.34), Vector2(L, 0), Vector2(L - T * 0.4, T * 0.34), Vector2(T * 0.4, T * 0.34)])
	var wake := Vector2(0 if dir > 0 else L, 0)
	for i in 3:
		Draw.ellipse_line(ci, wake - Vector2(dir * (8 + i * 10), 0), T * 0.1 + i * 4, T * 0.25 + i * 3, Color(1, 1, 1, 0.25 - i * 0.07), 2)
	var sh := hull.duplicate()
	for i in sh.size():
		sh[i] += Vector2(4, 8)
	Draw.poly(ci, sh, Color(0, 0, 0, 0.22))
	Draw.poly(ci, hull, b.darkened(0.2))
	var inner := PackedVector2Array()
	for p in hull:
		inner.append(Vector2(L * 0.5, 0) + (p - Vector2(L * 0.5, 0)) * Vector2(0.92, 0.78))
	Draw.poly(ci, inner, b)
	for i in int(L / (T * 0.35)):
		var x := T * 0.4 + i * T * 0.35
		Draw.line(ci, Vector2(x, -T * 0.25), Vector2(x, T * 0.25), b.darkened(0.15), 2)
	var trim := hull.duplicate()
	trim.append(hull[0])
	Draw.polyline(ci, trim, c(cl, "trim"), 4, true)
	Draw.rrect(ci, Rect2(L * 0.35, -T * 0.22, L * 0.3, T * 0.44), 8, c(cl, "canopy"))
	var _tt := t


static func _bridge(ci: CanvasItem, cl: Dictionary, L: float, T: float, t: float) -> void:
	var plank := c(cl, "plank")
	Draw.shadow(ci, Vector2(L * 0.5, T * 0.38), L * 0.5, T * 0.1, 0.25)
	var n := maxi(1, int(L / (T * 0.22)))
	for i in n:
		var x := i * L / n
		var sag := sin(float(i) / n * PI) * 2.0
		Draw.rrect(ci, Rect2(x + 1, -T * 0.32 + sag, L / n - 3, T * 0.64), 3, plank.lightened(0.06 * (i % 3)))
	for sy in [-1.0, 1.0]:
		Draw.line(ci, Vector2(0, sy * T * 0.34), Vector2(L, sy * T * 0.34), c(cl, "rope"), 4, true)
		for i in range(0, n + 1, 3):
			Draw.ellipse(ci, Vector2(i * L / n, sy * T * 0.34), 4, 4, c(cl, "body"))
	var _tt := t


static func _stone(ci: CanvasItem, cl: Dictionary, L: float, T: float) -> void:
	var cx := L * 0.5
	var r := minf(L, T) * 0.42
	Draw.shadow(ci, Vector2(cx + 4, r * 0.5), r, r * 0.45, 0.25)
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cx, 0) + Vector2(cos(a) * r * (0.95 + 0.08 * sin(i * 1.7)), sin(a) * r * 0.85))
	Draw.poly(ci, pts, c(cl, "body"))
	Draw.ellipse(ci, Vector2(cx - r * 0.2, -r * 0.25), r * 0.5, r * 0.3, c(cl, "body").lightened(0.15))
	Draw.ellipse(ci, Vector2(cx + r * 0.25, -r * 0.1), r * 0.35, r * 0.22, c(cl, "moss"))


# ------------------------------------------------------------------ predators

static func draw_pred(ci: CanvasItem, hz: Dictionary, p: Dictionary, T: float, state: String, prog: float, t: float, reveal: float) -> void:
	if Draw.detail > 0 and Draw.outline == 0.0:
		Draw.begin_outline(maxf(1.2, T * 0.028))
		draw_pred(ci, hz, p, T, state, prog, t, reveal)
		Draw.end_outline()
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	match String(p.kind):
		"surfacer":
			_croc(ci, cl, float(p.span) * T, T, state, prog, t)
		"striker":
			if String(hz.get("art", {}).get("painter", "")) == "tiger":
				_tiger(ci, cl, p, T, state, prog, t, reveal)
			else:
				_snake(ci, cl, p, T, state, prog, t)
		"faller":
			_faller(ci, hz, cl, T, state, prog, t)


static func _croc(ci: CanvasItem, cl: Dictionary, span: float, T: float, state: String, prog: float, t: float) -> void:
	match state:
		"warn":
			for i in 3:
				var k := fposmod(prog + i / 3.0, 1.0)
				Draw.ellipse_line(ci, Vector2.ZERO, span * 0.25 + k * span * 0.35, T * 0.12 + k * T * 0.2, Color(1, 1, 1, 0.55 * (1.0 - k)), 3)
			Draw.ellipse(ci, Vector2(-span * 0.15, 0), 5, 4, Color(1, 1, 1, 0.5))
			Draw.ellipse(ci, Vector2(span * 0.12, -4), 4, 3, Color(1, 1, 1, 0.5))
		"active":
			var open := sin(minf(1.0, prog * 2.5) * PI) * 0.5 + 0.2
			var b := c(cl, "body")
			Draw.ellipse(ci, Vector2(0, 0), span * 0.55, T * 0.32, Color(1, 1, 1, 0.25))
			var jaw := T * 0.08 + open * T * 0.22
			Draw.poly(ci, PackedVector2Array([Vector2(-span * 0.5, -jaw), Vector2(span * 0.45, -T * 0.06), Vector2(span * 0.45, T * 0.06), Vector2(-span * 0.5, jaw)]), Color("8a2a2a"))
			Draw.poly(ci, PackedVector2Array([Vector2(-span * 0.5, -jaw - T * 0.08), Vector2(span * 0.5, -T * 0.12), Vector2(span * 0.5, -T * 0.02), Vector2(-span * 0.5, -jaw)]), b)
			Draw.poly(ci, PackedVector2Array([Vector2(-span * 0.5, jaw), Vector2(span * 0.5, T * 0.02), Vector2(span * 0.5, T * 0.12), Vector2(-span * 0.5, jaw + T * 0.08)]), b.darkened(0.1))
			# pink mouth, teeth on both jaws
			Draw.poly(ci, PackedVector2Array([Vector2(-span * 0.42, -jaw * 0.7), Vector2(span * 0.38, -T * 0.04), Vector2(span * 0.38, T * 0.04), Vector2(-span * 0.42, jaw * 0.7)]), Color("c86a6a"))
			for i in 7:
				var x := -span * 0.42 + i * span * 0.13
				var f := float(i) / 6.0
				var ty := lerpf(jaw, T * 0.07, f)
				Draw.poly(ci, PackedVector2Array([Vector2(x, -ty), Vector2(x + 6, -ty), Vector2(x + 3, -ty + 9)]), Color("f2ecd8"))
				Draw.poly(ci, PackedVector2Array([Vector2(x + 4, ty), Vector2(x + 10, ty), Vector2(x + 7, ty - 9)]), Color("f2ecd8"))
			# scutes on the head, raised eyes with slit pupils, nostrils at the tip
			if Draw.outline == 0.0:
				for i in 4:
					Draw.rrect(ci, Rect2(-span * 0.45 + i * span * 0.07, -jaw - T * 0.075, span * 0.05, T * 0.035), 3, b.darkened(0.25))
			for ey in [-1.0, 1.0]:
				var ep := Vector2(-span * 0.25, -jaw - T * 0.06 + ey * T * 0.02)
				Draw.ellipse(ci, ep, 9, 8, b.darkened(0.15))
				Draw.ellipse(ci, ep, 6.5, 6, c(cl, "eye"))
				Draw.ellipse(ci, ep, 1.8, 5, Color.BLACK)
			Draw.ellipse(ci, Vector2(span * 0.47, -T * 0.09), 4, 3, b.darkened(0.35))
			Draw.ellipse(ci, Vector2(span * 0.47, -T * 0.05), 4, 3, b.darkened(0.35))
		_:
			var b2 := sin(t * 3.0) * 0.5 + 0.5
			Draw.ellipse(ci, Vector2(0, 0), 4 + b2 * 2, 3, Color(1, 1, 1, 0.18))


static func _snake(ci: CanvasItem, cl: Dictionary, p: Dictionary, T: float, state: String, prog: float, t: float) -> void:
	var b := c(cl, "body")
	var pat := c(cl, "pattern")
	var dir := int(p.dir)
	var center := Vector2(T * 0.5, 0)
	Draw.shadow(ci, center + Vector2(4, 8), T * 0.36, T * 0.16, 0.2)
	for i in 2:
		var pts := Draw.ellipse_points(center + Vector2(0, -i * 6), T * (0.3 - i * 0.08), T * (0.16 - i * 0.04), 0.0, 20)
		pts.append(pts[0])
		Draw.polyline(ci, pts, b.darkened(0.1), T * 0.1, true)
		Draw.polyline(ci, pts, b, T * 0.075, true)
	var head := center + Vector2(dir * T * 0.18, -T * 0.16)
	if state == "warn":
		head += Vector2(sin(t * 40.0) * 3.0, -prog * T * 0.12)
	elif state == "active":
		var ext := sin(minf(1.0, prog) * PI) * float(p.span) * T
		var neck := PackedVector2Array()
		for i in 10:
			var k := i / 9.0
			neck.append(center + Vector2(dir * (T * 0.1 + k * ext), sin(k * 9.0) * T * 0.08 * (1.0 - k) - T * 0.05))
		Draw.polyline(ci, neck, b, T * 0.11, true)
		for i in range(1, 9, 2):
			Draw.ellipse(ci, neck[i], T * 0.035, T * 0.03, pat)
		head = neck[-1]
	Draw.ellipse(ci, head, T * 0.13, T * 0.1, b.darkened(0.05))
	Draw.ellipse(ci, head + Vector2(dir * T * 0.04, -T * 0.04), 3.5, 3.5, c(cl, "eye"))
	if state == "active":
		Draw.line(ci, head + Vector2(dir * T * 0.12, 0), head + Vector2(dir * T * 0.22, 0), Color("d8242a"), 2, true)
	if state == "warn":
		_hazard_marker(ci, center + Vector2(0, -T * 0.42), T * 0.13)


static func _tiger(ci: CanvasItem, cl: Dictionary, p: Dictionary, T: float, state: String, prog: float, t: float, reveal: float) -> void:
	var dir := int(p.dir)
	var center := Vector2(T * 0.5, 0)
	var rustle := 0.0
	if state == "warn":
		rustle = sin(t * 30.0) * 4.0 * prog
	for i in 7:
		var bx := center.x + (i - 3) * T * 0.11
		Draw.leaf(ci, Vector2(bx, T * 0.3), Vector2(sin(i * 1.3) * 0.4 + rustle * 0.05, -1), T * (0.6 + 0.12 * (i % 2)), T * 0.07, Color("8a9a4a").darkened(0.1 * (i % 3)))
	if reveal > 0.0 or state == "warn":
		var a := clampf(reveal + (prog if state == "warn" else 0.0), 0.0, 1.0)
		for sx in [-1.0, 1.0]:
			Draw.ellipse(ci, center + Vector2(sx * T * 0.08, -T * 0.05), 4, 3, Color(1.0, 0.85, 0.2, a))
	if state == "active":
		var ext := sin(minf(1.0, prog) * PI) * float(p.span) * T
		var tc := center + Vector2(dir * ext, 0)
		Draw.ellipse(ci, tc - Vector2(dir * T * 0.3, 0), T * 0.45, T * 0.24, c(cl, "body"))
		for i in 4:
			Draw.line(ci, tc + Vector2(-dir * T * (0.6 - i * 0.14), -T * 0.2), tc + Vector2(-dir * T * (0.55 - i * 0.14), T * 0.2), c(cl, "stripe"), 4, true)
		Draw.ellipse(ci, tc + Vector2(dir * T * 0.1, 0), T * 0.2, T * 0.19, c(cl, "body"))
		Draw.ellipse(ci, tc + Vector2(dir * T * 0.22, T * 0.02), T * 0.09, T * 0.08, Color("fbf2e2"))


static func _faller(ci: CanvasItem, hz: Dictionary, cl: Dictionary, T: float, state: String, prog: float, t: float) -> void:
	var center := Vector2(T * 0.5, 0)
	var fruit := String(hz.get("art", {}).get("painter", "")) == "fruit_fall"
	match state:
		"warn":
			Draw.ellipse(ci, center, T * (0.15 + prog * 0.3), T * (0.08 + prog * 0.16), Color(0, 0, 0, 0.15 + prog * 0.3))
			for i in 2:
				var y := -T * 0.5 + fposmod(t * 90.0 + i * 37.0, T * 0.6)
				Draw.leaf(ci, center + Vector2((i - 0.5) * T * 0.3, y), Vector2(sin(t * 4.0 + i), 1), T * 0.12, T * 0.05, c(cl, "leaf", "#4a9a3a"))
		"active":
			var drop := (1.0 - minf(1.0, prog * 3.0)) * T * 0.6
			if fruit:
				Draw.ellipse(ci, center - Vector2(0, drop), T * 0.22, T * 0.22, c(cl, "body"))
				for i in 8:
					var a := TAU * i / 8.0
					Draw.line(ci, center - Vector2(0, drop) + Vector2(cos(a), sin(a)) * T * 0.18, center - Vector2(0, drop) + Vector2(cos(a), sin(a)) * T * 0.28, c(cl, "spike"), 3)
			else:
				Draw.line(ci, center - Vector2(T * 0.42, drop + 6), center + Vector2(T * 0.42, -drop + 4), c(cl, "body"), T * 0.13, true)
				Draw.leaf(ci, center + Vector2(T * 0.3, -drop), Vector2(1, -1), T * 0.25, T * 0.1, c(cl, "leaf"))
				Draw.leaf(ci, center + Vector2(-T * 0.25, -drop), Vector2(-1, -0.5), T * 0.22, T * 0.09, c(cl, "leaf"))
			if prog > 0.3:
				Draw.ellipse_line(ci, center + Vector2(0, T * 0.1), T * 0.3 * prog, T * 0.12 * prog, Color(0.9, 0.8, 0.6, 1.0 - prog), 3)
		"idle":
			if prog < 0.25:
				var a2 := 1.0 - prog * 4.0
				Draw.line(ci, center - Vector2(T * 0.35, -6), center + Vector2(T * 0.35, 10), Color(c(cl, "body"), a2), T * 0.1, true)


# ------------------------------------------------------------------ tiles

static func draw_tile(ci: CanvasItem, hz: Dictionary, T: float, t: float, salt: int) -> void:
	if String(hz.get("art", {}).get("painter", "")) == "falls":
		_falls(ci, hz.get("art", {}).get("colors", {}), T, t, salt)
		return
	if Draw.detail > 0 and Draw.outline == 0.0:
		Draw.begin_outline(maxf(1.0, T * 0.022))
		draw_tile(ci, hz, T, t, salt)
		Draw.end_outline()
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	var center := Vector2(T * 0.5, 0)
	match String(hz.get("art", {}).get("painter", "")):
		"quicksand":
			Draw.ellipse(ci, center, T * 0.44, T * 0.38, c(cl, "body"))
			var pts := PackedVector2Array()
			for i in 30:
				var k := i / 29.0
				var a := k * 9.0 + t * 1.5
				pts.append(center + Vector2(cos(a), sin(a) * 0.85) * T * 0.36 * (1.0 - k))
			Draw.polyline(ci, pts, c(cl, "swirl"), 3, true)
		"gully":
			var rng := RandomNumberGenerator.new()
			rng.seed = salt
			var poly := PackedVector2Array()
			for i in 10:
				var a2 := TAU * i / 10.0
				poly.append(center + Vector2(cos(a2) * T * rng.randf_range(0.42, 0.52), sin(a2) * T * rng.randf_range(0.38, 0.5)))
			Draw.poly(ci, poly, c(cl, "edge"))
			var inner := PackedVector2Array()
			for p in poly:
				inner.append(center + (p - center) * 0.82)
			Draw.poly(ci, inner, c(cl, "body"))
			Draw.ellipse(ci, center + Vector2(0, T * 0.06), T * 0.25, T * 0.18, c(cl, "body").darkened(0.4))
		"boulders":
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = salt * 7 + 3
			Draw.shadow(ci, center + Vector2(4, T * 0.16), T * 0.46, T * 0.22, 0.28)
			for i in 3:
				var bp := center + Vector2((i - 1) * T * 0.24 + rng2.randf_range(-3, 3), (1 - i % 2) * T * 0.1 - T * 0.04)
				var r := T * (0.24 if i == 1 else 0.19) * rng2.randf_range(0.9, 1.1)
				Draw.shaded(ci, bp, r, r * 0.82, c(cl, "body"))
				Draw.ellipse(ci, bp + Vector2(-r * 0.15, -r * 0.42), r * 0.62, r * 0.3, c(cl, "moss"))
				if Draw.detail > 1:
					Draw.line(ci, bp + Vector2(r * 0.2, -r * 0.1), bp + Vector2(r * 0.5, r * 0.3), c(cl, "dark"), 1.5, true)
		"roots":
			for i in 5:
				var a3 := i * 1.3 + salt
				var pts2 := PackedVector2Array()
				for k in 6:
					pts2.append(center + Vector2(cos(a3) * T * 0.4 * (k / 5.0 - 0.5) * 2.0, sin(k * 1.4 + a3) * T * 0.25))
				Draw.polyline(ci, pts2, c(cl, "body").darkened(0.08 * (i % 3)), 7, true)
			for i in 3:
				Draw.leaf(ci, center + Vector2((i - 1) * T * 0.25, -T * 0.15), Vector2(i - 1, -1), T * 0.22, T * 0.08, c(cl, "leaf"))
		"bush":
			Draw.shadow(ci, center + Vector2(4, 10), T * 0.45, T * 0.25, 0.25)
			for i in 6:
				var a4 := TAU * i / 6.0 + salt
				Draw.ellipse(ci, center + Vector2(cos(a4) * T * 0.2, sin(a4) * T * 0.15 - T * 0.05), T * 0.22, T * 0.2, c(cl, "body").lightened(0.05 * (i % 3)))
			Draw.ellipse(ci, center + Vector2(0, -T * 0.1), T * 0.2, T * 0.18, c(cl, "leaf"))


# ------------------------------------------------------------------ lane effects

## A tile of a waterfall ledge: the river pouring over the lip (streaks
## running down), foam and spray where it lands, the pool below.
static func _falls(ci: CanvasItem, cl: Dictionary, T: float, t: float, salt: int) -> void:
	var water := c(cl, "water", "#cdeeff")
	var pool := c(cl, "pool", "#2a6a8a")
	Draw.rect(ci, Rect2(0, -T * 0.5, T, T), pool.lightened(0.18))
	Draw.rect(ci, Rect2(0, -T * 0.5, T, T * 0.55), water.darkened(0.12))
	Draw.rect(ci, Rect2(0, -T * 0.5, T, T * 0.1), water.lightened(0.3))
	var n := 6 if Draw.detail > 0 else 3
	for i in n:
		var x := (i + 0.5) * T / n + sin(float(i * 7 + salt)) * T * 0.04
		var y := fposmod(t * T * 1.4 + float(i * 37 + salt * 13) * 0.61, T * 0.8) - T * 0.45
		Draw.line(ci, Vector2(x, y), Vector2(x, minf(y + T * 0.28, T * 0.32)), Color(1, 1, 1, 0.75), 3.0 if Draw.detail > 0 else 2.0, true)
	for i in 4:
		var fx := (i + 0.5) * T / 4.0
		Draw.ellipse(ci, Vector2(fx, T * 0.32 + sin(t * 5.0 + i + salt) * 2.0), T * 0.15, T * 0.07, Color(c(cl, "foam", "#ffffff"), 0.9))
	Draw.ellipse(ci, Vector2(T * 0.5, T * 0.22), T * 0.55, T * 0.16, Color(1, 1, 1, 0.14 + 0.06 * sin(t * 2.0 + salt)))


## A land crab scuttling sideways: wide shell, two raised claws, eight legs.
static func _crab(ci: CanvasItem, cl: Dictionary, L: float, T: float, dir: int, t: float) -> void:
	var b := c(cl, "body", "#c8402a")
	var claw := c(cl, "claw", "#e86a3a")
	var leg := c(cl, "legs", "#8a2a1a")
	var cx := L * 0.5
	var sc := sin(t * 18.0 + L * 3.0)
	Draw.shadow(ci, Vector2(cx + 3, 6), L * 0.42, T * 0.2, 0.22)
	for side in [-1.0, 1.0]:
		for k in 4:
			var lx := cx + (k - 1.5) * L * 0.16
			var lift := sc * (1 if k % 2 == 0 else -1) * 2.0
			var knee := Vector2(lx + side * 0.0, side * T * 0.2)
			Draw.line(ci, Vector2(lx, side * T * 0.08), knee + Vector2(lift, 0), leg, 3, true)
			Draw.line(ci, knee + Vector2(lift, 0), knee + Vector2(lift + (k - 1.5) * 3.0, side * T * 0.08), leg, 2.5, true)
	Draw.shaded(ci, Vector2(cx, 0), L * 0.36, T * 0.17, b)
	if Draw.detail > 0:
		Draw.ellipse(ci, Vector2(cx - L * 0.06, -T * 0.05), L * 0.18, T * 0.05, b.lightened(0.25))
	var front := cx + dir * L * 0.32
	for side in [-1.0, 1.0]:
		var cp := Vector2(front + dir * T * 0.08, side * T * 0.12)
		Draw.line(ci, Vector2(front, side * T * 0.06), cp, claw.darkened(0.2), 3.5, true)
		Draw.ellipse(ci, cp + Vector2(dir * T * 0.06, 0), T * 0.09, T * 0.06, claw)
		Draw.line(ci, cp + Vector2(dir * T * 0.1, -side * 1.0), cp + Vector2(dir * T * 0.16, side * (2.0 + sc * 2.0)), claw.darkened(0.3), 2, true)
		_dot_eye(ci, Vector2(front - dir * T * 0.02, side * T * 0.05), T * 0.025)


## Harmless wildlife on the banks: coquí frogs, hermit crabs, butterflies,
## perched birds, lizards and beetles. Purely for looks; kind/colour come
## from the map's "trail_critters".
static func draw_critter(ci: CanvasItem, kind: String, col: Color, T: float, t: float, salt: int) -> void:
	var ph := float(salt % 97) * 0.37
	match kind:
		"frog":
			var hop := maxf(0.0, sin(t * 1.3 + ph)) ** 6
			var p := Vector2(sin(t * 0.21 + ph) * T * 0.08, -hop * T * 0.12)
			Draw.shadow(ci, Vector2(0, T * 0.05), T * 0.08, T * 0.03, 0.2)
			for s in [-1.0, 1.0]:
				Draw.ellipse(ci, p + Vector2(s * T * 0.06, T * 0.03), T * 0.04, T * 0.025, col.darkened(0.2))
			Draw.ellipse(ci, p, T * 0.075, T * 0.06, col)
			for s in [-1.0, 1.0]:
				Draw.ellipse(ci, p + Vector2(s * T * 0.035, -T * 0.05), T * 0.022, T * 0.022, Color(0.1, 0.08, 0.05))
		"crab":
			var sx := sin(t * 0.9 + ph) * T * 0.18
			var p2 := Vector2(sx, 0)
			for s in [-1.0, 1.0]:
				for k in 3:
					Draw.line(ci, p2 + Vector2((k - 1) * 3.0, 0), p2 + Vector2((k - 1) * 5.0, s * T * 0.07), col.darkened(0.3), 1.5, true)
			Draw.ellipse(ci, p2, T * 0.07, T * 0.05, col)
			Draw.ellipse(ci, p2 + Vector2(-T * 0.06, -T * 0.06), T * 0.03, T * 0.025, col.lightened(0.15))
			Draw.ellipse(ci, p2 + Vector2(T * 0.06, -T * 0.06), T * 0.03, T * 0.025, col.lightened(0.15))
			if col.r < 0.7:
				Draw.ellipse(ci, p2 + Vector2(0, -T * 0.02), T * 0.055, T * 0.05, Color("d8c8a0"))   # a hermit crab's shell
		"butterfly":
			var c0 := Vector2(sin(t * 0.7 + ph) * T * 0.3, cos(t * 0.9 + ph * 1.3) * T * 0.18 - T * 0.15)
			var flap := absf(sin(t * 12.0 + ph))
			for s in [-1.0, 1.0]:
				Draw.ellipse(ci, c0 + Vector2(s * T * 0.05 * (0.3 + flap), -T * 0.01), T * 0.05 * (0.3 + flap), T * 0.045, col)
				Draw.ellipse(ci, c0 + Vector2(s * T * 0.035 * (0.3 + flap), T * 0.035), T * 0.03 * (0.3 + flap), T * 0.03, col.darkened(0.25))
			Draw.line(ci, c0 + Vector2(0, -T * 0.04), c0 + Vector2(0, T * 0.05), Color(0.1, 0.08, 0.06), 2, true)
		"bird":
			var bob := sin(t * 3.0 + ph) * 1.5
			var flap2 := sin(t * 0.5 + ph) > 0.92
			Draw.shadow(ci, Vector2(0, T * 0.08), T * 0.08, T * 0.03, 0.2)
			if flap2:
				for s in [-1.0, 1.0]:
					Draw.ellipse(ci, Vector2(s * T * 0.1, -T * 0.03), T * 0.09, T * 0.03, col.darkened(0.15), s * 0.3)
			Draw.ellipse(ci, Vector2(0, bob), T * 0.06, T * 0.09, col)
			Draw.ellipse(ci, Vector2(0, -T * 0.08 + bob), T * 0.045, T * 0.045, col.lightened(0.1))
			Draw.ellipse(ci, Vector2(T * 0.04, -T * 0.08 + bob), T * 0.025, T * 0.015, Color("f0c040"))
			Draw.ellipse(ci, Vector2(0, T * 0.1 + bob), T * 0.03, T * 0.05, col.darkened(0.3))
		"lizard":
			var dart := fposmod(t * 0.4 + ph, 1.0)
			var lx := (T * 0.2 if dart > 0.5 else -T * 0.2) * smoothstep(0.0, 0.08, absf(dart - 0.5) - 0.0)
			var p3 := Vector2(lx, 0)
			Draw.line(ci, p3 + Vector2(-T * 0.08, 0), p3 + Vector2(-T * 0.2, sin(t * 4.0 + ph) * 3.0), col.darkened(0.2), 2.5, true)
			Draw.ellipse(ci, p3, T * 0.09, T * 0.03, col)
			Draw.ellipse(ci, p3 + Vector2(T * 0.09, 0), T * 0.035, T * 0.025, col.lightened(0.1))
			for s in [-1.0, 1.0]:
				Draw.line(ci, p3 + Vector2(T * 0.03, 0), p3 + Vector2(T * 0.05, s * T * 0.05), col.darkened(0.3), 1.5, true)
				Draw.line(ci, p3 + Vector2(-T * 0.04, 0), p3 + Vector2(-T * 0.06, s * T * 0.05), col.darkened(0.3), 1.5, true)
		_:
			var p4 := Vector2(fposmod(t * T * 0.05 + ph * 10.0, T * 0.6) - T * 0.3, 0)
			Draw.ellipse(ci, p4, T * 0.04, T * 0.03, col)
			Draw.ellipse(ci, p4 + Vector2(-T * 0.01, -T * 0.01), T * 0.015, T * 0.01, col.lightened(0.5))


static func draw_effect(ci: CanvasItem, hz: Dictionary, width: float, T: float, state: String, prog: float, t: float) -> void:
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	match String(hz.get("art", {}).get("painter", "")):
		"fire":
			if state == "warn":
				Draw.rect(ci, Rect2(0, -T * 0.5, width, T), Color(0.9, 0.3, 0.05, 0.12 + prog * 0.2))
				for i in int(width / (T * 0.7)):
					var x := i * T * 0.7 + T * 0.35
					Draw.ellipse(ci, Vector2(x, -prog * T * 0.4 - fposmod(t * 30.0 + i * 13.0, 20.0)), T * 0.18, T * 0.14, Color(c(cl, "smoke"), 0.35 * prog))
			elif state == "active":
				Draw.rect(ci, Rect2(0, -T * 0.5, width, T), Color(0.25, 0.08, 0.02, 0.45))
				for i in int(width / (T * 0.33)):
					var x2 := i * T * 0.33 + T * 0.16
					var h := T * (0.45 + 0.2 * sin(t * 18.0 + i * 1.7))
					Draw.poly(ci, PackedVector2Array([Vector2(x2 - T * 0.16, T * 0.3), Vector2(x2, T * 0.3 - h), Vector2(x2 + T * 0.16, T * 0.3)]), c(cl, "body"))
					Draw.poly(ci, PackedVector2Array([Vector2(x2 - T * 0.08, T * 0.3), Vector2(x2, T * 0.3 - h * 0.55), Vector2(x2 + T * 0.08, T * 0.3)]), c(cl, "core"))
		"tide":
			var water := c(cl, "body")
			if state == "warn":
				var w2 := width * 0.5 * prog
				Draw.rect(ci, Rect2(0, -T * 0.5, w2, T), Color(water, 0.75))
				Draw.rect(ci, Rect2(width - w2, -T * 0.5, w2, T), Color(water, 0.75))
			elif state == "active":
				Draw.rect(ci, Rect2(0, -T * 0.5, width, T), Color(water, 0.88))
				for i in int(width / (T * 0.8)):
					var x3 := fposmod(i * T * 0.8 + t * 30.0, width)
					Draw.line(ci, Vector2(x3, -T * 0.15 + (i % 3) * 10), Vector2(x3 + T * 0.3, -T * 0.15 + (i % 3) * 10), Color(1, 1, 1, 0.35), 3, true)
		"mud":
			if state == "warn":
				for i in int(width / (T * 0.6)):
					var x4 := i * T * 0.6 + sin(t * 25.0 + i) * 3.0
					Draw.line(ci, Vector2(x4, -T * 0.3), Vector2(x4 + T * 0.2, T * 0.1), Color(c(cl, "body"), 0.5 * prog), 4, true)
			elif state == "active":
				Draw.rect(ci, Rect2(0, -T * 0.5, width, T), Color(c(cl, "body"), 0.55))
				for i in int(width / (T * 0.4)):
					var x5 := i * T * 0.4
					var y := -T * 0.5 + prog * T
					Draw.line(ci, Vector2(x5, y - T * 0.4), Vector2(x5 + 4, y), c(cl, "body").darkened(0.2), 6, true)


# ------------------------------------------------------------------ items

static func draw_item(ci: CanvasItem, def: Dictionary, T: float, t: float, ghost := false) -> void:
	if Draw.detail > 0 and Draw.outline == 0.0 and not ghost:
		Draw.begin_outline(maxf(1.2, T * 0.025))
		draw_item(ci, def, T, t, ghost)
		Draw.end_outline()
	var cl: Dictionary = def.get("art", {}).get("colors", {})
	var bob := sin(t * 3.0) * 4.0
	var p := Vector2(0, -T * 0.12 + bob)
	Draw.shadow(ci, Vector2(0, T * 0.12), T * 0.16, T * 0.06, 0.25)
	var a := 0.55 if ghost else 1.0
	match String(def.get("art", {}).get("painter", "")):
		"berry":
			ci.draw_set_transform(p, 0, Vector2.ONE * 0.9)
			Draw.berry_icon(ci, Vector2.ZERO, T * 0.2)
			ci.draw_set_transform(Vector2.ZERO)
		"beetle":
			Draw.ellipse(ci, p, T * 0.16, T * 0.2, Color(c(cl, "body"), a))
			Draw.line(ci, p + Vector2(0, -T * 0.18), p + Vector2(0, T * 0.18), Color(0, 0, 0, 0.4 * a), 2)
			Draw.ellipse(ci, p + Vector2(-T * 0.05, -T * 0.07), T * 0.05, T * 0.07, Color(c(cl, "shine"), 0.8 * a))
			Draw.ellipse(ci, p + Vector2(0, -T * 0.22), T * 0.07, T * 0.05, Color(0.1, 0.1, 0.1, a))
		"fruit":
			Draw.ellipse(ci, p, T * 0.2, T * 0.22, Color(c(cl, "body"), a))
			Draw.ellipse(ci, p + Vector2(-T * 0.06, -T * 0.08), T * 0.06, T * 0.05, Color(1, 1, 1, 0.7 * a))
			Draw.leaf(ci, p + Vector2(0, -T * 0.2), Vector2(1, -1), T * 0.15, T * 0.06, c(cl, "leaf"))
			Draw.star(ci, p + Vector2(T * 0.18, -T * 0.2), T * 0.06 + sin(t * 6.0) * 2.0, Color(1, 1, 0.8, 0.9 * a), 4, 0.35)
		"amber":
			Draw.amber_icon(ci, p, T * 0.2)
			Draw.star(ci, p + Vector2(T * 0.16, -T * 0.18), T * 0.06 + sin(t * 6.0) * 2.0, Color(1, 1, 0.8, 0.9), 4, 0.35)
		"truffle":
			Draw.ellipse(ci, p, T * 0.17, T * 0.14, Color(c(cl, "body"), a))
			_spot_row(ci, p, T * 0.12, T * 0.08, Color(c(cl, "shine"), 0.6 * a))
			Draw.star(ci, p + Vector2(T * 0.16, -T * 0.16), T * 0.07, Color(1, 0.95, 0.6, a), 4, 0.35)
