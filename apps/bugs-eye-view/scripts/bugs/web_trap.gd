class_name WebTrap
extends Area3D
## A sticky web patch. Pets and robot vacuums that cross it get slowed or
## stuck for a few seconds. Pooled.

const SLOW_SECONDS := 3.0

var _life := 0.0
var _pool: NodePool


func _ready() -> void:
	collision_layer = 0
	collision_mask = Phys.THREAT
	body_entered.connect(_on_body)


func setup(pos: Vector3, normal: Vector3, lifetime: float, pool: NodePool) -> void:
	_pool = pool
	_life = lifetime
	var f := Vector3.FORWARD - normal * normal.z
	if f.length_squared() < 0.01:
		f = Vector3.RIGHT
	global_transform = Transform3D(Basis.looking_at(f.normalized(), normal), pos)
	monitoring = true


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0 and _pool:
		set_deferred("monitoring", false)
		_pool.release(self)


func _on_body(b: Node3D) -> void:
	if b is Threat:
		(b as Threat).apply_web(SLOW_SECONDS)
		AudioManager.play_at(&"web_shoot", global_position, -6.0, 0.5)
