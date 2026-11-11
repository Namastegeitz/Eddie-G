class_name WorldView3D
extends SubViewportContainer
## First-person view: the same RunSim seen through the animal's eyes, as a
## low-poly 3D scene (1 unit = 1 tile, rows run along -Z). Hazards are built
## from their content files' painter id and colours, so new hazard files
## show up here too. Under dense canopy the light drops and leaves close in
## overhead, but nothing is hidden: this is the view that sees under them.

const AHEAD := 22
## First-person view profiles (Settings > First-person view). h: side-to-side
## field of view (open sky, under canopy); v: the least top-to-bottom view (so
## wide screens see the canopy and far ahead too); vmax: the most top-to-bottom
## on a tall phone (beyond it the edges stretch, so the sides give way);
## back: how far behind the animal's head the eye sits; up: how far above it
## (a little higher shows more rows ahead); pitch: look-down angle; fog: how
## much of the usual mist.
const VIEWS := {
	"classic": {"h": [86.0, 97.0], "v": [0.0, 0.0], "vmax": 140.0, "back": 0.8, "up": 0.0, "pitch": [-27.0, -19.0], "fog": 1.0},
	"wide": {"h": [96.0, 104.0], "v": [80.0, 88.0], "vmax": 124.0, "back": 1.1, "up": 0.35, "pitch": [-27.0, -20.0], "fog": 0.8},
	"extra": {"h": [108.0, 114.0], "v": [92.0, 98.0], "vmax": 132.0, "back": 1.3, "up": 0.55, "pitch": [-27.0, -19.0], "fog": 0.65},
}
const BEHIND := 2
const POOL_MAX := 12              # spare moving-thing nodes kept per kind and size
const POOL_TOTAL := 64            # ...and in all (lengths vary, so the oldest spares go first)
const MID := 4.5                 # centre of the 9 play columns

var sim: RunSim
var map: Dictionary = {}
var pal: Dictionary = {}
var animal: Dictionary = {}
var vp3: SubViewport
var world3: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var _sky_mat: ProceduralSkyMaterial    # open-sky gradient with a sun (darkens under the canopy)
var _normal: NoiseTexture2D            # fine bumps for soil, grass and mud (not on Low)
var eye_h := 0.55
var t := 0.0
var shade := 0.0                 # 0 open sky .. 1 deep under canopy
var _lanes := {}
var _ents := {}
var _ent_pool := {}               # "hazard:length" -> hidden nodes ready to reuse
var _pool_order: Array[Node3D] = []   # every pooled node, oldest first
var _open_trees: Array = []        # tree kinds for the open rows (from this jungle's scenes)
var _open_plants: Array = []
var ents_built := 0               # moving-thing nodes built so far (the rest are reused)
var ents_missed := 0              # ...of which built on the spot, because the pool had none ready
var _preds := {}
var _items := {}
var _swoops := {}
var _mats := {}
var _meshes := {}
var _sky := Color("9ad0e8")
var _walls: Array[Node3D] = []
var _grain: NoiseTexture2D       # shared surface grain for ground, water, walls
var _water_mats: Array[StandardMaterial3D] = []
var _fit_key := Vector2.ZERO
var _warm_row := 0                # next row to pre-build scenery for (see warm_step)
var built_this_frame := 0         # rows built by the last update_view
var _land_t := 1.0                # time since the last landing (camera dip)
var _land_k := 1.0                # how hard that landing was
var _ride_y := 0.0                # eye height from what you stand on (log top, stone, water)
var _seg := 10                   # sphere / cylinder smoothness (quality)
var scene := {}                  # the canopy scene we're in or about to enter
var _fog0 := Color.WHITE
var _fog_d0 := 0.05


func setup(run: RunSim, animal_def: Dictionary) -> void:
	sim = run
	map = run.world.map
	pal = map.get("palette", {})
	animal = animal_def
	stretch = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the open rows grow this jungle's own trees (from its first-person scenes)
	var weights := {}
	for sc in map.get("fpv_scenes", []):
		for kind in sc.get("props", {}):
			weights[kind] = float(weights.get(kind, 0.0)) + float(sc.props[kind])
	for kind in Content.models.get("open_trees", []):
		if weights.has(kind):
			_open_trees.append(kind)
	if _open_trees.is_empty():
		_open_trees = Content.models.get("open_trees", []).slice(0, 2)
	_open_plants = Content.models.get("open_plants", [])
	_seg = 18 if Gfx.level() == "high" else (12 if Gfx.level() == "medium" else 8)
	if Gfx.level() != "low":
		_grain = NoiseTexture2D.new()
		_grain.width = 256
		_grain.height = 256
		_grain.seamless = true
		_grain.generate_mipmaps = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.035
		fn.fractal_octaves = 4
		_grain.noise = fn
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.78, 0.78, 0.78))
		ramp.set_color(1, Color(1.12, 1.12, 1.12))
		_grain.color_ramp = ramp
	vp3 = SubViewport.new()
	vp3.own_world_3d = true
	vp3.msaa_3d = Gfx.msaa_3d()
	vp3.handle_input_locally = false
	vp3.gui_disable_input = true
	add_child(vp3)
	world3 = Node3D.new()
	vp3.add_child(world3)
	var atm: Dictionary = map.get("atmosphere", {})
	_sky = color("sky", "#1a4a2a").lerp(Color("bfe0d8"), 0.55)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _sky
	if Gfx.level() != "low":
		# a real sky: deep blue-green overhead fading to a hazy, sunlit horizon
		_sky_mat = ProceduralSkyMaterial.new()
		_sky_mat.sky_top_color = _sky.darkened(0.25).lerp(Color("4a86b8"), 0.35)
		_sky_mat.sky_horizon_color = _sky.lightened(0.25)
		_sky_mat.ground_horizon_color = _sky.lightened(0.1)
		_sky_mat.ground_bottom_color = color("canopy_dark", "#0b3a1a")
		_sky_mat.sun_angle_max = 18.0
		var skyr := Sky.new()
		skyr.sky_material = _sky_mat
		env.sky = skyr
		env.background_mode = Environment.BG_SKY
		# film-like light: soft highlights, a touch more contrast and colour
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 0.9
		env.tonemap_white = 6.0
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.14
		env.adjustment_saturation = 1.12
		env.fog_sun_scatter = 0.18
		if Gfx.level() == "high":
			env.glow_enabled = true
			env.glow_intensity = 0.35
			env.glow_bloom = 0.04
			env.glow_hdr_threshold = 1.1
		_normal = NoiseTexture2D.new()
		_normal.width = 256
		_normal.height = 256
		_normal.seamless = true
		_normal.as_normal_map = true
		_normal.bump_strength = 5.0
		_normal.generate_mipmaps = true
		var nn := FastNoiseLite.new()
		nn.frequency = 0.06
		nn.fractal_octaves = 3
		_normal.noise = nn
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.92, 0.82)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_light_color = Color(String(atm.get("fog_color", _sky.to_html(false))))
	env.fog_density = 0.045 + float(atm.get("mist", 0.0)) * 0.07
	_fog0 = env.fog_light_color
	_fog_d0 = env.fog_density
	var we := WorldEnvironment.new()
	we.environment = env
	world3.add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 28, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = Gfx.shadows()
	sun.shadow_opacity = 0.55
	sun.directional_shadow_max_distance = float(AHEAD) * 0.8
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	world3.add_child(sun)
	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 86.0
	cam.near = 0.05
	cam.far = float(AHEAD) + 6.0
	world3.add_child(cam)
	cam.current = true
	eye_h = 0.62 + 0.3 * float(animal.get("look", {}).get("size", 0.75))
	# two long jungle walls follow the camera and hide where things loop around
	for side in [-1.0, 1.0]:
		var wall := box(Vector3(5.0, 3.2, float(AHEAD + BEHIND + 8)), color("canopy_dark", "#0b3a1a"), Vector3.ZERO, world3)
		wall.material_override = surface(color("canopy_dark", "#0b3a1a"), 0.5)
		wall.set_meta("side", side)
		_walls.append(wall)


