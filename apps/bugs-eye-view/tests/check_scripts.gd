extends Node
func _ready() -> void:
	var files: PackedStringArray = []
	var stack := ["res://"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(d):
			if not sub.begins_with("."):
				stack.append(d.path_join(sub))
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				files.append(d.path_join(f))
	for f in files:
		load(f)
	print("checked %d scripts" % files.size())
	get_tree().quit()
