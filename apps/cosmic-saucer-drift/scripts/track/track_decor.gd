class_name TrackDecor
extends RefCounted
## Backdrop per theme: planets with orbiting moons, asteroid fields and
## belts, alien plants, ice crystals, station structures, lava ground, plus
## the extras a world asks for: neon lamp posts and holo gates along the
## road, floating billboards, satellites and a comet crossing the sky.
## Scenery is batched in MultiMeshes; only moons and the comet move.

static var _rock_mesh: ArrayMesh = null


const GROUNDS := {
	"red": [Color(0.45, 0.2, 0.12), Color(0.9, 0.5, 0.3), 0, 0.05],
	"sulphur": [Color(0.55, 0.45, 0.15), Color(1.0, 0.4, 0.05), 1, 0.6],
	"lava": [Color(0.16, 0.07, 0.05), Color(1.0, 0.35, 0.05), 1, 1.0],
	"jungle": [Color(0.10, 0.22, 0.12), Color(0.25, 1.0, 0.6), 0, 0.6],
	"ice": [Color(0.55, 0.65, 0.8), Color(0.6, 0.85, 1.0), 2, 0.6],
	"frost": [Color(0.18, 0.12, 0.16), Color(1.0, 0.4, 0.3), 2, 0.5],
	"clouds": [Color(0.7, 0.5, 0.4), Color(1.0, 0.75, 0.55), 3, 1.0],
	"iron": [Color(0.25, 0.1, 0.06), Color(1.0, 0.6, 0.2), 1, 1.2],
}


