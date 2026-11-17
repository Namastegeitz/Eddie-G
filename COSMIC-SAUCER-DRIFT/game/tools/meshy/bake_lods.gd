extends Node
## Pipeline step after generate.py + import: for every biome formation whose
## import slot holds a GLB, weld the mesh, move it into unit space (base on
## the ground, footprint radius 1, height 1, long side along X), build LODs
## and save <slot>_lod.res. The game loads that file first.
##   godot --headless --path . res://tools/meshy/bake_lods.tscn
## (Meshy meshes split every vertex per face, so Godot's import-time LOD
## generation finds nothing to collapse; welding first fixes that.)

func _ready() -> void:
	var made := 0
	for b: Dictionary in Content.biomes:
		for f: Dictionary in b.formations:
			var slot := String(f.get("mesh", ""))
			if slot == "" or not ResourceLoader.exists(slot):
				continue
			var src := BiomeBuilder._import(slot)
			if src.is_empty():
				print("SKIP %s: no mesh" % slot)
				continue
			var mesh: Mesh = src.near
			var norm: Transform3D = src.norm
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var tris := 0
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				var n := idx.size() if idx.size() > 0 else v.size()
				for i in n:
					st.add_vertex(norm * v[idx[i] if idx.size() > 0 else i])
				tris += n / 3
			st.index()               # weld: identical positions become one vertex
			st.generate_normals()
			var im := ImporterMesh.new()
			im.add_surface(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			im.generate_lods(25.0, 60.0, [])
			var out_mesh := im.get_mesh()
			var out := slot.get_basename() + "_lod.res"
			var err := ResourceSaver.save(out_mesh, out)
			var lods := (RenderingServer.mesh_get_surface(out_mesh.get_rid(), 0).get("lods", []) as Array).size()
			print("%s/%s: %d tris, %d LOD levels -> %s (%s)" % [b.id, f.id, tris, lods, out, "ok" if err == OK else "FAILED %d" % err])
			made += 1
	print("baked %d formation meshes" % made)
	get_tree().quit()
