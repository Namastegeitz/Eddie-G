class_name WorldView
extends Node2D
## Draws a RunSim: lane backgrounds, moving things (y-sorted so lower rows
## stand in front), the player, raptor shadows and particles. The camera is
## just this node's position.

const T := 80.0

var sim: RunSim
var map: Dictionary = {}
var pal: Dictionary = {}
var animal: Dictionary = {}
var look_override: Dictionary = {}
var trail: Dictionary = {}
var colorblind := false
var reveal := 0.0
var field_x := 0.0
var cam_row := -0.5
var shake := 0.0
var vp := Vector2(720, 1280)

var ground: Node2D
var objects: Node2D
var overlay: Node2D
var fx: FxLayer
var player: PlayerView
var _lanes := {}        # row -> LaneView
var _ents := {}         # "row:i" -> EntView
var _preds := {}        # "row:i" -> PredView
var _items := {}        # key -> ItemView
var _swoops := []
var _swoop_view: SwoopView
var roof: CanopyRoof


func setup(run: RunSim, animal_def: Dictionary, look: Dictionary, trail_def: Dictionary) -> void:
	sim = run
	map = run.world.map
	pal = map.get("palette", {})
	animal = animal_def
	look_override = look
	trail = trail_def
	colorblind = bool(Save.setting("colorblind", false))
	reveal = run.reveal_amount()
	ground = Node2D.new()
	ground.name = "Ground"
	add_child(ground)
	objects = Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)
	overlay = Node2D.new()
	overlay.name = "Overlay"
	add_child(overlay)
	_swoop_view = SwoopView.new()
	_swoop_view.wv = self
	overlay.add_child(_swoop_view)
	roof = CanopyRoof.new()
	roof.wv = self
	roof.z_index = 5
	add_child(roof)
	fx = FxLayer.new()
	overlay.add_child(fx)
	player = PlayerView.new()
	player.wv = self
	objects.add_child(player)


static var _water_shader: Shader


static func water_shader() -> Shader:
	if _water_shader == null:
		_water_shader = load("res://assets/shaders/water.gdshader")
	return _water_shader


func color(key: String, fallback := "#3c9a3a") -> Color:
	return Color(String(pal.get(key, fallback)))


func px(x_tiles: float, row: float) -> Vector2:
	return Vector2(x_tiles * T, -row * T)


func to_screen(x_tiles: float, row: float) -> Vector2:
	return position + px(x_tiles, row)


func update_view(dt: float) -> void:
	vp = get_viewport_rect().size
	field_x = floorf((vp.x - Lane.COLS * T) * 0.5)
	var dp := sim.display_pos()
	var target := dp.y - (vp.y / T) * 0.27
	if sim.mode in ["endless", "daily"]:
		target = maxf(target, sim.cam_floor - 1.0)
	if sim.world.goal_row >= 0:
		target = minf(target, sim.world.goal_row + 3.5 - vp.y / T)
	target = maxf(target, -0.5)
	cam_row = lerpf(cam_row, target, 1.0 - exp(-dt * 6.0))
	shake = maxf(0.0, shake - dt * 2.5)
	var off := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 14.0 if not Save.setting("reduce_motion", false) else Vector2.ZERO
	position = Vector2(field_x, vp.y - T * 0.5 + cam_row * T) + off
	_sync_lanes()
	_sync_things(dt)
	player.z_index = 6 if sim.world.lane(int(roundf(sim.display_pos().y))).covered else 0
	player.update_view(dt)


func visible_rows() -> Vector2i:
	var lo := int(floorf(cam_row)) - 2
	var hi := int(ceilf(cam_row + vp.y / T)) + 2
	return Vector2i(lo, hi)


func _sync_lanes() -> void:
	var r := visible_rows()
	sim.world.ensure(r.y + 4)
	for row in _lanes.keys():
		if row < r.x or row > r.y:
			_lanes[row].queue_free()
			_lanes.erase(row)
	for row in range(r.x, r.y + 1):
		if not _lanes.has(row):
			var lv := LaneView.new()
			lv.wv = self
			lv.lane = sim.world.lane(row)
			lv.row = row
			lv.position = Vector2(0, -row * T)
			ground.add_child(lv)
			_lanes[row] = lv


