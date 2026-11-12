class_name RobotVacuum
extends Threat
## Robot vacuum: bumps around the floor and sucks in anything nearby. In the
## Cleaning Day boss it "learns" to home in on your noise. Web traps jam it.
## It also hoovers up crumbs in its path (they turn up again a little later)
## and shoves small things aside; pets keep well clear of it.

@export var speed: float = 5.5
@export var suction_radius: float = 7.0
@export var suction_strength: float = 26.0
@export var contact_radius: float = 2.6
@export var bounds_min: Vector3 = Vector3(-50, 0, -40)
@export var bounds_max: Vector3 = Vector3(50, 0, 40)

var boss_mode := false
var _heading := 0.0
var _turn_cd := 0.0
var _hum: AudioStreamPlayer3D
var _wall_ray := PhysicsRayQueryParameters3D.new()
var _tidy_cd := 0.0
## Crumbs it has eaten this run.
var crumbs_eaten := 0


func _setup() -> void:
	_heading = randf() * TAU
	_hum = AudioManager.make_loop_emitter(&"vacuum", self, -4.0)
	_wall_ray.collision_mask = Phys.WORLD
	_wall_ray.exclude = [get_rid()]


func _on_presence_changed(now: bool) -> void:
	if now:
		AudioManager.start_loop(_hum)
	else:
		AudioManager.stop_loop(_hum)


func hear(pos: Vector3, loudness: float, from_player: bool) -> void:
	if boss_mode:
		super.hear(pos, loudness, from_player)


func _think(delta: float) -> void:
	_turn_cd -= delta
	var dir := Vector3(sin(_heading), 0.0, cos(_heading))
	if boss_mode and alert.has_target and alert.state >= AlertState.SEARCHING:
		var to := alert.last_known - global_position
		to.y = 0.0
		if to.length() > 1.0:
			var want := atan2(to.x, to.z)
			_heading = lerp_angle(_heading, want, clampf(2.0 * delta, 0.0, 1.0))
			dir = Vector3(sin(_heading), 0.0, cos(_heading))
	_wall_ray.from = global_position + Vector3.UP * 0.8
	_wall_ray.to = _wall_ray.from + dir * 4.0
	var blocked := not get_world_3d().direct_space_state.intersect_ray(_wall_ray).is_empty()
	var p := global_position
	var out := p.x < bounds_min.x or p.x > bounds_max.x or p.z < bounds_min.z or p.z > bounds_max.z
	if (blocked or out or is_on_wall()) and _turn_cd <= 0.0:
		_turn_cd = 0.4
		if out:
			var c := (bounds_min + bounds_max) * 0.5 - p
			_heading = atan2(c.x, c.z) + randf_range(-0.6, 0.6)
		else:
			_heading += PI * randf_range(0.5, 1.2) * (1.0 if randf() > 0.5 else -1.0)
	var spd := speed * speed_mult() * (1.5 if boss_mode else 1.0)
	velocity = Vector3(dir.x * spd, -10.0, dir.z * spd)
	move_and_slide()
	rotation.y = _heading
	_suck(delta)
	_tidy(delta)


## Crumbs under it disappear into the bin; toys get bumped out of the way.
func _tidy(delta: float) -> void:
	_tidy_cd -= delta
	if _tidy_cd > 0.0:
		return
	_tidy_cd = 0.1
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb == null or crumb.taken or crumb.golden:
			continue
		var d := crumb.global_position - global_position
		if absf(d.y) < 3.0 and Vector2(d.x, d.z).length() < contact_radius + 1.2:
			crumb.suck_up(25.0)
			crumbs_eaten += 1
			AudioManager.play_at(&"crunch", global_position, -6.0, 1.4)
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := n as PhysicsProp
		if prop and prop.mass < 3.0 and absf(prop.global_position.y - global_position.y) < 3.0 \
				and Vector2(prop.global_position.x - global_position.x, prop.global_position.z - global_position.z).length() < contact_radius + 2.0:
			prop.push_by_npc(global_position, 1.0)


func _suck(delta: float) -> void:
	var pl := PerceptionSystem.player
	if pl == null or pl.dead or pl.is_hidden_safe():
		return
	if pl is Fly and (pl as Fly).flying:
		return
	var to := global_position - pl.global_position
	if absf(to.y) > 3.0:
		return
	to.y = 0.0
	var d := to.length()
	if d < contact_radius:
		pl.take_hit(&"vacuumed", global_position)
	elif d < suction_radius:
		pl.apply_force(to.normalized() * suction_strength * (1.0 - d / suction_radius) * 2.0, delta)


func apply_web(seconds: float) -> void:
	super.apply_web(seconds)
	stun(seconds)


## A robot doesn't look up when something smashes.
func _notices_commotion() -> bool:
	return false
