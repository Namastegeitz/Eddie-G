class_name PhysicsProp
extends RigidBody3D
## Pushable / knockable household object (pea, grape, mug, cereal box, ball,
## a glass, a teacup, a potted plant, a domino).
## Lands with a clatter that threats investigate, stuns any threat it hits
## hard, and (trip hazard) trips a human who steps on it. Knocked off a table
## or counter it crashes (commotion): everyone in the room stops to look at
## it for a moment and then goes to check; glass and china shatter and a
## clay pot breaks and spills its soil (fragile).

@export var noise_on_impact: float = 1.6
@export var impact_speed: float = 5.0
@export var stuns_threats: bool = true
@export var trip_hazard: bool = false
@export var impact_sound: StringName = &"clatter"
@export var nudge_strength: float = 4.0
## Seconds everyone in the room stares when it crashes down from a height
## (0 = it only clatters). See PerceptionSystem.commotion.
@export var commotion: float = 0.0
## How hard it has to land to count as a crash (gravity is 30: falling off a
## coffee table lands at ~30, off a counter at ~48; knocked over on the
## floor it's well under 10).
@export var crash_speed: float = 14.0
@export var crash_sound: StringName = &""
## Breaks when it crashes (glass, china, a clay pot).
@export var fragile: bool = false
## Tall and thin (a domino): a push lands this high above its middle, so it
## topples over instead of sliding.
@export var tip_height: float = 0.0
var broken := false

var _last_speed := 0.0
var _cd := 0.0
var _touched_by_player := 0.0
var _npc_cd := 0.0
## Being batted / thrown in play by a pet or a person: its bumps don't stun
## anyone and don't count as your trick.
var _played := 0.0


func _ready() -> void:
	add_to_group(Phys.GROUP_PROP)
	collision_layer = Phys.PROP
	collision_mask = Phys.WORLD | Phys.PROP | Phys.PLAYER | Phys.THREAT
	contact_monitor = true
	max_contacts_reported = 4
	can_sleep = true
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_last_speed = linear_velocity.length()
	if _cd > 0.0:
		_cd -= delta
	if _touched_by_player > 0.0:
		_touched_by_player -= delta
	if _played > 0.0:
		_played -= delta
	if _npc_cd > 0.0:
		_npc_cd -= delta


## Pushed by the player (USE or walking into it).
func nudge(from: Vector3, strength_mult: float = 1.0) -> void:
	freeze = false
	sleeping = false
	var dir := global_position - from
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	apply_central_impulse((dir.normalized() + Vector3.UP * 0.25) * nudge_strength * mass * strength_mult)
	_touched_by_player = 6.0


## Knocked aside by a person's foot, a broom, a running pet or the vacuum
## (not the player: it doesn't count as your trick).
func push_by_npc(from: Vector3, strength_mult: float = 1.0) -> void:
	if _npc_cd > 0.0:
		return
	freeze = false
	sleeping = false
	var dir := global_position - from
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	apply_central_impulse((dir.normalized() + Vector3.UP * 0.2) * nudge_strength * mass * strength_mult)
	mark_played(2.0)
	_npc_cd = 0.4


func mark_touched() -> void:
	_touched_by_player = 6.0


## A pet or person is playing with it (see Pet play, Human fetch).
func mark_played(seconds: float = 3.0) -> void:
	_played = seconds
	_touched_by_player = 0.0


func is_in_play() -> bool:
	return _played > 0.0


## Pushed by a bug walking into it (BugBase._push_props).
func push_by_bug(impulse: Vector3) -> void:
	freeze = false
	sleeping = false
	if tip_height > 0.0:
		apply_impulse(impulse, Vector3.UP * tip_height)
	else:
		apply_central_impulse(impulse)
	mark_touched()


func _on_body_entered(body: Node) -> void:
	if broken or _last_speed < impact_speed or _cd > 0.0:
		return
	_cd = 0.6
	var crash := commotion > 0.0 and _last_speed >= crash_speed
	if _played > 0.0 and not crash:
		AudioManager.play_at(impact_sound, global_position, -8.0, randf_range(1.0, 1.2))
		PerceptionSystem.emit_world_noise(global_position, noise_on_impact * 0.4)
		return
	if crash:
		AudioManager.play_at(crash_sound if crash_sound != &"" else impact_sound, global_position, 3.0, randf_range(0.92, 1.08))
		PerceptionSystem.emit_world_noise(global_position, noise_on_impact * 1.5)
		PerceptionSystem.commotion(global_position, commotion)
	else:
		AudioManager.play_at(impact_sound, global_position, 0.0, randf_range(0.9, 1.15))
		PerceptionSystem.emit_world_noise(global_position, noise_on_impact)
	if crash and fragile:
		_shatter.call_deferred()
	if _touched_by_player > 0.0 and Level.current:
		Level.current.note_lure_used()
	if not stuns_threats:
		return
	# A human's feet are separate bodies that point back at their owner.
	var t := body as Threat
	if t == null and body.has_meta(&"threat"):
		t = body.get_meta(&"threat") as Threat
	if t:
		t.stun()


## Called by a FootHazard that lands on this prop.
func on_stepped_on(by: Threat) -> void:
	if trip_hazard and by and _played <= 0.0:
		AudioManager.play_at(&"squish", global_position)
		by.stun()
		apply_central_impulse(Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)) * 3.0 * mass)


## Breaks: the pieces scatter, glint and fade, and the thing itself is gone.
func _shatter() -> void:
	if broken or not is_inside_tree():
		return
	broken = true
	var mats: Array[Material] = []
	for n in find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.material_override:
			mats.append(mi.material_override)
		elif mi.mesh:
			for i in mi.mesh.get_surface_count():
				var m := mi.get_active_material(i)
				if m:
					mats.append(m)
	var parent: Node = Level.current if Level.current else get_parent()
	Shards.burst(parent, global_position, mats, 9)
	visible = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	queue_free.call_deferred()