func _sync_things(dt: float) -> void:
	var r := visible_rows()
	var seen := {}
	var seen_items := {}
	var w := sim.world
	for row in range(r.x, r.y + 1):
		var l := w.lane(row)
		for i in l.ents.size():
			var key := "%d:%d" % [row, i]
			seen[key] = true
			var ev: EntView = _ents.get(key)
			if ev == null:
				ev = EntView.new()
				ev.setup(self, l, l.ents[i])
				objects.add_child(ev)
				_ents[key] = ev
			ev.update_view(dt)
		for j in l.preds.size():
			if l.preds[j].kind == "swooper":
				continue
			var pk := "p%d:%d" % [row, j]
			seen[pk] = true
			var pv: PredView = _preds.get(pk)
			if pv == null:
				pv = PredView.new()
				pv.setup(self, l, l.preds[j])
				objects.add_child(pv)
				_preds[pk] = pv
			pv.queue_redraw()
		for it in l.items:
			var ik := String(it.key)
			if sim.taken.has(ik):
				continue
			if it.bonus and not sim.forages():
				continue
			seen_items[ik] = true
			var iv: ItemView = _items.get(ik)
			if iv == null:
				iv = ItemView.new()
				iv.setup(self, l, it)
				objects.add_child(iv)
				_items[ik] = iv
			iv.update_view()
	for k in _ents.keys():
		if not seen.has(k):
			_ents[k].queue_free()
			_ents.erase(k)
	for k in _preds.keys():
		if not seen.has(k):
			_preds[k].queue_free()
			_preds.erase(k)
	for k in _items.keys():
		if not seen_items.has(k):
			_items[k].queue_free()
			_items.erase(k)
	_swoop_view.queue_redraw()


func item_screen_pos(key: String) -> Vector2:
	var iv: ItemView = _items.get(key)
	return iv.global_position if iv else Vector2.ZERO


# ==================================================================== views

