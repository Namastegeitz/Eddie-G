class_name MiniMap
extends Control
## A live mini-map in the corner of the run, in both views. On the right, a
## zoomed-in view of the rows around you: lane types, logs, traffic and
## creatures moving as they really are, canopy patches, waterfall ledges, the
## goal, and you (pulsing). On the left, a slim gauge for the whole level:
## where you are between the start and the goal, the canopy zones, and the
## stretch the zoomed view shows. Tap it to make it larger or smaller.

const BEHIND := 2
const AHEAD := 11
const GAUGE_W := 10.0

var sim: RunSim
var world: World
var map: Dictionary
var big := false
var _t := 0.0
var _top := 0.0


## Placed in the top-right corner, `top` pixels down.
func setup(run: RunSim, w: World, map_def: Dictionary, top: float) -> void:
	sim = run
	world = w
	map = map_def
	_top = top
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_resize()


func _resize() -> void:
	var s := Vector2(170, 330) if big else Vector2(124, 244)
	offset_left = -s.x - 22.0
	offset_right = -22.0
	offset_top = _top
	offset_bottom = _top + s.y


func _gui_input(e: InputEvent) -> void:
	if Widgets.tap(self, e):
		big = not big
		_resize()
		accept_event()


func _process(dt: float) -> void:
	_t += dt
	if is_visible_in_tree():
		queue_redraw()


func _col(key: String, fallback: String) -> Color:
	return Color(String(map.get("palette", {}).get(key, fallback)))


func _draw() -> void:
	if sim == null:
		return
	var w := size.x
	var h := size.y
	var box := Rect2(GAUGE_W + 6.0, 0.0, w - GAUGE_W - 6.0, h)
	# frame
	Draw.rrect(self, Rect2(-4, -4, w + 8, h + 8), 10.0, Color(0.02, 0.08, 0.04, 0.72))
	var rows := AHEAD + BEHIND + 1
	var rh := box.size.y / rows
	var cw := box.size.x / Lane.COLS
	var dp := sim.display_pos()
	# the camera follows you smoothly, so the map scrolls row by row
	var base := dp.y - BEHIND - 0.5
	var t := sim.vt
	for k in rows + 1:
		var r := int(floorf(base)) + k
		if r < 0:
			continue
		var l := world.lane(r)
		var y := box.position.y + box.size.y - (float(r) - base) * rh - rh
		if y > box.end.y or y + rh < box.position.y:
			continue
		var rr := Rect2(box.position.x, y, box.size.x, rh).intersection(box)
		var c := _col("safe", "#3c9a3a")
		match l.type:
			"water":
				c = _col("water", "#3a7ab0")
			"ground":
				c = _col("ground", "#8a6a4a")
		if l.goal:
			c = _col("goal", "#c8f0a0")
		draw_rect(rr, c)
		if l.layout == "falls":
			draw_rect(rr, Color(0.85, 0.95, 1.0, 0.75))
		# tiles: gullies, boulders, falls water
		for col in l.tiles:
			var tr := Rect2(box.position.x + col * cw, y, cw, rh).intersection(box)
			draw_rect(tr, Color(0.1, 0.12, 0.1, 0.6) if l.layout != "falls" else Color(0.55, 0.8, 1.0, 0.9))
		# logs, traffic, creatures at their real place right now
		for e in l.ents:
			if not e.active(t):
				continue
			var x := world.ent_x(l, e, t)
			if x + e.length < 0.0 or x > Lane.COLS:
				continue
			var hz := Content.hazard(e.hazard)
			var ec := Color(String(hz.get("art", {}).get("colors", {}).get("body", "#d0d0d0")))
			if e.platform:
				ec = ec.lightened(0.15)
			else:
				ec = ec.lerp(Color(1, 0.3, 0.2), 0.35)
			var er := Rect2(box.position.x + x * cw, y + rh * 0.18, e.length * cw, rh * 0.64).intersection(box)
			if er.size.x > 0.0:
				draw_rect(er, ec)
		for p in l.preds:
			if String(p.get("kind", "")) == "striker":
				var px := box.position.x + (float(p.col) + 0.5) * cw
				draw_circle(Vector2(px, y + rh * 0.5), rh * 0.28, Color(1, 0.35, 0.25, 0.9))
		if l.covered:
			draw_rect(rr, Color(0.02, 0.22, 0.08, 0.55))
	# you
	var me := Vector2(box.position.x + dp.x * cw, box.position.y + box.size.y - (dp.y - base) * rh - rh * 0.5)
	var pulse := 0.5 + 0.5 * sin(_t * 6.0)
	draw_circle(me, rh * (0.55 + 0.25 * pulse), Color(1, 1, 1, 0.25))
	draw_circle(me, rh * 0.42, Color(1.0, 0.86, 0.2))
	draw_arc(me, rh * 0.42, 0.0, TAU, 16, Color(0.1, 0.06, 0.0), 1.5, true)
	# whole-level gauge
	var g := Rect2(0.0, 0.0, GAUGE_W, h)
	Draw.rrect(self, g, 4.0, Color(1, 1, 1, 0.12))
	var goal := float(world.goal_row) if world.goal_row > 0 else maxf(60.0, float(Progress.best_rows(String(map.get("id", "")))) + 20.0)
	var gy := func(row: float) -> float: return h - clampf(row / goal, 0.0, 1.0) * h
	for z in world.gen.cover:
		var a: float = gy.call(float(z.x))
		var b: float = gy.call(float(z.y + 1))
		draw_rect(Rect2(1.0, b, GAUGE_W - 2.0, a - b), Color(0.05, 0.4, 0.15, 0.9))
	draw_rect(Rect2(2.0, gy.call(float(sim.max_row)), GAUGE_W - 4.0, h - gy.call(float(sim.max_row))), Color(0.6, 0.95, 0.5, 0.45))
	var top: float = gy.call(base + rows)
	var bot: float = gy.call(base)
	draw_rect(Rect2(-1.0, top, GAUGE_W + 2.0, maxf(2.0, bot - top)), Color(1, 1, 1, 0.55), false, 1.5)
	draw_circle(Vector2(GAUGE_W * 0.5, gy.call(dp.y)), 4.0, Color(1.0, 0.86, 0.2))
	if world.goal_row > 0:
		Draw.star(self, Vector2(GAUGE_W * 0.5, 0.0), 6.0, Color(1, 0.9, 0.4), 5, 0.45)
