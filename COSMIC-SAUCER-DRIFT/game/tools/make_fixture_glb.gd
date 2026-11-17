extends Node
## Writes tests/fixtures/formation_fixture.glb: a procedural ridge exported
## as glTF by the game itself. It stands in for a downloaded Meshy model in
## the import-slot test (smoke) and the mock pipeline test; it is NOT a
## Meshy asset. godot --headless --path . res://tools/make_fixture_glb.tscn

func _ready() -> void:
	var root := Node3D.new()
	root.name = "Formation"
	var mi := MeshInstance3D.new()
	mi.name = "Rock"
	mi.mesh = Formations.make({"type": "ridge", "peaks": 5, "jag": 0.5, "sharp": 1.5, "seed": 99}, 1)
	# A Meshy-like model: off-centre, metres tall, lying above y = 0.
	mi.transform = Transform3D(Basis.from_scale(Vector3(40, 25, 40)), Vector3(7, 3, -5))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.18, 0.17)
	mi.material_override = mat
	root.add_child(mi)
	add_child(root)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path("res://tests/fixtures/formation_fixture.glb"))
	print("fixture written" if err == OK else "fixture FAILED %d" % err)
	get_tree().quit(0 if err == OK else 1)