class LaneView extends Node2D:
	var wv: WorldView
	var lane: Lane
	var row := 0
	var dyn: Node2D

	var surface: Node2D
	var water_mat: ShaderMaterial

	func _ready() -> void:
		if lane.type == "water" and Draw.detail > 0:
			# shader water under everything else in the lane
			surface = Node2D.new()
			water_mat = ShaderMaterial.new()
			water_mat.shader = WorldView.water_shader()
			water_mat.set_shader_parameter("base", wv.color("water"))
			water_mat.set_shader_parameter("deep", wv.color("water_deep"))
			water_mat.set_shader_parameter("foam", wv.color("foam"))
			water_mat.set_shader_parameter("flow", (lane.speed if lane.speed != 0.0 else 0.4) * (1.6 if lane.fast else 1.0) * 0.5)
			water_mat.set_shader_parameter("tile", WorldView.T)
			water_mat.set_shader_parameter("glints", 1.0 if Draw.detail > 1 else 0.6)
			surface.material = water_mat
			surface.draw.connect(func():
				surface.draw_rect(Rect2(-wv.field_x - 40.0, -WorldView.T * 0.5, wv.vp.x + 80.0, WorldView.T), Color.WHITE))
			add_child(surface)
		dyn = Node2D.new()
		dyn.draw.connect(_draw_dyn)
		add_child(dyn)
		set_process(true)

	func _process(_dt: float) -> void:
		if water_mat:
			water_mat.set_shader_parameter("lt", wv.sim.world.lane_time(lane, wv.sim.vt))
		if lane.type == "water" or not lane.effect.is_empty() or not lane.tiles.is_empty() or lane.goal:
			dyn.queue_redraw()

	func _draw() -> void:
		var T := WorldView.T
		var x0 := -wv.field_x - 40.0
		var w := wv.vp.x + 80.0
		var rng := RandomNumberGenerator.new()
		rng.seed = lane.deco + row * 7
		var alt := row % 2 == 0
		match lane.type:
			"water":
				var deep := wv.color("water_deep")
				var base := wv.color("water")
				draw_rect(Rect2(x0, -T * 0.5, w, T), base)
				draw_rect(Rect2(x0, -T * 0.5, w, T * 0.12), deep)
				draw_rect(Rect2(x0, T * 0.38, w, T * 0.12), base.lightened(0.06))
			"ground":
				var g := wv.color("ground_alt" if alt else "ground")
				draw_rect(Rect2(x0, -T * 0.5, w, T), g)
				var x := x0
				while x < x0 + w:
					var len := rng.randf_range(20, 60)
					draw_line(Vector2(x, -T * 0.22), Vector2(x + len, -T * 0.22), g.darkened(0.12), 3)
					draw_line(Vector2(x + 30, T * 0.22), Vector2(x + 30 + len, T * 0.22), g.darkened(0.12), 3)
					x += len + rng.randf_range(30, 90)
				for i in int(w / 70.0):
					Draw.ellipse(self, Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.4, T * 0.4)), rng.randf_range(2, 5), rng.randf_range(2, 4), g.lightened(0.15))
			_:
				var s := wv.color("safe_alt" if alt else "safe")
				draw_rect(Rect2(x0, -T * 0.5, w, T), s)
				if lane.layout == "ridge":
					draw_rect(Rect2(x0, -T * 0.5, w, T), s.darkened(0.12))
				for i in int(w / 55.0):
					var p := Vector2(x0 + rng.randf() * w, rng.randf_range(-T * 0.42, T * 0.42))
					var k := rng.randi() % 7
					if k < 4:
						for j in 3:
							draw_line(p, p + Vector2((j - 1) * 4, -9 - j % 2 * 4), s.lightened(0.18), 2, true)
					elif k == 4:
						Draw.star(self, p, 5, wv.color("accent", "#f6d43a").lerp(Color.WHITE, 0.3), 5, 0.5)
					elif k == 5:
						Draw.ellipse(self, p, 6, 4, s.darkened(0.15))
				if lane.goal:
					draw_rect(Rect2(x0, -T * 0.5, w, T), Color(wv.color("goal"), 0.35))
		if Draw.detail > 0 and lane.type != "water":
			# soil / turf grain, then a soft lip so each row reads as raised
			draw_set_transform(Vector2(0, 0), 0.0, Vector2(2, 2))
			var ox := fposmod(float(row) * 37.0, 128.0)
			draw_texture_rect(Draw.grain(), Rect2((x0 - ox) * 0.5, -T * 0.25, w * 0.5 + 128.0, T * 0.5), true)
			draw_set_transform(Vector2.ZERO)
			if lane.type != "ground":
				draw_rect(Rect2(x0, T * 0.42, w, T * 0.08), Color(0, 0, 0, 0.1))
				draw_rect(Rect2(x0, -T * 0.5, w, T * 0.05), Color(1, 1, 1, 0.07))
			else:
				draw_rect(Rect2(x0, -T * 0.5, w, T * 0.06), Color(0, 0, 0, 0.1))
		for col in lane.tiles:
			var tile: Dictionary = lane.tiles[col]
			if tile.kind == "quicksand":
				continue
			var hz := Content.hazard(String(tile.hazard))
			draw_set_transform(Vector2(int(col) * T, 0))
			HazardPainter.draw_tile(self, hz, T, 0.0, int(col) * 31 + row)
			draw_set_transform(Vector2.ZERO)
		if lane.type != "water" and row >= 0:
			for c in range(0, Lane.COLS + 1):
				draw_line(Vector2(c * T, -T * 0.5), Vector2(c * T, -T * 0.42), Color(0, 0, 0, 0.06), 2)

	func _draw_dyn() -> void:
		var T := WorldView.T
		var t := wv.sim.vt
		var x0 := -wv.field_x - 40.0
		var w := wv.vp.x + 80.0
		if lane.type == "water":
			var lt := wv.sim.world.lane_time(lane, t)
			var sp := lane.speed if lane.speed != 0.0 else 0.4
			var foam := wv.color("foam")
			var n := int(w / 90.0) + 2
			for i in (n if water_mat == null else n / 2):
				var y := -T * 0.32 + (i % 4) * T * 0.2
				var x := fposmod(i * 97.0 + lt * sp * T * (1.6 if lane.fast else 1.0), w) + x0
				var len := 26.0 if not lane.fast else 44.0
				dyn.draw_line(Vector2(x, y), Vector2(x + len, y), Color(foam, 0.35 if not lane.fast else 0.55), 3, true)
		for col in lane.tiles:
			var tile: Dictionary = lane.tiles[col]
			if tile.kind == "quicksand":
				dyn.draw_set_transform(Vector2(int(col) * T, 0))
				HazardPainter.draw_tile(dyn, Content.hazard(String(tile.hazard)), T, t, int(col))
				dyn.draw_set_transform(Vector2.ZERO)
		if not lane.effect.is_empty():
			var st := lane.effect_state(t)
			if st[0] != "idle":
				dyn.draw_set_transform(Vector2(x0, 0))
				HazardPainter.draw_effect(dyn, Content.hazard(String(lane.effect.hazard)), w, T, String(st[0]), float(st[1]), t)
				dyn.draw_set_transform(Vector2.ZERO)
				if wv.colorblind and st[0] == "warn":
					HazardPainter._hazard_marker(dyn, Vector2(-T * 0.4, 0), T * 0.2)
					HazardPainter._hazard_marker(dyn, Vector2(Lane.COLS * T + T * 0.4, 0), T * 0.2)
		if lane.goal:
			var pulse := 0.5 + 0.5 * sin(t * 3.0)
			dyn.draw_rect(Rect2(0, -T * 0.5, Lane.COLS * T, T), Color(wv.color("goal"), 0.18 + 0.15 * pulse))
			for i in 9:
				Draw.star(dyn, Vector2(i * T + T * 0.5, sin(t * 2.0 + i) * 10.0), 7 + pulse * 3.0, Color(1, 1, 0.8, 0.7), 4, 0.35)
			var flag := Content.cosmetic(String(Save.data.get("equipped_flag", "")))
			if not flag.is_empty() and String(flag.id) in Save.data.owned_cosmetics:
				var cols: Array = flag.get("art", {}).get("colors", ["#ffffff", "#cccccc"])
				var fx := Lane.COLS * T * 0.5 + T * 2.0
				dyn.draw_line(Vector2(fx, T * 0.3), Vector2(fx, -T * 0.9), Color("e8e0c8"), 5)
				dyn.draw_colored_polygon(PackedVector2Array([Vector2(fx, -T * 0.9), Vector2(fx + T * 0.7, -T * 0.72 + sin(t * 4.0) * 5.0), Vector2(fx, -T * 0.5)]), Color(String(cols[0])))
				Draw.ellipse(dyn, Vector2(fx + T * 0.22, -T * 0.71), T * 0.08, T * 0.08, Color(String(cols[1])))