func color(key: String, fallback := "#3c9a3a") -> Color:
	return Color(String(pal.get(key, fallback)))


# ------------------------------------------------------------------ frame

## Render the 3D scene at screen resolution (High) or game resolution, and
## draw it scaled to fill the playfield.
func _fit() -> void:
	var par := get_parent_area_size()
	if par.x < 2.0 or par.y < 2.0:
		par = get_viewport_rect().size
	var screen := float(get_tree().root.size.x) / maxf(1.0, get_viewport_rect().size.x)
	var key := Vector2(par.x * 1000.0 + par.y, screen)
	if key == _fit_key or par.x < 2.0:
		return
	_fit_key = key
	var k := Gfx.scale_3d(screen)
	position = Vector2.ZERO
	scale = Vector2.ONE / k
	size = par * k
	vp3.size = Vector2i(maxi(2, int(par.x * k)), maxi(2, int(par.y * k)))


func update_view(dt: float) -> void:
	if not is_visible_in_tree():
		return
	_fit()
	t += dt
	for wm in _water_mats:
		wm.uv1_offset = Vector3(t * 0.04, t * 0.11, 0.0)
	var dp := sim.display_pos()
	var lift := sim.hop_height()
	var y := eye_h + lift * 0.7 + sin(t * 2.2) * 0.008
	if sim.state in ["respawn", "dead", "restart", "over"] and sim.cause != "":
		y = lerpf(cam.position.y, 0.05 if sim.cause in ["drowned", "fell"] else 0.18, minf(1.0, dt * 3.0))
	var vw := view_profile()
	if not (sim.state in ["respawn", "dead", "restart", "over"] and sim.cause != ""):
		y += float(vw.up)
		# ride at the height of what you stand on: up on a log's back or a
		# waterfall stone, low on a lily pad, lower still when swimming
		var want := 0.0
		var cl := sim.cur_lane()
		if sim.hopping:
			want = _ride_y
		elif sim.plat >= 0 and sim.plat < cl.ents.size():
			var ph := String(Content.hazard(cl.ents[sim.plat].hazard).get("art", {}).get("painter", ""))
			want = 0.04 if ph in ["lilypad"] else (0.14 if ph in ["stones", "bridge", "boat"] else 0.2)
		elif sim.swimming:
			want = -0.22
		elif cl.layout == "falls":
			want = 0.1
		_ride_y = lerpf(_ride_y, want, minf(1.0, dt * 9.0))
		y += _ride_y
		# a landing dips the view and recovers with a little spring
		_land_t += dt
		if _land_t < 0.32:
			var kk := _land_t / 0.32
			y -= sin(kk * PI) * exp(-kk * 2.0) * 0.07 * _land_k
	cam.position = Vector3(dp.x, y, -dp.y + float(vw.back))
	# under the canopy the gaze lifts a little to take in the scene ahead
	cam.rotation_degrees = Vector3(lerpf(float(vw.pitch[0]), float(vw.pitch[1]), shade) + lift * 6.0, 0.0, 0.0)
	_apply_fov(vw)
	var here := sim.world.lane(sim.row)
	var next := sim.world.lane(sim.row + 1)
	var covered := here.covered or next.covered
	if covered:
		scene = Scenery3D.scene_def(map, here.scene if here.covered else next.scene)
	shade = move_toward(shade, 1.0 if covered else 0.0, dt * 1.5)
	# each scene has its own light: warm shafts, cool cave light, white mist
	var light := Scenery3D.col(scene, pal, "light", "#fff2c8")
	var fog := Scenery3D.col(scene, pal, "fog", _fog0.to_html(false))
	var dim := 0.3 + float(scene.get("shafts", 0.4)) * 0.16
	env.ambient_light_energy = lerpf(0.42 if _sky_mat else 0.5, dim, shade)
	env.ambient_light_color = Color(0.85, 0.92, 0.82).lerp(light, shade * 0.35)
	sun.light_energy = lerpf(0.8, 0.25 + float(scene.get("shafts", 0.4)) * 0.25, shade)
	sun.light_color = Color.WHITE.lerp(light, shade * 0.6)
	env.fog_light_color = _fog0.lerp(fog, shade)
	var mist := 1.0 if "mist" in Array(scene.get("particles", [])) else 0.0
	# thicker air under the leaves, but capped so hazards a few rows ahead stay readable
	env.fog_density = lerpf(_fog_d0, minf(0.075, _fog_d0 + 0.015 * mist + 0.008), shade) * float(vw.fog)
	env.background_color = _sky.lerp(color("canopy_dark", "#0b3a1a"), shade * 0.85).lerp(fog.darkened(0.3), shade * 0.3)
	if _sky_mat:
		# under the leaves the sky closes in: dim green overhead, misty below
		var dark := color("canopy_dark", "#0b3a1a")
		_sky_mat.sky_top_color = _sky.darkened(0.25).lerp(Color("4a86b8"), 0.35).lerp(dark, shade * 0.9)
		_sky_mat.sky_horizon_color = _sky.lightened(0.25).lerp(fog.darkened(0.2), shade * 0.8)
		_sky_mat.sky_energy_multiplier = lerpf(1.0, 0.45, shade)
	var lo := sim.row - BEHIND
	var hi := sim.row + AHEAD
	for wall in _walls:
		wall.position = Vector3(MID + float(wall.get_meta("side")) * 8.4, 1.5, -(dp.y + (AHEAD - BEHIND) * 0.5))
	sim.world.ensure(hi + 2)
	Scenery3D.falling_water_material().uv1_offset = Vector3(0.0, -t * 1.6, 0.0)
	for r in _lanes.keys():
		var sn: Node3D = _lanes[r].get_node_or_null("Scenery")
		if sn and r >= lo and r <= hi:
			Scenery3D.animate(sn, t)
		if r >= lo and r <= hi and _lanes[r].has_meta("critters"):
			_animate_critters(_lanes[r].get_meta("critters"), t)
		if r < lo or r > hi:
			_lanes[r].queue_free()
			_lanes.erase(r)
	var seen := {}
	var seen_items := {}
	var built := 0
	# a fresh view (just switched to, or after a restart) builds everything
	# at once; while playing, only a hop's worth of rows a frame
	var fresh := _lanes.size() < (hi - lo + 1) / 2
	if _warm_row < sim.row:
		_warm_row = sim.row
	for r in range(lo, hi + 1):
		var l := sim.world.lane(r)
		if not _lanes.has(r):
			# rows near you are built at once; far rows (in the fog) at most
			# one a frame, so a hop never builds a burst of rows in one frame
			if built >= 1 and r > sim.row + 6 and not fresh:
				continue
			_lanes[r] = _build_lane(l, r)
			built += 1
		_update_lane_fx(l, _lanes[r])
		for i in l.ents.size():
			var key := "%d:%d" % [r, i]
			seen[key] = true
			var n: Node3D = _ents.get(key)
			if n == null:
				n = _take_ent(l, l.ents[i])
				_ents[key] = n
			_place_ent(n, l, l.ents[i])
		for j in l.preds.size():
			var p: Dictionary = l.preds[j]
			if p.kind == "swooper":
				continue
			var pk := "p%d:%d" % [r, j]
			seen[pk] = true
			var pn: Node3D = _preds.get(pk)
			if pn == null:
				pn = _build_pred(l, p)
				world3.add_child(pn)
				_preds[pk] = pn
			_place_pred(pn, l, p)
		for it in l.items:
			var ik := String(it.key)
			if sim.taken.has(ik) or (it.bonus and not sim.forages()):
				continue
			seen_items[ik] = true
			var inode: Node3D = _items.get(ik)
			if inode == null:
				inode = _build_item(String(it.id))
				world3.add_child(inode)
				_items[ik] = inode
			var ix: float = float(it.col) + 0.5
			if int(it.ent) >= 0:
				ix = sim.world.ent_x(l, l.ents[int(it.ent)], sim.vt) + float(it.rel)
			inode.position = Vector3(ix, 0.35 + sin(t * 3.0 + ix) * 0.05, -r)
			inode.rotation.y = t * 2.0
	built_this_frame = built
	for k in _ents.keys():
		if not seen.has(k):
			_give_ent(_ents[k])
			_ents.erase(k)
	_prune(_preds, seen)
	_prune(_items, seen_items)
	_update_swoops(lo, hi)


