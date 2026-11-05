class_name DugHole
extends Node3D
## A hole a dog dug in the lawn: a dark hollow any bug can crawl into and
## hide (no squeezing), with a mound of dirt beside it that blocks the way.

const RADIUS := 2.6


static func make(at: Vector3, away: Vector3) -> DugHole:
	var h := DugHole.new()
	h.name = "DugHole"
	h.set_meta(&"away", away)
	h.position = at
	return h


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_to_group(&"dug_hole")
	var hole := MeshInstance3D.new()
	hole.name = "Hollow"
	var cm := CylinderMesh.new()
	cm.top_radius = RADIUS
	cm.bottom_radius = RADIUS * 0.7
	cm.height = 0.1
	cm.radial_segments = 16
	hole.mesh = cm
	hole.material_override = load("res://assets/materials/hole.tres")
	hole.position = Vector3(0, 0.06, 0)
	add_child(hole)
	var away: Vector3 = get_meta(&"away", Vector3.BACK)
	var mound := StaticBody3D.new()
	mound.name = "Mound"
	mound.collision_layer = Phys.WORLD
	mound.collision_mask = 0
	mound.set_meta(&"surface", &"soil")
	mound.position = away.normalized() * (RADIUS + 1.6)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.2
	sm.height = 2.2
	mi.mesh = sm
	mi.material_override = load("res://assets/materials/soil.tres")
	mound.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.0
	cs.shape = sh
	cs.position = Vector3(0, -0.4, 0)
	mound.add_child(cs)
	add_child(mound)
	var spot := HidingSpot.new()
	spot.name = "Hide"
	spot.requires_squeeze = false
	spot.allowed_bugs = PackedStringArray()
	spot.hint = "Hiding in the dug hole"
	var scs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(RADIUS * 1.4, 2.0, RADIUS * 1.4)
	scs.shape = bs
	spot.add_child(scs)
	spot.position = Vector3(0, 0.9, 0)
	add_child(spot)
	var dark := LightZone.new()
	dark.name = "Dark"
	dark.light_level = 0
	dark.zone_priority = 3
	var dcs := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(RADIUS * 1.6, 2.4, RADIUS * 1.6)
	dcs.shape = dbs
	dark.add_child(dcs)
	dark.position = Vector3(0, 1.0, 0)
	add_child(dark)
