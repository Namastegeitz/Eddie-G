class_name Shards
extends Node3D
## The pieces of something that broke (a glass, a teacup, a clay pot and its
## soil): they burst out, skitter to a stop on the surface it broke on, glint
## for a moment and fade away. Kinematic and short-lived (no physics bodies).

const LIFE := 3.2
const GRAVITY := 30.0

var _pieces: Array[MeshInstance3D] = []
var _vel: Array[Vector3] = []
var _spin: Array[Vector3] = []
var _rest_y := 0.0
var _t := 0.0


## Scatters `count` pieces at `at`, using the broken thing's materials.
static func burst(parent: Node, at: Vector3, mats: Array[Material], count: int = 9) -> Shards:
	var s := Shards.new()
	s.name = "Shards"
	parent.add_child(s)
	s.global_position = at
	s._build(mats, count)
	return s


func _build(mats: Array[Material], count: int) -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, global_position + Vector3.DOWN * 6.0, Phys.WORLD)
	var hit := space.intersect_ray(q)
	_rest_y = (hit["position"] as Vector3).y + 0.12 if not hit.is_empty() else global_position.y - 0.8
	# See-through things (a glass) leave glinting splinters you can see.
	var clear := false
	for m in mats:
		var sm := m as BaseMaterial3D
		if sm and sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			clear = true
	if clear:
		var glint := StandardMaterial3D.new()
		glint.albedo_color = Color(0.85, 0.95, 1.0)
		glint.emission_enabled = true
		glint.emission = Color(0.7, 0.85, 1.0)
		glint.emission_energy_multiplier = 0.8
		glint.metallic = 0.6
		glint.roughness = 0.1
		mats = mats.duplicate()
		mats.append(glint)
		mats.append(glint)
	for i in count:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		var sz := randf_range(0.5, 1.0)
		pm.size = Vector3(sz, sz * randf_range(0.6, 1.2), 0.12)
		mi.mesh = pm
		if not mats.is_empty():
			mi.material_override = mats[i % mats.size()]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		add_child(mi)
		_pieces.append(mi)
		var a := randf() * TAU
		var out := randf_range(3.0, 9.0)
		_vel.append(Vector3(cos(a) * out, randf_range(3.0, 8.0), sin(a) * out))
		_spin.append(Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12)))


func _process(delta: float) -> void:
	_t += delta
	for i in _pieces.size():
		var mi := _pieces[i]
		var v := _vel[i]
		if mi.global_position.y > _rest_y or v.y > 0.0:
			v.y -= GRAVITY * delta
			mi.global_position += v * delta
			mi.rotation += _spin[i] * delta
			if mi.global_position.y <= _rest_y and v.y < 0.0:
				mi.global_position.y = _rest_y
				# A small skip, then it slides to a stop.
				v = Vector3(v.x * 0.35, -v.y * 0.2 if absf(v.y) > 3.0 else 0.0, v.z * 0.35)
				_spin[i] *= 0.3
			_vel[i] = v
		elif v.length() > 0.05:
			_vel[i] = v.move_toward(Vector3.ZERO, 20.0 * delta)
			mi.global_position += _vel[i] * delta
	if _t > LIFE - 0.6:
		var k := clampf((LIFE - _t) / 0.6, 0.0, 1.0)
		for mi in _pieces:
			mi.scale = Vector3.ONE * maxf(k, 0.01)
	if _t >= LIFE:
		queue_free()
