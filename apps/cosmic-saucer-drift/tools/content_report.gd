extends Node
## Content report: validates every content file and pack (Content.issues),
## lists what loaded, and for each biome formation shows where its mesh
## comes from (Meshy GLB in the import slot, or the procedural recipe), its
## triangle counts, LOD levels and unit-space bounds.
##   godot --headless --path . res://tools/content_report.tscn
## Exit code 1 when there are content issues.

func _ready() -> void:
	print("== Content")
	print("packs: %s" % (", ".join(Content.packs) if not Content.packs.is_empty() else "none"))
	print("pilots %d, craft %d, wonders %d, mods %d, sets %d, biomes %d" % [Catalog.PILOTS.size(), Catalog.SAUCERS.size(),
		Content.wonders.size(), Content.mods.size(), Content.sets.size(), Content.biomes.size()])
	for msg in Content.waiting:
		print("waiting for its Meshy model (hidden from the Hangar): " + msg)
	for msg in Content.issues:
		print("ISSUE: " + msg)
	print("== Biome formations")
	for b: Dictionary in Content.biomes:
		for f: Dictionary in b.formations:
			var ms := BiomeBuilder.formation_meshes(b, f)
			var near: Mesh = ms.near
			var far: Mesh = ms.far
			var box: AABB = ms.norm * near.get_aabb()
			print("%-8s %-9s %-6s near %5d tris  far %5s  lods %d  unit box %s  slot %s %s" % [b.id, f.id, ms.source,
				tri_count(near), str(tri_count(far)) if far else "-", lod_count(near), _box(box), f.get("mesh", ""),
				"(present)" if ResourceLoader.exists(String(f.get("mesh", "-"))) else "(empty)"])
	print("content report done")
	get_tree().quit(1 if not Content.issues.is_empty() else 0)


static func tri_count(m: Mesh) -> int:
	var n := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		n += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


## Mesh LOD levels the importer generated (0 for procedural meshes, which
## switch between a near and a far mesh by distance instead).
static func lod_count(m: Mesh) -> int:
	if m == null or m.get_surface_count() == 0:
		return 0
	var d: Dictionary = RenderingServer.mesh_get_surface(m.get_rid(), 0)
	return (d.get("lods", []) as Array).size()


static func _box(b: AABB) -> String:
	return "[%.2f..%.2f, %.2f..%.2f, %.2f..%.2f]" % [b.position.x, b.end.x, b.position.y, b.end.y, b.position.z, b.end.z]
