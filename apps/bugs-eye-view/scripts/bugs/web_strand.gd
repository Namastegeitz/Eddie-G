class_name WebStrand
extends StaticBody3D
## A web line left behind after a zip. Walkable by the spider (web layer only),
## camouflages it, and disappears after a while. Pooled.

var _life := 0.0
var _pool: NodePool
@onready var _shape: CollisionShape3D = $Shape
@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	collision_layer = Phys.WEB
	collision_mask = 0
	set_meta(&"surface", &"web")
	set_meta(&"camo", &"web")
	# Pooled copies must not share (and resize) the same shape/mesh.
	_shape.shape = _shape.shape.duplicate()
	_mesh.mesh = _mesh.mesh.duplicate()


func setup(a: Vector3, b: Vector3, lifetime: float, pool: NodePool) -> void:
	_pool = pool
	_life = lifetime
	var seg_len := a.distance_to(b)
	var dir := (b - a) / maxf(seg_len, 0.001)
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	global_transform = Transform3D(Basis.looking_at(dir, up), (a + b) * 0.5)
	(_shape.shape as BoxShape3D).size = Vector3(0.6, 0.15, seg_len)
	(_mesh.mesh as BoxMesh).size = Vector3(0.12, 0.06, seg_len)
	_shape.disabled = false


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 and _pool:
		_shape.disabled = true
		_pool.release(self)