## Pre-builds what the run will need next, at most one real build per call:
## first (in first person) the moving things of the two rows about to come
## into view (hidden, in the reuse pool), then row meshes (canopy scenery and grass rows) up to
## 60 rows ahead. Runs every frame in either view, so by the time you hop
## forward, reach a canopy or switch to first person, nothing stalls.
## Called when you land: the view dips a little (more after a big leap).
func landed(surface: String) -> void:
	_land_t = 0.0
	_land_k = 1.3 if surface == "platform" else (0.8 if surface == "ground" else 1.0)


func view_profile() -> Dictionary:
	return VIEWS.get(String(Save.setting("fpv_view", "wide")), VIEWS.wide)


## Field of view for this screen's shape: at least the profile's side-to-side
## angle, and at least its top-to-bottom angle (a wide screen gets a taller
## view instead of a letterbox), but never so tall on a phone that the edges
## smear (the sides give way first).
func _apply_fov(vw: Dictionary, aspect := -1.0) -> void:
	var a := aspect if aspect > 0.0 else size.x / maxf(1.0, size.y)
	var h := lerpf(float(vw.h[0]), float(vw.h[1]), shade)
	var v_min := lerpf(float(vw.v[0]), float(vw.v[1]), shade)
	var v_of_h := rad_to_deg(2.0 * atan(tan(deg_to_rad(h) * 0.5) / maxf(0.1, a)))
	if v_of_h < v_min:
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.fov = v_min
	else:
		if v_of_h > float(vw.vmax):
			h = rad_to_deg(2.0 * atan(tan(deg_to_rad(float(vw.vmax)) * 0.5) * a))
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.fov = h


## The view's angles on screen now, in degrees: (side to side, top to bottom).
func view_angles(aspect := -1.0) -> Vector2:
	var a := aspect if aspect > 0.0 else size.x / maxf(1.0, size.y)
	var t := tan(deg_to_rad(cam.fov) * 0.5)
	if cam.keep_aspect == Camera3D.KEEP_WIDTH:
		return Vector2(cam.fov, rad_to_deg(2.0 * atan(t / a)))
	return Vector2(rad_to_deg(2.0 * atan(t * a)), cam.fov)


func warm_step() -> void:
	if is_visible_in_tree() and _warm_ents():
		return
	var limit := sim.row + 60
	if sim.world.goal_row >= 0:
		limit = mini(limit, sim.world.goal_row)
	while _warm_row <= limit:
		var r := _warm_row
		_warm_row += 1
		var l := sim.world.lane(r)
		if _lanes.has(r):
			continue
		var zr := Vector2i(r, r)
		if l.zone >= 0 and l.zone < sim.world.gen.cover.size():
			zr = sim.world.gen.cover[l.zone]
		var sc := Scenery3D.scene_def(map, l.scene) if l.covered else {}
		if Scenery3D.warm_row(l, sc, pal, Draw.detail, zr, _open_trees, _open_plants):
			return


## Moving things are built once per kind and size, then reused: a log that
## drifts out of range is hidden and handed to the next log of that length,
## so hopping forward rarely builds anything.
func _take_ent(l: Lane, e: Ent) -> Node3D:
	var key := "%s:%.2f" % [e.hazard, e.length]
	var pool: Array = _ent_pool.get(key, [])
	if not pool.is_empty():
		var reused: Node3D = pool.pop_back()
		_pool_order.erase(reused)
		reused.visible = true
		return reused
	ents_missed += 1
	return _new_ent(l, e, key)


func _new_ent(l: Lane, e: Ent, key: String) -> Node3D:
	var n := _build_ent(l, e)
	_bake(n, key)
	ents_built += 1
	n.set_meta("pool", key)
	world3.add_child(n)
	return n


func _warm_ents() -> bool:
	if world3 == null:
		return false
	var need := {}
	for r in [sim.row + AHEAD + 1, sim.row + AHEAD + 2]:
		var l := sim.world.lane(r)
		for e in l.ents:
			var key := "%s:%.2f" % [e.hazard, e.length]
			need[key] = int(need.get(key, 0)) + 1
			if (_ent_pool.get(key, []) as Array).size() < mini(int(need[key]), POOL_MAX):
				_give_ent(_new_ent(l, e, key))
				return true
	return false


func _give_ent(n: Node3D) -> void:
	var key := String(n.get_meta("pool", ""))
	var pool: Array = _ent_pool.get(key, [])
	if key == "" or pool.size() >= POOL_MAX:
		n.queue_free()
		return
	n.visible = false
	pool.append(n)
	_ent_pool[key] = pool
	_pool_order.append(n)
	if _pool_order.size() > POOL_TOTAL:
		var old: Node3D = _pool_order.pop_front()
		(_ent_pool[String(old.get_meta("pool"))] as Array).erase(old)
		old.queue_free()


func _prune(d: Dictionary, seen: Dictionary) -> void:
	for k in d.keys():
		if not seen.has(k):
			d[k].queue_free()
			d.erase(k)


# ------------------------------------------------------------------ building blocks

func mat(c: Color, emissive := false) -> StandardMaterial3D:
	var key := c.to_html() + ("e" if emissive else "")
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.8
	_mats[key] = m
	return m


## A textured surface: the shared grain multiplied into the colour, mapped
## in world space so tiles line up. Water gets a glossy, drifting finish.
func surface(c: Color, uv := 0.35, water := false) -> StandardMaterial3D:
	var key := "surf%s:%.2f:%s" % [c.to_html(), uv, water]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.18 if water else 0.92
	if water:
		m.metallic_specular = 0.8
	if _grain:
		m.albedo_texture = _grain
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE * uv
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if _normal:
			# fine bumps that catch the light: soil grit, turf, ripples on water
			m.normal_enabled = true
			m.normal_texture = _normal
			m.normal_scale = 0.35 if water else 0.8
		if water:
			_water_mats.append(m)
	_mats[key] = m
	return m


func _mi(mesh: Mesh, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, emissive := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(c, emissive)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func box(size: Vector3, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, emissive := false) -> MeshInstance3D:
	var key := "b%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent, rot, emissive)


func sph(r: float, c: Color, pos: Vector3, parent: Node3D, scale := Vector3.ONE) -> MeshInstance3D:
	var key := "s%.2f" % r
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = _seg
		m.rings = maxi(5, _seg / 2)
		_meshes[key] = m
	var mi := _mi(_meshes[key], c, pos, parent)
	mi.scale = scale
	return mi


func cyl(r: float, h: float, c: Color, pos: Vector3, parent: Node3D, rot := Vector3.ZERO, top := -1.0) -> MeshInstance3D:
	var key := "c%.2f:%.2f:%.2f" % [r, h, top]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = r if top < 0.0 else top
		m.bottom_radius = r
		m.height = h
		m.radial_segments = _seg
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent, rot)


