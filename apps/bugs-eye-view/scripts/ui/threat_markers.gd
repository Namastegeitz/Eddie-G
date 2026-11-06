class_name ThreatMarkers
extends Control
## Edge-of-screen arrows for threats that are off screen but relevant
## (nearby, or suspicious and above), and - once it's open - a gold marker
## showing the way to the exit, with the distance.

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
	_draw_exit(cam, rect, center)
	_draw_radar(cam, rect)
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


## The exit: an arrow at the screen edge when it's off screen, a bobbing
## chevron over it when it's on screen; both with the distance.
## Bug Radar: every crumb and power-up nearby shows as a small diamond,
## through walls (power-ups in their own colour, slightly bigger).
func _draw_radar(cam: Camera3D, rect: Rect2) -> void:
	var p := PerceptionSystem.player
	if p == null or not p.has_effect(&"radar"):
		return
	var reach := float(p.effect_amount.get(&"radar", 90.0))
	var t := Time.get_ticks_msec() * 0.008
	for group in [Phys.GROUP_CRUMB, Phys.GROUP_ITEM]:
		for n in get_tree().get_nodes_in_group(group):
			var node := n as Node3D
			if node == null or not node.is_inside_tree():
				continue
			var col := Color(1.0, 0.85, 0.4)
			var dot := 6.0
			if n is Crumb:
				if (n as Crumb).taken:
					continue
			elif n is PickupItem:
				var pi := n as PickupItem
				if pi.taken or not pi.is_power():
					continue
				col = pi.def.color
				dot = 9.0
			var w := node.global_position + Vector3.UP * 1.0
			if w.distance_to(p.global_position) > reach or cam.is_position_behind(w):
				continue
			var sp := cam.unproject_position(w)
			if not rect.has_point(sp):
				continue
			var s := dot + sin(t + w.x) * 1.5
			draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -s), sp + Vector2(s, 0), sp + Vector2(0, s), sp + Vector2(-s, 0)]),
				Color(col.r, col.g, col.b, 0.85))


func _draw_exit(cam: Camera3D, rect: Rect2, center: Vector2) -> void:
	var lvl := Level.current
	if lvl == null or lvl.goal == null or not lvl.goal.active:
		return
	var world := lvl.goal.global_position + Vector3.UP * 6.0
	var dist := world.distance_to(PerceptionSystem.player.global_position)
	var behind := cam.is_position_behind(world)
	var sp := cam.unproject_position(world)
	var font := get_theme_default_font()
	# One game unit is 2.5 cm.
	var label := "EXIT %.1f m" % (dist * 0.025)
	var col := UIKit.GOLD
	if not behind and rect.has_point(sp):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 5.0
		var p := sp + Vector2(0, -18.0 + bob)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, 14), p + Vector2(-12, -2), p + Vector2(12, -2)]), col)
		draw_string(font, p + Vector2(-30, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 15, col)
		return
	var dir := sp - center
	if behind:
		dir = -dir
	if dir.length_squared() < 0.01:
		dir = Vector2.DOWN
	dir = dir.normalized()
	var edge := center + dir * minf(rect.size.x * 0.5 / maxf(absf(dir.x), 0.001), rect.size.y * 0.5 / maxf(absf(dir.y), 0.001))
	var tip := edge + dir * 16.0
	var side := Vector2(-dir.y, dir.x) * 14.0
	draw_colored_polygon(PackedVector2Array([tip, edge - dir * 8.0 + side, edge - dir * 8.0 - side]), col)
	draw_string(font, edge - dir * 34.0 + Vector2(-30, 5), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 15, col)
