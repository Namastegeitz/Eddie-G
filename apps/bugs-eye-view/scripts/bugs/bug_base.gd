class_name BugBase
extends CharacterBody3D
## Shared bug interface. Levels, hazards and threats treat every bug the same:
## health (hits, healing, snap-trap knockouts), stealth inputs (motion, surface, camouflage), senses, external
## forces (wind, suction, sticky traps) and interaction. Subclasses implement
## _move() and their abilities.

signal hit_taken(hits_left: int)
signal died(cause: StringName)
signal sense_changed(active: bool)
signal meter_changed(meter: StringName, value: float, max_value: float)
signal hint_changed(text: String)
## Bug food / gem effects started, ended or healed (see PowerUps).
signal effects_changed
## Health went up or down (gain > 0 when healed, < 0 when hurt).
signal health_changed(health: float, gain: float)
## Snapped in a trap: out cold for `seconds`.
signal knocked_out(seconds: float)

enum Motion { STILL, CREEP, WALK, SPRINT }

const INTERACT_PROP_RADIUS := 3.0
const PROBE_INTERVAL := 0.1
const HINT_INTERVAL := 0.25

@export var stats: BugStats

## Health: every bug has 100. A stomp, swat or bite costs a whole "hit"
## (100 / the bug's max_hits, so most bugs still die to one), a snap trap
## costs TRAP_DAMAGE and knocks you out. Health comes back on its own once
## nothing has hurt you for REGEN_DELAY seconds, and from crumbs and
## power-ups (HEAL_*). Cheese can push it one hit above full.
const MAX_HEALTH := 100.0
const REGEN_DELAY := 4.0
const REGEN_RATE := 5.0
const TRAP_DAMAGE := 65.0
const TRAP_KO_TIME := 3.0
## A second snap within this many seconds of the last one (before you've
## healed back up) can kill; a single snap never does.
const TRAP_BACK_TO_BACK := 15.0
const TRAP_FLOOR := 5.0
## Health from pickups: a crumb, a bite of bug food, a gem or treasure, a
## hidden power-up, a golden crumb (everything).
const HEAL_CRUMB := 6.0
const HEAL_FOOD := 20.0
const HEAL_GEM := 12.0
const HEAL_POWER := 40.0

var health := MAX_HEALTH
## Whole hits left before the next stomp kills (derived from health; setting
## it sets health to that many hits' worth).
var hits_left: int:
	get:
		return 0 if health <= 0.0 else ceili(health / hit_damage() - 0.001)
	set(v):
		health = clampf(float(v) * hit_damage(), 0.0, health_cap())
var _since_hurt := 99.0
var _since_snap := 99.0
## Out cold in a trap (seconds left); the bug can't move.
var knocked_out_left := 0.0
var motion: int = Motion.STILL
var still_time := 0.0
var surface_id: StringName = &"default"
var camo_tag: StringName = &""
var is_squeezing := false
var dead := false
var invuln := 0.0
var knockdown := 0.0
var stuck_time := 0.0
var slow_mult := 1.0
var external_velocity := Vector3.ZERO
var spray_exposure := 0.0
var wiper_count := 0
var sense_meter := 0.0
var sense_active := false
## Yaw-only basis from the follow camera; movement is camera-relative.
var camera_yaw_basis: Basis = Basis.IDENTITY
var cam: FollowCamera = null
var facing := Vector3.FORWARD
## Timed effects from bug food and crumb gems: effect id -> seconds left.
var effects: Dictionary = {}
## Strength of each active effect (speed multiplier, radius...).
var effect_amount: Dictionary = {}

var _spots: Array[HidingSpot] = []
var _interactables: Array[Node] = []
var _noise_timer := 0.0
var _probe_timer := 0.0
var _hint_timer := 0.0
var _probe := PhysicsRayQueryParameters3D.new()
var _dodge_time := 0.0
var _dodge_cd := 0.0
var _dodge_dir := Vector3.ZERO
## Dash Burst (an add-on) dashes further than a normal dodge.
var _dash_mult := 1.0
var _jump_queued := false
## Forgiving jumps: a jump still works just after running off an edge
## (coyote time) and a press just before landing is remembered (buffer).
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.15
var _coyote := 0.0
var _jump_buffer := 0.0
var _slow_timer := 0.0
var _hint := ""
var _cfg: StealthConfig

@onready var visual: Node3D = get_node_or_null("Visual")


func _ready() -> void:
	add_to_group(Phys.GROUP_PLAYER)
	collision_layer = Phys.PLAYER
	collision_mask = Phys.WORLD | Phys.PROP | Phys.WEB
	if stats == null:
		stats = BugStats.new()
	health = MAX_HEALTH
	sense_meter = stats.sense_max
	floor_max_angle = deg_to_rad(stats.floor_max_angle_deg)
	floor_snap_length = 0.3
	_cfg = PerceptionSystem.config
	_probe.collision_mask = Phys.WORLD | Phys.PROP | Phys.WEB
	_probe.exclude = [get_rid()]
	_climb_q.collision_mask = Phys.WORLD
	_climb_q.exclude = [get_rid()]
	InputRouter.action_pressed.connect(_on_action_pressed)
	InputRouter.action_released.connect(_on_action_released)
	if visual:
		# The rig animates every frame; it rides on the smoothed body.
		visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_setup()


## Subclass hook called at the end of _ready().
func _setup() -> void:
	pass


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_timers(delta)
	if _grapple_left > 0.0:
		_grapple_tick(delta)
		_update_motion(delta)
		return
	if knockdown > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		velocity.y -= stats.gravity * delta
		move_and_slide()
		return
	_move(delta)
	_apply_size(delta)
	_push_props()
	_update_motion(delta)
	_probe_timer -= delta
	if _probe_timer <= 0.0:
		_probe_timer = PROBE_INTERVAL
		_probe_surface()
	_emit_noise(delta)
	_update_sense(delta)
	_magnet_tick(delta)
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = HINT_INTERVAL
		_update_hint()
	if global_position.y < -40.0:
		die(&"fell")