static func build(td: TrackData, root: Node3D) -> void:
	var theme := Themes.get_theme(td.theme)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(td.id)
	var holder := Node3D.new()
	holder.name = "Decor"
	root.add_child(holder)
	for p in theme.planets:
		_planet(holder, p, theme)
	var low := _lowest(td)
	var hi_detail := int(Gfx.q().detail) > 0
	if not td.skyway.is_empty():
		_skyway(td, holder, rng, theme)
	for x in theme.get("extras", []):
		match String(x):
			"belt":
				_belt(td, holder, rng, Color(0.4, 0.36, 0.38))
			"satellites":
				_satellites(td, holder, rng)
			"gates":
				_gates(td, holder, rng, theme.neon)
			"lamps":
				_lamps(td, holder, rng, theme.neon)
			"signs":
				_signs(td, holder, rng, theme.neon)
			"comet":
				if hi_detail:
					_comet(td, holder, rng)
	var gy := low - 50.0
	var g: String = theme.get("ground", "")
	if GROUNDS.has(g):
		var gd: Array = GROUNDS[g]
		_ground(holder, gy, gd[0], gd[1], gd[2], gd[3])
	match String(theme.get("decor", "")):
		"asteroids":
			_rocks(td, holder, rng, 320, Color(0.34, 0.29, 0.30), Vector2(2.0, 16.0), Vector2(-90.0, 110.0), 260.0)
			_rocks(td, holder, rng, 14, Color(0.28, 0.24, 0.26), Vector2(40.0, 90.0), Vector2(-250.0, 200.0), 700.0, 160.0)
			if hi_detail:
				_rocks(td, holder, rng, 260, Color(0.4, 0.34, 0.35), Vector2(0.6, 2.2), Vector2(-14.0, 18.0), 40.0)
		"rings":
			_rocks(td, holder, rng, 260, Color(0.75, 0.72, 0.68), Vector2(1.0, 6.0), Vector2(-60.0, 40.0), 320.0)
			if hi_detail:
				_rocks(td, holder, rng, 340, Color(0.85, 0.82, 0.78), Vector2(0.4, 1.6), Vector2(-10.0, 14.0), 50.0)
			_buoys(td, holder, rng, theme.neon)
		"canyon":
			_spires(td, holder, rng, gy, Color(0.5, 0.24, 0.14), 160, Vector2(30.0, 95.0), Vector2(14.0, 34.0))
			_rocks(td, holder, rng, 40, Color(0.45, 0.25, 0.18), Vector2(2.0, 6.0), Vector2(-20.0, 10.0), 120.0)
		"lava":
			_spires(td, holder, rng, gy, Color(0.45, 0.38, 0.12), 110, Vector2(25.0, 70.0), Vector2(6.0, 16.0))
		"hot":
			_spires(td, holder, rng, gy, Color(0.2, 0.1, 0.08), 120, Vector2(25.0, 70.0), Vector2(6.0, 16.0))
		"jungle":
			_plants(td, holder, rng, gy)
		"ice":
			_crystals(td, holder, rng, gy, Color(0.6, 0.85, 1.0, 0.85), Color(0.3, 0.6, 1.0))
			_rocks(td, holder, rng, 90, Color(0.7, 0.85, 1.0), Vector2(2.0, 10.0), Vector2(-30.0, 60.0), 240.0)
		"twilight":
			_crystals(td, holder, rng, gy, Color(0.4, 0.25, 0.3, 0.9), Color(1.0, 0.3, 0.25))
			_rocks(td, holder, rng, 60, Color(0.3, 0.22, 0.24), Vector2(2.0, 8.0), Vector2(-20.0, 50.0), 200.0)
		"station":
			_station(td, holder, rng)
		"twinsuns":
			_rocks(td, holder, rng, 240, Color(0.55, 0.45, 0.32), Vector2(2.0, 12.0), Vector2(-80.0, 80.0), 300.0)
			if hi_detail:
				_rocks(td, holder, rng, 200, Color(0.65, 0.55, 0.4), Vector2(0.5, 2.0), Vector2(-12.0, 16.0), 45.0)
			_buoys(td, holder, rng, theme.neon)
		"storm":
			_clouds(td, holder, rng, Color(0.35, 0.55, 1.0, 0.35), 90)
			_crystals(td, holder, rng, low - 30.0, Color(0.7, 0.9, 1.0, 0.6), Color(0.4, 0.7, 1.0), true)
		"diamond":
			_crystals(td, holder, rng, gy, Color(0.95, 0.95, 1.0, 0.85), Color(0.9, 0.9, 1.0))
			_spires(td, holder, rng, gy, Color(0.1, 0.08, 0.1), 60, Vector2(25.0, 60.0), Vector2(6.0, 14.0))
		"gas":
			_clouds(td, holder, rng, Color(1.0, 0.75, 0.6, 0.35), 70)
			_buoys(td, holder, rng, theme.neon)
		"iron":
			_spires(td, holder, rng, gy, Color(0.3, 0.12, 0.08), 120, Vector2(25.0, 70.0), Vector2(6.0, 16.0))


static func _lowest(td: TrackData) -> float:
	var y := INF
	for p in td.main.pts:
		y = minf(y, p.y)
	return y


static func _planet(parent: Node3D, p: Dictionary, theme: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = p.r
	sm.height = p.r * 2.0
	var hi := Gfx.tier_index(Game.quality()) >= 2
	sm.radial_segments = 72 if hi else 40
	sm.rings = 36 if hi else 20
	mi.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/planet.gdshader")
	mat.set_shader_parameter("color_a", p.a)
	mat.set_shader_parameter("color_b", p.b)
	mat.set_shader_parameter("rim_color", p.rim)
	mat.set_shader_parameter("sun_dir", -Themes.light_dir(theme))
	# Big backdrop worlds are gas giants (bands + storms); small ones are rocky (craters).
	mat.set_shader_parameter("bands", p.get("bands", 12.0 if float(p.r) >= 850.0 else 9.0))
	mat.set_shader_parameter("detail", 1.0 if int(Gfx.q().detail) > 0 else 0.0)
	mi.material_override = mat
	mi.position = p.pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if int(Gfx.q().detail) > 0:
		var atmo := MeshInstance3D.new()
		var am := SphereMesh.new()
		am.radius = p.r * 1.07
		am.height = p.r * 2.14
		am.radial_segments = 48
		am.rings = 24
		atmo.mesh = am
		var amat := ShaderMaterial.new()
		amat.shader = preload("res://shaders/atmo.gdshader")
		amat.set_shader_parameter("color", Color(p.rim))
		amat.set_shader_parameter("sun_dir", -Themes.light_dir(theme))
		amat.set_shader_parameter("inner", 1.0 / 1.07)
		atmo.material_override = amat
		atmo.position = p.pos
		atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(atmo)
	for mn in p.get("moons", []):
		_moon(parent, p, mn, theme)
	if p.get("ring", false):
		var ring := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(p.r * 4.6, p.r * 4.6)
		ring.mesh = pm
		var rm := ShaderMaterial.new()
		rm.shader = preload("res://shaders/ring.gdshader")
		ring.material_override = rm
		ring.position = p.pos
		ring.rotation_degrees = Vector3(16, 0, -12)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ring)


