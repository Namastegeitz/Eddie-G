class_name DesktopHints
extends Control
## Keyboard and mouse players get a small on-screen joystick that mirrors
## what they're pressing (W/A/S/D or the arrows, or the mouse stick), and
## key chips for the other actions. Bottom-left and bottom-right, out of the
## way of the HUD. Off in Settings > Key hints.

var racer: Racer
var _vis := Vector2.ZERO
var _t := 0.0
var _sig := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(dt: float) -> void:
	_t += dt
	if racer == null or not is_instance_valid(racer):
		return
	# The racer's own inputs (calling InputRouter.controls again polled every
	# key and pad a second time each frame).
	var want := Vector2(racer.in_steer, racer.in_throttle - racer.in_brake)
	_vis = _vis.lerp(want, 1.0 - exp(-18.0 * dt))
	# Redraw only when something shown changed (it redrew ~20 labels a frame).
	var sig := hash([(_vis * 50.0).round(), racer.in_drift, racer.in_item, racer.in_look_back, racer.gliding,
		InputRouter.mouse_on() and InputRouter.mouse_active, size])
	if sig != _sig:
		_sig = sig
		queue_redraw()


func _draw() -> void:
	if racer == null or not is_instance_valid(racer):
		return
	var s := size
	var u := minf(minf(s.x, s.y) / 720.0, maxf(s.x, s.y) / 1280.0)
	var font := UiKit.bold()
	var mouse := InputRouter.mouse_on()
	var mouse_live := mouse and InputRouter.mouse_active
	# Joystick indicator, bottom-left.
	var r := 62.0 * u
	var base := Vector2(r + 44.0 * u, s.y - r - 40.0 * u)
	var lit := Color(0.3, 0.92, 1.0)
	draw_circle(base, r, Color(1, 1, 1, 0.07))
	draw_arc(base, r, 0, TAU, 48, Color(lit.r, lit.g, lit.b, 0.5), 3.0 * u)
	var fs := int(r * 0.3)
	var labels := [["W", Vector2(0, -1)], ["S", Vector2(0, 1)], ["A", Vector2(-1, 0)], ["D", Vector2(1, 0)]]
	if mouse_live:
		labels = [["GAS", Vector2(0, -1)], ["BRAKE", Vector2(0, 1)], ["◀", Vector2(-1, 0)], ["▶", Vector2(1, 0)]]
	for l in labels:
		var txt: String = l[0]
		var d: Vector2 = l[1]
		var held := false
		if d.y < 0.0:
			held = _vis.y > 0.2
		elif d.y > 0.0:
			held = _vis.y < -0.2
		elif d.x < 0.0:
			held = _vis.x < -0.2
		else:
			held = _vis.x > 0.2
		var ts := int(fs * (0.75 if txt.length() > 1 else 1.0))
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x
		var col := lit if held else Color(1, 1, 1, 0.45)
		draw_string(font, base + d * r * 0.72 + Vector2(-tw * 0.5, ts * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, col)
	var knob := base + Vector2(_vis.x, -_vis.y) * r * 0.55
	draw_circle(knob, r * 0.3, Color(lit.r, lit.g, lit.b, 0.45 if _vis.length() > 0.1 else 0.25))
	draw_arc(knob, r * 0.3, 0, TAU, 24, Color(1, 1, 1, 0.7), 2.0 * u)
	var cap := "MOUSE" if mouse_live else ("KEYS / MOUSE" if mouse else "KEYS")
	var cs := int(r * 0.2)
	var cw := font.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x
	draw_string(font, base + Vector2(-cw * 0.5, r + cs * 1.4), cap, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, Color(1, 1, 1, 0.5))
	if mouse and not mouse_live and _t < 12.0:
		var hint := "move the mouse to steer, forward = gas, back = brake"
		var hs := int(r * 0.2)
		draw_string(font, base + Vector2(r + 14.0 * u, 4.0), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, hs, Color(1, 1, 1, 0.45 + 0.2 * sin(_t * 4.0)))
	# Key chips, bottom-right (above DRIFT's spot on touch; here there are no buttons).
	var chips: Array = [["SPACE", "DRIFT / TRICK"], ["SHIFT", "GLIDE"], ["E", "ITEM"], ["Q", "LOOK BACK"], ["V", "COCKPIT"], ["ESC", "PAUSE"]]
	if mouse_live:
		chips = [["LMB", "DRIFT / TRICK"], ["SHIFT", "GLIDE"], ["RMB", "ITEM"], ["MMB", "LOOK BACK"], ["V", "COCKPIT"], ["ESC", "PAUSE"]]
	var ch := 30.0 * u
	var y := s.y - 40.0 * u - ch
	var ks := int(ch * 0.5)
	for i in range(chips.size() - 1, -1, -1):
		var key: String = chips[i][0]
		var act: String = chips[i][1]
		var kw := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, ks).x + 16.0 * u
		var aw := font.get_string_size(act, HORIZONTAL_ALIGNMENT_LEFT, -1, int(ks * 0.8)).x
		var x := s.x - 24.0 * u - aw - kw - 8.0 * u
		var held := false
		match act:
			"DRIFT / TRICK": held = racer.in_drift
			"ITEM": held = racer.in_item
			"LOOK BACK": held = racer.in_look_back
			"GLIDE": held = racer.gliding
		var box := Rect2(x, y, kw, ch)
		draw_rect(box, Color(lit.r, lit.g, lit.b, 0.35) if held else Color(1, 1, 1, 0.1))
		draw_rect(box, Color(lit.r, lit.g, lit.b, 0.9 if held else 0.45), false, 2.0 * u)
		draw_string(font, Vector2(x + 8.0 * u, y + ch * 0.68), key, HORIZONTAL_ALIGNMENT_LEFT, -1, ks, Color(1, 1, 1, 0.9))
		draw_string(font, Vector2(x + kw + 8.0 * u, y + ch * 0.66), act, HORIZONTAL_ALIGNMENT_LEFT, -1, int(ks * 0.8), Color(1, 1, 1, 0.55))
		y -= ch + 8.0 * u
