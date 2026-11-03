extends Node
## Generates every config resource and scene from code.
##   godot --headless --path . res://tools/build_all.tscn            (only missing files)
##   godot --headless --path . res://tools/build_all.tscn -- --force (overwrite all)
## Runs as a scene (not -s) so the game's autoload singletons exist.
## After generation the .tres/.tscn files are the editable source of truth.


func _ready() -> void:
	var tree := get_tree()
	await tree.process_frame
	var args := OS.get_cmdline_user_args()
	var force := args.has("--force")
	var only := ""
	for a in args:
		if a.begins_with("--only="):
			only = a.substr(7)
	print("Building Bug's-Eye View content (force=%s)" % force)
	if only == "" or only == "res":
		ResBuilder.materials(force)
		ResBuilder.configs(force)
		ResBuilder.bugs(force)
		ResBuilder.threats(force)
		ResBuilder.upgrades(force)
		ResBuilder.items(force)
		var routines := ResBuilder.routines(force)
		ResBuilder.levels(force, routines)
		ResBuilder.sound_library(force)
		print("  resources done")
	if only == "" or only == "actors":
		ActorBuilder.bugs(force)
		ActorBuilder.threats(force)
		ActorBuilder.hazards(force)
		ActorBuilder.pickups(force)
		ActorBuilder.items(force)
		ActorBuilder.props(force)
		print("  actor scenes done")
	if only == "" or only == "levels":
		for id in ["kitchen", "living_room", "backyard"]:
			var path := "res://scenes/levels/%s.tscn" % id
			if not force and ResourceLoader.exists(path):
				continue
			match id:
				"kitchen":
					KitchenLayout.build(tree)
				"living_room":
					if ResourceLoader.exists("res://tools/builders/living_room_layout.gd"):
						(load("res://tools/builders/living_room_layout.gd") as GDScript).call("build", tree)
				"backyard":
					if ResourceLoader.exists("res://tools/builders/backyard_layout.gd"):
						(load("res://tools/builders/backyard_layout.gd") as GDScript).call("build", tree)
		print("  level scenes done")
	tree.quit()