## The glide corridor: a trail of faint floating shards along the flight
## line, tall pillars flanking it so the way over reads from the ramp, and a
## soft ring over the landing strip. No HUD or minimap marking: a secret.
static func _skyway(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, theme: Dictionary) -> void:
	var sw: Dictionary = td.skyway
	var from: Vector3 = sw.from
	var to: Vector3 = sw.to
	var dir: Vector3 = sw.dir
	var up: Vector3 = sw.up
	var side := dir.cross(up).normalized()
	var neon: Color = theme.neon
	# Shards: along the arc a glider follows (up a little, then down).
	var shards: Array[Transform3D] = []
	var cols: Array[Color] = []
	var n := 9
	for k in n:
		var t := float(k + 1) / float(n + 1)
		var p := from.lerp(to, t) + up * (sin(t * PI) * 3.5 + 1.5)
		var b := Basis.from_euler(Vector3(0.3, rng.randf() * TAU, 0.2)).scaled(Vector3(0.9, 1.6, 0.9))
		shards.append(Transform3D(b, p))
		cols.append(neon.lerp(Color.WHITE, 0.3))
	var sm := SphereMesh.new()
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1, 0.55)
	_multimesh(parent, sm, shards, mat, "SkywayShards", cols)
	# Pillars either side of the corridor, leaning in, lower near the landing.
	var pillars: Array[Transform3D] = []
	var gy := _lowest(td) - 50.0
	for k in 7:
		var t := float(k) / 6.0
		for sx: float in [-1.0, 1.0]:
			var p := from.lerp(to, t) + side * sx * (16.0 + rng.randf_range(0.0, 6.0))
			var h := rng.randf_range(14.0, 26.0) - t * 6.0 + (p.y - gy)
			var w := rng.randf_range(2.5, 4.5)
			var base := Vector3(p.x, gy, p.z)
			var b := Basis.from_euler(Vector3(0.0, rng.randf() * TAU, -sx * 0.06)).scaled(Vector3(w, h, w))
			pillars.append(Transform3D(b, base + Vector3.UP * h * 0.5))
	_multimesh(parent, spire_mesh(), pillars, rock_mat(Color(theme.barrier).lightened(0.15), 0.8), "SkywayPillars")
	# Landing ring.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	tm.rings = 40
	tm.ring_segments = 6
	ring.mesh = tm
	ring.material_override = TrackBuilder.ghost(neon, 0.4)
	ring.transform = Transform3D(TrackBuilder.sb(Basis(side, dir, up), Vector3(9.0, 1.0, 9.0)), to + dir * 6.0 + up * 4.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)