func torus(inner: float, outer: float, c: Color, pos: Vector3, parent: Node3D) -> MeshInstance3D:
	var key := "t%.2f:%.2f" % [inner, outer]
	if not _meshes.has(key):
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = maxi(12, _seg + 4)
		m.ring_segments = maxi(6, _seg / 2)
		_meshes[key] = m
	return _mi(_meshes[key], c, pos, parent)


static func hc(cl: Dictionary, key: String, fallback := "#888888") -> Color:
	return Color(String(cl.get(key, fallback)))


# ------------------------------------------------------------------ lanes

func _build_lane(l: Lane, r: int) -> Node3D:
	var n := Node3D.new()
	n.position = Vector3(0, 0, -r)
	world3.add_child(n)
	var alt := r % 2 == 0
	var rng := RandomNumberGenerator.new()
	rng.seed = l.deco + r * 13
	match l.type:
		"water":
			box(Vector3(26, 0.3, 1.0), color("water"), Vector3(MID, -0.27, 0), n).material_override = surface(color("water"), 0.22, true)
		"ground":
			box(Vector3(26, 0.3, 1.0), color("ground_alt" if alt else "ground"), Vector3(MID, -0.15, 0), n).material_override = surface(color("ground_alt" if alt else "ground"))
			box(Vector3(26, 0.02, 0.06), color("ground").darkened(0.2), Vector3(MID, 0.005, -0.25), n)
		_:
			var g := color("safe_alt" if alt else "safe")
			if l.goal:
				box(Vector3(26, 0.3, 1.0), color("goal", "#9cf06a"), Vector3(MID, -0.15, 0), n, Vector3.ZERO, true)
			elif l.layout == "falls":
				# a rocky lip with dry, mossy stones; the river pours over the rest
				var fh := Content.hazard(String(l.tiles.values()[0].hazard)) if not l.tiles.is_empty() else {}
				var fc: Dictionary = fh.get("art", {}).get("colors", {})
				var rock := hc(fc, "rock", "#6a6e60")
				box(Vector3(26, 0.3, 1.0), rock.darkened(0.3), Vector3(MID, -0.2, 0), n).material_override = surface(rock.darkened(0.3), 0.6)
				for cc in Lane.COLS:
					if not l.tiles.has(cc):
						sph(0.47, rock, Vector3(cc + 0.5, -0.12, 0), n, Vector3(1.0, 0.42, 0.95))
						sph(0.3, hc(fc, "moss", "#4f8a3a"), Vector3(cc + 0.42, 0.04, -0.1), n, Vector3(1.0, 0.3, 0.8))
			elif l.covered:
				# forest floor under the canopy: darker, browner, leaf litter
				var floor_c := g.darkened(0.3).lerp(Color("2e4a22"), 0.35)
				box(Vector3(26, 0.3, 1.0), floor_c, Vector3(MID, -0.15, 0), n).material_override = surface(floor_c, 0.8)
			else:
				box(Vector3(26, 0.3, 1.0), g, Vector3(MID, -0.15, 0), n).material_override = surface(g.lerp(Color("5a7a3a"), 0.3).darkened(0.16), 0.5)
	for col in l.tiles:
		var tile: Dictionary = l.tiles[col]
		var hz := Content.hazard(String(tile.hazard))
		var tc: Dictionary = hz.get("art", {}).get("colors", {})
		var x := float(col) + 0.5
		match String(tile.kind):
			"gap":
				if l.layout == "falls":
					# white water rushing across the ledge towards you and
					# pouring over its near lip, foam boiling where it goes over
					box(Vector3(1.0, 0.1, 1.0), hc(tc, "pool", "#2a6a8a"), Vector3(x, -0.08, 0), n)
					var rush := MeshInstance3D.new()
					var pm := PlaneMesh.new()
					pm.size = Vector2(1.0, 1.0)
					rush.mesh = pm
					rush.material_override = Scenery3D.falling_water_material()
					rush.position = Vector3(x, -0.02, 0)
					n.add_child(rush)
					var lip := MeshInstance3D.new()
					var qm := QuadMesh.new()
					qm.size = Vector2(1.0, 0.5)
					lip.mesh = qm
					lip.material_override = Scenery3D.falling_water_material()
					lip.position = Vector3(x, -0.27, 0.5)
					n.add_child(lip)
					for k in 3:
						sph(0.13, Color(1, 1, 1), Vector3(x - 0.32 + k * 0.32, 0.0, 0.42), n, Vector3(1.5, 0.45, 0.8))
					sph(0.1, Color(0.92, 0.97, 1.0), Vector3(x + 0.1, 0.02, -0.4), n, Vector3(2.6, 0.3, 0.6))
				else:
					box(Vector3(0.98, 0.04, 0.98), hc(tc, "body").darkened(0.5), Vector3(x, 0.01, 0), n)
					box(Vector3(1.0, 0.03, 0.06), hc(tc, "edge"), Vector3(x, 0.02, -0.48), n)
			"brush" when String(hz.get("art", {}).get("painter", "")) == "boulders" and Models3D.has_model(String(Content.models.get("tiles", {}).get("boulders", {}).get("model", ""))) and Draw.detail > 0:
				var bd: Dictionary = Content.models.tiles.boulders
				n.add_child(Scenery3D.model_node({"model": String(bd.model), "pos": Vector3(x, 0.0, rng.randf_range(-0.1, 0.1)), "yaw": rng.randf() * TAU, "height": float(bd.height) * rng.randf_range(0.85, 1.1)}))
			"brush" when String(hz.get("art", {}).get("painter", "")) == "boulders":
				for k in 3:
					var br := 0.3 if k == 1 else 0.24
					sph(br, hc(tc, "body").lightened(0.04 * k), Vector3(x - 0.24 + k * 0.24, br * 0.7, (k % 2) * 0.12 - 0.06), n, Vector3(1.0, 0.85, 1.0))
					sph(br * 0.7, hc(tc, "moss"), Vector3(x - 0.26 + k * 0.24, br * 1.25, (k % 2) * 0.12 - 0.08), n, Vector3(1.0, 0.35, 1.0))
			"brush":
				for k in 3:
					sph(0.3, hc(tc, "body").lightened(0.06 * k), Vector3(x - 0.2 + k * 0.2, 0.25 + (k % 2) * 0.1, rng.randf_range(-0.15, 0.15)), n)
			"quicksand":
				cyl(0.44, 0.02, hc(tc, "body"), Vector3(x, 0.01, 0), n)
				torus(0.15, 0.22, hc(tc, "swirl"), Vector3(x, 0.025, 0), n)
	if l.covered:
		var zr := Vector2i(r, r)
		if l.zone >= 0 and l.zone < sim.world.gen.cover.size():
			zr = sim.world.gen.cover[l.zone]
		n.add_child(Scenery3D.build_lane(l, Scenery3D.scene_def(map, l.scene), pal, Draw.detail, zr))
	else:
		# grass tufts, flowers and the trees along the sides: one mesh a row
		var open := Scenery3D.open_lane(l, pal, Draw.detail, _open_trees, _open_plants)
		if open:
			n.add_child(open)
	if not l.effect.is_empty():
		_build_lane_fx(l, n)
	_critters(l, n)
	return n


