class_name Newspaper
extends Hazard
## A rolled newspaper swept in a low arc across the floor around the human.

enum { IDLE, AIM, SWEEP, RETURN }

@export var length: float = 16.0
@export var sweep_angle_deg: float = 120.0
@export var sweep_time: float = 0.3

var _phase := IDLE
var _t := 0.0
var _pivot := Vector3.ZERO
var _start_yaw := 0.0
var _telegraph := 0.8
var _target := Vector3.ZERO
var _paper: Node3D


func _setup() -> void:
	top_level = true
	hit_cause = &"swatted"
	can_rebound = true
	_paper = get_node_or_null("Paper")
	visible = false


func sweep_at(pivot: Vector3, target: Vector3, telegraph: float) -> void:
	_pivot = Vector3(pivot.x, target.y, pivot.z)
	_target = target
	_telegraph = telegraph
	var to := target - _pivot
	var center_yaw := atan2(-to.x, -to.z)
	_start_yaw = center_yaw - deg_to_rad(sweep_angle_deg) * 0.5
	_phase = AIM
	_t = 0.0
	busy = true
	visible = true
	global_transform = Transform3D(Basis(Vector3.UP, _start_yaw), _pivot + Vector3.UP * 3.0)
	PerceptionSystem.warn_strike(target, telegraph, impact_radius)


func _physics_process(delta: float) -> void:
	match _phase:
		AIM:
			_t += delta
			show_telegraph(_target, impact_radius * 1.6, _t / _telegraph)
			if _t >= _telegraph:
				_phase = SWEEP
				_t = 0.0
				AudioManager.play_at(&"swoosh", _target, 2.0, 0.8)
		SWEEP:
			_t += delta
			var k := minf(_t / sweep_time, 1.0)
			var y := _start_yaw + deg_to_rad(sweep_angle_deg) * k
			global_transform = Transform3D(Basis(Vector3.UP, y), _pivot + Vector3.UP * lerpf(3.0, 1.0, k))
			if k >= 1.0:
				if resolve_impact(_target):
					AudioManager.play_at(&"smack", _target, 0.0, 0.7)
				_phase = RETURN
				_t = 0.0
		RETURN:
			_t += delta
			if _t > 0.5:
				_phase = IDLE
				busy = false
				visible = false


## Hit if the player is inside the swept sector of the floor.
func _player_in_zone(p: BugBase, _pos: Vector3, _radius: float) -> bool:
	var to := p.global_position - _pivot
	if absf(to.y) > 3.5:
		return false
	var flat := Vector2(to.x, to.z)
	if flat.length() > length + 1.0 or flat.length() < 2.0:
		return false
	var yaw := atan2(-to.x, -to.z)
	var rel := wrapf(yaw - _start_yaw, 0.0, TAU)
	return rel <= deg_to_rad(sweep_angle_deg)