## A moon orbiting a backdrop planet: a pivot at the planet turns slowly,
## the moon sits out along its x axis.
static func _moon(parent: Node3D, p: Dictionary, mn: Dictionary, theme: Dictionary) -> void:
	var pivot := Node3D.new()
	pivot.position = p.pos
	pivot.rotation = Vector3(float(mn.get("tilt", 0.2)), fmod(float(mn.get("r", 20.0)) * 0.37, TAU), 0.0)
	pivot.set_script(preload("res://scripts/track/spinner.gd"))
	pivot.set("speed", float(mn.get("speed", 0.05)))
	parent.add_child(pivot)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	var r := float(mn.get("r", 20.0))
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 28
	sm.rings = 14
	mi.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/planet.gdshader")
	mat.set_shader_parameter("color_a", mn.get("a", Color(p.a).lightened(0.15)))
	mat.set_shader_parameter("color_b", mn.get("b", Color(p.b).darkened(0.1)))
	mat.set_shader_parameter("rim_color", p.rim)
	mat.set_shader_parameter("sun_dir", -Themes.light_dir(theme))
	mat.set_shader_parameter("bands", 7.0)
	mat.set_shader_parameter("detail", 1.0 if int(Gfx.q().detail) > 0 else 0.0)
	mi.material_override = mat
	mi.position = Vector3(float(p.r) * float(mn.get("dist", 1.8)), 0.0, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(mi)


## A wide band of small rocks far out around the course.
static func _belt(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, color: Color) -> void:
	var center := Vector3.ZERO
	for p in td.main.pts:
		center += p
	center /= float(td.main.n)
	var tfs: Array[Transform3D] = []
	var count := 520 if int(Gfx.q().detail) > 0 else 260
	for k in count:
		var a := rng.randf() * TAU
		var rad := rng.randf_range(850.0, 1500.0)
		var p := center + Vector3(cos(a) * rad, rng.randf_range(-260.0, 90.0) + sin(a * 3.0) * 60.0, sin(a) * rad)
		var r := rng.randf_range(3.0, 14.0)
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3(r, r * rng.randf_range(0.6, 1.0), r * rng.randf_range(0.7, 1.2)))
		tfs.append(Transform3D(b, p))
	_multimesh(parent, rock_mesh(), tfs, rock_mat(color, 0.3), "Belt")


## Satellites drifting around the course: a body, two solar wings and a
## blinking light (static, far enough out that they read as distant).
static func _satellites(td: TrackData, parent: Node3D, rng: RandomNumberGenerator) -> void:
	var bodies: Array[Transform3D] = []
	var wings: Array[Transform3D] = []
	var lights: Array[Transform3D] = []
	var path := td.main
	for k in 14:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(90.0, 320.0)) + Vector3.UP * rng.randf_range(20.0, 160.0)
		if not _clear(td, p, td.width * 0.5 + 40.0):
			continue
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.3, 0.3)))
		var sz := rng.randf_range(3.0, 6.0)
		bodies.append(Transform3D(TrackBuilder.sb(b, Vector3(sz, sz * 0.8, sz * 1.6)), p))
		for sx: float in [-1.0, 1.0]:
			wings.append(Transform3D(TrackBuilder.sb(b, Vector3(sz * 3.2, 0.25, sz * 1.1)), p + b.x * sx * sz * 2.4))
		lights.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.9), p + b.y * sz * 0.6))
	var bm := BoxMesh.new()
	_multimesh(parent, bm, bodies, TrackBuilder.flat(Color(0.7, 0.7, 0.75), 0.0, 0.8, 0.35), "SatBodies")
	_multimesh(parent, bm, wings, TrackBuilder.flat(Color(0.12, 0.2, 0.6), 0.5, 0.9, 0.2), "SatWings")
	var sph := SphereMesh.new()
	sph.radial_segments = 8
	sph.rings = 4
	_multimesh(parent, sph, lights, TrackBuilder.glow(Color(1.0, 0.3, 0.2), 2.5), "SatLights")


## Holographic gates arching over the road every so often.
static func _gates(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, neon: Color) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	var step := int(170.0 / path.step)
	var i := rng.randi_range(10, step)
	while i < path.n - 10:
		if td.gap[i] == 0 and absf(path.curv[i]) < 0.02:
			var p := path.pts[i] + path.upv[i] * (td.width * 0.42)
			var b := Basis(path.rgt[i], path.tan[i], path.upv[i])
			tfs.append(Transform3D(TrackBuilder.sb(b, Vector3(td.width * 0.62, 1.0, td.width * 0.62)), p))
		i += step
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	tm.rings = 48
	tm.ring_segments = 8
	var mat := TrackBuilder.ghost(neon.lerp(Color.WHITE, 0.3), 0.55)
	_multimesh(parent, tm, tfs, mat, "Gates")