## Subclass movement. Must set velocity and call move_and_slide().
func _move(_delta: float) -> void:
	pass


func _tick_timers(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	knockdown = maxf(knockdown - delta, 0.0)
	_since_hurt += delta
	_since_snap += delta
	if knocked_out_left > 0.0:
		knocked_out_left = maxf(knocked_out_left - delta, 0.0)
		_spin_stars(delta)
		if knocked_out_left <= 0.0:
			_come_to()
	# Health creeps back once nothing has hurt you for a moment.
	if _since_hurt >= REGEN_DELAY and health < MAX_HEALTH:
		health = minf(health + REGEN_RATE * delta, MAX_HEALTH)
	_dodge_cd = maxf(_dodge_cd - delta * (3.0 if has_effect(&"wired") else 1.0), 0.0)
	_tick_effects(delta)
	_dodge_time = maxf(_dodge_time - delta, 0.0)
	if _dodge_time <= 0.0:
		_dash_mult = 1.0
	_leap_off_t = maxf(_leap_off_t - delta, 0.0)
	stuck_time = maxf(stuck_time - delta, 0.0)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			slow_mult = 1.0
	external_velocity = external_velocity.move_toward(Vector3.ZERO, 25.0 * delta)
	spray_exposure = maxf(spray_exposure - _cfg.spray_exposure_decay * delta, 0.0)
	if visual:
		visual.visible = knocked_out_left > 0.0 or invuln <= 0.0 or fmod(invuln, 0.2) > 0.1


# --- Input helpers ----------------------------------------------------------

func move_input() -> Vector2:
	if stuck_time > 0.0:
		return Vector2.ZERO
	return InputRouter.get_move_vector()


## Camera-relative direction on the ground plane. Length follows the stick.
func flat_dir(v2: Vector2) -> Vector3:
	var fwd := -camera_yaw_basis.z
	var right := camera_yaw_basis.x
	return right * v2.x + fwd * v2.y


func _on_action_pressed(a: StringName) -> void:
	if dead or not is_inside_tree():
		return
	if stuck_time > 0.0:
		# Mash any button to tear free of a sticky trap.
		stuck_time = maxf(stuck_time - 0.35, 0.0)
		return
	match a:
		&"interact":
			_do_interact()
		&"dodge":
			_try_dodge()
		&"sense":
			toggle_sense()
		&"jump":
			_jump_queued = true
	_action_pressed(a)


func _on_action_released(a: StringName) -> void:
	if not dead:
		_action_released(a)


func _action_pressed(_a: StringName) -> void:
	pass


func _action_released(_a: StringName) -> void:
	pass


## The button labels right now (Jump leaps off a wall while climbing).
func action_labels() -> Dictionary:
	var l := get_action_labels()
	if climbing:
		l["jump"] = "Leap off"
	return l


## Labels for the touch buttons and the controls help.
func get_action_labels() -> Dictionary:
	return {"primary": "Sprint", "secondary": "Squeeze", "jump": "Jump",
		"dodge": "Run", "interact": "Use", "sense": "Sense"}


# --- Shared ground movement -------------------------------------------------

func ground_move(delta: float, speed: float) -> void:
	_climb_cd = maxf(_climb_cd - delta, 0.0)
	if climbing:
		climb_move(delta, speed * stats.climb_speed_mult * (float(effect_amount.get(&"grip", 1.0)) if has_effect(&"grip") else 1.0))
		return
	var dir := flat_dir(move_input())
	var target := dir * speed
	var accel := stats.acceleration
	# Just leapt off a wall or got flung by something springy: keep the
	# momentum, steer only a little.
	if _leap_off_t > 0.0 and not is_on_floor():
		accel *= 0.15
		if dir.length() < 0.1:
			target = Vector3(velocity.x, 0.0, velocity.z)
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if _dodge_time > 0.0:
		velocity.x = _dodge_dir.x * stats.dodge_speed * _dash_mult
		velocity.z = _dodge_dir.z * stats.dodge_speed * _dash_mult
	var grounded := is_on_floor()
	if grounded:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	if _jump_queued:
		_jump_buffer = JUMP_BUFFER
	if _jump_buffer > 0.0 and _coyote > 0.0 and velocity.y <= 0.5:
		velocity.y = stats.jump_velocity * jump_scale()
		_coyote = 0.0
		_jump_buffer = 0.0
	elif not grounded:
		velocity.y -= stats.gravity * delta
	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	_jump_queued = false
	var ext := external_velocity
	velocity += ext
	move_and_slide()
	velocity -= ext
	try_grab_wall(delta)


## Bug's-eye view: "up" for the camera (the surface for a wall-walker).
func fp_up() -> Vector3:
	if on_surface() and visual:
		return visual.global_basis.y.normalized()
	return Vector3.UP


## Bug's-eye view: where the eyes look (and the body faces): the camera yaw,
## or straight up the wall while climbing.
func fp_forward() -> Vector3:
	var up := fp_up()
	if up.dot(Vector3.UP) <= 0.95:
		var w := surface_wish(Vector2(0, 1), up)
		if w.length_squared() > 0.0001:
			return w.normalized()
	var f := -camera_yaw_basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD


## Walking on a wall (or, for the spider, any surface) with the body turned to it.
func on_surface() -> bool:
	return climbing


# --- Climbing: every bug walks up walls and furniture -----------------------
## Push into a wall, a cupboard, a table leg or a box for a moment and you
## start up it; at the top you walk over the edge onto it. Pull back to climb
## down, Jump to leap off. A small lip (a counter's overhang, a table's edge)
## is clambered round; only the spider walks across ceilings.

const CLIMB_GRAB_TIME := 0.12
const CLIMB_STICK := 3.0
const CLIMB_REGRAB := 0.35
## How far out an overhang's edge can be and still be clambered round.
const CLAMBER_REACH := 5.0
const CLAMBER_SPEED := 9.0

var climbing := false
## The surface underfoot (UP on the ground; a wall's normal while climbing).
var surface_normal := Vector3.UP
var _grab_t := 0.0
var _climb_cd := 0.0
var _clamber: Array[Vector3] = []
var _clamber_n := Vector3.UP
var _clamber_fail := 0.0
var _leap_off_t := 0.0
var _settle := 0.0
var _climb_q := PhysicsRayQueryParameters3D.new()
static var _climb_hinted := false


## Whether this bug can start climbing right now.
func can_climb() -> bool:
	return stats.can_climb and not is_squeezing and not dead and knockdown <= 0.0 and stuck_time <= 0.0


func _surface_ray(from: Vector3, to: Vector3) -> Dictionary:
	_climb_q.from = from
	_climb_q.to = to
	return get_world_3d().direct_space_state.intersect_ray(_climb_q)


## Camera-relative direction projected onto a surface. On walls, pushing
## "forward" while facing the wall climbs up it.
func surface_wish(input: Vector2, n: Vector3) -> Vector3:
	var fl := -camera_yaw_basis.z
	var d := fl.dot(n)
	var f := fl - n * d
	if absf(n.y) < 0.95:
		var up_proj := (Vector3.UP - n * n.y).normalized()
		f += up_proj * -d
	if f.length_squared() < 0.0001:
		f = Vector3.UP - n * n.y
	f = f.normalized()
	var r := f.cross(n).normalized()
	return r * input.x + f * input.y


## After moving on the ground or in the air: pushing into a climbable wall for
## a moment grabs it.
func try_grab_wall(delta: float) -> void:
	if climbing or _climb_cd > 0.0 or not can_climb():
		_grab_t = 0.0
		return
	var n := _wall_contact(flat_dir(move_input()))
	if n == Vector3.ZERO:
		_grab_t = 0.0
		return
	_grab_t += delta
	if _grab_t >= CLIMB_GRAB_TIME:
		start_climb(n)


## The wall we're pushing into this frame (ZERO if none). Loose things you
## can push (props) aren't climbed - and nor are invisible boundaries.
func _wall_contact(wish: Vector3) -> Vector3:
	if wish.length() < 0.3:
		return Vector3.ZERO
	var w := wish.normalized()
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var n := c.get_normal()
		if absf(n.y) > 0.6:
			continue
		var col := c.get_collider() as CollisionObject3D
		if col == null or col is PhysicsProp or col.has_meta(&"no_climb") or not col is StaticBody3D \
				or (col.collision_layer & Phys.WORLD) == 0:
			continue
		var flat := Vector3(n.x, 0.0, n.z)
		if flat.length_squared() > 0.0001 and w.dot(-flat.normalized()) > 0.55:
			return n.normalized()
	return Vector3.ZERO


func start_climb(n: Vector3) -> void:
	climbing = true
	_grab_t = 0.0
	_clamber.clear()
	_clamber_fail = 0.0
	surface_normal = n.normalized()
	motion_mode = MOTION_MODE_FLOATING
	up_direction = surface_normal
	velocity = Vector3.ZERO
	if not _climb_hinted:
		_climb_hinted = true
		show_hint("Climbing! Pull back to climb down, Jump to leap off")


## Back to walking (or falling): `push` is the velocity to leave with,
## `face` the way to face (flattened).
func stop_climb(push: Vector3 = Vector3.ZERO, face: Vector3 = Vector3.ZERO) -> void:
	if not climbing:
		return
	climbing = false
	_clamber.clear()
	var f := face if face != Vector3.ZERO else facing
	f.y = 0.0
	if f.length_squared() < 0.0001:
		f = Vector3(surface_normal.x, 0.0, surface_normal.z)
	if f.length_squared() > 0.0001:
		facing = f.normalized()
	surface_normal = Vector3.UP
	motion_mode = MOTION_MODE_GROUNDED
	up_direction = Vector3.UP
	velocity = push
	_settle = 0.3


func climb_move(delta: float, speed: float) -> void:
	_clamber_fail = maxf(_clamber_fail - delta, 0.0)
	var n := surface_normal
	var input := move_input()
	if _jump_queued:
		# Leap off, away from the surface.
		_jump_queued = false
		var wish0 := surface_wish(input, n)
		var push := n * stats.jump_velocity * 0.9 + Vector3.UP * stats.jump_velocity * 0.6 * jump_scale() + wish0 * speed * 0.4
		_climb_cd = CLIMB_REGRAB
		_leap_off_t = 0.6
		stop_climb(push, n)
		move_and_slide()
		return
	if not _clamber.is_empty():
		_clamber_tick(delta, maxf(speed * 1.6, CLAMBER_SPEED))
		return
	var wish := surface_wish(input, n)
	var hit := _surface_ray(global_position + n * 0.4, global_position - n * 1.0)
	if hit.is_empty():
		# Over an edge: round onto the next face, or onto the top.
		var over := _climb_wrap(wish, n)
		if over.is_empty() or (over["normal"] as Vector3).y < -0.5:
			_climb_cd = 0.25
			stop_climb(n * 2.0, n)
			return
		var wn: Vector3 = over["normal"]
		global_position = (over["position"] as Vector3) + wn * 0.38
		if wn.y > 0.7:
			stop_climb(Vector3.ZERO, -n)
			return
		surface_normal = wn
	else:
		var hn: Vector3 = hit["normal"]
		if hn.y > 0.7:
			stop_climb(Vector3.ZERO, -n)
			return
		var dn := n.dot(hn)
		if hn.y < -0.5:
			pass
		elif dn > 0.9995 or dn <= -0.5:
			surface_normal = hn
		else:
			surface_normal = n.slerp(hn, 0.35).normalized()
	n = surface_normal
	wish = surface_wish(input, n)
	if wish.length() > 0.05:
		var from := global_position + n * 0.2
		var ahead := _surface_ray(from, from + wish.normalized() * 0.9)
		if not ahead.is_empty():
			var an: Vector3 = ahead["normal"]
			if an.dot(n) < 0.7:
				if an.y > 0.7:
					# Climbed down to the floor (or a ledge).
					stop_climb(Vector3.ZERO, n)
					return
				elif an.y < -0.5:
					# An overhang: clamber round its lip if it's a small one.
					if _clamber_fail <= 0.0 and wish.y > 0.3 and _start_clamber(n):
						return
					_clamber_fail = 0.5
					wish.y = minf(wish.y, 0.0)
				else:
					surface_normal = an
					n = an
					wish = surface_wish(input, n)
	up_direction = n
	var v := wish * speed
	if _dodge_time > 0.0:
		var dd := _dodge_dir - n * _dodge_dir.dot(n)
		if dd.length_squared() < 0.01:
			dd = wish if wish.length() > 0.1 else facing - n * facing.dot(n)
		v = dd.normalized() * stats.dodge_speed if dd.length_squared() > 0.0001 else Vector3.ZERO
	var ext := external_velocity
	velocity = v - n * CLIMB_STICK + ext
	move_and_slide()
	velocity -= ext
	if wish.length() > 0.05:
		facing = wish.normalized()


## Walked over a convex edge: look back under it for the next face.
func _climb_wrap(wish: Vector3, n: Vector3) -> Dictionary:
	var dir := wish.normalized() if wish.length() > 0.05 else facing
	dir = dir - n * dir.dot(n)
	if dir.length_squared() < 0.0001:
		return {}
	dir = dir.normalized()
	var origin := global_position - n * 0.7 + dir * 0.15
	return _surface_ray(origin, origin - dir * 1.6)


## Climbing up into an overhang (the lip of a counter, the edge of a table
## top): find its edge and plot a short clamber out, up and round it.
func _start_clamber(n: Vector3) -> bool:
	var pos := global_position
	var flat := Vector3(n.x, 0.0, n.z)
	if flat.length_squared() < 0.01:
		return false
	var out := flat.normalized()
	var k := 0.0
	var d := 0.6
	while d <= CLAMBER_REACH:
		var p := pos + out * d
		if not _surface_ray(pos, p).is_empty():
			return false
		if _surface_ray(p, p + Vector3.UP * 1.3).is_empty():
			k = d
			break
		d += 0.6
	if k == 0.0:
		return false
	# The lip's front face, just above us: climb on up it.
	for h: float in [0.9, 1.5, 2.1, 2.8]:
		var from := pos + out * (k + 0.4) + Vector3.UP * h
		var face := _surface_ray(from, from - out * (k + 0.8))
		if face.is_empty():
			continue
		var fn: Vector3 = face["normal"]
		var beside: Vector3 = (face["position"] as Vector3) + fn * 0.38
		var dist := (beside - pos).dot(out)
		if fn.dot(out) > 0.7 and dist > 0.4:
			_clamber = [pos + out * dist, beside] as Array[Vector3]
			_clamber_n = fn
			return true
		if fn.y > 0.7:
			# A thin lip: its top is right there.
			var top: Vector3 = (face["position"] as Vector3) + Vector3.UP * 0.4
			_clamber = [pos + out * (k + 0.4), Vector3(pos.x, top.y, pos.z) + out * (k + 0.4), top] as Array[Vector3]
			_clamber_n = Vector3.UP
			return true
	# Look down onto a thin lip's top.
	var above := pos + out * maxf(k - 0.5, 0.3) + Vector3.UP * 3.0
	var t := _surface_ray(above, above + Vector3.DOWN * 3.0)
	if t.is_empty() or (t["normal"] as Vector3).y < 0.7:
		return false
	var top2: Vector3 = (t["position"] as Vector3) + Vector3.UP * 0.4
	var outer := pos + out * (k + 0.4)
	_clamber = [outer, Vector3(outer.x, top2.y, outer.z), top2] as Array[Vector3]
	_clamber_n = Vector3.UP
	return true


func _clamber_tick(delta: float, speed: float) -> void:
	var target: Vector3 = _clamber[0]
	var to := target - global_position
	var step := speed * delta
	if to.length() <= step:
		global_position = target
		_clamber.pop_front()
		if _clamber.is_empty():
			if _clamber_n.y > 0.7:
				stop_climb(Vector3.ZERO, -surface_normal)
			else:
				surface_normal = _clamber_n
				up_direction = _clamber_n
		velocity = Vector3.ZERO
		return
	global_position += to.normalized() * step
	velocity = to.normalized() * speed
	if to.length() > 0.05:
		var f := to - surface_normal * to.dot(surface_normal)
		if f.length_squared() > 0.001:
			facing = f.normalized()


## Dash Burst: a long, untouchable dash the way you're heading.
func power_dash(seconds: float, mult: float) -> void:
	var dir := flat_dir(move_input())
	if dir.length() < 0.1:
		dir = fp_forward() if in_first_person() else facing
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	stop_climb()
	_dodge_dir = dir.normalized()
	_dodge_time = seconds
	_dash_mult = mult
	invuln = maxf(invuln, seconds + 0.1)
	AudioManager.play(&"dash", -2.0, 0.9)


## Where the middle of the screen points (on a surface within `max_dist` of
## the bug), or a spot that far ahead on the floor.
func aim_point(max_dist: float) -> Vector3:
	var ahead := fp_forward() if in_first_person() else -camera_yaw_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized() if ahead.length_squared() > 0.0001 else facing
	var fallback := global_position + ahead * max_dist
	if cam == null or not is_instance_valid(cam):
		return fallback
	var hit := _camera_ray(max_dist + cam.camera.global_position.distance_to(global_position))
	if hit.is_empty():
		return fallback
	var p: Vector3 = hit["position"]
	if p.distance_to(global_position) > max_dist:
		return global_position + (p - global_position).normalized() * max_dist
	return p + (hit["normal"] as Vector3) * 0.4


func _camera_ray(length: float) -> Dictionary:
	var c := cam.camera
	var center := c.get_viewport().get_visible_rect().size * 0.5
	var from := c.project_ray_origin(center)
	var q := PhysicsRayQueryParameters3D.create(from, from + c.project_ray_normal(center) * length, Phys.WORLD | Phys.PROP)
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)


