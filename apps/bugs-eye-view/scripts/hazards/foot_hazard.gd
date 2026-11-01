class_name FootHazard
extends Hazard
## A giant human foot. Lifts, hovers over its landing spot with a shadow ring,
## stomps (rumble + screen shake + thud), then stays planted as an obstacle.
## Stepping on a trip-hazard prop (a grape) trips the human.

enum { PLANTED, LIFT, HOVER, STOMP }

@export var foot_size: Vector3 = Vector3(4.0, 2.5, 10.0)
@export var lift_height: float = 9.0
@export var heavy: bool = false

var yaw := 0.0
var _phase := PLANTED
var _t := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _to_yaw := 0.0
var _from_yaw := 0.0
var _telegraph := 0.5
var _body: AnimatableBody3D


func _setup() -> void:
	top_level = true
	can_rebound = false
	hit_cause = &"stomped"
	impact_radius = foot_size.x * 0.75
	_body = get_node_or_null("Body") as AnimatableBody3D
	if _body:
		_body.collision_layer = Phys.WORLD
		_body.collision_mask = 0
		# The foot node (our parent) is what moves. Physics-synced animatable
		# bodies only follow their own local transform, so they would stay
		# behind at the spawn point; follow the global transform instead.
		_body.sync_to_physics = false
		_body.set_meta(&"surface", &"cloth")


func set_owner_threat(t: Threat) -> void:
	owner_threat = t
	if _body:
		_body.set_meta(&"threat", t)


func plant_at(pos: Vector3, new_yaw: float) -> void:
	_phase = PLANTED
	yaw = new_yaw
	global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	busy = false
	hide_telegraph()


## Lift and stomp onto `pos`. `telegraph` = seconds the shadow warns first.
func step_to(pos: Vector3, new_yaw: float, telegraph: float) -> void:
	_from = global_position
	_from_yaw = yaw
	_to = pos
	_to_yaw = new_yaw
	_telegraph = maxf(telegraph, 0.2)
	_phase = LIFT
	_t = 0.0
	busy = true


func is_planted() -> bool:
	return _phase == PLANTED


func _physics_process(delta: float) -> void:
	match _phase:
		LIFT, HOVER:
			_t += delta
			var k := clampf(_t / _telegraph, 0.0, 1.0)
			var flat := _from.lerp(_to, minf(k * 1.4, 1.0))
			var h := lift_height * minf(_t / 0.12, 1.0)
			yaw = lerp_angle(_from_yaw, _to_yaw, minf(k * 1.4, 1.0))
			global_transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(flat.x, _to.y + h, flat.z))
			show_telegraph(_to, impact_radius, k)
			if _t >= _telegraph:
				_phase = STOMP
				_t = 0.0
		STOMP:
			_t += delta
			var k2 := minf(_t / 0.07, 1.0)
			global_transform = Transform3D(Basis(Vector3.UP, yaw), _to + Vector3.UP * lerpf(lift_height, 0.0, k2))
			if k2 >= 1.0:
				_phase = PLANTED
				busy = false
				_land()


func _land() -> void:
	resolve_impact(_to)
	AudioManager.play_at(&"thud", _to, 2.0 if heavy else 0.0, 0.8 if heavy else 1.0)
	PerceptionSystem.emit_world_noise(_to, 0.6)
	# Trip on a grape or ball under the sole.
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := n as PhysicsProp
		if prop and prop.trip_hazard and _point_under_foot(prop.global_position, _to):
			prop.on_stepped_on(owner_threat)


func _point_under_foot(p: Vector3, pos: Vector3) -> bool:
	var local := Basis(Vector3.UP, yaw).inverse() * (p - pos)
	return absf(local.x) <= foot_size.x * 0.5 + 0.4 and absf(local.z) <= foot_size.z * 0.5 + 0.4 \
		and local.y > -1.0 and local.y < foot_size.y + 2.0


## Oriented box test so the long foot feels fair.
func _player_in_zone(p: BugBase, pos: Vector3, _radius: float) -> bool:
	return _point_under_foot(p.global_position, pos)


## Elliptical warning that matches the sole.
func show_telegraph(pos: Vector3, _radius: float, progress: float) -> void:
	var p := pos + Vector3.UP * 0.08
	var b := Basis(Vector3.UP, _to_yaw)
	var grow := lerpf(1.8, 1.0, clampf(progress, 0.0, 1.0))
	var sx := foot_size.x * 0.65
	var sz := foot_size.z * 0.55
	_ring.visible = true
	_ring.global_transform = Transform3D(b * Basis.from_scale(Vector3(sx * grow, 0.15, sz * grow)), p)
	_disc.visible = true
	_disc.global_transform = Transform3D(b * Basis.from_scale(Vector3(sx, 1.0, sz)), p)
	_disc.transparency = 1.0 - clampf(progress, 0.0, 1.0) * 0.9