## Neon lamp posts along both barriers.
static func _lamps(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, neon: Color) -> void:
	var poles: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var path := td.main
	var step := int(26.0 / path.step)
	var hi := int(Gfx.q().detail) > 0
	for i in range(0, path.n, step):
		if td.gap[i] == 1:
			continue
		var side := 1.0 if (i / step) % 2 == 0 else -1.0
		if (side > 0.0 and td.open_r[i] == 1) or (side < 0.0 and td.open_l[i] == 1):
			continue
		var base := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + 1.6)
		var b := Basis(path.rgt[i], path.upv[i], -path.tan[i])
		var h := 7.0
		poles.append(Transform3D(TrackBuilder.sb(b, Vector3(0.35, h, 0.35)), base + path.upv[i] * h * 0.5))
		heads.append(Transform3D(TrackBuilder.sb(b, Vector3(2.4, 0.5, 0.9)), base + path.upv[i] * h - path.rgt[i] * side * 0.9))
		if not hi and poles.size() > 60:
			break
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	_multimesh(parent, cyl, poles, TrackBuilder.flat(Color(0.3, 0.32, 0.4), 0.0, 0.7, 0.5), "LampPoles")
	var bm := BoxMesh.new()
	_multimesh(parent, bm, heads, TrackBuilder.glow(neon, 2.6), "LampHeads")


## Floating billboards beside the road: a glowing frame around a dim panel
## with a bright stripe, facing the road.
static func _signs(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, neon: Color) -> void:
	var panels: Array[Transform3D] = []
	var frames: Array[Transform3D] = []
	var path := td.main
	var step := int(230.0 / path.step)
	var i := rng.randi_range(5, step)
	var palette := [neon, Color(0.4, 0.9, 1.0), Color(1.0, 0.5, 0.9), Color(1.0, 0.85, 0.3)]
	var cols: Array[Color] = []
	while i < path.n - 5:
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(14.0, 26.0)) + path.upv[i] * rng.randf_range(9.0, 16.0)
		var b := Basis(path.tan[i] * -side, path.upv[i], path.rgt[i] * side)
		b = b.rotated(path.upv[i], rng.randf_range(-0.3, 0.3))
		var w := rng.randf_range(14.0, 22.0)
		panels.append(Transform3D(TrackBuilder.sb(b, Vector3(w, w * 0.45, 0.3)), p))
		frames.append(Transform3D(TrackBuilder.sb(b, Vector3(w * 1.06, w * 0.45 * 1.12, 0.2)), p - b.z * 0.2))
		cols.append(palette[cols.size() % palette.size()])
		i += step
	var bm := BoxMesh.new()
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(1, 1, 1, 0.45)
	_multimesh(parent, bm, panels, pm, "SignPanels", cols)
	_multimesh(parent, bm, frames, TrackBuilder.glow(neon, 1.8), "SignFrames")


