class_name Cricket
extends GroundBug
## Hold Jump to crouch and charge a long leap; let go to spring (aim with the
## stick). Primary chirps: you throw your voice to a spot ahead, and threats go
## to investigate there instead of where you are.

const MAX_CHARGE := 1.0
## Gravity is lighter mid-leap: a full charge lands you on a chair seat.
const LEAP_GRAVITY := 0.66
const AIR_STEER := 10.0

var charging := false
var charge := 0.0
var leaping := false
## Jump pressed in the air: start charging as soon as you land.
var _charge_on_land := false


func _bug_setup() -> void:
	sprint_on_primary = false


func get_action_labels() -> Dictionary:
	return {"primary": "Chirp", "secondary": "Squeeze", "jump": "Leap",
		"dodge": "Dash", "interact": "Use", "sense": "Antennae"}


func ability_name() -> String:
	return "CHIRP"


func stamina_name() -> String:
	return "LEAP"


func _action_pressed(a: StringName) -> void:
	match a:
		&"jump":
			_jump_queued = false
			if is_on_floor() and not leaping:
				charging = true
				charge = 0.0
			else:
				_charge_on_land = true
		&"primary":
			chirp()


func _action_released(a: StringName) -> void:
	if a == &"jump":
		_charge_on_land = false
		if charging:
			leap()


## Spring forward; the longer Jump was held, the further (up to a full charge).
func leap() -> void:
	charging = false
	var k := clampf(charge / MAX_CHARGE, 0.0, 1.0)
	var dir := flat_dir(move_input())
	if dir.length() < 0.1:
		dir = facing
	dir = dir.normalized()
	velocity = dir * lerpf(6.0, 14.0, k) + Vector3.UP * lerpf(10.0, 29.0, k)
	facing = dir
	leaping = true
	AudioManager.play(&"whoosh", -6.0, 1.5)


func _custom_move(delta: float) -> bool:
	if _charge_on_land and not leaping and is_on_floor():
		_charge_on_land = false
		charging = true
		charge = 0.0
	if charging:
		charge = minf(charge + delta, MAX_CHARGE)
		velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 40.0 * delta)
		velocity.y = 0.0 if is_on_floor() else velocity.y - stats.gravity * delta
		move_and_slide()
		if visual:
			visual.scale.y = lerpf(visual.scale.y, 0.7, clampf(10.0 * delta, 0.0, 1.0))
		meter_changed.emit(&"stamina", charge, MAX_CHARGE)
		return true
	if leaping:
		velocity.y -= stats.gravity * LEAP_GRAVITY * delta
		# A little steering in the air, to land where you meant to.
		var steer := flat_dir(move_input())
		if steer.length() > 0.1:
			var flat := Vector2(velocity.x, velocity.z)
			var want := Vector2(steer.x, steer.z).normalized() * maxf(flat.length(), 6.0)
			flat = flat.move_toward(want, AIR_STEER * delta)
			velocity.x = flat.x
			velocity.z = flat.y
		var ext := external_velocity
		velocity += ext
		move_and_slide()
		velocity -= ext
		face_velocity(delta)
		if visual:
			visual.scale.y = lerpf(visual.scale.y, 1.0, clampf(10.0 * delta, 0.0, 1.0))
		if is_on_floor() and velocity.y <= 0.0:
			leaping = false
			AudioManager.play(&"thud", -14.0, 1.7)
			PerceptionSystem.emit_player_noise(global_position, 0.8 * stats.noise_mult)
		return true
	return false


## Throw your voice: a chirp from a spot ahead of where the camera looks.
func chirp() -> bool:
	if not use_ability():
		return false
	var spot := chirp_spot()
	PerceptionSystem.emit_world_noise(spot, 2.6)
	AudioManager.play_at(&"chirp", spot, 4.0)
	if Level.current and Level.current.ripple_pool:
		var r := Level.current.ripple_pool.acquire() as Ripple
		r.play(spot, Color(0.6, 1.0, 0.5), Level.current.ripple_pool)
	show_hint("Chirp! It sounds like you're over there")
	return true


func chirp_spot() -> Vector3:
	var fwd := -camera_yaw_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var from := global_position + Vector3.UP * 0.8
	var to := from + fwd * stats.ability_radius
	var q := PhysicsRayQueryParameters3D.create(from, to, Phys.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var spot: Vector3 = (hit["position"] as Vector3) - fwd * 1.0 if not hit.is_empty() else to
	spot.y = global_position.y
	return spot


func teleport_to(xform: Transform3D) -> void:
	super(xform)
	charging = false
	leaping = false
	_charge_on_land = false
	charge = 0.0
