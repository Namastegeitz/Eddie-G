class_name Sweeper
extends Node3D
## A broom (the cook sweeping) or a rake (the gardener): the head swings side
## to side across the floor in front of them. It shoves a bug aside (no
## harm, but it carries you along and gives you away), pushes crumbs along
## with it and knocks small things out of the way.

const HEAD_RADIUS := 4.5
const PUSH := 70.0

var kind := &"broom"
var holder: Human
var _t := 0.0
var _head: Node3D
var _handle: MeshInstance3D
var _last_head := Vector3.INF
var _sound_cd := 0.0
var _hint_cd := 0.0
## A bump with the bristles: they notice a moment later ("what was that?").
var _notice_in := -1.0
const NOTICE_AFTER := 0.35
## Where the head sweeps, relative to the holder: forward reach and swing.
var reach := 11.0
var swing := 7.0


static func make(tool_kind: StringName, by: Human) -> Sweeper:
	var s := Sweeper.new()
	s.name = "RakeSweep" if tool_kind == &"rake" else "BroomSweep"
	s.kind = tool_kind
	s.holder = by
	return s


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_head = Node3D.new()
	_head.name = "Head"
	add_child(_head)
	var bristles := MeshInstance3D.new()
	if kind == &"rake":
		var bar := BoxMesh.new()
		bar.size = Vector3(9.0, 0.6, 0.8)
		bristles.mesh = bar
		bristles.material_override = load("res://assets/materials/dark_metal.tres")
		bristles.position = Vector3(0, 1.2, 0)
		for i in 9:
			var tine := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.25, 1.2, 0.25)
			tine.mesh = tm
			tine.material_override = bristles.material_override
			tine.position = Vector3(-4.0 + i * 1.0, 0.6, 0.2)
			_head.add_child(tine)
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(8.0, 2.4, 2.2)
		bristles.mesh = bm
		bristles.material_override = load("res://assets/materials/leaves.tres")
		bristles.position = Vector3(0, 1.2, 0)
	_head.add_child(bristles)
	_handle = MeshInstance3D.new()
	_handle.name = "Handle"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.45
	cm.bottom_radius = 0.45
	cm.height = 10.0
	cm.radial_segments = 10
	_handle.mesh = cm
	_handle.material_override = load("res://assets/materials/wood.tres")
	add_child(_handle)


## Where the head is this moment.
func head_position() -> Vector3:
	return _head.global_position


func _physics_process(delta: float) -> void:
	if holder == null or not is_instance_valid(holder):
		queue_free()
		return
	_t += delta
	var fwd := -holder.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP)
	var rate := 2.2 if kind == &"broom" else 1.6
	var side := sin(_t * rate)
	var pos := holder.global_position + fwd * reach + right * side * swing
	pos.y = holder.global_position.y
	_head.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), pos)
	# The handle: from the hands down to the head.
	var hands := holder.global_transform * Vector3(0, 40, -6)
	Human._place_bone(_handle, pos + Vector3.UP * 1.5, hands, 10.0)
	var vel := Vector3.ZERO
	if _last_head != Vector3.INF:
		vel = (pos - _last_head) / maxf(delta, 0.001)
	_last_head = pos
	_sound_cd -= delta
	_hint_cd -= delta
	if _sound_cd <= 0.0:
		_sound_cd = PI / rate
		AudioManager.play_at(&"sweep", pos, -4.0 if kind == &"broom" else -8.0, randf_range(0.9, 1.1))
	_shove(pos, vel, delta)


func _shove(pos: Vector3, vel: Vector3, delta: float) -> void:
	var flat_vel := Vector3(vel.x, 0.0, vel.z)
	var p := PerceptionSystem.player
	if p and not p.dead and not p.is_hidden_safe() and not (p is Fly and (p as Fly).flying):
		var to := p.global_position - pos
		if absf(to.y) < 3.0 and Vector2(to.x, to.z).length() < HEAD_RADIUS:
			# Carried along with the bristles, and nudged out from under them.
			var out := Vector3(to.x, 0.0, to.z).normalized() if Vector2(to.x, to.z).length() > 0.1 else Vector3.FORWARD
			var carry := flat_vel * 1.05 + out * 6.0
			p.external_velocity = p.external_velocity.move_toward(carry.limit_length(30.0), PUSH * 3.0 * delta)
			if _notice_in < 0.0:
				_notice_in = NOTICE_AFTER
				# The first bump flicks you out from under the bristles.
				p.external_velocity += out * 12.0 + flat_vel.limit_length(12.0) * 0.5
			if _hint_cd <= 0.0:
				_hint_cd = 4.0
				p.show_hint("Swept along! Get out from under the %s" % String(kind))
	if _notice_in >= 0.0:
		_notice_in -= delta
		if _notice_in < 0.0 and p and holder.alert.state == AlertState.UNAWARE:
			# Something skittered out from under the bristles.
			holder.alert.force(AlertState.SUSPICIOUS, p.global_position)
	# Crumbs ride along in front of the bristles.
	for c in get_tree().get_nodes_in_group(Phys.GROUP_CRUMB):
		var crumb := c as Crumb
		if crumb == null or crumb.taken or crumb.golden:
			continue
		var d := crumb.global_position - pos
		if absf(d.y) < 3.0 and Vector2(d.x, d.z).length() < HEAD_RADIUS:
			var moved := crumb.global_position + flat_vel * delta
			if Level.current == null or Level.current.is_open_floor(Vector3(moved.x, crumb.global_position.y, moved.z)):
				crumb.global_position = moved
	# Small things get knocked aside.
	for n in get_tree().get_nodes_in_group(Phys.GROUP_PROP):
		var prop := n as PhysicsProp
		if prop and prop.global_position.distance_to(pos) < HEAD_RADIUS + 1.0 and prop.mass < 3.0:
			prop.push_by_npc(pos - flat_vel.normalized() * 2.0, 0.6)
