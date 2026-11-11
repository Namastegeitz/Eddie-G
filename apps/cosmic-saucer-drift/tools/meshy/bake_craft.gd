extends Node
## Bakes the HD craft from their Meshy GLBs (after generate.py --source craft,
## extract_textures.py and an import):
##   <slot>_lod.res   welded mesh with tangents, in unit space: nose toward -Z
##                    (after the data's "yaw"), longest side 1, centred; LODs
##                    for the exterior
##   <slot>_mat.tres  PBR material using the extracted textures
## godot --headless --path . res://tools/meshy/bake_craft.tscn [-- --only=aurora]

func _ready() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",", false)
	var made := 0
	for c: Dictionary in Catalog.SAUCERS:
		if not c.get("hd", false) or (not only.is_empty() and not (String(c.id) in only)):
			continue
		for part in ["model", "cockpit"]:
			var spec: Dictionary = c.get(part, {})
			var slot := String(spec.get("mesh", ""))
			if slot == "" or not ResourceLoader.exists(slot):
				continue
			if bake(slot, float(spec.get("yaw", 0.0)), part == "model"):
				made += 1
	print("baked %d HD craft parts" % made)
	get_tree().quit()


static func bake(slot: String, yaw_deg: float, lods: bool) -> bool:
	var ps: PackedScene = load(slot)
	if ps == null:
		print("SKIP %s: not imported" % slot)
		return false
	var root := ps.instantiate()
	var mi := BiomeBuilder._first_mesh(root)
	if mi == null:
		root.free()
		print("SKIP %s: no mesh" % slot)
		return false
	var mesh: Mesh = mi.mesh
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3.ZERO) * BiomeBuilder._rel_xform(mi, root)
	root.free()
	var box := xf * mesh.get_aabb()
	var span := maxf(maxf(box.size.x, box.size.z), box.size.y)
	var c := box.get_center()
	var norm := Transform3D(Basis.from_scale(Vector3.ONE / span), -c / span) * xf
	var nb := norm.basis.inverse().transposed()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := idx.size() if idx.size() > 0 else v.size()
		for k in count:
			var i := idx[k] if idx.size() > 0 else k
			if n.size() > i:
				st.set_normal((nb * n[i]).normalized())
			if uv.size() > i:
				st.set_uv(uv[i])
			st.add_vertex(norm * v[i])
		tris += count / 3
	st.index()
	st.generate_tangents()
	var arrays := st.commit_to_arrays()
	var out_mesh: ArrayMesh
	if lods:
		var im := ImporterMesh.new()
		im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		im.generate_lods(25.0, 60.0, [])
		out_mesh = im.get_mesh()
	else:
		out_mesh = ArrayMesh.new()
		out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var base := slot.get_basename()
	var err := ResourceSaver.save(out_mesh, base + "_lod.res")
	var mat := StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(base + "_albedo.jpg"):
		mat.albedo_texture = load(base + "_albedo.jpg")
	if ResourceLoader.exists(base + "_orm.jpg"):
		var orm: Texture2D = load(base + "_orm.jpg")
		mat.roughness_texture = orm
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		mat.metallic_texture = orm
		mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		mat.metallic = 1.0
		mat.roughness = 1.0
	if ResourceLoader.exists(base + "_normal.jpg"):
		mat.normal_enabled = true
		mat.normal_texture = load(base + "_normal.jpg")
	ResourceSaver.save(mat, base + "_mat.tres")
	var lv := (RenderingServer.mesh_get_surface(out_mesh.get_rid(), 0).get("lods", []) as Array).size()
	print("%s: %d tris, %d LODs, box %s -> %s (%s)" % [slot, tris, lv, str((norm * mesh.get_aabb()).size.snapped(Vector3.ONE * 0.01)), base + "_lod.res", "ok" if err == OK else "FAILED"])
	return err == OK