class EntView extends Node2D:
	var wv: WorldView
	var lane: Lane
	var e: Ent
	var hz: Dictionary
	var anim := false
	var last_dive := ""

	func setup(world_view: WorldView, l: Lane, ent: Ent) -> void:
		wv = world_view
		lane = l
		e = ent
		hz = Content.hazard(e.hazard)
		anim = HazardPainter.animated(String(hz.get("art", {}).get("painter", "")))

	func update_view(_dt: float) -> void:
		var t := wv.sim.vt
		var x := wv.sim.world.ent_x(lane, e, t)
		position = Vector2(x * WorldView.T, -lane.row * WorldView.T + (0.0 if e.platform else 0.2))
		visible = x > -3.5 and x < Lane.COLS + 3.5
		if not e.active(t):
			modulate.a = 0.25
		else:
			modulate.a = 1.0
		if e.platform and e.dive_period > 0.0:
			var ds := wv.sim.world.ent_dive(lane, e, t)
			var pr := e.dive_progress(wv.sim.world.lane_time(lane, t))
			match ds:
				"warn":
					modulate.a = 1.0 - pr * 0.35
					position.y += sin(t * 30.0) * 1.5
				"under":
					modulate.a = 0.18
				_:
					modulate.a = 1.0
			if ds != last_dive:
				last_dive = ds
				queue_redraw()
		if anim:
			queue_redraw()

	func _draw() -> void:
		var dir := 1 if lane.speed >= 0.0 else -1
		if e.motion == "pendulum":
			dir = 1 if e.velocity(0.0, wv.sim.vt) >= 0.0 else -1
		HazardPainter.draw_entity(self, hz, e.length * WorldView.T, WorldView.T,
			{"dir": dir, "t": wv.sim.vt, "speed": lane.speed, "colorblind": wv.colorblind})
		if e.platform and e.dive_period > 0.0 and last_dive == "warn":
			for i in 3:
				Draw.ellipse_line(self, Vector2(e.length * WorldView.T * (0.25 + i * 0.25), 0), 6 + i * 2, 4 + i, Color(1, 1, 1, 0.6), 2)