## A comet crossing the far sky with a long glowing tail (animated).
static func _comet(td: TrackData, parent: Node3D, rng: RandomNumberGenerator) -> void:
	var center := Vector3.ZERO
	for p in td.main.pts:
		center += p
	center /= float(td.main.n)
	var root := Node3D.new()
	root.name = "Comet"
	root.position = center + Vector3(1600.0, 700.0 + rng.randf_range(-100.0, 200.0), -900.0)
	root.set_script(preload("res://scripts/track/drifter.gd"))
	root.set("velocity", Vector3(-22.0, -3.0, 9.0))
	root.set("span", 3200.0)
	parent.add_child(root)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 9.0
	sm.height = 18.0
	sm.radial_segments = 16
	sm.rings = 8
	head.mesh = sm
	head.material_override = TrackBuilder.glow(Color(0.85, 0.95, 1.0), 2.6)
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(head)
	for k in 3:
		var tail := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 9.0 - 2.0 * k
		cm.bottom_radius = 0.0
		cm.height = 420.0 - 90.0 * k
		cm.radial_segments = 10
		cm.rings = 1
		tail.mesh = cm
		var dir := Vector3(22.0, 3.0, -9.0).normalized()
		var side := Vector3.UP.cross(dir).normalized()
		tail.basis = Basis(side, dir, side.cross(dir))
		tail.position = dir * (cm.height * 0.5) + side * (float(k) - 1.0) * 6.0
		var tc: Color = [Color(0.5, 0.8, 1.0, 0.22), Color(0.9, 0.95, 1.0, 0.16), Color(0.3, 0.6, 1.0, 0.14)][k]
		tail.material_override = Gfx.additive(tc)
		tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(tail)


## Strata/dust rock material for spires, boulders and asteroids.
static func rock_mat(c: Color, strata := 1.0, top := Color(-1, 0, 0)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/rock.gdshader")
	m.set_shader_parameter("color", c)
	m.set_shader_parameter("top", c.lightened(0.35) if top.r < 0.0 else top)
	m.set_shader_parameter("strata", strata)
	m.set_shader_parameter("detail", 1.0 if int(Gfx.q().detail) > 0 else 0.0)
	return m


static func rock_mesh() -> ArrayMesh:
	if _rock_mesh:
		return _rock_mesh
	var sm := SphereMesh.new()
	sm.radial_segments = 9
	sm.rings = 6
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 1.6
	for i in verts.size():
		var v := verts[i]
		verts[i] = v * (1.0 + 0.32 * noise.get_noise_3dv(v * 2.0))
	arr[Mesh.ARRAY_VERTEX] = verts
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var st := SurfaceTool.new()
	st.create_from(tmp, 0)
	st.deindex()
	st.generate_normals()
	_rock_mesh = st.commit()
	return _rock_mesh


## Eroded rock spire: a tapered column with noisy ledges (unit height,
## centred at the origin like a CylinderMesh).
static var _spire_mesh: ArrayMesh = null
static func spire_mesh() -> ArrayMesh:
	if _spire_mesh:
		return _spire_mesh
	var segs := 9 if int(Gfx.q().detail) > 0 else 7
	var rings := 10 if int(Gfx.q().detail) > 0 else 3
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.frequency = 2.2
	var pts := PackedVector2Array()
	for k in rings + 1:
		var t := float(k) / float(rings)
		var r := lerpf(0.14, 0.62, pow(t, 1.3)) * (1.0 + 0.22 * noise.get_noise_1d(t * 4.0))
		pts.append(Vector2(r, 0.5 - t))
	pts.insert(0, Vector2(0.0, 0.5))
	var lathe := MeshKit.lathe(pts, segs)
	var arr := lathe.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var v := verts[i]
		var wob := 1.0 + 0.18 * noise.get_noise_3dv(v * 3.0)
		verts[i] = Vector3(v.x * wob, v.y, v.z * wob)
	arr[Mesh.ARRAY_VERTEX] = verts
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_spire_mesh = MeshKit.faceted(tmp)
	return _spire_mesh


## True when p is clear of the main track by `clear` metres.
static func _clear(td: TrackData, p: Vector3, clear: float) -> bool:
	var path := td.main
	for i in range(0, path.n, 4):
		if path.pts[i].distance_squared_to(p) < clear * clear:
			return false
	return true


static func _multimesh(parent: Node3D, mesh: Mesh, tfs: Array[Transform3D], mat: Material, node_name: String, colors: Array[Color] = []) -> void:
	if tfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = mesh
	mm.instance_count = tfs.size()
	for k in tfs.size():
		mm.set_instance_transform(k, tfs[k])
		if mm.use_colors:
			mm.set_instance_color(k, colors[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)


static func _rocks(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, count: int, color: Color,
		size: Vector2, yrange: Vector2, reach: float, min_clear := 0.0) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	var tries := 0
	while tfs.size() < count and tries < count * 6:
		tries += 1
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(14.0, reach))
		var p := path.pts[i] + path.rgt[i] * lat + Vector3.UP * rng.randf_range(yrange.x, yrange.y)
		var r := rng.randf_range(size.x, size.y)
		if not _clear(td, p, td.width * 0.5 + r + 8.0 + min_clear):
			continue
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		b = b.scaled(Vector3(r, r * rng.randf_range(0.6, 1.0), r * rng.randf_range(0.7, 1.2)))
		tfs.append(Transform3D(b, p))
	_multimesh(parent, rock_mesh(), tfs, rock_mat(color, 0.35), "Rocks%d" % count)


static func _ground(parent: Node3D, y: float, base: Color, glow_c: Color, mode: int, amount := 0.6) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5000, 5000)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ground.gdshader")
	mat.set_shader_parameter("base", base)
	mat.set_shader_parameter("glow_color", glow_c)
	mat.set_shader_parameter("mode", mode)
	mat.set_shader_parameter("glow_amount", amount)
	mi.material_override = mat
	mi.position = Vector3(150, y, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


static func _plants(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float) -> void:
	var trunks: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var cap_cols: Array[Color] = []
	var path := td.main
	var palette := [Color(1.0, 0.35, 0.8), Color(0.3, 1.0, 0.8), Color(1.0, 0.85, 0.2), Color(0.6, 0.4, 1.0)]
	for k in 170:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(6.0, 90.0))
		var top := path.pts[i] + path.rgt[i] * lat + Vector3.UP * rng.randf_range(4.0, 26.0)
		if not _clear(td, Vector3(top.x, path.pts[i].y, top.z), td.width * 0.5 + 5.0):
			continue
		var h := top.y - ground_y
		var w := rng.randf_range(0.8, 2.2)
		trunks.append(Transform3D(Basis().scaled(Vector3(w, h, w)), Vector3(top.x, ground_y + h * 0.5, top.z)))
		var cr := rng.randf_range(3.0, 8.0)
		caps.append(Transform3D(Basis().scaled(Vector3(cr, cr * 0.55, cr)), top))
		cap_cols.append(palette[k % palette.size()])
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.9
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.15, 0.32, 0.2)
	_multimesh(parent, cyl, trunks, tm, "Trunks")
	var sph := SphereMesh.new()
	sph.radial_segments = 10
	sph.rings = 5
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.emission_enabled = true
	cm.emission = Color(0.3, 0.3, 0.3)
	cm.emission_energy_multiplier = 0.6
	_multimesh(parent, sph, caps, cm, "Caps", cap_cols)


