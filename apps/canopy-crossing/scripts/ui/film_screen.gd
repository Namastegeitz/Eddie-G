extends Control
## "The Bee and the Giraffe": a short film on a jungle trade road. Scarlet
## macaws fly over a honeybee working a hibiscus; the camera zooms into the
## bee in slow motion, follows it up past a giraffe's eye, and the annoyed
## giraffe swings its neck at a kangaroo, which leaps clear by a whisker.
## Plays from the home screen (Skip button) and renders to a video file
## with tools/render_film.sh.
##
## Two clocks: `T` is real time (cameras, cuts, captions) and each shot's
## `story` time runs slower in slow motion (wings, hops, the swing).

const DUR := 28.0
const SHOTS := [0.0, 5.0, 11.0, 16.0, 22.0, DUR]
const G := Vector3(2.0, 0.0, -3.4)          # the giraffe stands here, facing +X
const F := Vector3(-1.2, 0.0, -3.0)         # the hibiscus
const K := Vector3(5.0, 0.0, -2.85)         # the kangaroo grazes here, under the giraffe's chin
const GH := 4.6                             # giraffe height (m)

var movie := false                          # rendering to a file: no skip button, quit at the end
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var env: Environment
var giraffe: Node3D
var roo: Node3D
var mob: Array[Node3D] = []
var flock: Node3D
var bee: Node3D
var bloom: Node3D
var jeep: Node3D
var truck: Node3D
var T := 0.0
var story := 0.0
var speed := 1.0
var shot := -1
var _bee_from := Vector3.ZERO
var _eye0 := Vector3.ZERO
var _roo_h := 1.0
var _cap: Label
var _tag: Label
var _title: Label
var _sub: Label
var _fade: ColorRect
var _bars: Array[ColorRect] = []
var _buzz: AudioStreamPlayer
var _hopped := false
var _swung := false


var _seek := 0.0
var stay := false                           # tests: don't leave the screen at the end
var done := false


func setup(args: Dictionary) -> void:
	movie = bool(args.get("movie", false))
	_seek = float(args.get("seek", 0.0))
	stay = bool(args.get("stay", false))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := SubViewportContainer.new()
	box.stretch = true
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	vp = SubViewport.new()
	vp.own_world_3d = true
	# the video renders on a software GPU where MSAA costs 5x: FXAA instead
	vp.msaa_3d = Viewport.MSAA_DISABLED if movie else Gfx.msaa_3d()
	if movie:
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	box.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	_build_world()
	_build_cast()
	_build_overlay()
	_buzz = AudioStreamPlayer.new()
	_buzz.stream = _buzz_sound()
	_buzz.volume_db = -60.0
	add_child(_buzz)
	_buzz.play()
	Sfx.music(Sfx.MENU_CALM)
	_cut(0)
	_step(0.0)
	while T + 1.0 / 30.0 < _seek:
		_step(1.0 / 30.0)


func _unhandled_input(ev: InputEvent) -> void:
	# the phone's back gesture (or Esc) leaves, like the Skip button
	if not movie and ev.is_action_pressed("ui_cancel"):
		_finish()


func _finish() -> void:
	done = true
	if stay:
		set_process(false)
		return
	if movie:
		get_tree().quit()
		return
	Game.goto("home", {}, false)


func _process(dt: float) -> void:
	_step(dt)


func _step(dt: float) -> void:
	if done:
		return
	T += dt
	if T >= DUR:
		_finish()
		return
	var s := 0
	for i in range(SHOTS.size() - 1):
		if T >= SHOTS[i]:
			s = i
	if s != shot:
		_cut(s)
	var u := T - float(SHOTS[s])
	speed = _speed(s, u)
	story += dt * speed
	match s:
		0: _shot_road(u)
		1: _shot_bee(u)
		2: _shot_flight(u)
		3: _shot_swing(u)
		4: _shot_away(u)
	_overlay(s, u)
	_sound()


# ------------------------------------------------------------------ the set

