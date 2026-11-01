extends Node
## Physical feedback: phone haptics, gamepad rumble and camera shake carry the
## same cues on every platform. Honors the "haptics" setting.

signal shake_requested(strength: float, duration: float)


func rumble(strength: float, duration: float) -> void:
	strength = clampf(strength, 0.0, 1.0)
	if strength <= 0.02:
		return
	shake_requested.emit(strength, duration)
	if not bool(SaveSystem.get_setting("haptics", true)):
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(int(duration * 1000.0), strength)
	for pad in Input.get_connected_joypads():
		Input.start_joy_vibration(pad, strength * 0.6, strength, duration)


## A heavy impact somewhere in the world; strength falls off with distance to the player.
func impact_at(pos: Vector3, strength: float, falloff: float = 30.0) -> void:
	var p: Node3D = PerceptionSystem.player
	if p == null:
		return
	var d := p.global_position.distance_to(pos)
	var k := clampf(1.0 - d / falloff, 0.0, 1.0)
	rumble(strength * k * k, 0.12 + 0.2 * k)