# --- Silk Grapple (an add-on) -----------------------------------------------

const GRAPPLE_SPEED := 32.0
var _grapple_left := 0.0
var _grapple_to := Vector3.ZERO
var _grapple_n := Vector3.UP
var _grapple_from := Vector3.ZERO
var _silk: MeshInstance3D


## Zip to the surface at the middle of the screen, if it's within reach.
func grapple(max_dist: float) -> bool:
	if cam == null or not is_instance_valid(cam):
		return false
	var hit := _camera_ray(max_dist + cam.camera.global_position.distance_to(global_position))
	if hit.is_empty() or (hit["position"] as Vector3).distance_to(global_position) > max_dist:
		return false
	stop_climb()
	_grapple_n = hit["normal"]
	_grapple_to = (hit["position"] as Vector3) + _grapple_n * 0.45
	_grapple_from = global_position
	_grapple_left = global_position.distance_to(_grapple_to) / GRAPPLE_SPEED + 0.4
	AudioManager.play(&"web_shoot", -2.0, 1.1)
	return true


func is_grappling() -> bool:
	return _grapple_left > 0.0


func _grapple_tick(delta: float) -> void:
	_grapple_left -= delta
	var to := _grapple_to - global_position
	_draw_silk()
	var arrived := to.length() <= GRAPPLE_SPEED * delta + 0.1
	if arrived:
		# The last bit: finish exactly at the line's end, against the surface.
		global_position = _grapple_to
	else:
		velocity = to.normalized() * GRAPPLE_SPEED
		var was := motion_mode
		motion_mode = MOTION_MODE_FLOATING
		move_and_slide()
		motion_mode = was
		# Arrived when it touches the surface it aimed at (sliding along the
		# floor on the way doesn't count).
		for i in get_slide_collision_count():
			if get_slide_collision(i).get_normal().dot(_grapple_n) > 0.7 and global_position.distance_to(_grapple_to) < 2.5:
				arrived = true
	if arrived or _grapple_left <= 0.0:
		_grapple_left = 0.0
		if _silk:
			_silk.visible = false
		velocity = Vector3.ZERO
		if absf(_grapple_n.y) < 0.6 and can_climb():
			start_climb(_grapple_n)
		elif _grapple_n.y > 0.6:
			velocity = Vector3.DOWN


