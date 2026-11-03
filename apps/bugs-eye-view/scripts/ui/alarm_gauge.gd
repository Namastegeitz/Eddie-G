class_name AlarmGauge
extends Control
## The house-wide alarm meter. Fills as threats see or hear you (green ->
## yellow -> red); at 100% it flashes FULL ALARM and every threat comes for
## you. Drains once you break line of sight, faster while hidden.

var _shown := 0.0
var _flash := 0.0
var _font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(240, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	PerceptionSystem.alarm_raised.connect(_on_raised)


func _on_raised() -> void:
	_flash = 2.5


func _process(delta: float) -> void:
	_shown = move_toward(_shown, PerceptionSystem.alarm, delta * 2.0)
	_flash = maxf(_flash - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var w := minf(size.x, 320.0)
	var x0 := (size.x - w) * 0.5
	var bar := Rect2(x0, 4.0, w, 12.0)
	var k := clampf(_shown, 0.0, 1.0)
	var col := Color(0.45, 0.85, 0.4).lerp(Color(1.0, 0.85, 0.2), clampf(k * 2.0, 0.0, 1.0))
	if k > 0.5:
		col = Color(1.0, 0.85, 0.2).lerp(Color(0.95, 0.2, 0.15), (k - 0.5) * 2.0)
	draw_rect(bar, Color(0, 0, 0, 0.55))
	draw_rect(Rect2(bar.position, Vector2(w * k, bar.size.y)), col)
	draw_rect(bar, Color(1, 1, 1, 0.35), false, 1.0)
	var text := "ALARM %d%%" % int(round(k * 100.0))
	var text_col := Color(1, 1, 1, 0.85)
	if PerceptionSystem.alarm_active:
		text = "FULL ALARM - GET OUT OF SIGHT!"
		var blink := fmod(Time.get_ticks_msec() / 250.0, 2.0) < 1.0
		text_col = Color(1.0, 0.3, 0.2) if blink or _flash <= 0.0 else Color(1, 1, 1)
	var fs := 15
	var tw := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string_outline(_font, Vector2(size.x * 0.5 - tw * 0.5, 32.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
	draw_string(_font, Vector2(size.x * 0.5 - tw * 0.5, 32.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