static func _crystals(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float,
		color := Color(0.6, 0.85, 1.0, 0.85), glow_c := Color(0.3, 0.6, 1.0), floating := false) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in 150:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(10.0, 160.0))
		var base := path.pts[i] + path.rgt[i] * lat
		base.y = ground_y if not floating else path.pts[i].y + rng.randf_range(-60.0, 40.0)
		var h := rng.randf_range(20.0, 75.0) * (0.3 if floating else 1.0)
		var w := rng.randf_range(3.0, 9.0) * (0.5 if floating else 1.0)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.35, 0.35))).scaled(Vector3(w, h, w))
		var tip := base + b.y * 0.5
		if not _clear(td, tip, td.width * 0.5 + 8.0):
			continue
		tfs.append(Transform3D(b, base + b.y * 0.5))
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = 0.6
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.05
	mat.emission_enabled = true
	mat.emission = glow_c
	mat.emission_energy_multiplier = 0.5
	_multimesh(parent, cyl, tfs, mat, "Crystals")


static func _spires(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, ground_y: float,
		color := Color(0.2, 0.1, 0.08), count := 120, hrange := Vector2(25.0, 70.0), wrange := Vector2(6.0, 16.0)) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in count:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var lat := side * (td.width * 0.5 + rng.randf_range(12.0, 200.0))
		var base := path.pts[i] + path.rgt[i] * lat
		base.y = ground_y
		var h := rng.randf_range(hrange.x, hrange.y) + (path.pts[i].y - ground_y)
		var w := rng.randf_range(wrange.x, wrange.y)
		var tip := base + Vector3.UP * h
		if not _clear(td, tip, td.width * 0.5 + 10.0):
			continue
		tfs.append(Transform3D(Basis().scaled(Vector3(w, h, w)), base + Vector3.UP * h * 0.5))
	_multimesh(parent, spire_mesh(), tfs, rock_mat(color, 1.0), "Spires")