## Harmless wildlife on a bank, matching the bird's-eye view: the map's
## "trail_critters" (frogs, crabs, butterflies, birds, lizards, beetles).
func _critters(l: Lane, n: Node3D) -> void:
	if l.type != "safe" or l.goal or l.layout != "" or Draw.detail <= 0:
		return
	var list: Array = sim.world.map.get("trail_critters", [])
	if list.is_empty():
		return
	var made := []
	for k in mini(int(l.deco % 5), 2):
		var cr: Dictionary = list[(l.deco / 7 + k * 3) % list.size()]
		var col := int((l.deco / 13 + k * 4) % Lane.COLS)
		if l.tiles.has(col):
			continue
		var kind := String(cr.get("kind", "frog"))
		var cc := Color(String(cr.get("color", "#5aaa3a")))
		var c := Node3D.new()
		c.position = Vector3(col + 0.5, 0.0, (k - 0.5) * 0.3)
		n.add_child(c)
		match kind:
			"frog":
				sph(0.08, cc, Vector3(0, 0.06, 0), c, Vector3(1.0, 0.75, 1.1))
				for s in [-1.0, 1.0]:
					sph(0.025, Color("1a140c"), Vector3(s * 0.04, 0.11, -0.05), c)
			"crab":
				sph(0.08, cc, Vector3(0, 0.05, 0), c, Vector3(1.3, 0.55, 1.0))
				for s in [-1.0, 1.0]:
					sph(0.04, cc.lightened(0.15), Vector3(s * 0.08, 0.07, -0.08), c)
				if cc.r < 0.7:
					sph(0.07, Color("d8c8a0"), Vector3(0, 0.1, 0.02), c)
			"butterfly":
				c.position.y = 0.45
				for s in [-1.0, 1.0]:
					var wing := box(Vector3(0.12, 0.01, 0.1), cc, Vector3(s * 0.06, 0, 0), c)
					wing.name = "WingL" if s < 0 else "WingR"
			"bird":
				sph(0.07, cc, Vector3(0, 0.1, 0), c, Vector3(0.9, 1.2, 0.9))
				sph(0.05, cc.lightened(0.1), Vector3(0, 0.2, -0.02), c)
				sph(0.02, Color("f0c040"), Vector3(0, 0.2, -0.07), c)
			"lizard":
				sph(0.06, cc, Vector3(0, 0.03, 0), c, Vector3(1.8, 0.5, 0.7))
				sph(0.035, cc.lightened(0.1), Vector3(0.11, 0.04, 0), c)
			_:
				sph(0.04, cc, Vector3(0, 0.03, 0), c, Vector3(1.2, 0.7, 1.0))
		c.set_meta("kind", kind)
		c.set_meta("phase", float((l.deco + k) % 97) * 0.37)
		c.set_meta("home", c.position)
		made.append(c)
	if not made.is_empty():
		n.set_meta("critters", made)


func _animate_critters(list: Array, tt: float) -> void:
	for c in list:
		var node := c as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var ph := float(node.get_meta("phase"))
		var home: Vector3 = node.get_meta("home")
		match String(node.get_meta("kind")):
			"frog":
				node.position = home + Vector3(sin(tt * 0.21 + ph) * 0.08, pow(maxf(0.0, sin(tt * 1.3 + ph)), 6) * 0.12, 0)
			"crab":
				node.position = home + Vector3(sin(tt * 0.9 + ph) * 0.18, 0, 0)
			"butterfly":
				node.position = home + Vector3(sin(tt * 0.7 + ph) * 0.3, sin(tt * 1.7 + ph) * 0.06, cos(tt * 0.9 + ph * 1.3) * 0.18)
				var flap := sin(tt * 12.0 + ph) * 1.1
				(node.get_node("WingL") as Node3D).rotation.z = flap
				(node.get_node("WingR") as Node3D).rotation.z = -flap
			"bird":
				node.position = home + Vector3(0, sin(tt * 3.0 + ph) * 0.01, 0)
				node.rotation.y = sin(tt * 0.6 + ph) * 0.8
			"lizard":
				var dart := fposmod(tt * 0.4 + ph, 1.0)
				node.position = home + Vector3((0.2 if dart > 0.5 else -0.2), 0, 0)


func _build_lane_fx(l: Lane, n: Node3D) -> void:
	var fx := Node3D.new()
	fx.name = "Fx"
	n.add_child(fx)
	var hz := Content.hazard(String(l.effect.hazard))
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	match String(l.effect.kind):
		"fire":
			for i in 5:
				sph(0.3, Color(0.4, 0.4, 0.4, 0.5), Vector3(i * 2.0 + 0.5, 0.5, 0), fx).set_meta("smoke", true)
			for i in 10:
				cyl(0.18, 0.7, hc(cl, "body"), Vector3(i + 0.5, 0.35, sin(i * 2.1) * 0.2), fx, Vector3.ZERO, 0.0).set_meta("flame", i)
		"tide":
			box(Vector3(14.0, 0.06, 1.0), Color(hc(cl, "body"), 0.85), Vector3(MID, -0.2, 0), fx).set_meta("water", true)
		"mudslide":
			box(Vector3(14.0, 0.05, 1.0), hc(cl, "body"), Vector3(MID, 0.02, 0), fx).set_meta("mud", true)


func _update_lane_fx(l: Lane, n: Node3D) -> void:
	if l.effect.is_empty():
		return
	var fx: Node3D = n.get_node_or_null("Fx")
	if fx == null:
		return
	var st := l.effect_state(sim.vt)
	var k := float(st[1])
	for c in fx.get_children():
		var mi := c as Node3D
		if mi.has_meta("smoke"):
			mi.visible = st[0] == "warn"
			mi.scale = Vector3.ONE * (0.6 + k * 0.6)
			mi.position.y = 0.3 + k * 0.6
		elif mi.has_meta("flame"):
			mi.visible = st[0] == "active"
			mi.scale = Vector3(1.0, 0.7 + 0.35 * sin(t * 14.0 + int(mi.get_meta("flame")) * 1.7), 1.0)
		elif mi.has_meta("water"):
			mi.visible = st[0] in ["warn", "active"]
			mi.position.y = -0.2 + (0.22 * k if st[0] == "warn" else 0.22)
		elif mi.has_meta("mud"):
			mi.visible = st[0] == "active"
			mi.position.z = 0.5 * k - 0.25


# ------------------------------------------------------------------ moving things

