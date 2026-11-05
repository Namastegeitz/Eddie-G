class_name LightZone
extends Area3D
## Authored light volume (shadow / dim / lit / bright). Used instead of
## sampling real-time lighting so stealth stays cheap on phones. Routine
## events (fridge open, lamp on, sunbeam) switch zones and their lights.

@export_enum("Shadow", "Dim", "Lit", "Bright") var light_level: int = 0
@export var zone_priority: int = 1
## Active only during these routine events (empty = always).
@export var active_events: PackedStringArray = []
## Switched off during these events.
@export var inactive_events: PackedStringArray = []
## Optional light / mesh switched together with the zone.
@export var linked_nodes: Array[NodePath] = []

var _active := true
var _forced := 0.0
## Set by people (curtains drawn): -1 none, 0 off, 1 on.
var _override := -1
var _override_time := 0.0


func _ready() -> void:
	collision_layer = Phys.ZONE
	collision_mask = Phys.PLAYER
	monitorable = false
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	HouseClock.routine_changed.connect(_refresh)
	_refresh()


func is_active() -> bool:
	if _override_time > 0.0:
		return _override == 1
	return _active or _forced > 0.0


## Someone switched it (curtains drawn, a lamp clicked off) for `seconds`.
func override(on: bool, seconds: float) -> void:
	_override = 1 if on else 0
	_override_time = seconds
	_apply_links(on)
	set_process(true)


## Temporarily turns the zone on (phone screen lighting up).
func flash(seconds: float) -> void:
	_forced = seconds
	_apply_links(true)
	set_process(true)


func _process(delta: float) -> void:
	if _override_time > 0.0:
		_override_time -= delta
		if _override_time <= 0.0:
			_override = -1
			_apply_links(_active or _forced > 0.0)
		return
	if _forced > 0.0:
		_forced -= delta
		if _forced <= 0.0:
			_apply_links(_active)
			set_process(false)
	elif _override_time <= 0.0:
		set_process(false)


func _refresh() -> void:
	_active = (active_events.is_empty() or HouseClock.any_active(active_events)) \
		and not HouseClock.any_active(inactive_events)
	if _override_time > 0.0:
		return
	_apply_links(_active or _forced > 0.0)


func _apply_links(on: bool) -> void:
	for p in linked_nodes:
		var n := get_node_or_null(p)
		if n is Node3D:
			(n as Node3D).visible = on


func _on_enter(body: Node3D) -> void:
	if body is BugBase:
		PerceptionSystem.player_entered_light(self)


func _on_exit(body: Node3D) -> void:
	if body is BugBase:
		PerceptionSystem.player_exited_light(self)