func _draw_silk() -> void:
	if _silk == null:
		_silk = MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 1.0
		cm.radial_segments = 6
		cm.rings = 1
		_silk.mesh = cm
		_silk.material_override = load("res://assets/materials/web.tres")
		_silk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_silk.top_level = true
		add_child(_silk)
	var a := _grapple_to
	var b := global_position
	var l := a.distance_to(b)
	if l < 0.1:
		_silk.visible = false
		return
	_silk.visible = true
	var dir := (a - b) / l
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var b2 := Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, PI * 0.5)
	_silk.global_transform = Transform3D(b2.scaled_local(Vector3(1, l, 1)), (a + b) * 0.5)


## Gravity while airborne (what a bounce pad aims with).
func air_gravity() -> float:
	return stats.gravity


## Flung by something springy: fly the arc, keeping the momentum. False if
## this bug can't be launched right now (a fly already in the air).
func launch(vel: Vector3, flight_time: float) -> bool:
	if dead or knockdown > 0.0:
		return false
	stop_climb()
	velocity = vel
	_leap_off_t = flight_time + 0.15
	_climb_cd = 0.3
	_coyote = 0.0
	_jump_buffer = 0.0
	return true


## Turn the body to the surface it's on.
func orient_to_surface(delta: float) -> void:
	if visual == null:
		return
	var n := surface_normal
	if in_first_person():
		facing = surface_wish(Vector2(0, 1), n)
	var f := facing - n * facing.dot(n)
	if f.length_squared() < 0.001:
		f = Vector3.UP - n * n.y
		if f.length_squared() < 0.001:
			f = Vector3.FORWARD - n * n.dot(Vector3.FORWARD)
	_turn_visual(Basis.looking_at(f.normalized(), n), clampf(14.0 * delta, 0.0, 1.0))


