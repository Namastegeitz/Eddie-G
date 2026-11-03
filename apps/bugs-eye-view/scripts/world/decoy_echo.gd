class_name DecoyEcho
extends Node3D
## Left behind by a Sapphire gem: a humming shard that makes a noise every
## beat for a while. Threats hear it like a lure and go to investigate.

var time_left := 8.0
var loudness := 3.0
var _beat := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.8
	s.height = 1.6
	_mesh.mesh = s
	_mesh.material_override = load("res://assets/materials/gem_sapphire.tres")
	_mesh.position.y = 0.8
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	time_left -= delta
	_beat -= delta
	if _beat <= 0.0:
		_beat = 0.8
		PerceptionSystem.emit_world_noise(global_position, loudness)
		AudioManager.play_at(&"clink", global_position, 2.0, randf_range(1.2, 1.5))
	var k := 1.0 + absf(sin(time_left * 6.0)) * 0.4
	_mesh.scale = Vector3(k, k, k)
	if time_left <= 0.0:
		queue_free()
