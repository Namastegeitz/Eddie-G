class_name SkinAnchor
extends Node3D
## A slot for a generated 3D model (e.g. from Meshy). If
## <model_dir>/<model_id>.glb exists, the model is loaded, turned by
## `yaw_offset_deg`, scaled to fit inside `fit_size` (centred on this node,
## resting on the bottom of the box) and the placeholder meshes in
## `hide_paths` are hidden. With no model file nothing changes, so the game
## always works with or without generated art. Gameplay never depends on it.

@export var model_id: String = ""
## Box the model is fitted into, centred on this node.
@export var fit_size: Vector3 = Vector3.ONE
## Placeholder meshes to hide once the model is in.
@export var hide_paths: Array[NodePath] = []
## glTF models face +Z; the game's "forward" is -Z, hence 180 by default.
@export var yaw_offset_deg: float = 180.0
@export var model_dir: String = "res://assets/models/"

var model: Node3D = null


func _ready() -> void:
	add_to_group(Phys.GROUP_SKIN)
	apply()


func model_path() -> String:
	return model_dir.path_join(model_id + ".glb")


func has_model_file() -> bool:
	var path := model_path()
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## Loads and fits the model. Returns true if a model is shown.
func apply() -> bool:
	if model != null:
		return true
	if model_id == "" or not has_model_file():
		return false
	model = _load_model(model_path())
	if model == null:
		return false
	model.name = "Model"
	add_child(model)
	_fit()
	for p in hide_paths:
		var n := get_node_or_null(p) as Node3D
		if n:
			n.visible = false
	return true


## Imported resource first (editor and exported builds); a raw .glb file is
## parsed at runtime as a fallback (handy right after dropping a file in).
static func _load_model(path: String) -> Node3D:
	if ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		if scene:
			var inst := scene.instantiate()
			if inst is Node3D:
				return inst
			var holder := Node3D.new()
			holder.add_child(inst)
			return holder
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		push_warning("SkinAnchor: could not read %s" % path)
		return null
	return doc.generate_scene(state) as Node3D


func _fit() -> void:
	model.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_offset_deg)), Vector3.ZERO)
	var box := mesh_bounds(model, self)
	if box.size.x <= 0.0001 or box.size.y <= 0.0001 or box.size.z <= 0.0001:
		return
	var s := minf(minf(fit_size.x / box.size.x, fit_size.y / box.size.y), fit_size.z / box.size.z)
	model.transform = Transform3D(model.transform.basis.scaled(Vector3.ONE * s), Vector3.ZERO)
	box = mesh_bounds(model, self)
	var centre := box.get_center()
	model.position = Vector3(-centre.x, -fit_size.y * 0.5 - box.position.y, -centre.z)


## Combined bounds of every mesh under `root`, in `space`'s coordinates.
static func mesh_bounds(root: Node, space: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var inv := space.global_transform.affine_inverse()
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for n in nodes:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var b := (inv * mi.global_transform) * mi.get_aabb()
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out