func _build_ent(l: Lane, e: Ent) -> Node3D:
	var hz := Content.hazard(e.hazard)
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	var L := e.length
	var n := Node3D.new()
	var body := hc(cl, "body")
	# a detailed model where there is one (content/models.json)
	var md := Models3D.model_def(e.hazard, String(hz.get("art", {}).get("painter", "")))
	if not md.is_empty() and String(hz.get("art", {}).get("painter", "")) in ["log", "roll_log"]:
		# a detailed log, centred on a spinning axle so rolling logs roll
		var spin := Node3D.new()
		spin.name = "Spin"
		var rad := float(md.get("thick", 0.42)) * 0.5
		spin.position.y = rad - float(md.get("sink", 0.0)) if hz.kind == "platform" else 0.3
		n.add_child(spin)
		var dd: Dictionary = md.duplicate()
		dd["center"] = true
		spin.add_child(Models3D.creature(dd, L))
		if hz.kind != "platform":
			n.set_meta("roll", true)
		n.set_meta("platform", e.platform)
		return n
	if not md.is_empty():
		var mdl := Models3D.creature(md, L * float(md.get("length", 0.95)))
		mdl.position.y = -float(md.get("sink", 0.0))
		n.add_child(mdl)
		if String(hz.get("art", {}).get("painter", "")) == "soldier_ant":
			# the ant's wedge of cheese, held out in front
			var ch := box(Vector3(0.16, 0.1, 0.16), hc(cl, "cheese", "#ffd23a"), Vector3(L * 0.52, 0.14, 0), n, Vector3(0, 45, 0))
			ch.name = "Cheese"
		n.set_meta("bob", float(md.get("bob", 1.0)))
		n.set_meta("model_y", mdl.position.y)
		n.set_meta("platform", e.platform)
		return n
	match String(hz.get("art", {}).get("painter", "")):
		"truck":
			box(Vector3(L * 0.68, 0.5, 0.62), body, Vector3(-L * 0.15, 0.36, 0), n)
			box(Vector3(L * 0.26, 0.68, 0.6), hc(cl, "cab"), Vector3(L * 0.36, 0.45, 0), n)
			box(Vector3(0.04, 0.25, 0.46), Color("9fd0e8"), Vector3(L * 0.49, 0.6, 0), n)
			_lights(n, L * 0.5, 0.3, 0.2)
			for k in 2:
				cyl(0.13, L * 0.62, hc(cl, "cargo").lightened(0.08 * k), Vector3(-L * 0.15, 0.7, -0.13 + k * 0.26), n, Vector3(0, 0, 90))
		"jeep":
			box(Vector3(L, 0.42, 0.62), body, Vector3(0, 0.3, 0), n)
			box(Vector3(L * 0.5, 0.26, 0.56), hc(cl, "roof"), Vector3(-L * 0.08, 0.62, 0), n)
			box(Vector3(0.04, 0.22, 0.5), Color("9fd0e8"), Vector3(L * 0.18, 0.6, 0), n)
			_lights(n, L * 0.5, 0.3, 0.22)
		"tractor":
			box(Vector3(L * 0.55, 0.4, 0.62), hc(cl, "cargo").darkened(0.35), Vector3(-L * 0.2, 0.3, 0), n)
			for k2 in 6:
				sph(0.1, hc(cl, "cargo"), Vector3(-L * 0.4 + k2 * L * 0.08, 0.55, sin(k2) * 0.15), n)
			box(Vector3(L * 0.32, 0.6, 0.5), body, Vector3(L * 0.3, 0.42, 0), n)
			cyl(0.3, 0.14, Color("1a1a1a"), Vector3(L * 0.22, 0.3, -0.33), n, Vector3(90, 0, 0))
			cyl(0.3, 0.14, Color("1a1a1a"), Vector3(L * 0.22, 0.3, 0.33), n, Vector3(90, 0, 0))
		"cart":
			box(Vector3(L * 0.5, 0.4, 0.6), body, Vector3(-L * 0.2, 0.35, 0), n)
			sph(0.22, hc(cl, "animal"), Vector3(L * 0.3, 0.4, 0), n, Vector3(1.6, 1.0, 1.0))
			sph(0.12, hc(cl, "animal").darkened(0.1), Vector3(L * 0.48, 0.5, 0), n)
		"scooter":
			box(Vector3(L * 0.9, 0.25, 0.22), body, Vector3(0, 0.3, 0), n)
			_lights(n, L * 0.45, 0.35, 0.0)
			sph(0.15, hc(cl, "rider"), Vector3(0, 0.62, 0), n)
		"herd", "runner", "lizard", "elephant":
			var big := 1.0
			if hz.art.painter == "elephant":
				big = 1.8
			var bc := body
			var hcol := body.darkened(0.08)
			if hz.art.painter == "runner":
				hcol = hc(cl, "neck")
			sph(0.24 * big, bc, Vector3(0, 0.3 * big, 0), n, Vector3(L * 0.9 / (0.48 * big), 0.9, 1.0))
			var hy := (0.4 if hz.art.painter != "runner" else 0.65) * big
			sph(0.13 * big, hcol, Vector3(L * 0.45, hy, 0), n)
			for ez3 in [-1.0, 1.0]:
				sph(0.028 * big, Color("140d08"), Vector3(L * 0.45 + 0.09 * big, hy + 0.04 * big, ez3 * 0.07 * big), n)
			if hz.art.painter == "elephant":
				for ez in [-0.3, 0.3]:
					sph(0.2, hc(cl, "ear"), Vector3(L * 0.38, 0.6, ez), n, Vector3(0.3, 1.0, 1.0))
				cyl(0.06, 0.5, body, Vector3(L * 0.55, 0.3, 0), n)
			box(Vector3(L * 0.6, 0.2 * big, 0.3 * big), bc.darkened(0.3), Vector3(0, 0.1 * big, 0), n)
		"ants":
			sph(0.08, body, Vector3(0, 0.08, 0), n, Vector3(2.0, 1.0, 1.0))
			box(Vector3(0.18, 0.02, 0.12), hc(cl, "leaf"), Vector3(0.05, 0.22, 0), n, Vector3(0, 0, 25))
		"soldier_ant":
			Models3D.soldier_ant(n, L, cl)
		"crab":
			# a land crab: wide shell, raised claws, legs splayed to the sides
			sph(L * 0.36, body, Vector3(0, 0.16, 0), n, Vector3(1.0, 0.45, 0.8))
			sph(L * 0.2, body.lightened(0.18), Vector3(-L * 0.05, 0.24, 0), n, Vector3(1.0, 0.3, 0.7))
			for s in [-1.0, 1.0]:
				for k in 4:
					box(Vector3(0.04, 0.04, 0.26), hc(cl, "legs", "#8a2a1a"), Vector3((k - 1.5) * L * 0.16, 0.1, s * 0.22), n, Vector3(s * 25.0, 0, 0))
				sph(0.08, hc(cl, "claw", "#e86a3a"), Vector3(L * 0.42, 0.24, s * 0.13), n, Vector3(1.3, 0.8, 0.9))
				sph(0.03, Color("140d08"), Vector3(L * 0.3, 0.3, s * 0.06), n)
		"roll_log", "log":
			# bark, knots, branch stubs, moss, ringed ends; rolling logs turn
			var spin := Node3D.new()
			spin.name = "Spin"
			spin.position.y = 0.12 if hz.kind == "platform" else 0.3
			n.add_child(spin)
			Models3D._mi(Models3D.log_mesh(e.hazard, L, cl, hz.kind == "platform"), Models3D.matte(), spin)
			if hz.kind != "platform":
				n.set_meta("roll", true)
		"boulder":
			sph(minf(L, 1.0) * 0.45, body, Vector3(0, 0.42, 0), n)
		"vine":
			cyl(0.03, 2.4, Color("3a6a2a"), Vector3(0, 1.7, 0), n)
			sph(0.3, hc(cl, "leaf"), Vector3(0, 0.5, 0), n, Vector3(1.0, 1.3, 1.0))
		"lilypad":
			cyl(0.46, 0.04, body, Vector3(0, 0.0, 0), n)
		"caiman_back":
			Models3D._mi(Models3D.caiman_back(e.hazard, L, cl), Models3D.gloss(), n)
		"branch":
			cyl(0.1, L, body, Vector3(0, 0.05, 0), n, Vector3(0, 0, 90))
			for k3 in 3:
				sph(0.18, hc(cl, "leaf"), Vector3(-L * 0.3 + k3 * L * 0.3, 0.15, (k3 % 2 - 0.5) * 0.4), n, Vector3(1.4, 0.5, 1.0))
		"boat":
			box(Vector3(L, 0.28, 0.7), body, Vector3(0, 0.02, 0), n)
			for tz in [-0.36, 0.36]:
				box(Vector3(L * 0.98, 0.1, 0.06), hc(cl, "trim"), Vector3(0, 0.2, tz), n)
			for k5 in 2:
				cyl(0.03, 0.45, Color("5a3a22"), Vector3(-L * 0.15 + k5 * L * 0.3, 0.38, 0), n)
			box(Vector3(L * 0.35, 0.05, 0.6), hc(cl, "canopy"), Vector3(0, 0.6, 0), n)
		"bridge":
			var nplank := maxi(1, int(L / 0.25))
			for k4 in nplank:
				box(Vector3(0.2, 0.06, 0.64), hc(cl, "plank").lightened(0.05 * (k4 % 3)), Vector3(-L * 0.5 + (k4 + 0.5) * L / nplank, 0.0, 0), n)
			for rz in [-0.34, 0.34]:
				cyl(0.025, L, hc(cl, "rope"), Vector3(0, 0.45, rz), n, Vector3(0, 0, 90))
		"stones":
			sph(0.42, body, Vector3(0, -0.06, 0), n, Vector3(1.0, 0.45, 0.9))
			sph(0.2, hc(cl, "moss"), Vector3(0.1, 0.08, 0), n, Vector3(1.2, 0.4, 1.0))
		_:
			box(Vector3(L, 0.5, 0.6), body, Vector3(0, 0.3, 0), n)
	n.set_meta("platform", e.platform)
	return n


