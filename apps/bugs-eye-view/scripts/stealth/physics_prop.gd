class_name PhysicsProp
extends RigidBody3D
## Pushable / knockable household object (pea, grape, mug, cereal box, ball).
## Lands with a clatter that threats investigate, stuns any threat it hits
## hard, and (trip hazard) trips a human who steps on it.

@export var noise_on_impact: float = 1.6
@export var impact_speed: float = 5.0
@export var stuns_threats: bool = true
@export var trip_hazard: bool = false
@export var impact_sound: StringName = &"clatter"
@export var nudge_strength: float = 4.0

var _last_speed := 0.0
var _cd := 0.0
var _touched_by_player := 0.0


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


func mark_touched() -> void:
	_touched_by_player = 6.0


func _on_body_entered(body: Node) -> void:
	if _last_speed < impact_speed or _cd > 0.0:
		return
	_cd = 0.6
	AudioManager.play_at(impact_sound, global_position, 0.0, randf_range(0.9, 1.15))
	PerceptionSystem.emit_world_noise(global_position, noise_on_impact)
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
	if trip_hazard and by:
		AudioManager.play_at(&"squish", global_position)
		by.stun()
		apply_central_impulse(Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)) * 3.0 * mass)
