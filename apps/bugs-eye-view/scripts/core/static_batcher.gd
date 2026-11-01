class_name StaticBatcher
## Mobile performance: merges the level's static meshes that share a material
## (and shadow setting) into one mesh each at load time, turning hundreds of
## draw calls into a couple of dozen. The source nodes stay in the scene,
## hidden, so levels remain fully editable in the Godot editor.

const SOURCES: Array[String] = ["NavRegion/Geometry", "Decor"]


static func batch(level: Node3D) -> Dictionary:
	var groups := {}
	var merged := 0
	var inv := level.global_transform.affine_inverse()
	for path in SOURCES:
		var src := level.get_node_or_null(path)
		if src == null:
			continue
		for node in src.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if not mi.is_visible_in_tree() or mi.mesh == null or mi.material_override == null \
					or mi.mesh.get_surface_count() != 1 or mi.is_in_group(&"no_batch"):
				continue
			var key := "%d|%d" % [mi.material_override.get_instance_id(), mi.cast_shadow]
			if not groups.has(key):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[key] = [st, mi.material_override, mi.cast_shadow]
			(groups[key][0] as SurfaceTool).append_from(mi.mesh, 0, inv * mi.global_transform)
			mi.visible = false
			merged += 1
	var holder := Node3D.new()
	holder.name = "StaticBatches"
	level.add_child(holder)
	for key: String in groups.keys():
		var g: Array = groups[key]
		var out := MeshInstance3D.new()
		out.mesh = (g[0] as SurfaceTool).commit()
		out.material_override = g[1]
		out.cast_shadow = g[2]
		holder.add_child(out)
	return {"merged": merged, "batches": groups.size()}