func _build_world() -> void:
	env = Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("3d7ec8")
	sky_mat.sky_horizon_color = Color("cfe2d8")
	sky_mat.ground_horizon_color = Color("b8cfa8")
	sky_mat.ground_bottom_color = Color("2a4a22")
	sky_mat.sun_angle_max = 12.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.tonemap_white = 6.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("c8dccf")
	env.fog_density = 0.008
	env.fog_sun_scatter = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -52, 0)
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.75
	sun.directional_shadow_max_distance = 40.0
	world.add_child(sun)
	cam = Camera3D.new()
	cam.far = 260.0
	world.add_child(cam)
	cam.current = true
	# the ground: meadow grass, and a red-dirt trade road along X
	var grass_mat := _noise_mat([Color("3a6a22"), Color("6a9a32")], 0.3, 0.035)
	_plane(Vector2(220, 220), Vector3(0, 0, 0), grass_mat)
	var dirt := Color("9a6440")
	_plane(Vector2(220, 4.2), Vector3(0, 0.006, 0), _noise_mat([dirt.darkened(0.15), dirt.lightened(0.12)], 0.5, 0.06))
	for z in [-0.75, 0.75]:
		_plane(Vector2(220, 0.42), Vector3(0, 0.009, z), _noise_mat([dirt.darkened(0.35), dirt.darkened(0.15)], 0.8, 0.08))
	_plane(Vector2(220, 0.35), Vector3(0, 0.008, 0), _noise_mat([Color("6a7a3a"), Color("8a8a4a")], 0.8, 0.08))
	_grass()
	# jungle edge: big trees, palms, ferns and undergrowth on both sides
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var kinds := [["scene_giant_tree", 17.0], ["scene_strangler_fig", 13.0], ["scene_palm", 9.0], ["scene_bamboo", 7.0], ["scene_tree_fern", 4.5], ["scene_undergrowth", 2.6]]
	for side in [-1.0, 1.0]:
		var x := -60.0
		while x < 70.0:
			var kd: Array = kinds[rng.randi() % kinds.size()]
			# kept clear of where the cameras stand
			var z: float = -rng.randf_range(12.0, 19.0) if side < 0.0 else rng.randf_range(17.0, 26.0)
			_model(String(kd[0]), float(kd[1]) * rng.randf_range(0.85, 1.2), Vector3(x, 0, z), rng.randf() * TAU)
			x += rng.randf_range(3.0, 6.5)
	for i in 10:
		_model("scene_undergrowth", 2.4, Vector3(-30.0 + i * 7.0, 0, -9.0 - rng.randf() * 2.0), rng.randf() * TAU)
	# plants by the flower, and the hibiscus itself
	_model("scene_heliconia", 1.7, F + Vector3(-1.1, 0, -0.9), 0.4)
	_model("scene_bromeliad", 0.6, F + Vector3(0.6, 0, -0.5), 1.1)
	_model("scene_monstera", 1.4, F + Vector3(-2.2, 0, 0.6), 2.0)
	_model("scene_fern", 0.9, G + Vector3(-1.4, 0, -1.4), 0.5)
	var fl := Critters3D.flower(1.25)
	fl.position = F
	world.add_child(fl)
	bloom = fl.get_node("Bloom")
	for i in 3:
		var f2 := Critters3D.flower(1.0 + i * 0.12)
		f2.position = F + Vector3(-0.5 - i * 0.35, 0, -0.4 + i * 0.25)
		f2.rotation.y = 0.6 + i * 0.9
		world.add_child(f2)
	# goods by the road: crates of fruit, sacks, barrels, a market stall
	_goods(Vector3(-7.0, 0, 3.0))
	_stall(Vector3(-13.0, 0, 3.3))
	_goods(Vector3(16.0, 0, -2.9))
	var sign := Label3D.new()
	sign.text = "MARKET 2 km  ›"
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.outline_size = 12
	sign.modulate = Color("fff6d8")
	sign.outline_modulate = Color("3a2412")
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = Vector3(-4.0, 1.9, 2.7)
	world.add_child(sign)
	_mesh_box(Vector3(0.08, 1.9, 0.08), Color("6a4a2a"), Vector3(-4.0, 0.95, 2.72))
	_mesh_box(Vector3(1.9, 0.36, 0.05), Color("8a6038"), Vector3(-4.0, 1.9, 2.66))


func _noise_mat(cols: Array, scale: float, freq: float) -> StandardMaterial3D:
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.frequency = freq
	fn.fractal_octaves = 5
	tex.noise = fn
	var ramp := Gradient.new()
	ramp.set_color(0, cols[0])
	ramp.set_color(1, cols[1])
	tex.color_ramp = ramp
	var nm := NoiseTexture2D.new()
	nm.width = 256
	nm.height = 256
	nm.seamless = true
	nm.as_normal_map = true
	nm.bump_strength = 6.0
	nm.generate_mipmaps = true
	var fn2 := FastNoiseLite.new()
	fn2.frequency = 0.09
	nm.noise = fn2
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.normal_enabled = true
	m.normal_texture = nm
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