class PredView extends Node2D:
	var wv: WorldView
	var lane: Lane
	var p: Dictionary
	var hz: Dictionary

	func setup(world_view: WorldView, l: Lane, pred: Dictionary) -> void:
		wv = world_view
		lane = l
		p = pred
		hz = Content.hazard(String(p.hazard))
		var T := WorldView.T
		if p.kind == "surfacer":
			position = Vector2(float(p.x) * T, -lane.row * T + 1)
		else:
			position = Vector2(int(p.col) * T, -lane.row * T + 1)

	func _draw() -> void:
		var st := lane.pred_state(p, wv.sim.vt)
		var reveal := wv.reveal if bool(p.get("hidden", false)) else 0.0
		HazardPainter.draw_pred(self, hz, p, WorldView.T, String(st[0]), float(st[1]), wv.sim.vt, reveal)
		if wv.colorblind and st[0] == "warn" and p.kind != "striker":
			HazardPainter._hazard_marker(self, Vector2(0, -WorldView.T * 0.4), WorldView.T * 0.14)
		if st[0] == "distracted":
			Draw.star(self, Vector2(WorldView.T * 0.5 if p.kind != "surfacer" else 0.0, -WorldView.T * 0.45), 10, Color("ffe066"), 5, 0.45)


class ItemView extends Node2D:
	var wv: WorldView
	var lane: Lane
	var it: Dictionary
	var def: Dictionary

	func setup(world_view: WorldView, l: Lane, item: Dictionary) -> void:
		wv = world_view
		lane = l
		it = item
		def = Content.collectible(String(it.id))

	func update_view() -> void:
		var T := WorldView.T
		var x: float
		if int(it.ent) >= 0:
			x = wv.sim.world.ent_x(lane, lane.ents[int(it.ent)], wv.sim.vt) + float(it.rel)
		else:
			x = float(it.col) + 0.5
		position = Vector2(x * T, -lane.row * T + 2)
		queue_redraw()

	func _draw() -> void:
		HazardPainter.draw_item(self, def, WorldView.T, wv.sim.t + float(it.col) * 0.7, bool(it.bonus))


class SwoopView extends Node2D:
	var wv: WorldView

	func _draw() -> void:
		var T := WorldView.T
		var w := wv.sim.world
		var vis := wv.visible_rows()
		for s in w.swoopers:
			if int(s.hi) < vis.x or int(s.lo) > vis.y:
				continue
			var st := w.pred_state(s, wv.sim.vt)
			var col := w.swoop_col(s, wv.sim.vt)
			var x := (col + 0.5) * T
			var top := -float(s.hi) * T - T * 0.5
			var bottom := -float(s.lo) * T + T * 0.5
			var hz := Content.hazard(String(s.hazard))
			var cl: Dictionary = hz.get("art", {}).get("colors", {})
			match String(st[0]):
				"warn":
					var k := float(st[1])
					draw_rect(Rect2(x - T * 0.5, top, T, bottom - top), Color(0, 0, 0, 0.06 + 0.12 * k))
					var sy := lerpf(top - T, bottom - T * 0.5, k * 0.3)
					_bird_shadow(Vector2(x, sy), T * (0.5 + 0.3 * k), Color(0, 0, 0, 0.25 + 0.25 * k))
					if wv.colorblind:
						HazardPainter._hazard_marker(self, Vector2(x, top + T * 0.4), T * 0.18)
				"active":
					var k2 := float(st[1])
					var by := lerpf(top, bottom, k2)
					draw_rect(Rect2(x - T * 0.5, top, T, bottom - top), Color(0, 0, 0, 0.12))
					_bird(Vector2(x, by), T * 0.9, cl)

	func _bird_shadow(p: Vector2, r: float, c: Color) -> void:
		Draw.ellipse(self, p, r * 0.25, r * 0.4, c)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r, -r * 0.1), p + Vector2(0, -r * 0.25), p + Vector2(r, -r * 0.1), p + Vector2(0, r * 0.15)]), c)

	func _bird(p: Vector2, r: float, cl: Dictionary) -> void:
		var wing := Color(String(cl.get("wing", "#2a2a30")))
		var body := Color(String(cl.get("body", "#55565e")))
		Draw.shadow(self, p + Vector2(10, 20), r * 0.6, r * 0.2, 0.3)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r, -r * 0.05), p + Vector2(-r * 0.2, -r * 0.3), p + Vector2(0, -r * 0.1), p + Vector2(r * 0.2, -r * 0.3), p + Vector2(r, -r * 0.05), p + Vector2(0, r * 0.15)]), wing)
		Draw.ellipse(self, p, r * 0.18, r * 0.35, body)
		Draw.ellipse(self, p + Vector2(0, r * 0.28), r * 0.12, r * 0.12, Color(String(cl.get("belly", "#f4f4f2"))))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 0.05, r * 0.38), p + Vector2(r * 0.05, r * 0.38), p + Vector2(0, r * 0.5)]), Color("f2c02a"))
