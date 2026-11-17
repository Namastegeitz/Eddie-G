extends Node
## Loads every script once (with autoloads present) so compile errors surface together.

func _ready() -> void:
	var bad := 0
	var stack := ["res://autoload", "res://scripts", "res://tests"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(d):
			stack.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var s = load(d + "/" + f)
				if s == null or not s.can_instantiate():
					print("BAD ", d + "/" + f)
					bad += 1
	print("parse check done, bad=", bad)
	get_tree().quit(1 if bad > 0 else 0)