func _plane(size: Vector2, pos: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = m
	mi.position = pos
	world.add_child(mi)


func _mesh_box(size: Vector3, c: Color, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	world.add_child(mi)
	return mi


func _ball(r: float, c: Color, pos: Vector3, sc := Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	mi.material_override = m
	mi.position = pos
	mi.scale = sc
	world.add_child(mi)


func _model(id: String, h: float, pos: Vector3, yaw: float) -> void:
	if not Models3D.has_model(id):
		return
	var mi := Scenery3D.model_node({"model": id, "height": h, "pos": pos, "yaw": yaw})
	if mi.mesh != null:
		world.add_child(mi)


## Meadow grass on the verges, thick around where the action happens.
func _grass() -> void:
	var k := Scenery3D.Kit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var n := 0
	while n < 5200:
		var p := Vector3(rng.randf_range(-14.0, 22.0), 0, rng.randf_range(-9.0, 7.0))
		if absf(p.z) < 2.2 and absf(p.z) > 0.25:
			continue
		var near := p.distance_to(F) < 3.0 or p.distance_to(G) < 3.5 or p.distance_to(K) < 2.5
		if not near and rng.randf() < 0.55:
			continue
		var tall := rng.randf_range(0.18, 0.5) * (0.6 if absf(p.z) < 0.3 else 1.0)
		k.blade(Scenery3D.xf(p, rng.randf() * TAU, rng.randf_range(-1.45, -1.15)), tall, 0.035, Color("2a5a1a"), Color("9ab84a").lerp(Color("c8b860"), rng.randf() * 0.4), 0.35, 3)
		n += 1
	var mi := MeshInstance3D.new()
	mi.mesh = k.mesh()
	mi.material_override = Scenery3D.material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)


func _goods(at: Vector3) -> void:
	var wood := Color("8a6038")
	for i in 3:
		_mesh_box(Vector3(0.6, 0.45, 0.5), wood.darkened(0.08 * i), at + Vector3(i * 0.62 - 0.6, 0.225 + (0.45 if i == 2 else 0.0), (i % 2) * 0.1), Vector3(0, i * 9.0, 0))
	for f in 9:
		_ball(0.07, [Color("f2a83a"), Color("e8442a"), Color("f6d43a")][f % 3], at + Vector3(-0.6 + (f % 3) * 0.12, 0.5, -0.12 + (f / 3) * 0.12))
	for s in 3:
		_ball(0.26, Color("c8b07a").darkened(0.05 * s), at + Vector3(1.2 + s * 0.45, 0.24, 0.5), Vector3(1.0, 0.85, 1.25))


func _stall(at: Vector3) -> void:
	var wood := Color("7a5030")
	for px in [-0.9, 0.9]:
		for pz in [-0.7, 0.7]:
			_mesh_box(Vector3(0.07, 2.1, 0.07), wood, at + Vector3(px, 1.05, pz))
	for s in 7:
		_mesh_box(Vector3(0.3, 0.04, 1.7), [Color("d8442a"), Color("f2e2b0")][s % 2], at + Vector3(-0.9 + s * 0.3, 2.12, 0), Vector3(-8, 0, 0))
	_mesh_box(Vector3(1.9, 0.08, 1.4), wood.lightened(0.2), at + Vector3(0, 0.95, 0))
	for f in 14:
		_ball(0.08, [Color("f2a83a"), Color("7ac03a"), Color("e8442a"), Color("f6d43a")][f % 4], at + Vector3(-0.7 + (f % 7) * 0.22, 1.05, -0.3 + (f / 7) * 0.5))


# ------------------------------------------------------------------ the cast

func _build_cast() -> void:
	giraffe = Critters3D.giraffe(GH)
	giraffe.position = G
	world.add_child(giraffe)
	var md: Dictionary = Content.models.get("hazards", {}).get("kangaroo_mob", {})
	roo = _kangaroo(md)
	for i in 3:
		mob.append(_kangaroo(md))
	flock = Node3D.new()
	world.add_child(flock)
	for i in 6:
		var bd := Critters3D.bird(1.0) if i % 3 != 1 else Critters3D.bird(0.95, Color("1f6fd0"), Color("2a8ad8"), Color("173a8a"))
		bd.position = Vector3(-i * 1.3 - (i % 2) * 0.5, (i % 3) * 0.5, (i - 2.5) * 1.1)
		bd.set_meta("phase", i * 1.7)
		flock.add_child(bd)
	bee = Critters3D.bee(0.045)
	world.add_child(bee)
	var jd: Dictionary = Content.models.get("painters", {}).get("jeep", {})
	if not jd.is_empty() and Models3D.has_model(String(jd.get("model", ""))):
		jeep = Models3D.creature(jd, 4.0)
		world.add_child(jeep)
	var td: Dictionary = Content.models.get("painters", {}).get("truck", {})
	if not td.is_empty() and Models3D.has_model(String(td.get("model", ""))):
		truck = Models3D.creature(td, 7.0)
		world.add_child(truck)


func _kangaroo(md: Dictionary) -> Node3D:
	var n: Node3D
	if not md.is_empty() and Models3D.has_model(String(md.get("model", ""))):
		n = Models3D.creature(md, 1.5)
		_roo_h = float(n.get_meta("height", 1.1))
		n.scale = Vector3.ONE * (1.55 / maxf(0.1, _roo_h))
	else:
		n = Node3D.new()
		var b := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.25
		cm.height = 1.2
		b.mesh = cm
		b.position.y = 0.6
		n.add_child(b)
	var holder := Node3D.new()
	holder.add_child(n)
	world.add_child(holder)
	return holder


## A kangaroo's bound at phase `ph` (0..1): height off the ground and nose tilt.
func _bound(ph: float, height: float) -> Vector2:
	var air := clampf(ph / 0.78, 0.0, 1.0)
	if ph >= 0.78:
		return Vector2(0.0, 0.0)
	return Vector2(4.0 * air * (1.0 - air) * height, (0.5 - air) * 0.5)


func _place_roo(n: Node3D, pos: Vector3, dir: Vector3, lift: Vector2) -> void:
	n.position = pos + Vector3(0, lift.x, 0)
	n.rotation = Vector3(0, atan2(-dir.z, dir.x), lift.y)


func _bee_at(p: Vector3, face: Vector3) -> void:
	bee.position = p
	if face.length() > 0.0001:
		bee.rotation = Vector3(0, atan2(-face.z, face.x), clampf(face.normalized().y, -0.6, 0.6))
	Critters3D.bee_beat(bee, story)


func _eye() -> Vector3:
	var head: Node3D = giraffe.get_node("Neck/Head")
	return head.global_transform * (Vector3(0.13, 0.045, 0.088) * (GH / 3.0))


func _look(from: Vector3, at: Vector3, fov: float, near := 0.05) -> void:
	cam.position = from
	cam.near = near
	if from.distance_to(at) > 0.0001:
		cam.look_at(at, Vector3.UP)
	# a portrait phone keeps the subject (always in the middle) about as big
	# as in the landscape film, losing a little at the sides
	var aspect := size.x / maxf(1.0, size.y)
	cam.keep_aspect = Camera3D.KEEP_HEIGHT if aspect >= 1.0 else Camera3D.KEEP_WIDTH
	cam.fov = fov if aspect >= 1.0 else minf(fov * 1.3, 100.0)


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _bez(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t


# ------------------------------------------------------------------ shots

func _cut(s: int) -> void:
	shot = s
	story = 0.0
	_hopped = false
	_swung = false
	if s == 2:
		_bee_from = bee.position
		_eye0 = _eye()
	# the vehicles only drive through the wide shots
	for v in [jeep, truck]:
		if v:
			v.visible = s == 0 or s == 4
			v.position = Vector3(-200, 0, 0)


## How fast story time runs in each shot (slow motion where it matters).
func _speed(s: int, u: float) -> float:
	match s:
		1:
			return lerpf(1.0, 0.08, _ease((u - 2.6) / 1.4))
		2:
			return 0.5 if u < 3.2 else 0.3
		3:
			if u < 0.8:
				return 1.0
			if u < 1.3:
				return lerpf(1.0, 0.12, _ease((u - 0.8) / 0.5))
			if u < 4.2:
				return 0.12
			return lerpf(0.12, 1.0, _ease((u - 4.2) / 0.8))
	return 1.0


## The trade road: a jeep and a logging truck hauling goods, kangaroos
## bounding down the road, a giraffe ambling at the edge, macaws overhead.
func _shot_road(u: float) -> void:
	var k := _ease(u / 5.0)
	_look(Vector3(-9.0, 5.6, 9.5).lerp(Vector3(-5.0, 2.8, 7.2), k), Vector3(3.0, 1.8, -2.0).lerp(Vector3(2.0, 2.4, -2.4), k), 50.0)
	if jeep:
		jeep.position = Vector3(-30.0 + story * 9.0, 0.0, 0.85)
		jeep.rotation.y = 0.0
	if truck:
		truck.position = Vector3(26.0 - story * 6.0, 0.0, -0.9)
		truck.rotation.y = PI
	giraffe.position = G + Vector3(-1.6 + minf(story, 4.0) * 0.4, 0, 0)
	Critters3D.giraffe_walk(giraffe, story, maxf(0.0, 1.0 - story / 4.0))
	Critters3D.giraffe_swing(giraffe, sin(story * 0.8) * 0.15, story)
	_mob(story, Vector3(22.0, 0, 0.6), -1.0)
	_place_roo(roo, K, Vector3(1, 0, 0.3), Vector2(0.0, 0.0))
	_flock_at(Vector3(-22.0 + story * 6.0, 9.0, -5.0), 1.0)
	_bee_at(_bee_hover(story), Vector3(1, 0, 0))


## Macaws over a honeybee; the camera tilts down to the bee and zooms in
## as time slows to a crawl.
func _shot_bee(u: float) -> void:
	giraffe.position = G
	Critters3D.giraffe_walk(giraffe, 0.0, 0.0)
	Critters3D.giraffe_swing(giraffe, sin(story * 0.8) * 0.12, story)
	_mob(story + 5.0, Vector3(22.0, 0, 0.6), -1.0)
	_place_roo(roo, K, Vector3(1, 0, 0.3), _bound(fposmod(story * 0.6, 1.0), 0.12))
	_flock_at(Vector3(-14.0 + story * 6.5, 6.2, -3.4), 1.0)
	var bp := _bee_hover(story)
	_bee_at(bp, bloom.global_position - bp)
	var cam_low := Vector3(-3.4, 0.9, 0.2)
	var sky_target := flock.position + Vector3(-2.0, 0.0, 0.0)
	var tilt := _ease((u - 1.6) / 1.5)
	var target := sky_target.lerp(bp, tilt)
	var zoom := _ease((u - 2.4) / 3.0)
	# in close to the bee's side, swinging round towards its face
	var fwd := (bloom.global_position - bp)
	fwd = Vector3(fwd.x, 0.0, fwd.z).normalized()
	var side_v := fwd.cross(Vector3.UP).normalized()
	var ang := lerpf(0.2, 0.85, _ease((u - 3.5) / 2.5))
	var close := bp + (side_v * cos(ang) + fwd * sin(ang)) * 0.12 + Vector3(0, 0.022, 0)
	var from := cam_low.lerp(close, zoom)
	_look(from, target, lerpf(56.0, 30.0, zoom), lerpf(0.05, 0.004, zoom))


func _bee_hover(st: float) -> Vector3:
	var c := bloom.global_position + bloom.global_transform.basis.y.normalized() * 0.075 + Vector3(-0.02, 0.04, 0.03)
	return c + Vector3(sin(st * 2.3) * 0.02, sin(st * 3.7) * 0.012, cos(st * 1.9) * 0.018)


## The bee lifts off and climbs, the camera riding alongside, then it zips
## right past the giraffe's eye.
func _shot_flight(u: float) -> void:
	giraffe.position = G
	Critters3D.giraffe_swing(giraffe, sin(story * 0.8) * 0.06, story)
	_place_roo(roo, K, Vector3(1, 0, 0.3), _bound(fposmod(story * 0.6 + 0.3, 1.0), 0.12))
	_flock_at(Vector3(-6.0 + story * 6.5, 6.6, -2.0), 1.0)
	var eye := _eye0
	var a := _bee_from
	var b := a + Vector3(0.9, 1.3, 0.7)
	var c := eye + Vector3(-1.5, -0.5, 0.9)
	var d := eye + Vector3(0.05, 0.03, 0.22)
	var p := clampf(story / 1.6, 0.0, 1.0)
	var pos := _bez(a, b, c, d, _ease(p) * 0.3 + p * 0.7)
	if story > 1.6:
		pos = d.lerp(eye + Vector3(1.6, 0.25, 0.55), clampf((story - 1.6) / 0.7, 0.0, 1.0))
	var ahead := _bez(a, b, c, d, minf(1.0, p + 0.04)) - pos if story <= 1.6 else Vector3(1, 0.1, 0.2)
	_bee_at(pos, ahead)
	if u < 3.2:
		# riding alongside, a little behind and to the right
		var dir := ahead.normalized() if ahead.length() > 0.001 else Vector3.RIGHT
		var side := dir.cross(Vector3.UP).normalized()
		_look(pos - dir * 0.22 + side * 0.16 + Vector3(0, 0.05, 0), pos + dir * 0.06, 42.0, 0.005)
	else:
		# the giraffe's eye, close up: the bee crosses right in front of it
		var head: Node3D = giraffe.get_node("Neck/Head")
		head.rotation.y = lerpf(0.0, 0.25, _ease((u - 4.2) / 0.8))
		_look(eye + Vector3(0.75, 0.12, 1.25), eye + Vector3(0.05, 0.0, 0.15), 34.0, 0.02)


## The giraffe swings its long neck at the kangaroo, which leaps clear,
## missed by a whisker (in slow motion). Seen face-on, so the swing runs
## across the frame.
const LEAP_AT := 1.08
const LEAP_LEN := 0.85
const LEAP_TO := Vector3(1.2, 0.0, 2.6)       # from K
var _closest := 99.0


func _swing_pose(st: float) -> Vector2:
	# rears its head back, hammers it down and across, then recovers
	if st < 0.75:
		var k0 := _ease(st / 0.75)
		return Vector2(0.35 * k0, -0.45 * k0)
	if st < 1.3:
		var k := (st - 0.75) / 0.55
		k = k * k * 0.6 + k * 0.4
		return Vector2(lerpf(0.35, -0.5, k), lerpf(-0.45, 2.2, k))
	var k2 := _ease((st - 1.3) / 1.4)
	return Vector2(lerpf(-0.5, 0.0, k2), lerpf(2.2, 0.0, k2))


func _roo_story(st: float) -> void:
	var to := K + LEAP_TO
	if st < LEAP_AT:
		_place_roo(roo, K, Vector3(0.2, 0, 1), _bound(fposmod(st * 1.4, 1.0), 0.1))
	elif st < LEAP_AT + LEAP_LEN:
		var lk := (st - LEAP_AT) / LEAP_LEN
		_place_roo(roo, K.lerp(to, lk), LEAP_TO, Vector2(4.0 * lk * (1.0 - lk) * 1.35, (0.5 - lk) * 0.6))
	else:
		# landed on the road: turns and bounds off down it, away from the camera
		var run := st - LEAP_AT - LEAP_LEN
		var turn := minf(run / 0.4, 1.0)
		var dir := LEAP_TO.normalized().lerp(Vector3(-1, 0, 0), turn)
		_place_roo(roo, to + Vector3(-run * 5.0 * turn, 0, run * 0.6 * (1.0 - turn)), dir, _bound(fposmod(run * 1.6, 1.0), 0.7))


## How close the giraffe's head (eye or nose) is to the kangaroo (body or
## tail), in metres.
func near_miss() -> float:
	var head: Node3D = giraffe.get_node("Neck/Head")
	var nose: Vector3 = head.global_transform * (Vector3(0.42, -0.04, 0) * (GH / 3.0))
	var fwd := Vector3(cos(roo.rotation.y), 0, -sin(roo.rotation.y))
	var body := roo.global_position + Vector3(0, 0.75, 0)
	var tail := roo.global_position + Vector3(0, 0.35, 0) - fwd * 0.7
	var eye := _eye()
	return minf(minf(eye.distance_to(body), nose.distance_to(body)), minf(eye.distance_to(tail), nose.distance_to(tail)))


func _shot_swing(u: float) -> void:
	giraffe.position = G
	var head: Node3D = giraffe.get_node("Neck/Head")
	head.rotation.y = 0.0
	var st := story
	var pose := _swing_pose(st)
	Critters3D.giraffe_swing(giraffe, pose.y, st, pose.x)
	if st >= 0.75 and not _swung:
		_swung = true
		Sfx.play("ability", 0.55, -4.0)
	_roo_story(st)
	if st >= LEAP_AT and not _hopped:
		_hopped = true
		Sfx.play("hop", 0.7, -2.0)
	if OS.has_environment("FILM_DEBUG"):
		var d := near_miss()
		if d < _closest:
			_closest = d
			print("closest %.2f at story %.2f u %.2f roo %s" % [d, st, u, roo.global_position])
	_mob(story + 9.0, Vector3(30.0, 0, 0.6), -1.0)
	_flock_at(Vector3(-4.0 + story * 6.5, 8.5, -6.0), 1.0)
	_bee_at(_eye0 + Vector3(1.6 + story * 0.8, 0.3 + sin(story * 3.0) * 0.1, 0.8), Vector3(1, 0, 0.3))
	var push := _ease(u / 6.0)
	_look(Vector3(8.0, 1.9, 4.8).lerp(Vector3(7.3, 1.8, 4.1), push), Vector3(4.3, 1.9, -2.4), 42.0)


## Away it goes: the camera rides behind the kangaroo as it bounds off down
## the trade road towards the market, the mob ahead, macaws overhead; then
## the title comes up.
func _shot_away(u: float) -> void:
	giraffe.position = G
	var calm := maxf(0.0, 1.0 - story / 2.0)
	Critters3D.giraffe_swing(giraffe, sin(story * 4.0) * 0.12 * calm, story, sin(story * 5.0) * 0.15 * calm)
	var start := K + LEAP_TO + Vector3(-3.0, 0, 0)
	var pos := start + Vector3(-story * 5.0, 0, -minf(story, 1.0) * 0.4)
	_place_roo(roo, pos, Vector3(-1, 0, 0), _bound(fposmod(story * 1.6 + 0.3, 1.0), 0.7))
	_mob(story, pos + Vector3(-5.0, 0, -0.5), -1.0)
	_flock_at(Vector3(pos.x + 14.0 - story * 8.5, 6.5, -1.5), -1.0)
	if jeep:
		jeep.position = Vector3(pos.x - 60.0 + story * 9.0, 0.0, -0.9)
		jeep.rotation.y = 0.0
	_bee_at(pos + Vector3(2.2 + sin(story) * 0.3, 1.5 + sin(story * 2.0) * 0.15, 0.6), Vector3(-1, 0, 0))
	var back := lerpf(4.5, 6.5, _ease(u / 6.0))
	_look(pos + Vector3(back, 1.25, 0.9), pos + Vector3(-4.0, 1.0, -0.2), 50.0)


## The rest of the mob, bounding along the road in single file.
func _mob(st: float, from: Vector3, dirx: float) -> void:
	for i in mob.size():
		var x := from.x + dirx * (st * 5.0) - dirx * i * 2.6
		var pos := Vector3(x, 0, from.z + (i % 2) * 0.5)
		_place_roo(mob[i], pos, Vector3(dirx, 0, 0), _bound(fposmod(st * 1.6 + i * 0.37, 1.0), 0.65))


func _flock_at(p: Vector3, dir: float) -> void:
	flock.position = p
	flock.rotation.y = 0.0 if dir > 0.0 else PI
	for bd in flock.get_children():
		var ph := float(bd.get_meta("phase"))
		Critters3D.bird_flap(bd, story + ph)
		(bd as Node3D).rotation.z = sin(T * 1.3 + ph) * 0.08


# ------------------------------------------------------------------ titles and sound

func _build_overlay() -> void:
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_bars.append(bar)
	_title = UI.label("CANOPY CROSSING", 76, UI.ACCENT, true, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_constant_override("outline_size", 16)
	_title.add_theme_color_override("font_outline_color", Color("0a2012"))
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_sub = UI.label("", 34, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_sub.add_theme_constant_override("outline_size", 10)
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub)
	_cap = UI.label("", 30, Color.WHITE, false, HORIZONTAL_ALIGNMENT_CENTER)
	_cap.add_theme_constant_override("outline_size", 10)
	_cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cap)
	_tag = UI.label("", 24, Color("ffd23a"), true, HORIZONTAL_ALIGNMENT_LEFT)
	_tag.add_theme_constant_override("outline_size", 8)
	_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tag)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	if not movie:
		var skip := UI.button("Skip ›", _finish, Color(0, 0, 0, 0.45), 24, 64)
		skip.position = Vector2(0, 0)
		skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		skip.offset_left = -160
		skip.offset_top = UI.safe_top(self) + 20
		skip.offset_right = -20
		skip.offset_bottom = skip.offset_top + 64
		add_child(skip)


const CAPTIONS := [
	[0, 1.0, 4.4, "Goods on the move: a jungle trade road"],
	[1, 0.3, 2.4, "Scarlet macaws overhead…"],
	[1, 2.6, 5.8, "…and below them, a honeybee"],
	[2, 0.2, 3.0, "Ten times slower: every wingbeat"],
	[2, 3.3, 5.0, "Straight past a giraffe's eye"],
	[3, 0.3, 1.9, "The giraffe swings…"],
	[3, 2.2, 5.6, "…and the kangaroo leaps clear by a whisker!"],
	[4, 0.3, 2.3, "Off down the trade road, with the mob"],
]


func _overlay(s: int, u: float) -> void:
	var w := size.x
	var h := size.y
	var landscape := w > h * 1.2
	var bar_h := h * 0.1 if landscape else 0.0
	_bars[0].position = Vector2(0, 0)
	_bars[0].size = Vector2(w, bar_h)
	_bars[1].position = Vector2(0, h - bar_h)
	_bars[1].size = Vector2(w, bar_h)
	var text := ""
	var alpha := 0.0
	for c in CAPTIONS:
		if int(c[0]) == s and u >= float(c[1]) and u <= float(c[2]):
			text = String(c[3])
			alpha = minf(1.0, minf((u - float(c[1])) / 0.35, (float(c[2]) - u) / 0.35))
	_cap.text = text
	_cap.modulate.a = alpha
	_cap.size = Vector2(w - 80, 90)
	_cap.position = Vector2(40, h - bar_h - (110 if landscape else 260))
	var slow := speed < 0.6
	_tag.text = "● SLOW MOTION  ×%d" % int(round(1.0 / maxf(speed, 0.05))) if slow else ""
	_tag.position = Vector2(36, bar_h + 24 + (0 if landscape else UI.safe_top(self) + 80))
	_tag.modulate.a = 0.6 + 0.4 * absf(sin(T * 3.0))
	# the title at the start, and an end card
	var ta := 0.0
	if s == 0:
		ta = clampf(minf((u - 0.4) / 0.8, (4.6 - u) / 0.6), 0.0, 1.0)
	elif s == 4:
		ta = clampf((u - 2.6) / 0.8, 0.0, 1.0)
		_sub.text = "Giraffes · Kangaroos · Macaws\nNow on the trade roads"
	_title.modulate.a = ta
	_sub.modulate.a = ta if s == 4 else 0.0
	_title.position = Vector2((w - _title.size.x) * 0.5, h * 0.36 - _title.size.y * 0.5)
	_sub.size = Vector2(w - 80, 120)
	_sub.position = Vector2(40, h * 0.36 + 60)
	# fade in from black, dip between shots, fade out at the end
	var f := 0.0
	f = maxf(f, 1.0 - T / 0.8)
	f = maxf(f, (T - (DUR - 1.2)) / 1.2)
	if s > 0:
		f = maxf(f, 1.0 - u / 0.25)
	if s < SHOTS.size() - 2:
		f = maxf(f, 1.0 - (float(SHOTS[s + 1]) - float(SHOTS[s]) - u) / 0.25)
	_fade.color.a = clampf(f, 0.0, 1.0)
	if s == 4:
		_fade.color.a = maxf(_fade.color.a, clampf((u - 2.4) / 1.0, 0.0, 0.55))


## The bee's buzz: lower and slower in slow motion, louder up close.
func _sound() -> void:
	var d := cam.global_position.distance_to(bee.global_position)
	var vol := clampf(0.25 / (d + 0.12), 0.0, 1.0)
	_buzz.volume_db = linear_to_db(maxf(vol, 0.0005)) + _db_sfx()
	_buzz.pitch_scale = clampf(lerpf(0.42, 1.0, speed), 0.3, 1.2)


func _db_sfx() -> float:
	return linear_to_db(maxf(0.001, float(Save.setting("sfx", 0.9)))) - 4.0


static func _buzz_sound() -> AudioStreamWAV:
	var rate := 22050
	var n := rate
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var lp := 0.0
	for i in n:
		var t := float(i) / rate
		# 225 Hz wingbeat: a buzzy sawtooth with harmonics and a little rasp
		var ph := fposmod(t * 225.0, 1.0)
		var saw := ph * 2.0 - 1.0
		var tone := saw * 0.55 + sin(t * 450.0 * TAU) * 0.25 + sin(t * 675.0 * TAU) * 0.12
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.3
		var v := (tone + lp * 0.15) * (0.75 + 0.25 * sin(t * 6.0 * TAU))
		data.encode_s16(i * 2, int(clampf(v * 0.45, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w