func _turn_visual(target: Basis, k: float) -> void:
	var cur := visual.global_basis.orthonormalized()
	var q := Quaternion(cur).slerp(Quaternion(target), k)
	var s := visual.scale
	visual.global_basis = Basis(q)
	visual.scale = s


func in_first_person() -> bool:
	return cam != null and is_instance_valid(cam) and cam.first_person


func face_velocity(delta: float) -> void:
	if climbing:
		orient_to_surface(delta)
		return
	if _settle > 0.0 and visual:
		# Just stepped off a wall: tip back upright.
		_settle = maxf(_settle - delta, 0.0)
		var yaw := atan2(-facing.x, -facing.z)
		if _settle <= 0.0:
			var s := visual.scale
			visual.rotation = Vector3(0.0, yaw, 0.0)
			visual.scale = s
		else:
			_turn_visual(Basis(Vector3.UP, yaw), clampf(16.0 * delta, 0.0, 1.0))
		return
	if in_first_person():
		# Through its eyes the bug faces where you look; it can still crab
		# sideways without the view swinging round.
		facing = fp_forward()
		if visual:
			visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-facing.x, -facing.z), clampf(30.0 * delta, 0.0, 1.0))
		return
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.5:
		facing = flat.normalized()
	if visual:
		var yaw := atan2(-facing.x, -facing.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, yaw, clampf(stats.turn_speed * delta, 0.0, 1.0))


func _try_dodge() -> void:
	if _dodge_cd > 0.0:
		return
	var dir := flat_dir(move_input())
	if dir.length() < 0.1:
		dir = facing
	_dodge_dir = dir.normalized()
	_dodge_time = stats.dodge_duration
	_dodge_cd = stats.dodge_cooldown
	invuln = maxf(invuln, stats.dodge_duration + 0.05)
	AudioManager.play(&"dash", -4.0)


