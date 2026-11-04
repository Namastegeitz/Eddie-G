class_name StinkCloud
extends Node3D
## A stink bug's cloud: every person or pet that comes within reach while it
## lasts reacts once - pets bolt, people cough and can't see.

var radius := 8.0
var time_left := 6.0
var affected: Array[Threat] = []
var _check := 0.0
var _puffs: Array[MeshInstance3D] = []
var _t := 0.0


func _ready() -> void:
	var m: Material = load("res://assets/materials/stink_cloud.tres")
	for i in 5:
		var puff := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 10
		s.rings = 5
		puff.mesh = s
		puff.material_override = m
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := TAU * i / 5.0
		puff.position = Vector3(cos(a) * radius * 0.35, 0.6 + 0.4 * float(i % 2), sin(a) * radius * 0.35)
		add_child(puff)
		_puffs.append(puff)


func _physics_process(delta: float) -> void:
	_t += delta
	time_left -= delta
	var grow := clampf(_t / 0.6, 0.0, 1.0)
	var fade := clampf(time_left / 1.0, 0.0, 1.0)
	for i in _puffs.size():
		var k := radius * 0.45 * grow * (0.8 + 0.2 * sin(_t * 2.0 + i)) * fade
		_puffs[i].scale = Vector3(k, k * 0.4, k)
	if time_left <= 0.0:
		queue_free()
		return
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.2
	for t in PerceptionSystem.threats:
		if t.present and not affected.has(t) and _reaches(t):
			if t.stink(global_position, 3.0):
				affected.append(t)


func _reaches(t: Threat) -> bool:
	var p := t.global_position
	var flat := Vector2(p.x - global_position.x, p.z - global_position.z).length()
	# People are tall: their feet are in it if they're close enough.
	return flat <= radius and p.y - global_position.y < 12.0
