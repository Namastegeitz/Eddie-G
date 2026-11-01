class_name LureProp
extends Area3D
## A distraction that makes noise/light somewhere other than where you are.
##   PHONE  - run across it (or press USE) and the screen lights up and buzzes.
##   SPOON  - USE it, or hit it with a web line, and it clatters.
##   REMOTE - USE it and the TV blares: a huge lure that also masks your noise.

enum Kind { PHONE, SPOON, REMOTE }

@export var kind: Kind = Kind.SPOON
@export var loudness: float = 2.5
@export var cooldown: float = 8.0
## Where the noise comes from (defaults to this node).
@export var noise_origin_path: NodePath
## REMOTE: the TV's AmbientNoise to boost. PHONE: a LightZone to flash.
@export var linked_path: NodePath
@export var glow_path: NodePath

var _cd := 0.0


func _ready() -> void:
	add_to_group(Phys.GROUP_INTERACTABLE)
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var glow := get_node_or_null(glow_path) as Node3D
	if glow:
		glow.visible = false


func _physics_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta


func hint_text(_bug: BugBase) -> String:
	match kind:
		Kind.PHONE:
			return "USE: light up the phone (lure)"
		Kind.REMOTE:
			return "USE: blast the TV (lure + cover)"
	return "USE: clatter the spoon (lure)"


func can_interact(_bug: BugBase) -> bool:
	return _cd <= 0.0


func interact(_bug: BugBase) -> void:
	trigger(true)


## by_player = true counts toward the "lures used" score.
func trigger(by_player: bool) -> void:
	if _cd > 0.0:
		return
	_cd = cooldown
	var origin := get_node_or_null(noise_origin_path) as Node3D
	var pos := origin.global_position if origin else global_position
	match kind:
		Kind.PHONE:
			AudioManager.play_at(&"phone_buzz", pos)
			var zone := get_node_or_null(linked_path) as LightZone
			if zone:
				zone.flash(4.0)
			_glow(4.0)
		Kind.SPOON:
			AudioManager.play_at(&"clatter", pos)
		Kind.REMOTE:
			AudioManager.play_at(&"tv_blare", pos, 4.0)
			var tv := get_node_or_null(linked_path) as AmbientNoise
			if tv:
				tv.boost(0.8, 8.0)
	PerceptionSystem.emit_world_noise(pos, loudness)
	if by_player and Level.current:
		Level.current.note_lure_used()


func _glow(seconds: float) -> void:
	var glow := get_node_or_null(glow_path) as Node3D
	if glow == null:
		return
	glow.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(glow):
			glow.visible = false)


func _on_body_entered(b: Node3D) -> void:
	if b is BugBase:
		(b as BugBase).add_interactable(self)
		if kind == Kind.PHONE:
			trigger(true)


func _on_body_exited(b: Node3D) -> void:
	if b is BugBase:
		(b as BugBase).remove_interactable(self)