func motion_speed() -> float:
	if climbing:
		return (velocity - surface_normal * velocity.dot(surface_normal)).length()
	return Vector2(velocity.x, velocity.z).length()


func is_sprinting() -> bool:
	return false


## Shift (the dash button): a tap dashes; keep holding it and you run.
const RUN_MULT := 1.55


func is_running() -> bool:
	return InputRouter.is_held(&"dodge") and move_input().length() > 0.1 and not is_squeezing \
		and stuck_time <= 0.0 and knockdown <= 0.0


## Ground speed while running (at least the bug's own sprint).
func run_speed() -> float:
	return maxf(stats.sprint_speed, stats.move_speed * RUN_MULT)


## Shrink power-up: the body eases down to a fraction of its size.
var _size := 1.0


func size_mult() -> float:
	return _size


## Subclasses that animate the body's height (squeezing, crouching) fold
## size_mult() into their own targets.
func _owns_visual_height() -> bool:
	return false


func _apply_size(delta: float) -> void:
	var want := float(effect_amount.get(&"shrink", 0.55)) if has_effect(&"shrink") else 1.0
	_size = move_toward(_size, want, delta * 2.0)
	if visual == null:
		return
	visual.scale.x = _size
	visual.scale.z = _size
	if not _owns_visual_height():
		visual.scale.y = _size


## Jumps go higher with Spring Legs.
func jump_scale() -> float:
	return float(effect_amount.get(&"spring", 1.8)) if has_effect(&"spring") else 1.0


func _update_motion(delta: float) -> void:
	var input_len := move_input().length()
	if input_len < 0.05 and motion_speed() < 0.6:
		motion = Motion.STILL
		still_time += delta
	else:
		still_time = 0.0
		if is_sprinting() or is_running():
			motion = Motion.SPRINT
		elif input_len < _cfg.creep_threshold:
			motion = Motion.CREEP
		else:
			motion = Motion.WALK


func _push_props() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var prop := c.get_collider() as PhysicsProp
		if prop:
			prop.push_by_bug(-c.get_normal() * stats.push_force)


# --- Stealth ------------------------------------------------------------------

func compute_visibility(light: float, cfg: StealthConfig) -> float:
	if is_hidden_safe():
		return 0.0
	var m := 1.0
	match motion:
		Motion.STILL:
			m = lerpf(1.0, cfg.freeze_factor, clampf(still_time / cfg.freeze_delay, 0.0, 1.0))
		Motion.CREEP:
			m = cfg.creep_visibility
		Motion.SPRINT:
			m = cfg.sprint_visibility
	var camo := 1.0
	if is_frozen() and has_camo():
		camo = cfg.camo_factor / maxf(stats.camo_mult, 0.01)
	var cloak := float(effect_amount.get(&"cloak", 0.2)) if has_effect(&"cloak") else 1.0
	var small := 0.6 if has_effect(&"shrink") else 1.0
	return clampf(light * m * camo * cloak * small * stats.visibility_mult * _extra_visibility_mult(), 0.0, 1.5)


func is_frozen() -> bool:
	return motion == Motion.STILL and still_time >= _cfg.freeze_delay


func has_camo() -> bool:
	var tag := current_camo_tag()
	return tag != &"" and stats.camo_tags.has(String(tag))


func current_camo_tag() -> StringName:
	if climbing and surface_normal.y < 0.7:
		return &"wall"
	return camo_tag


func _extra_visibility_mult() -> float:
	return 1.0


func _probe_surface() -> void:
	_probe.from = global_position + up_direction * 0.3
	_probe.to = global_position - up_direction * 1.2
	var hit := get_world_3d().direct_space_state.intersect_ray(_probe)
	if hit.is_empty():
		surface_id = &"air"
		camo_tag = &""
		return
	var col: Object = hit["collider"]
	surface_id = StringName(col.get_meta(&"surface", &"default")) if col else &"default"
	camo_tag = StringName(col.get_meta(&"camo", &"")) if col else &""


func current_noise() -> float:
	if motion == Motion.STILL or surface_id == &"air":
		return 0.0
	var mm := _cfg.walk_noise
	if motion == Motion.CREEP:
		mm = _cfg.creep_noise
	elif motion == Motion.SPRINT:
		mm = _cfg.sprint_noise
	return _cfg.loudness_of(surface_id) * mm * stats.noise_mult


func _emit_noise(delta: float) -> void:
	_noise_timer -= delta
	if _noise_timer > 0.0:
		return
	_noise_timer = _cfg.noise_interval
	var l := current_noise() * noise_scale()
	if l > 0.01:
		PerceptionSystem.emit_player_noise(global_position, l)


func is_scent_active() -> bool:
	return wiper_count <= 0 and not is_hidden_safe() and not has_effect(&"fresh") and not climbing and _leaves_scent()


func _leaves_scent() -> bool:
	return true


## How strong your scent trail is (1 = normal; it fades more slowly when higher).
func scent_strength() -> float:
	return 1.0


## Name of the bug's special move for the HUD meter ("" if none).
func ability_name() -> String:
	return ""


## Label of the HUD's stamina bar.
func stamina_name() -> String:
	return "WINGS"


## The ladybug: people don't swat it unless the alarm is full.
func is_spared_by_people() -> bool:
	return false


# --- Senses ---------------------------------------------------------------

func toggle_sense() -> void:
	if sense_active:
		_end_sense()
	elif sense_meter > 0.5:
		sense_active = true
		_sense_start()
		sense_changed.emit(true)
		AudioManager.play(&"sense_on", -6.0)


func _end_sense() -> void:
	if not sense_active:
		return
	sense_active = false
	_sense_end()
	sense_changed.emit(false)


