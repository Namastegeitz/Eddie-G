class_name StealthMeters
extends Control
## The stealth readout: an eye that fills as you become visible, a noise ring
## that pulses with every sound you make, and the sense / stamina bars.

var player: BugBase
var _vis := 0.0
var _noise := 0.0
var _sense := 1.0
var _stamina := -1.0
var _ability := -1.0
var _font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(150, 216)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()


func bind_player(p: BugBase) -> void:
	player = p
	p.meter_changed.connect(func(meter: StringName, v: float, mx: float) -> void:
		if meter == &"sense":
			_sense = v / maxf(mx, 0.001)
		elif meter == &"stamina":
			_stamina = v / maxf(mx, 0.001)
		elif meter == &"ability":
			_ability = v / maxf(mx, 0.001))


func _process(delta: float) -> void:
	_vis = lerpf(_vis, PerceptionSystem.visibility, clampf(10.0 * delta, 0.0, 1.0))
	_noise = maxf(_noise - delta * 2.5, PerceptionSystem.player_loudness)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(48, 48)
	# Eye: outline + pupil that grows with visibility.
	var v := clampf(_vis, 0.0, 1.0)
	var eye_col := Color(0.45, 0.85, 0.4).lerp(Color(0.95, 0.25, 0.2), v)
	var pts := PackedVector2Array()
	for i in 25:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * 34.0, sin(a) * 18.0))
	draw_polyline(pts, eye_col, 3.0, true)
	draw_circle(c, 4.0 + 13.0 * v, eye_col)
	if player and player.is_hidden_safe():
		draw_line(c + Vector2(-34, 18), c + Vector2(34, -18), UIKit.GOLD, 4.0)
	# Noise ring.
	var n := clampf(_noise / 2.0, 0.0, 1.0)
	if n > 0.01:
		draw_arc(c, 40.0 + n * 18.0, 0.0, TAU, 36, Color(1, 1, 1, 0.25 + n * 0.5), 2.0 + n * 3.0)
	draw_string(_font, Vector2(4, 112), "SEEN %d%%" % int(v * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, eye_col)
	draw_string(_font, Vector2(4, 132), "NOISE", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.5 + n * 0.5))
	# Bars.
	_bar(Vector2(4, 142), _sense, Color(0.55, 0.75, 1.0), "SENSE")
	var y := 168.0
	if _stamina >= 0.0:
		_bar(Vector2(4, y), _stamina, UIKit.GOLD, player.stamina_name() if player else "WINGS")
		y += 26.0
	if _ability >= 0.0 and player:
		var is_ready := _ability >= 0.999
		_bar(Vector2(4, y), _ability, Color(0.55, 0.95, 0.5) if is_ready else Color(0.5, 0.6, 0.45),
			player.ability_name() + (" READY" if is_ready else ""))


func _bar(pos: Vector2, k: float, col: Color, text: String) -> void:
	draw_rect(Rect2(pos, Vector2(120, 10)), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(pos, Vector2(120 * clampf(k, 0.0, 1.0), 10)), col)
	draw_string(_font, pos + Vector2(0, 24), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.6))
