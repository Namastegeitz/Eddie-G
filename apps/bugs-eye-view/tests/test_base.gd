class_name TestBase
extends Node
## Shared helpers for the headless test suites.

var _fails: PackedStringArray = []
var _passes := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
		print("  ok   " + msg)
	else:
		_fails.append(msg)
		print("  FAIL " + msg)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func load_level(level: StringName, bug: StringName, slot: StringName = &"morning") -> Level:
	GameManager.current_level = level
	GameManager.current_bug = bug
	GameManager.current_time_slot = slot
	var cfg := GameManager.get_level(level)
	var lvl := (load(cfg.scene_path) as PackedScene).instantiate() as Level
	get_tree().root.add_child(lvl)
	await frames(3)
	return lvl


func unload(lvl: Level) -> void:
	InputRouter.set_touch_move(Vector2.ZERO)
	for a in InputRouter.GAME_ACTIONS:
		InputRouter.set_touch_action(a, false)
	for k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		key(k, false)
	get_tree().paused = false
	Engine.time_scale = 1.0
	lvl.queue_free()
	await frames(3)


func first_in_group(group: StringName, lvl: Node) -> Node:
	for n in get_tree().get_nodes_in_group(group):
		if lvl.is_ancestor_of(n):
			return n
	return null


func face(lvl: Level, yaw: float) -> void:
	lvl.camera.yaw = yaw
	lvl.camera.pitch = -0.3
	lvl.player.camera_yaw_basis = Basis(Vector3.UP, yaw)


func key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


## Touch helpers take canvas (UI) coordinates and convert them to window
## coordinates, like a real screen would deliver them.
func _to_window(pos: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * pos


func touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = _to_window(pos)
	ev.pressed = pressed
	Input.parse_input_event(ev)


func drag(index: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = _to_window(pos)
	ev.relative = get_tree().root.get_final_transform().basis_xform(rel)
	Input.parse_input_event(ev)


func finish(suite: String) -> void:
	print("== %s: %d passed, %d failed ==" % [suite, _passes, _fails.size()])
	for f in _fails:
		print("   FAILED: " + f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.save_path))
	GameManager.quit_game(0 if _fails.is_empty() else 1)
