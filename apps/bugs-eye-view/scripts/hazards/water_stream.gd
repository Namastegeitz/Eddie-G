class_name WaterStream
extends ScentWiper
## A gardener's watering: washes your scent away (like any spilled water), but
## the splash knocks you back and slows you while you're in it.

@export var push: float = 55.0
var from_point := Vector3.ZERO
var to_point := Vector3.ZERO
var _drops: Array[MeshInstance3D] = []
var _t := 0.0


## A stream from `from` (the can) landing on the ground at `to`.
static func make(from: Vector3, to: Vector3) -> WaterStream:
	var w := WaterStream.new()
	w.name = "WaterStream"
	w.from_point = from
	w.to_point = to
	w.wipe_radius = 5.0
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var b := BoxShape3D.new()
	b.size = Vector3(8, 6, 8)
	cs.shape = b
	cs.position = Vector3(0, 3, 0)
	w.add_child(cs)
	var drop_mesh := SphereMesh.new()
	drop_mesh.radius = 0.35
	drop_mesh.height = 0.9
	drop_mesh.radial_segments = 6
	drop_mesh.rings = 3
	var water: Material = load("res://assets/materials/water.tres")
	for i in 8:
		var d := MeshInstance3D.new()
		d.mesh = drop_mesh
		d.material_override = water
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.top_level = true
		w.add_child(d)
		w._drops.append(d)
	return w


func _exit_tree() -> void:
	# Leaving the tree while the bug is inside must not leave it "wet" forever.
	if _player and is_instance_valid(_player):
		_player.wiper_count -= 1
		_player = null


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_t += delta
	for i in _drops.size():
		var k := fmod(_t * 1.6 + float(i) / _drops.size(), 1.0)
		var p := from_point.lerp(to_point, k)
		p.y += sin(k * PI) * 3.0
		_drops[i].global_position = p
	if _player and not _player.dead:
		var away := to_point - from_point
		away.y = 0.0
		_player.apply_force(away.normalized() * push, delta)
		_player.set_slowed(0.7, 0.4)


## The splash where the water lands.
func covers(pos: Vector3) -> bool:
	return Vector2(pos.x - to_point.x, pos.z - to_point.z).length() < 6.0 and absf(pos.y - to_point.y) < 4.0