func _update_sense(delta: float) -> void:
	if sense_active:
		if not has_effect(&"wired"):
			sense_meter -= delta
		_sense_tick(delta)
		if sense_meter <= 0.0:
			sense_meter = 0.0
			_end_sense()
	else:
		sense_meter = minf(sense_meter + stats.sense_regen * delta, stats.sense_max)
	meter_changed.emit(&"sense", sense_meter, stats.sense_max)


func _sense_start() -> void:
	pass


func _sense_tick(_delta: float) -> void:
	pass


func _sense_end() -> void:
	pass


# --- Damage & forces --------------------------------------------------------

## Returns true if the hit landed.
func take_hit(cause: StringName, from: Vector3) -> bool:
	if dead or invuln > 0.0 or is_hidden_safe():
		return false
	if has_effect(&"iron_shell"):
		AudioManager.play(&"shield", -2.0, 1.3)
		invuln = 0.5
		return false
	if has_effect(&"spikes"):
		# Spiky Armor: the hit glances off and whoever struck is stunned.
		var left := float(effect_amount.get(&"spikes", 1.0)) - 1.0
		if left <= 0.0:
			effects.erase(&"spikes")
			effect_amount.erase(&"spikes")
		else:
			effect_amount[&"spikes"] = left
		effects_changed.emit()
		for t in PerceptionSystem.threats:
			if t.present and t.global_position.distance_to(from) < 14.0:
				t.stun(3.0)
		AudioManager.play(&"shield", 0.0, 0.8)
		invuln = 0.6
		show_hint("Spiky Armor! The hit glanced off")
		return false
	_hurt(hit_damage())
	Feedback.rumble(1.0, 0.4)
	AudioManager.play(&"hit")
	if health <= 0.0:
		die(cause)
		return true
	invuln = stats.invuln_time
	knockdown = stats.knockdown_time
	stop_climb()
	var away := global_position - from
	away.y = 0.0
	if away.length() > 0.01:
		velocity = away.normalized() * 10.0 + Vector3.UP * 6.0
	hit_taken.emit(hits_left)
	if visual:
		var tw := create_tween()
		tw.tween_property(visual, "rotation:z", PI, 0.15)
		tw.tween_interval(maxf(stats.knockdown_time - 0.3, 0.05))
		tw.tween_property(visual, "rotation:z", 0.0, 0.15)
	return true


# --- Health ------------------------------------------------------------------

## Health one ordinary hit (a stomp, swat or bite) costs this bug.
func hit_damage() -> float:
	return MAX_HEALTH / float(maxi(stats.max_hits if stats else 1, 1))


## The most health can reach: full, plus one hit's worth from cheese.
func health_cap() -> float:
	return MAX_HEALTH + hit_damage()


func _hurt(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	if health < 0.05:
		health = 0.0
	_since_hurt = 0.0
	health_changed.emit(health, -amount)


## Heals by `amount` (crumbs, food, power-ups); only cheese (over = true) can
## go above full, and nothing takes away health already above it. Returns
## what was actually gained.
func add_health(amount: float, over: bool = false) -> float:
	if dead or amount <= 0.0:
		return 0.0
	var cap := health_cap() if over else maxf(MAX_HEALTH, health)
	var before := health
	health = minf(health + amount, cap)
	var gain := health - before
	if gain > 0.0:
		health_changed.emit(health, gain)
	return gain


## Healing on its own right now (nothing has hurt it for a while).
func is_regenerating() -> bool:
	return not dead and health > 0.0 and health < MAX_HEALTH and _since_hurt >= REGEN_DELAY


## True while a second snap would kill: snapped recently and not yet healed
## past what a snap takes.
func trap_danger() -> bool:
	return not dead and _since_snap < TRAP_BACK_TO_BACK and health <= TRAP_DAMAGE


## Caught under a snap trap's bar: knocked out cold for TRAP_KO_TIME and a
## big bite out of your health. One snap never kills; a second one back to
## back (before you've healed past it) does. False if the bar missed you
## (dodging, shielded, already out cold).
func snap_trap(at: Vector3) -> bool:
	if dead or knocked_out_left > 0.0 or invuln > 0.0 or is_hidden_safe():
		return false
	if has_effect(&"iron_shell"):
		AudioManager.play(&"shield", -2.0, 1.3)
		invuln = 0.6
		show_hint("Iron Shell! The bar bounced off")
		return false
	var back_to_back := _since_snap < TRAP_BACK_TO_BACK
	_since_snap = 0.0
	var dmg := TRAP_DAMAGE if back_to_back else minf(TRAP_DAMAGE, maxf(health - TRAP_FLOOR, 0.0))
	_hurt(dmg)
	Feedback.rumble(1.0, 0.6)
	AudioManager.play(&"hit", 2.0, 0.8)
	if health <= 0.0:
		die(&"snapped")
		return true
	knock_out(TRAP_KO_TIME, at)
	return true


## Out cold: flat on your back with stars going round, can't move, and
## nothing else can hurt you until you come to (a moment after).
func knock_out(seconds: float, _at: Vector3) -> void:
	stop_climb()
	is_squeezing = false
	knocked_out_left = seconds
	knockdown = maxf(knockdown, seconds)
	invuln = maxf(invuln, seconds + 0.5)
	velocity = Vector3.ZERO
	_show_stars(true)
	if visual:
		var tw := create_tween()
		tw.tween_property(visual, "rotation:z", PI, 0.12)
	knocked_out.emit(seconds)


func _come_to() -> void:
	_show_stars(false)
	if visual and not dead:
		var tw := create_tween()
		tw.tween_property(visual, "rotation:z", 0.0, 0.25)
	if not dead:
		show_hint("You come to - get off that trap!")


var _stars: Node3D


func _show_stars(on: bool) -> void:
	if not on:
		if _stars:
			_stars.visible = false
		return
	if _stars == null:
		_stars = Node3D.new()
		_stars.name = "DizzyStars"
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.86, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.2)
		mat.emission_energy_multiplier = 1.4
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for i in 3:
			var star := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.5, 0.5, 0.12)
			star.mesh = pm
			star.material_override = mat
			star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var a := TAU * i / 3.0
			star.position = Vector3(cos(a) * 0.9, 0.0, sin(a) * 0.9)
			_stars.add_child(star)
		add_child(_stars)
	var s := clampf(size_mult(), 0.6, 2.0)
	_stars.position = Vector3(0, 1.1 * s, 0)
	_stars.scale = Vector3.ONE * s
	_stars.visible = true