static func _clouds(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, color: Color, count: int) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for k in count:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(30.0, 260.0)) + Vector3.UP * rng.randf_range(-70.0, 10.0)
		var r := rng.randf_range(18.0, 55.0)
		if not _clear(td, p, td.width * 0.5 + r + 6.0):
			continue
		tfs.append(Transform3D(Basis().scaled(Vector3(r * 1.8, r * 0.6, r)), p))
	var sph := SphereMesh.new()
	sph.radial_segments = 12
	sph.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_multimesh(parent, sph, tfs, mat, "Clouds")


static func _buoys(td: TrackData, parent: Node3D, rng: RandomNumberGenerator, neon: Color) -> void:
	var tfs: Array[Transform3D] = []
	var path := td.main
	for i in range(0, path.n, 14):
		for side: float in [-1.0, 1.0]:
			if rng.randf() < 0.4:
				continue
			var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + 8.0) + path.upv[i] * 3.0
			tfs.append(Transform3D(Basis.from_euler(Vector3(0.5, float(i), 0.3)), p))
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.2, 1.2)
	_multimesh(parent, bm, tfs, TrackBuilder.glow(neon, 1.8), "Buoys")


static func _station(td: TrackData, parent: Node3D, rng: RandomNumberGenerator) -> void:
	var center := Vector3.ZERO
	for p in td.main.pts:
		center += p
	center /= float(td.main.n)
	# Big slowly turning habitat ring behind the track.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 520.0
	tm.outer_radius = 560.0
	tm.rings = 64
	tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = TrackBuilder.flat(Color(0.5, 0.52, 0.6), 0.0, 0.7, 0.4)
	ring.position = center + Vector3(0, -120, -900)
	ring.rotation_degrees = Vector3(70, 0, 10)
	ring.set_script(preload("res://scripts/track/spinner.gd"))
	ring.set("speed", 0.03)
	parent.add_child(ring)
	# Modules and solar panels scattered around and below the course.
	var mods: Array[Transform3D] = []
	var panels: Array[Transform3D] = []
	var path := td.main
	for k in 60:
		var i := rng.randi_range(0, path.n - 1)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var p := path.pts[i] + path.rgt[i] * side * (td.width * 0.5 + rng.randf_range(25.0, 140.0)) + Vector3.UP * rng.randf_range(-60.0, 30.0)
		if not _clear(td, p, td.width * 0.5 + 22.0):
			continue
		var b := Basis.from_euler(Vector3(0, rng.randf() * TAU, PI * 0.5))
		mods.append(Transform3D(b.scaled(Vector3(rng.randf_range(6, 12), rng.randf_range(20, 50), rng.randf_range(6, 12))), p))
		panels.append(Transform3D(Basis.from_euler(Vector3(0.2, rng.randf() * TAU, 0)).scaled(Vector3(40, 0.6, 12)), p + Vector3.UP * 14.0))
	var cyl := CylinderMesh.new()
	cyl.radial_segments = 10
	cyl.rings = 1
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	_multimesh(parent, cyl, mods, TrackBuilder.flat(Color(0.62, 0.62, 0.68), 0.0, 0.8, 0.35), "Modules")
	var bm := BoxMesh.new()
	var pmat := TrackBuilder.flat(Color(0.12, 0.2, 0.55), 0.6, 0.9, 0.2)
	_multimesh(parent, bm, panels, pmat, "Panels")
