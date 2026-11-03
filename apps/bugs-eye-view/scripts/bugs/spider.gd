class_name Spider
extends BugBase
## Sticks to floors, walls and ceilings (re-orienting to the surface normal),
## zips along web lines that stay behind as walkable bridges, spins web traps
## that slow small threats, and feels footsteps as ripples through surfaces.
## Slow and exposed on open floor; rewards staying on walls and in corners.

const STICK_FORCE := 3.0
const RIPPLE_INTERVAL := 0.45
const STRAND_SCENE := "res://scenes/bugs/web_strand.tscn"
const TRAP_SCENE := "res://scenes/bugs/web_trap.tscn"

var surface_normal := Vector3.UP
var attached := true
var zipping := false
var _zip_target := Vector3.ZERO
var _zip_normal := Vector3.UP
var _zip_start := Vector3.ZERO
var _web_cd := 0.0
var _ripple_timer := 0.0
var _surf := PhysicsRayQueryParameters3D.new()
var _aim := PhysicsRayQueryParameters3D.new()
var _strand_pool: NodePool
var _trap_pool: NodePool
var _zip_line: Node3D


func _setup() -> void:
	motion_mode = MOTION_MODE_FLOATING
	_surf.collision_mask = Phys.WORLD | Phys.PROP | Phys.WEB
	_surf.exclude = [get_rid()]
	_aim.collision_mask = Phys.WORLD | Phys.PROP | Phys.PICKUP
	_aim.collide_with_areas = true
	_aim.exclude = [get_rid()]
	var host := get_parent()
	_strand_pool = NodePool.from_scene(load(STRAND_SCENE), host, 2)
	_trap_pool = NodePool.from_scene(load(TRAP_SCENE), host, 1)
	_zip_line = get_node_or_null("ZipLine")
	if _zip_line:
		_zip_line.visible = false
	InputRouter.aim_at_screen.connect(_fire_web)


func get_action_labels() -> Dictionary:
	return {"primary": "Web zip", "secondary": "Web trap", "jump": "Leap",
		"dodge": "Skitter", "interact": "Use", "sense": "Feel"}


func _action_pressed(a: StringName) -> void:
	match a:
		&"primary":
			if cam:
				_fire_web(cam.screen_center())
		&"secondary":
			_spin_trap()


func _move(delta: float) -> void:
	_web_cd = maxf(_web_cd - delta, 0.0)
	if zipping:
		_zip_move(delta)
	elif attached:
		_crawl(delta)
	else:
		_fall(delta)
	_orient_visual(delta)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	_surf.from = from
	_surf.to = to
	return get_world_3d().direct_space_state.intersect_ray(_surf)


## Camera-relative direction projected onto the current surface. On walls,
## pushing "forward" while facing the wall climbs up it.
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


func _crawl(_delta: float) -> void:
	var n := surface_normal
	var input := move_input()
	var wish := surface_wish(input, n)
	var hit := _ray(global_position + n * 0.4, global_position - n * 1.0)
	if hit.is_empty():
		if not _wrap_edge(wish, n):
			attached = false
			surface_normal = Vector3.UP
			return
	else:
		var hn: Vector3 = hit["normal"]
		# Ease toward the new normal; skip near-identical normals, where slerp's
		# rotation axis degenerates.
		var dn := n.dot(hn)
		if dn > 0.9995 or dn <= -0.5:
			surface_normal = hn
		else:
			surface_normal = n.slerp(hn, 0.35).normalized()
	n = surface_normal
	if wish.length() > 0.05:
		var ahead := _ray(global_position + n * 0.2, global_position + n * 0.2 + wish.normalized() * 0.9)
		if not ahead.is_empty():
			var an: Vector3 = ahead["normal"]
			if an.dot(n) < 0.7:
				surface_normal = an
				n = an
				wish = surface_wish(input, n)
	var on_floor := n.dot(Vector3.UP) > 0.7
	var speed := (stats.move_speed * stats.floor_speed_mult if on_floor else stats.wall_speed) * speed_scale()
	up_direction = n
	var v := wish * speed
	if _dodge_time > 0.0:
		v = _dodge_dir * stats.dodge_speed
	if _jump_queued:
		_jump_queued = false
		attached = false
		velocity = n * stats.jump_velocity + v
		surface_normal = Vector3.UP
		up_direction = Vector3.UP
		move_and_slide()
		return
	var ext := external_velocity
	velocity = v - n * STICK_FORCE + ext
	move_and_slide()
	velocity -= ext
	if wish.length() > 0.05:
		facing = wish.normalized()


