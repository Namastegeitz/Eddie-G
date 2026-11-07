class_name WonderMeter
extends Control
## HUD meter for a racer's Technical Wonder: name, charge bar (with the
## minimum charge to fire marked), heat bar when overclocked, and a status
## word (READY, ACTIVE, TACKING, BURNOUT). Redraws only when a shown value
## changes.

var racer: Racer
var k := 1.0
var _sig := -1
var _key := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	if racer == null or racer.wonder == null:
		return
	var w := racer.wonder
	var s := hash([int(w.charge), int(w.heat / 2.0), w.status_text(), int(w.active * 10.0)])
	if s != _sig:
		_sig = s
		queue_redraw()


func _draw() -> void:
	if racer == null or racer.wonder == null:
		return
	var w := racer.wonder
	var font := UiKit.bold()
	var fs := int(15 * k)
	var bw := size.x
	var name := String(w.def.get("name", "WONDER")).to_upper()
	draw_string(font, Vector2(0, fs), name, HORIZONTAL_ALIGNMENT_LEFT, bw, fs, Color(w.color, 0.95))
	var y := fs + 6.0 * k
	var bh := 12.0 * k
	draw_rect(Rect2(0, y, bw, bh), Color(0, 0, 0, 0.55))
	var c := w.color if w.burnout <= 0.0 else Color(0.5, 0.45, 0.45)
	var frac := w.charge / 100.0
	if w.active > 0.0 and w.active_len > 0.0:
		frac = w.active / w.active_len
	draw_rect(Rect2(0, y, bw * frac, bh), Color(c, 0.95 if w.ready() or w.active > 0.0 else 0.6))
	var mx := bw * w.min_charge() / 100.0
	if mx < bw - 1.0:
		draw_line(Vector2(mx, y - 2), Vector2(mx, y + bh + 2), Color(1, 1, 1, 0.7), 2.0)
	draw_rect(Rect2(0, y, bw, bh), Color(c, 0.8), false, 2.0)
	y += bh + 4.0 * k
	if w.overclocked():
		var hh := 6.0 * k
		draw_rect(Rect2(0, y, bw, hh), Color(0, 0, 0, 0.5))
		var hc := Color(1.0, 0.6, 0.1).lerp(Color(1.0, 0.1, 0.1), clampf(w.heat / 100.0, 0.0, 1.0))
		draw_rect(Rect2(0, y, bw * clampf(w.heat / 100.0, 0.0, 1.0), hh), hc)
		draw_string(font, Vector2(bw + 6.0 * k, y + hh), "HEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * k), hc)
		y += hh + 4.0 * k
	var st := w.status_text()
	if st != "":
		var col := Color.WHITE
		match st.get_slice(" ", 0):
			"READY":
				col = w.color.lightened(0.3)
				if not InputRouter.touch_seen:
					st += "  ·  R"
			"BURNOUT":
				col = UiKit.RED
			"TACKING":
				col = UiKit.GOLD
		draw_string(font, Vector2(0, y + fs), st, HORIZONTAL_ALIGNMENT_LEFT, bw + 80.0, fs, col)