func _place_ent(n: Node3D, l: Lane, e: Ent) -> void:
	var x := sim.world.ent_x(l, e, sim.vt)
	var dir := 1.0 if l.speed >= 0.0 else -1.0
	if e.motion == "pendulum":
		dir = 1.0 if e.velocity(0.0, sim.vt) >= 0.0 else -1.0
	n.position = Vector3(x + e.length * 0.5, 0.0, -l.row)
	n.rotation_degrees.y = 0.0 if dir > 0 else 180.0
	if n.has_meta("bob"):
		# a stride: a small bounce and sway, faster for small quick animals
		var bob := float(n.get_meta("bob"))
		var mdl: Node3D = n.get_node("Model")
		var ph2 := t * (7.0 + 5.0 / maxf(0.5, e.length)) + x * 2.0
		mdl.position.y = float(n.get_meta("model_y")) + absf(sin(ph2)) * 0.022 * bob
		mdl.rotation.z = sin(ph2) * 0.025 * bob
	elif n.has_meta("walk"):
		# tripod gait: one set of three legs swings forward while the other pushes
		var ph := t * 11.0 + x * 3.0
		(n.get_node("LegsA") as Node3D).rotation.y = sin(ph) * 0.32
		(n.get_node("LegsB") as Node3D).rotation.y = -sin(ph) * 0.32
		(n.get_node("Body") as Node3D).position.y = absf(sin(ph)) * 0.018
	elif n.has_meta("roll"):
		(n.get_node("Spin") as Node3D).rotation.x = -x / 0.3 * dir
	n.visible = e.active(sim.vt) and x > -4.0 and x < 13.0
	if e.platform and e.dive_period > 0.0:
		match sim.world.ent_dive(l, e, sim.vt):
			"warn":
				n.position.y = sin(t * 30.0) * 0.02 - 0.03
			"under":
				n.position.y = -0.45
	elif e.platform:
		n.position.y = sin(t * 2.0 + x) * 0.015


## Merges a moving thing's opaque parts into one vertex-coloured mesh (one
## draw call instead of several), cached so identical ones share it. Glowing
## or see-through parts stay separate.
var _baked := {}
static var _ent_mat: StandardMaterial3D


func _bake(n: Node3D, key: String) -> void:
	var parts: Array[MeshInstance3D] = []
	for ch in n.get_children():
		var mi := ch as MeshInstance3D
		if mi == null or mi.get_child_count() > 0:
			continue
		var m := mi.material_override as StandardMaterial3D
		if m == null or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or m.emission_enabled or m.vertex_color_use_as_albedo:
			continue
		parts.append(mi)
	if parts.size() < 2:
		return
	if not _baked.has(key):
		var k := Scenery3D.Kit.new()
		for mi in parts:
			var arr := mi.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var ids: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var c := (mi.material_override as StandardMaterial3D).albedo_color
			var base := k.v.size()
			var xf3 := mi.transform
			for vi in verts.size():
				k.v.append(xf3 * verts[vi])
				k.n.append((xf3.basis * norms[vi]).normalized())
				k.c.append(c)
			if ids.is_empty():
				for vi in verts.size():
					k.idx.append(base + vi)
			else:
				for id in ids:
					k.idx.append(base + id)
		_baked[key] = k.mesh()
	if _ent_mat == null:
		_ent_mat = StandardMaterial3D.new()
		_ent_mat.vertex_color_use_as_albedo = true
		_ent_mat.vertex_color_is_srgb = true
		_ent_mat.roughness = 0.9
	for mi in parts:
		n.remove_child(mi)
		mi.free()
	var one := MeshInstance3D.new()
	one.mesh = _baked[key]
	one.material_override = _ent_mat
	n.add_child(one)


func _lights(n: Node3D, x: float, y: float, z: float) -> void:
	for sz in ([-1.0, 1.0] if z > 0.0 else [0.0]):
		box(Vector3(0.04, 0.08, 0.1), Color("fff3b0"), Vector3(x, y, sz * z), n, Vector3.ZERO, true)


# ------------------------------------------------------------------ predators

func _build_pred(_l: Lane, p: Dictionary) -> Node3D:
	var hz := Content.hazard(String(p.hazard))
	var cl: Dictionary = hz.get("art", {}).get("colors", {})
	var n := Node3D.new()
	var md := Models3D.model_def(String(p.hazard), String(hz.get("art", {}).get("painter", "")))
	match String(p.kind):
		"surfacer" when not md.is_empty():
			# the detailed crocodile lunges up out of the water, nose first
			var head := Node3D.new()
			head.name = "Head"
			n.add_child(head)
			var upper := Node3D.new()
			upper.name = "Upper"
			head.add_child(upper)
			var croc := Models3D.creature(md, float(p.get("span", 1.2)) * 1.9)
			croc.rotation_degrees.z = 28.0
			croc.position = Vector3(-0.35, -0.2, 0)
			head.add_child(croc)
			var ring0 := torus(0.3, 0.38, Color(1, 1, 1, 0.6), Vector3.ZERO, n)
			ring0.name = "Ring"
		"striker" when not md.is_empty():
			# a detailed snake (or tiger) waiting at its spot; it lunges along the lane
			var tiger0 := String(hz.get("art", {}).get("painter", "")) == "tiger"
			var beast := Models3D.creature(md, 1.3 if tiger0 else 0.7)
			beast.name = "Head"
			n.add_child(beast)
			var strike0 := Node3D.new()
			strike0.name = "Strike"
			n.add_child(strike0)
			n.set_meta("lunge", true)
		"surfacer":
			var head := Node3D.new()
			head.name = "Head"
			n.add_child(head)
			var span := float(p.get("span", 1.2))
			var upper := Node3D.new()
			upper.name = "Upper"
			upper.position = Vector3(-span * 0.5, 0.08, 0)
			head.add_child(upper)
			Models3D.croc_head(head, span, cl)
			var ring := torus(0.3, 0.38, Color(1, 1, 1, 0.6), Vector3.ZERO, n)
			ring.name = "Ring"
		"striker":
			var tiger := String(hz.get("art", {}).get("painter", "")) == "tiger"
			if tiger:
				for k in 5:
					cyl(0.06, 0.7, Color("8a9a4a").darkened(0.1 * (k % 3)), Vector3(-0.3 + k * 0.15, 0.35, sin(k * 1.7) * 0.2), n, Vector3.ZERO, 0.0)
			else:
				torus(0.12, 0.26, hc(cl, "body"), Vector3(0, 0.08, 0), n)
			var strike := Node3D.new()
			strike.name = "Strike"
			n.add_child(strike)
			if tiger:
				sph(0.3, hc(cl, "body"), Vector3(0, 0.35, 0), strike, Vector3(2.0, 1.0, 1.0))
			else:
				sph(0.12, hc(cl, "body"), Vector3(0, 0.15, 0), strike, Vector3(4.0, 1.0, 1.0))
			var head2 := sph(0.13, hc(cl, "body").darkened(0.1), Vector3(0, 0.28, 0), n)
			head2.name = "Head"
		"faller":
			var sh := cyl(0.4, 0.01, Color(0, 0, 0, 0.35), Vector3(0, 0.01, 0), n)
			sh.name = "Shadow"
			var drop := Node3D.new()
			drop.name = "Drop"
			n.add_child(drop)
			if String(hz.get("art", {}).get("painter", "")) == "fruit_fall":
				sph(0.22, hc(cl, "body"), Vector3.ZERO, drop)
			else:
				cyl(0.08, 0.9, hc(cl, "body"), Vector3.ZERO, drop, Vector3(0, 0, 90))
				sph(0.2, hc(cl, "leaf", "#4a9a3a"), Vector3(0.35, 0.05, 0), drop, Vector3(1.3, 0.6, 1.0))
	return n