## Walked over a convex edge: look back under it for the next face.
func _wrap_edge(wish: Vector3, n: Vector3) -> bool:
	var dir := wish.normalized() if wish.length() > 0.05 else facing
	dir = (dir - n * dir.dot(n))
	if dir.length_squared() < 0.0001:
		return false
	dir = dir.normalized()
	var origin := global_position - n * 0.7 + dir * 0.15
	var hit := _ray(origin, origin - dir * 1.6)
	if hit.is_empty():
		return false
	surface_normal = hit["normal"]
	global_position = (hit["position"] as Vector3) + surface_normal * 0.4
	return true


func _fall(delta: float) -> void:
	_jump_queued = false
	velocity.y -= stats.gravity * delta
	var air := surface_wish(move_input(), Vector3.UP) * stats.move_speed
	velocity.x = move_toward(velocity.x, air.x, 10.0 * delta)
	velocity.z = move_toward(velocity.z, air.z, 10.0 * delta)
	move_and_slide()
	if get_slide_collision_count() > 0:
		surface_normal = get_slide_collision(0).get_normal()
		attached = true
		up_direction = surface_normal


func _orient_visual(delta: float) -> void:
	if visual == null:
		return
	var n := surface_normal
	var f := facing - n * facing.dot(n)
	if f.length_squared() < 0.001:
		f = Vector3.FORWARD - n * n.dot(Vector3.FORWARD)
		if f.length_squared() < 0.001:
			f = Vector3.RIGHT - n * n.dot(Vector3.RIGHT)
	var target := Basis.looking_at(f.normalized(), n)
	var cur := visual.global_basis.orthonormalized()
	var q := Quaternion(cur).slerp(Quaternion(target), clampf(14.0 * delta, 0.0, 1.0))
	var s := visual.scale
	visual.global_basis = Basis(q)
	visual.scale = s


func motion_speed() -> float:
	var n := surface_normal
	return (velocity - n * velocity.dot(n)).length()


func current_camo_tag() -> StringName:
	if attached and surface_normal.dot(Vector3.UP) < 0.7:
		return &"wall"
	return camo_tag


func _leaves_scent() -> bool:
	return attached and surface_normal.y > 0.7


func _try_dodge() -> void:
	if _dodge_cd > 0.0 or not attached:
		return
	var dir := surface_wish(move_input(), surface_normal)
	if dir.length() < 0.1:
		dir = facing
	_dodge_dir = dir.normalized()
	_dodge_time = stats.dodge_duration
	_dodge_cd = stats.dodge_cooldown
	invuln = maxf(invuln, stats.dodge_duration + 0.05)
	AudioManager.play(&"dash", -6.0, 1.4)


func teleport_to(xform: Transform3D) -> void:
	super.teleport_to(xform)
	zipping = false
	attached = true
	surface_normal = xform.basis.y.normalized()
	up_direction = surface_normal


# --- Web line ---------------------------------------------------------------

