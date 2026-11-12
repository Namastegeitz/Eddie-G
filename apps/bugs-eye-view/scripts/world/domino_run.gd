class_name DominoRun
extends Node3D
## A row of dominoes standing on end. Push the first one over and they go
## down one into the next with a run of clacks; once a few have fallen the
## whole room turns to look at the end of the row (a commotion). One go: the
## row stays down. The dominoes are separate rigid bodies but drawn as one
## multimesh, so a long row costs a single draw call.

## Seconds everyone in the room stares at the fallen row.
@export var commotion_time: float = 4.0
## How many have to fall before it's a commotion.
@export var needed: int = 4

## Toy colours, one per domino in turn.
const COLORS := [Color(0.9, 0.2, 0.18), Color(0.2, 0.45, 0.9), Color(1.0, 0.8, 0.15), Color(0.25, 0.75, 0.3),
	Color(0.97, 0.97, 0.95), Color(1.0, 0.5, 0.12)]

var fallen := 0
var done := false
var _down := {}
var _bodies: Array[PhysicsProp] = []
var _mm: MultiMeshInstance3D


func _ready() -> void:
	for c in get_children():
		if c is PhysicsProp:
			_bodies.append(c)
	_mm = get_node_or_null("Pieces") as MultiMeshInstance3D
	if _mm and _mm.multimesh:
		# Instance data isn't kept in the saved scene: set it up here.
		_mm.multimesh.instance_count = _bodies.size()
		if _mm.multimesh.use_colors:
			for i in _bodies.size():
				_mm.multimesh.set_instance_color(i, COLORS[i % COLORS.size()])
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _physics_process(_delta: float) -> void:
	if done:
		return
	var sum := Vector3.ZERO
	for d in _bodies:
		if not is_instance_valid(d):
			continue
		if not _down.has(d) and d.global_basis.y.dot(Vector3.UP) < 0.5:
			_down[d] = true
			fallen += 1
			AudioManager.play_at(&"domino", d.global_position, -3.0, randf_range(0.9, 1.15))
		if _down.has(d):
			sum += d.global_position
	if fallen >= needed:
		done = true
		PerceptionSystem.commotion(sum / maxf(fallen, 1), commotion_time)
		if Level.current:
			Level.current.note_lure_used()


func _sync() -> void:
	if _mm == null or _mm.multimesh == null:
		return
	var inv := _mm.global_transform.affine_inverse()
	for i in _bodies.size():
		var d := _bodies[i]
		if is_instance_valid(d):
			_mm.multimesh.set_instance_transform(i, inv * d.get_global_transform_interpolated())