func _spin_stars(delta: float) -> void:
	if _stars and _stars.visible:
		_stars.rotate_y(delta * 4.0)
		for c in _stars.get_children():
			(c as Node3D).rotate_y(delta * 9.0)


func die(cause: StringName) -> void:
	if dead:
		return
	dead = true
	health = 0.0
	knocked_out_left = 0.0
	_show_stars(false)
	velocity = Vector3.ZERO
	is_squeezing = false
	_end_sense()
	AudioManager.play(&"squish")
	if visual:
		visual.visible = true
		var tw := create_tween()
		tw.tween_property(visual, "scale", Vector3(1.4, 0.12, 1.4), 0.1)
	died.emit(cause)


func add_spray_exposure(amount: float) -> void:
	spray_exposure += amount
	if spray_exposure >= _cfg.spray_exposure_to_hit:
		spray_exposure = 0.0
		take_hit(&"sprayed", global_position)


func apply_force(force: Vector3, delta: float) -> void:
	external_velocity = (external_velocity + force * delta).limit_length(40.0)


func set_slowed(mult: float, seconds: float) -> void:
	slow_mult = mult
	_slow_timer = seconds


func set_stuck(seconds: float) -> void:
	stuck_time = maxf(stuck_time, seconds)


func is_on_ground_surface() -> bool:
	return is_on_floor()


# --- Bug food & gem effects ------------------------------------------------

func add_effect(effect: StringName, seconds: float, amount: float = 1.0) -> void:
	effects[effect] = maxf(float(effects.get(effect, 0.0)), seconds)
	effect_amount[effect] = amount
	effects_changed.emit()


func has_effect(effect: StringName) -> bool:
	return float(effects.get(effect, 0.0)) > 0.0


func effect_left(effect: StringName) -> float:
	return maxf(float(effects.get(effect, 0.0)), 0.0)


func clear_effects() -> void:
	effects.clear()
	effect_amount.clear()
	effects_changed.emit()


func _tick_effects(delta: float) -> void:
	if effects.is_empty():
		return
	var ended := false
	for k: StringName in effects.keys():
		effects[k] = float(effects[k]) - delta
		if effects[k] <= 0.0:
			effects.erase(k)
			effect_amount.erase(k)
			ended = true
	if ended:
		effects_changed.emit()


## Movement speed multiplier: slowdowns (glue, sticky webs) and Sugar Rush.
func speed_scale() -> float:
	var s := slow_mult
	if has_effect(&"speed"):
		s *= float(effect_amount.get(&"speed", 1.35))
	if has_effect(&"turbo"):
		s *= float(effect_amount.get(&"turbo", 1.6))
	return s


func noise_scale() -> float:
	return float(effect_amount.get(&"soft_step", 0.3)) if has_effect(&"soft_step") else 1.0


## Sugar Rush tops up the bug's meters. Subclasses add their own (stamina).
func refill() -> void:
	sense_meter = stats.sense_max


## Cheese: one more hit of shell, up to one above the bug's normal maximum.
func heal(amount: int = 1) -> void:
	add_health(float(amount) * hit_damage(), true)
	effects_changed.emit()


func _magnet_tick(delta: float) -> void:
	if not has_effect(&"magnet"):
		return
	var radius := float(effect_amount.get(&"magnet", 25.0))
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb == null or crumb.taken or crumb.golden:
			continue
		if crumb.global_position.distance_to(global_position) < radius:
			crumb.global_position = crumb.global_position.move_toward(global_position, 30.0 * delta)


# --- Hiding & interaction ---------------------------------------------------

func enter_spot(s: HidingSpot) -> void:
	if not _spots.has(s):
		_spots.append(s)


func exit_spot(s: HidingSpot) -> void:
	_spots.erase(s)


func is_hidden_safe() -> bool:
	for s in _spots:
		if s.is_safe_for(self):
			return true
	return false


func add_interactable(n: Node) -> void:
	if not _interactables.has(n):
		_interactables.append(n)


func remove_interactable(n: Node) -> void:
	_interactables.erase(n)


func _do_interact() -> void:
	for n in _interactables:
		if is_instance_valid(n) and n.call(&"can_interact", self):
			n.call(&"interact", self)
			return
	var best: PhysicsProp = null
	var best_d := INTERACT_PROP_RADIUS
	for p in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := p as PhysicsProp
		if prop:
			var d := prop.global_position.distance_to(global_position)
			if d < best_d:
				best = prop
				best_d = d
	if best:
		best.nudge(global_position)
		AudioManager.play(&"push", -6.0)


func _update_hint() -> void:
	var text := ""
	for n in _interactables:
		if is_instance_valid(n):
			text = String(n.call(&"hint_text", self))
			break
	if text == "":
		for s in _spots:
			if s.fits(self):
				text = "Hidden" if s.is_safe_for(self) else s.hint
				break
	if stuck_time > 0.0:
		text = "Stuck! Mash any button"
	if text != _hint:
		_hint = text
		hint_changed.emit(text)


func show_hint(text: String) -> void:
	_hint = text
	hint_changed.emit(text)


func teleport_to(xform: Transform3D) -> void:
	stop_climb()
	_grapple_left = 0.0
	if _silk:
		_silk.visible = false
	_settle = 0.0
	if visual:
		var s := visual.scale
		visual.rotation = Vector3(0.0, visual.rotation.y, 0.0)
		visual.scale = s
	global_position = xform.origin
	velocity = Vector3.ZERO
	_jump_buffer = 0.0
	reset_physics_interpolation()
	_interactables.clear()
	if cam:
		cam.snap()