func _fire_web(screen_pos: Vector2) -> void:
	if dead or zipping or _web_cd > 0.0 or cam == null or stuck_time > 0.0:
		return
	var camera := cam.camera
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var cam_dist := from.distance_to(global_position)
	_aim.from = from
	_aim.to = from + dir * (stats.web_range + cam_dist)
	var hit := get_world_3d().direct_space_state.intersect_ray(_aim)
	if hit.is_empty() or (hit["position"] as Vector3).distance_to(global_position) > stats.web_range:
		AudioManager.play(&"web_miss", -6.0)
		show_hint("Out of web range")
		return
	_web_cd = stats.web_cooldown
	var col: Object = hit["collider"]
	var pos: Vector3 = hit["position"]
	AudioManager.play_at(&"web_shoot", global_position)
	if col is LureProp:
		(col as LureProp).trigger(true)
		_flash_line(global_position, pos)
		return
	if col is PhysicsProp:
		var prop := col as PhysicsProp
		prop.freeze = false
		prop.apply_central_impulse((global_position - pos).normalized() * 3.0 * prop.mass + Vector3.UP * prop.mass)
		prop.mark_touched()
		_flash_line(global_position, pos)
		return
	zipping = true
	attached = false
	_zip_start = global_position
	_zip_normal = hit["normal"]
	_zip_target = pos + _zip_normal * 0.4


func _zip_move(_delta: float) -> void:
	var to := _zip_target - global_position
	var step := stats.zip_speed * get_physics_process_delta_time()
	_draw_line(_zip_start, global_position)
	if to.length() <= step + 0.05:
		global_position = _zip_target
		_attach_after_zip(_zip_normal)
		return
	velocity = to.normalized() * stats.zip_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		_attach_after_zip(get_slide_collision(0).get_normal())


func _attach_after_zip(n: Vector3) -> void:
	zipping = false
	attached = true
	surface_normal = n
	up_direction = n
	velocity = Vector3.ZERO
	if _zip_line:
		_zip_line.visible = false
	if _zip_start.distance_to(global_position) > 2.0:
		var strand := _strand_pool.acquire() as WebStrand
		strand.setup(_zip_start, global_position, stats.bridge_duration, _strand_pool)


func _draw_line(a: Vector3, b: Vector3) -> void:
	if _zip_line == null:
		return
	var seg_len := a.distance_to(b)
	if seg_len < 0.05:
		_zip_line.visible = false
		return
	_zip_line.visible = true
	var mid := (a + b) * 0.5
	var dir := (b - a) / seg_len
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	_zip_line.global_transform = Transform3D(Basis.looking_at(dir, up) * Basis.from_scale(Vector3(1, 1, seg_len)), mid)


func _flash_line(a: Vector3, b: Vector3) -> void:
	_draw_line(a, b)
	get_tree().create_timer(0.15).timeout.connect(_hide_line)


func _hide_line() -> void:
	if _zip_line and not zipping:
		_zip_line.visible = false


func _spin_trap() -> void:
	if _web_cd > 0.0 or not attached:
		return
	_web_cd = stats.web_cooldown
	var trap := _trap_pool.acquire() as WebTrap
	trap.setup(global_position - surface_normal * 0.3, surface_normal, stats.web_trap_duration, _trap_pool)
	AudioManager.play_at(&"web_shoot", global_position, -4.0, 0.7)


# --- Vibration sense --------------------------------------------------------

func _sense_tick(delta: float) -> void:
	_ripple_timer -= delta
	if _ripple_timer > 0.0:
		return
	_ripple_timer = RIPPLE_INTERVAL
	var lvl := Level.current
	if lvl == null:
		return
	for t in PerceptionSystem.threats:
		if t.present and t.global_position.distance_to(global_position) <= stats.sense_range:
			var r := lvl.ripple_pool.acquire() as Ripple
			r.play(t.ground_position(), Ripple.color_for(t.alert.state), lvl.ripple_pool)


## Footstep impacts call this so the spider can feel them through surfaces.
func on_vibration(pos: Vector3) -> void:
	if sense_active and Level.current and pos.distance_to(global_position) <= stats.sense_range:
		var r := Level.current.ripple_pool.acquire() as Ripple
		r.play(pos, Color(1, 0.6, 0.2), Level.current.ripple_pool)
