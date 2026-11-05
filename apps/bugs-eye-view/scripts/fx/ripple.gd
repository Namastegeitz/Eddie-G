class_name Ripple
extends Node3D
## Expanding ring seen through walls: the spider's vibration sense. Pooled.

const LIFE := 0.8

static var _mats: Dictionary = {}

var _t := 0.0
var _pool: NodePool
var _mesh: MeshInstance3D


func _ready() -> void:
	# Animated every frame (not by physics): no physics smoothing needed.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_mesh = get_node_or_null("Mesh") as MeshInstance3D
	if _mesh == null:
		_mesh = Fx.make_ring(Color(1, 1, 1, 0.9), true)
		add_child(_mesh)


static func color_for(state: int) -> Color:
	match state:
		AlertState.ALERT:
			return Color(1.0, 0.15, 0.1)
		AlertState.SEARCHING:
			return Color(1.0, 0.55, 0.1)
		AlertState.SUSPICIOUS:
			return Color(1.0, 0.9, 0.2)
	return Color(0.5, 0.85, 1.0)


func play(pos: Vector3, color: Color, pool: NodePool) -> void:
	_pool = pool
	_t = 0.0
	global_position = pos + Vector3.UP * 0.2
	var key := color.to_html()
	if not _mats.has(key):
		_mats[key] = Fx.unshaded(Color(color.r, color.g, color.b, 0.9), true)
	_mesh.material_override = _mats[key]


func _process(delta: float) -> void:
	_t += delta
	var k := _t / LIFE
	var r := lerpf(0.5, 6.0, k)
	_mesh.scale = Vector3(r, 0.15, r)
	_mesh.transparency = k
	if _t >= LIFE and _pool:
		_pool.release(self)
