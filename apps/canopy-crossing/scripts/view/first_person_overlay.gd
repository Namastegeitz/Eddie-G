class_name FirstPersonOverlay
extends Control
## Screen-space touches for the first-person view: your own paws (or beak)
## at the bottom of the screen, bobbing as you hop, and red arrows at the
## screen edges for traffic coming at you from outside the field of view.

var sim: RunSim
var animal: Dictionary = {}
var t := 0.0
var font: Font


func setup(run: RunSim, animal_def: Dictionary) -> void:
	sim = run
	animal = animal_def
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UI.font(true)


func _process(dt: float) -> void:
	if is_visible_in_tree():
		t += dt
		queue_redraw()


## Movers in the next lanes that are outside the view and heading for you:
## [[side (-1/+1), lane offset, closeness 0..1], ...]
func incoming() -> Array:
	var out := []
	for k in 3:
		var l := sim.world.lane(sim.row + k)
		if l.type == "water":
			continue
		var half := 0.93 * (k + 0.8)
		for e in l.ents:
			if e.platform or not e.active(sim.wt):
				continue
			var cx := sim.world.ent_x(l, e, sim.wt) + e.length * 0.5
			var dx := cx - sim.x
			var gap := absf(dx) - e.length * 0.5
			var v := e.velocity(l.speed, sim.wt)
			var approaching := signf(v) != signf(dx) and v != 0.0
			if approaching and absf(dx) > half and gap < 4.5:
				out.append([1 if dx > 0 else -1, k, clampf(1.0 - gap / 4.5, 0.0, 1.0)])
	return out


func _draw() -> void:
	if sim == null:
		return
	var s := size
	var look: Dictionary = animal.get("look", {})
	var cols: Dictionary = look.get("colors", {})
	var prim := Color(String(cols.get("primary", "#888888")))
	var dark := prim.darkened(0.35)
	var hop := sim.hop_t if sim.hopping else 0.0
	var bob := sin(hop * PI) * 26.0 + sin(t * 2.2) * 3.0
	match String(look.get("base", "mammal")):
		"bird":
			var bc := Color(String(cols.get("accent", "#e8a020")))
			var y := s.y + 30.0 - bob
			draw_colored_polygon(PackedVector2Array([Vector2(s.x * 0.5 - 70, y), Vector2(s.x * 0.5 + 70, y), Vector2(s.x * 0.5, y - 120)]), bc)
			draw_colored_polygon(PackedVector2Array([Vector2(s.x * 0.5 - 70, y), Vector2(s.x * 0.5 + 70, y), Vector2(s.x * 0.5, y - 40)]), bc.darkened(0.2))
		"snake":
			var tip := Vector2(s.x * 0.5, s.y - 60 - bob)
			if int(t * 1.5) % 2 == 0:
				draw_line(Vector2(s.x * 0.5, s.y), tip, Color("d8242a"), 8, true)
				draw_line(tip, tip + Vector2(-14, -20), Color("d8242a"), 6, true)
				draw_line(tip, tip + Vector2(14, -20), Color("d8242a"), 6, true)
		_:
			for side in [-1.0, 1.0]:
				var swing := (bob if side < 0 else sin(hop * PI + 0.5) * 26.0 + sin(t * 2.2 + 1.0) * 3.0)
				var c := Vector2(s.x * (0.5 + side * 0.26), s.y + 50.0 - swing)
				Draw.ellipse(self, c, 66, 86, dark)
				Draw.ellipse(self, c + Vector2(0, 5), 60, 80, prim)
				for k in 3:
					Draw.ellipse(self, c + Vector2((k - 1) * 27.0, -70), 17, 16, prim.lightened(0.08))
					Draw.ellipse(self, c + Vector2((k - 1) * 27.0, -76), 7, 6, dark)
	for w in incoming():
		var side2: int = w[0]
		var k2: int = w[1]
		var a: float = 0.35 + 0.65 * float(w[2])
		var y2 := s.y * (0.66 - k2 * 0.09)
		var x := 18.0 if side2 < 0 else s.x - 18.0
		var dirx := float(-side2)
		var pts := PackedVector2Array([Vector2(x, y2), Vector2(x + dirx * 46.0, y2 - 34.0), Vector2(x + dirx * 46.0, y2 + 34.0)])
		draw_colored_polygon(pts, Color(0.95, 0.25, 0.2, a))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(1, 1, 1, a), 3.0, true)
