class_name NodePool
extends RefCounted
## Reuses nodes so hazards, FX and audio never allocate in the middle of play.
## Inactive nodes are hidden and have processing (and physics) disabled.

var _factory: Callable
var _parent: Node
var _free: Array[Node] = []


func _init(factory: Callable, parent: Node, prewarm: int = 0) -> void:
	_factory = factory
	_parent = parent
	for i in prewarm:
		var n: Node = _factory.call()
		_parent.add_child(n)
		_deactivate(n)
		_free.append(n)


static func from_scene(scene: PackedScene, parent: Node, prewarm: int = 0) -> NodePool:
	return NodePool.new(func() -> Node: return scene.instantiate(), parent, prewarm)


func acquire() -> Node:
	var n: Node
	if _free.is_empty():
		n = _factory.call()
		_parent.add_child(n)
	else:
		n = _free.pop_back()
	n.process_mode = Node.PROCESS_MODE_INHERIT
	if n is Node3D:
		(n as Node3D).visible = true
	return n


func release(n: Node) -> void:
	if n == null or _free.has(n):
		return
	_deactivate(n)
	_free.append(n)


func _deactivate(n: Node) -> void:
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if n is Node3D:
		(n as Node3D).visible = false