func _place_pred(n: Node3D, l: Lane, p: Dictionary) -> void:
	var st := l.pred_state(p, sim.vt)
	var k := float(st[1])
	match String(p.kind):
		"surfacer":
			n.position = Vector3(float(p.x), 0.0, -l.row)
			var head: Node3D = n.get_node("Head")
			var ring: Node3D = n.get_node("Ring")
			ring.visible = st[0] == "warn"
			ring.scale = Vector3.ONE * (0.6 + k * 1.5)
			head.visible = st[0] == "active"
			if st[0] == "active":
				var rise := sin(minf(1.0, k * 3.0) * PI * 0.5)
				head.position.y = -0.3 + rise * 0.32
				(head.get_node("Upper") as Node3D).rotation_degrees.z = -sin(minf(1.0, k) * PI) * 35.0
		"striker" when n.has_meta("lunge"):
			n.position = Vector3(int(p.col) + 0.5, 0.0, -l.row)
			var beast: Node3D = n.get_node("Head")
			var hidden2 := bool(p.get("hidden", false))
			beast.visible = not hidden2 or st[0] in ["warn", "active"]
			beast.rotation_degrees.y = 0.0 if int(p.dir) > 0 else 180.0
			beast.position = Vector3.ZERO
			beast.scale = Vector3.ONE
			if st[0] == "warn":
				# rears up, quivering
				beast.position.y = sin(t * 40.0) * 0.01 + k * 0.05
				beast.scale = Vector3(1.0, 1.0 + k * 0.25, 1.0)
			elif st[0] == "active":
				var ext2 := sin(minf(1.0, k) * PI) * float(p.span)
				beast.position.x = int(p.dir) * ext2 * 0.6
		"striker":
			var col := int(p.col)
			n.position = Vector3(col + 0.5, 0.0, -l.row)
			var hidden := bool(p.get("hidden", false))
			var strike: Node3D = n.get_node("Strike")
			var head2: Node3D = n.get_node("Head")
			head2.visible = not hidden or st[0] == "warn"
			head2.position.y = 0.28 + (sin(t * 40.0) * 0.03 + k * 0.12 if st[0] == "warn" else 0.0)
			strike.visible = st[0] == "active"
			if st[0] == "active":
				var ext := sin(minf(1.0, k) * PI) * float(p.span)
				strike.position.x = int(p.dir) * ext * 0.5
				strike.scale = Vector3(maxf(0.2, ext), 1.0, 1.0)
		"faller":
			n.position = Vector3(int(p.col) + 0.5, 0.0, -l.row)
			var sh: Node3D = n.get_node("Shadow")
			var drop: Node3D = n.get_node("Drop")
			sh.visible = st[0] in ["warn", "active"]
			sh.scale = Vector3.ONE * (0.4 + (k if st[0] == "warn" else 1.0) * 0.8)
			drop.visible = st[0] == "active" or st[0] == "warn"
			if st[0] == "warn":
				drop.position = Vector3(sin(t * 30.0) * 0.03, 2.6, 0)
			else:
				drop.position = Vector3(0, lerpf(2.6, 0.12, minf(1.0, k * 3.0)), 0)


func _update_swoops(lo: int, hi: int) -> void:
	var w := sim.world
	var seen := {}
	for i in w.swoopers.size():
		var s: Dictionary = w.swoopers[i]
		if int(s.hi) < lo or int(s.lo) > hi:
			continue
		seen[i] = true
		var n: Node3D = _swoops.get(i)
		if n == null:
			n = Node3D.new()
			world3.add_child(n)
			var hz := Content.hazard(String(s.hazard))
			var cl: Dictionary = hz.get("art", {}).get("colors", {})
			var bird := Node3D.new()
			bird.name = "Bird"
			n.add_child(bird)
			var bmd := Models3D.model_def(String(s.hazard), String(hz.get("art", {}).get("painter", "")))
			if not bmd.is_empty():
				# a detailed eagle gliding in, wings spread
				bird.add_child(Models3D.creature(bmd, 1.9))
			else:
				box(Vector3(1.6, 0.04, 0.4), hc(cl, "wing", "#2a2a30"), Vector3.ZERO, bird)
				sph(0.16, hc(cl, "body", "#55565e"), Vector3(0, 0.02, 0), bird, Vector3(1.0, 0.8, 2.0))
			var sh := cyl(0.5, 0.01, Color(0, 0, 0, 0.35), Vector3.ZERO, n)
			sh.name = "Shadow"
			_swoops[i] = n
		var st := w.pred_state(s, sim.vt)
		var col := w.swoop_col(s, sim.vt)
		var bird2: Node3D = n.get_node("Bird")
		var sh2: Node3D = n.get_node("Shadow")
		n.position = Vector3(col + 0.5, 0, 0)
		bird2.visible = st[0] == "active"
		sh2.visible = st[0] in ["warn", "active"]
		var k := float(st[1])
		if st[0] == "warn":
			sh2.position = Vector3(0, 0.02, -float(s.hi))
			sh2.scale = Vector3.ONE * (0.5 + k)
		elif st[0] == "active":
			var z := -lerpf(float(s.hi), float(s.lo), k)
			bird2.position = Vector3(0, lerpf(2.4, 0.5, minf(1.0, k * 2.0)), z)
			sh2.position = Vector3(0, 0.02, z)
	for k2 in _swoops.keys():
		if not seen.has(k2):
			_swoops[k2].queue_free()
			_swoops.erase(k2)


# ------------------------------------------------------------------ items

func _build_item(id: String) -> Node3D:
	var def := Content.collectible(id)
	var cl: Dictionary = def.get("art", {}).get("colors", {})
	var n := Node3D.new()
	match String(def.get("art", {}).get("painter", "")):
		"berry":
			for k in 3:
				sph(0.08, Color("e8343a").darkened(0.1 * k), Vector3(-0.06 + k * 0.06, (k % 2) * 0.06, 0), n)
		"beetle":
			sph(0.1, hc(cl, "body"), Vector3.ZERO, n, Vector3(1.0, 0.7, 1.4))
		"fruit":
			sph(0.13, hc(cl, "body"), Vector3.ZERO, n)
		"amber":
			box(Vector3(0.18, 0.18, 0.18), hc(cl, "body"), Vector3.ZERO, n, Vector3(45, 0, 45), true)
		_:
			sph(0.11, hc(cl, "body", "#6a4a32"), Vector3.ZERO, n)
	return n
