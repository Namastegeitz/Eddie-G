class_name ThrownObject
extends Hazard
## Something a person throws at a bug they can't reach: a slipper, a kitchen
## sponge or a balled-up sheet of paper. It sits in their hand while they wind
## up (a ring already marks where it will land), flies in an arc, hits like a
## swat where it lands, bounces, lies there a moment and fades away.

enum Kind { SLIPPER, SPONGE, PAPER }
enum { HELD, FLY, BOUNCE, REST, FADE }

const REST_TIME := 3.0
const FADE_TIME := 0.4
const BOUNCE_TIME := 0.35

var kind: int = Kind.PAPER
## Did it hit the bug where it landed (for tests).
var hit_bug := false
var _phase := HELD
var _t := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _windup := 0.6
var _flight := 0.7
var _apex := 6.0
var _rest_y := 0.6
var _bounce_dir := Vector3.ZERO
var _spin := Vector3.RIGHT
var _holder: Human
var _mesh: MeshInstance3D


static func make(k: int) -> ThrownObject:
	var o := ThrownObject.new()
	o.kind = k
	o.name = "Thrown" + ["Slipper", "Sponge", "Paper"][k]
	return o


func _setup() -> void:
	hit_cause = &"thrown"
	can_rebound = false
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	match kind:
		Kind.SLIPPER:
			# A soft slipper: a long, flat, rounded shape (built here, at
			# run time, so no builder code is needed in the game).
			var c := CapsuleMesh.new()
			c.radius = 1.8
			c.height = 9.0
			c.radial_segments = 14
			c.rings = 4
			_mesh.mesh = c
			_mesh.rotation = Vector3(PI * 0.5, 0, 0)
			_mesh.scale = Vector3(1.0, 1.0, 0.45)
			_mesh.material_override = load("res://assets/materials/cloth_blue.tres")
			impact_radius = 3.0
			_rest_y = 0.8
		Kind.SPONGE:
			var b := BoxMesh.new()
			b.size = Vector3(3.6, 1.5, 2.4)
			_mesh.mesh = b
			_mesh.material_override = load("res://assets/materials/sponge.tres")
			impact_radius = 2.6
			_rest_y = 0.75
		_:
			# Balled-up paper: a few big facets read as crumpled.
			var s := SphereMesh.new()
			s.radius = 1.5
			s.height = 2.7
			s.radial_segments = 7
			s.rings = 4
			_mesh.mesh = s
			_mesh.material_override = load("res://assets/materials/paper.tres")
			impact_radius = 2.3
			_rest_y = 1.3
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_mesh)
	_spin = Vector3(randf_range(-1, 1), randf_range(-0.4, 0.4), randf_range(-1, 1)).normalized()


## Picked up for a throw at `target`: held in the hand for `windup` seconds
## (the ring warns from now) until Human releases it.
func hold(by: Human, target: Vector3, windup: float) -> void:
	owner_threat = by
	_holder = by
	_to = target
	_windup = maxf(windup, 0.2)
	_phase = HELD
	_t = 0.0
	busy = true
	var est := clampf(by.hand_position().distance_to(target) / 50.0, 0.45, 1.0)
	PerceptionSystem.warn_strike(target, _windup + est, impact_radius)


## Let go from `from`: it flies in an arc onto the marked spot.
func release(from: Vector3) -> void:
	_from = from
	var dist := from.distance_to(_to)
	_flight = clampf(dist / 50.0, 0.45, 1.0)
	_apex = clampf(dist * 0.15, 2.0, 9.0)
	var flat := Vector3(_to.x - from.x, 0, _to.z - from.z)
	_bounce_dir = flat.normalized() if flat.length() > 0.1 else Vector3.ZERO
	_phase = FLY
	_t = 0.0


## Dropped before it was thrown (they got stunned or lost you).
func drop() -> void:
	_holder = null
	hide_telegraph()
	_phase = FADE
	_t = 0.0
	busy = false


func _physics_process(delta: float) -> void:
	_t += delta
	match _phase:
		HELD:
			if _holder == null or not is_instance_valid(_holder):
				drop()
				return
			global_position = _holder.hand_position()
			show_telegraph(_to, impact_radius, _t / (_windup + 0.7))
		FLY:
			var s := minf(_t / _flight, 1.0)
			global_position = _from.lerp(_to, s) + Vector3.UP * (4.0 * _apex * s * (1.0 - s))
			_mesh.rotate(_spin, delta * 9.0)
			show_telegraph(_to, impact_radius, (_windup + _t) / (_windup + _flight))
			if s >= 1.0:
				_land()
		BOUNCE:
			var u := minf(_t / BOUNCE_TIME, 1.0)
			var base := _to + Vector3.UP * (_rest_y - 0.5)
			global_position = base + _bounce_dir * (u * 1.6) + Vector3.UP * (sin(PI * u) * 1.3)
			_mesh.rotate(_spin, delta * 4.0 * (1.0 - u))
			if u >= 1.0:
				_phase = REST
				_t = 0.0
		REST:
			if _t >= REST_TIME:
				_phase = FADE
				_t = 0.0
		FADE:
			var f := minf(_t / FADE_TIME, 1.0)
			scale = Vector3.ONE * maxf(1.0 - f, 0.01)
			if f >= 1.0:
				queue_free()


func _land() -> void:
	var p := PerceptionSystem.player
	var before := p.health if p else 0.0
	resolve_impact(_to)
	hit_bug = p != null and (p.dead or p.health < before)
	AudioManager.play_at(&"thud" if kind != Kind.PAPER else &"clatter", _to, -2.0, 1.4 if kind == Kind.SLIPPER else 1.8)
	PerceptionSystem.emit_world_noise(_to, 0.4)
	busy = false
	_phase = BOUNCE
	_t = 0.0
