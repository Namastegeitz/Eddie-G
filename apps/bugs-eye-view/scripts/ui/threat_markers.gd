class_name ThreatMarkers
extends Control
## Edge-of-screen arrows for threats that are off screen but relevant
## (nearby, or suspicious and above).

const NEAR := 35.0

var camera_rig: FollowCamera


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if camera_rig == null or not is_instance_valid(camera_rig) or PerceptionSystem.player == null:
		return
	if size.x < 80.0 or size.y < 80.0:
		return
	var cam := camera_rig.camera
	var rect := Rect2(Vector2.ZERO, size).grow(-28.0)
	var center := size * 0.5
	for t in PerceptionSystem.threats:
		if not t.present:
			continue
		var d := t.global_position.distance_to(PerceptionSystem.player.global_position)
		if d > NEAR and t.alert.state < AlertState.SUSPICIOUS:
			continue
		var world := t.global_position + Vector3.UP * 2.0
		var behind := cam.is_position_behind(world)
		var sp := cam.unproject_position(world)
		if not behind and rect.has_point(sp):
			continue
		var dir := (sp - center)
		if behind:
			dir = -dir
		if dir.length_squared() < 0.01:
			dir = Vector2.DOWN
		dir = dir.normalized()
		var edge := center + dir * minf(rect.size.x * 0.5 / maxf(absf(dir.x), 0.001), rect.size.y * 0.5 / maxf(absf(dir.y), 0.001))
		var col := Ripple.color_for(t.alert.state)
		var tip := edge + dir * 14.0
		var side := Vector2(-dir.y, dir.x) * 11.0
		draw_colored_polygon(PackedVector2Array([tip, edge - dir * 6.0 + side, edge - dir * 6.0 - side]), col)
