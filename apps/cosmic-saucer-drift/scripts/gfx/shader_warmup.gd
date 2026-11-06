class_name ShaderWarmup
extends RefCounted
## Compiles the race's shaders while the menu is on screen, so the first
## race doesn't stutter as each material is drawn for the first time. Every
## world/effect material is put on a tiny mesh in front of a camera for a
## few frames, then thrown away. (The GL renderer compiles a shader program
## the first time something using it is rendered.)

static var done := false


## One instance of every material the race draws (world, craft, effects).
static func materials() -> Array[Material]:
	var out: Array[Material] = []
	var neon := Color(0.3, 0.9, 1.0)
	out.append(TrackBuilder.road_material(neon))
	out.append(TrackBuilder.barrier_material(Color(0.2, 0.2, 0.3), neon))
	out.append(TrackBuilder.flat(Color(0.3, 0.3, 0.4), 0.0, 0.4, 0.8))
	out.append(TrackBuilder.flat(Color(0.3, 0.3, 0.4), 0.6, 0.9, 0.2))
	out.append(TrackBuilder.glow(neon, 2.2))
	out.append(TrackBuilder.ghost(neon, 0.3))
	out.append(TrackDecor.rock_mat(Color(0.4, 0.3, 0.3), 0.5))
	out.append(ItemModels.ice_material())
	out.append(Gfx.hull(Color(0.8, 0.2, 0.2), Color(0.3, 0.3, 0.3), Color(1, 1, 0)))
	out.append(Gfx.glass(Color(0.5, 0.8, 1.0)))
	out.append(Gfx.flame(Color(1.0, 0.5, 0.2), false))
	out.append(Gfx.flame(Color(1.0, 0.5, 0.2), true))
	out.append(Gfx.shield(Color(0.35, 0.8, 1.0)))
	out.append(Gfx.additive(Color(1, 1, 1, 1)))
	out.append(Gfx.additive(Color(1, 1, 1, 1), Gfx.ring_tex()))
	out.append(Gfx.additive(Color(1, 1, 1, 1), null, true))
	out.append(Gfx.blob_shadow_mat())
	for path in ["ground", "planet", "atmo", "ring", "boost_pad", "spin", "beam", "reticle", "vortex"]:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/%s.gdshader" % path)
		out.append(m)
	var ice := StandardMaterial3D.new()
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.vertex_color_use_as_albedo = true
	ice.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	out.append(ice)
	return out


## Show every material on a speck in front of `cam` for three frames.
static func run(cam: Camera3D) -> void:
	if done or cam == null or DisplayServer.get_name() == "headless":
		return
	done = true
	var holder := Node3D.new()
	holder.name = "ShaderWarmup"
	cam.add_child(holder)
	holder.position = Vector3(0, 0, -2.5)
	var mats := materials()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.02
	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.02)
	for k in mats.size():
		var mi := MeshInstance3D.new()
		mi.mesh = box if k % 2 == 0 else quad
		mi.material_override = mats[k]
		mi.position = Vector3(float(k % 8 - 4) * 0.05, float(k / 8 - 2) * 0.05, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
	# A multimesh too (decor), and a particle burst (effects).
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = box
	mm.instance_count = 2
	mm.set_instance_transform(0, Transform3D.IDENTITY)
	mm.set_instance_transform(1, Transform3D(Basis.IDENTITY, Vector3(0.03, 0, 0)))
	mm.set_instance_color(0, Color.WHITE)
	mm.set_instance_color(1, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mats[3]
	holder.add_child(mmi)
	var tree := cam.get_tree()
	for i in 3:
		await tree.process_frame
		if not is_instance_valid(holder):
			return
	holder.queue_free()
