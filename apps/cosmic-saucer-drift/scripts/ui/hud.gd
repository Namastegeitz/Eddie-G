class_name Hud
extends Control
## In-race HUD for one local player: place, lap, time, item slot, energy
## cells, Plasma Boost meter, minimap, countdown, toasts and overlays
## (nebula splats, emergency warning, boost streaks).

var race: Node
var racer: Racer
var compact := false     # split-screen: smaller text

var _place: Label
var _place_of: Label
var _lap: Label
var _time: Label
var _speed: Label
var _center: Label
var _sub: Label
var _toasts: VBoxContainer
var _item_box: PanelContainer
var _item_icon: ItemIcon
var _item_name: Label
var _energy_lbl: Label
var _minimap: Minimap
var _overlay: Control
var _center_t := 0.0
var _roll_t := 0.0
var _splats: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var _lines: ColorRect
var _lines_mat: ShaderMaterial
var _lines_amt := 0.0
var cockpit_tab: SideTab
var _cockpit := false
var _layout_key := ""
var pause_btn: Control
static var _rotate_hint_shown := false


## A phone held upright: the energy cells and boost meter go top-centre
## (the craft sits low on a tall screen and the thumbs own the bottom).
func tall() -> bool:
	return size.y > size.x and not compact


## Portrait with touch controls: how far the cockpit dashboard sits above
## the bottom edge to clear the pedals and DRIFT. 0 in landscape.
func bottom_pad() -> float:
	if tall() and InputRouter.touch_seen:
		return 150.0 * 1.25 + 150.0 * 1.05 + 24.0 * 3.0 + 10.0
	return 0.0


func setup(p_race: Node, p_racer: Racer, is_compact: bool) -> void:
	race = p_race
	racer = p_racer
	compact = is_compact
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := 0.72 if compact else 1.0
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	_lines = ColorRect.new()
	_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines_mat = ShaderMaterial.new()
	_lines_mat.shader = preload("res://shaders/speedlines.gdshader")
	_lines.material = _lines_mat
	_lines_mat.set_shader_parameter("amount", 0.0)
	_lines.visible = true   # drawn invisible for a moment so its shader compiles before the first boost
	add_child(_lines)
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_instance_valid(_lines) and _lines_amt <= 0.01:
			_lines.visible = false)
	set_speedlines(bool(Gfx.q().speedlines))
	add_child(_overlay)
	# Place (top left).
	var pl := UiKit.hbox(2)
	add_child(pl)
	UiKit.place(pl, Vector2(0, 0), Vector2(24, 4), Vector2(220, 90) * k)
	_place = UiKit.label("1st", int(70 * k), Color.WHITE)
	pl.add_child(_place)
	_place_of = UiKit.label("/8", int(30 * k), UiKit.DIM)
	_place_of.size_flags_vertical = Control.SIZE_SHRINK_END
	pl.add_child(_place_of)
	# Item slot under the place.
	_item_box = PanelContainer.new()
	_item_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.05, 0.03, 0.12, 0.7), 16, UiKit.CYAN.darkened(0.3), 3))
	add_child(_item_box)
	UiKit.place(_item_box, Vector2(0, 0), Vector2(26, 100 * k), Vector2(96, 96) * k)
	_item_icon = ItemIcon.new()
	_item_icon.custom_minimum_size = Vector2(84, 84) * k
	_item_box.add_child(_item_icon)
	_item_name = UiKit.label("", int(18 * k), UiKit.DIM)
	add_child(_item_name)
	UiKit.place(_item_name, Vector2(0, 0), Vector2(26, 200 * k), Vector2(260, 30))
	# Lap + time (top centre).
	var top := UiKit.vbox(0)
	add_child(top)
	UiKit.place(top, Vector2(0.5, 0), Vector2(-160, 6), Vector2(320, 80))
	_lap = UiKit.label("LAP 1/3", int(34 * k), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	top.add_child(_lap)
	_time = UiKit.label("0:00.00", int(24 * k), UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	top.add_child(_time)
	# Minimap (top right).
	_minimap = Minimap.new()
	var ms := 190.0 * k
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_minimap)
	UiKit.place(_minimap, Vector2(1, 0), Vector2(-ms - 16, 12), Vector2(ms, ms))
	_minimap.setup(race, racer)
	# Speed (bottom right above touch buttons on phones, bottom right otherwise).
	_speed = UiKit.label("0", int(30 * k), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	add_child(_speed)
	UiKit.place(_speed, Vector2(1, 0), Vector2(-220, 210 * k), Vector2(200, 40))
	# Energy label (bars are drawn in the overlay).
	_energy_lbl = UiKit.label("DARK MATTER", int(16 * k), UiKit.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_energy_lbl)
	_place_bottom()
	# Centre messages + toasts.
	_center = UiKit.label("", int(110 * k), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_center)
	UiKit.place(_center, Vector2(0.5, 0.5), Vector2(-500, -190 * k), Vector2(1000, 130 * k))
	_sub = UiKit.label("", int(30 * k), UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	add_child(_sub)
	UiKit.place(_sub, Vector2(0.5, 0.5), Vector2(-500, -60 * k), Vector2(1000, 40))
	_toasts = UiKit.vbox(2)
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_toasts)
	UiKit.place(_toasts, Vector2(0.5, 0.5), Vector2(-350, -10 * k), Vector2(700, 140))
	# COCKPIT tab on the left edge: first-person on/off at any time.
	cockpit_tab = SideTab.new()
	cockpit_tab.k = k
	add_child(cockpit_tab)
	UiKit.place(cockpit_tab, Vector2(0, 0.38), Vector2(0, 0), Vector2(48, 168) * k)
	racer.event.connect(_on_event)


## Positions that depend on the screen shape (re-done when it rotates).
func _place_bottom() -> void:
	var k := 0.72 if compact else 1.0
	if tall():
		UiKit.place(_energy_lbl, Vector2(0.5, 0), Vector2(-250, 150 * k), Vector2(500, 30))
	else:
		UiKit.place(_energy_lbl, Vector2(0.5, 1), Vector2(-250, -128 * k), Vector2(500, 30))
	if pause_btn:
		if tall():
			UiKit.place(pause_btn, Vector2(1, 0), Vector2(-96, 262 * k), Vector2(70, 64))
		else:
			UiKit.place(pause_btn, Vector2(1, 0), Vector2(-296, 14), Vector2(70, 64))
	_layout_key = "%s|%s" % [size, InputRouter.touch_seen]


## The pause button (made by the race) is laid out with the HUD.
func add_pause(btn: Control) -> void:
	pause_btn = btn
	add_child(btn)
	_place_bottom()


func set_cockpit(on: bool) -> void:
	_cockpit = on
	if cockpit_tab:
		cockpit_tab.set_on(on)
	_overlay.queue_redraw()


func is_cockpit() -> bool:
	return _cockpit


## Speed lines on (medium and up) or the cheap edge streaks (low).
func set_speedlines(on: bool) -> void:
	if _lines:
		_lines.set_meta("on", on)
		_lines.visible = on and _lines_amt > 0.01


func big(text: String, sub := "", secs := 1.2, color := Color.WHITE) -> void:
	_center.text = text
	_center.add_theme_color_override("font_color", color)
	_sub.text = sub
	_center_t = secs


func toast(text: String, color := Color.WHITE) -> void:
	var l := UiKit.label(text, 30 if not compact else 22, color, HORIZONTAL_ALIGNMENT_CENTER)
	_toasts.add_child(l)
	if _toasts.get_child_count() > 3:
		_toasts.get_child(0).queue_free()
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _on_event(kind: String, d: Dictionary) -> void:
	match kind:
		"trick":
			toast("TRICK x%d!  +BOOST" % d.count if d.count > 1 else "TRICK!  +BOOST", UiKit.GOLD)
		"sloppy":
			toast("Sloppy landing", UiKit.DIM)
		"near_miss":
			toast("NEAR MISS  +ENERGY", UiKit.CYAN)
		"slipstream":
			toast("SLIPSTREAM!", UiKit.CYAN)
		"drift_boost":
			var names := ["", "BLUE BOOST", "ORANGE BOOST", "PURPLE BOOST!"]
			toast(names[d.tier], SaucerModel.SPARK_COLORS[d.tier - 1])
		"start_boost":
			toast("ROCKET START!", UiKit.GOLD)
		"stall":
			toast("Engine stalled - too early!", UiKit.RED)
		"emergency":
			toast("CORE EMPTY - GRAB AN ENERGY POD!", UiKit.RED)
		"recharged":
			toast("Core recharged", UiKit.GREEN)
		"hit":
			toast("HIT!", UiKit.RED)
		"blocked":
			toast("Held shield took the hit!" if d.get("held", false) else "Shield blocked it", UiKit.CYAN)
		"hit_landed":
			toast("Got %s!" % (d.target as Racer).display_name, UiKit.PINK)
		"inked":
			_splats.clear()
			for k in 7:
				_splats.append(Vector3(_rng.randf_range(0.1, 0.9), _rng.randf_range(0.15, 0.85), _rng.randf_range(60, 150)))
		"comet_warning":
			toast("COMET INCOMING!", UiKit.RED)
		"warped":
			toast("WARP JUMP!", UiKit.GOLD)
		"decoy_popped":
			toast("Decoy took the hit!", UiKit.CYAN)
		"leeched":
			toast("ENERGY LEECHED!", UiKit.RED)
		"leech_hit":
			toast("Draining %s" % (d.target as Racer).display_name, UiKit.PINK)
		"welled":
			toast("GRAVITY WELL - pull free!", UiKit.RED)
		"frosted":
			toast("ICE! Sliding", UiKit.CYAN)
		"overcharge":
			toast("OVERCHARGE! %.1f s boost" % float(d.get("secs", 0.0)), Color(1.0, 0.65, 0.2))
		"rocket_lock":
			toast("ROCKET LOCKED ON YOU!" if racer.item != "shield" else "ROCKET LOCKED ON - shield ready", UiKit.RED)
		"item_lost":
			toast("EMP! Item knocked loose", UiKit.RED)
		"tractored":
			toast("Caught in a tractor beam!", UiKit.GREEN)
		"shard":
			toast("STAR SHARD!" if d.new else "Star Shard (already found)", UiKit.GOLD)
		"respawn":
			toast("Rescue beam", UiKit.DIM)
		"geyser":
			toast("WHOOSH!", UiKit.CYAN)
		"item_roll":
			_roll_t = 0.9


func _process(dt: float) -> void:
	if racer == null:
		return
	if _layout_key != "%s|%s" % [size, InputRouter.touch_seen]:
		_place_bottom()
	if not _rotate_hint_shown and size.y > size.x and InputRouter.touch_seen and race.racing:
		_rotate_hint_shown = true
		toast("Tip: turn your phone sideways for a wider view", UiKit.DIM)
	var n: int = race.racers.size()
	_place.text = UiKit.ordinal(racer.place)
	_place.add_theme_color_override("font_color", UiKit.GOLD if racer.place == 1 else Color.WHITE)
	_place_of.text = "/%d" % n
	var laps: int = race.td.laps
	_lap.text = "LAP %d/%d" % [clampi(racer.lap, 1, laps), laps] if not racer.finished else "FINISHED"
	_time.text = UiKit.time_str(race.time if not racer.finished else racer.finish_time)
	_speed.text = "%d km/h" % int(maxf(racer.fwd_speed, 0.0) * 3.6)
	# Item slot with roulette.
	if racer.item_roll > 0.0:
		_roll_t -= dt
		var keys := Catalog.ITEMS.keys()
		_item_icon.item = keys[int(Time.get_ticks_msec() / 70.0) % keys.size()]
		_item_name.text = "..."
	else:
		_item_icon.item = racer.item
		_item_name.text = Catalog.ITEMS[racer.item].name if racer.item != "" else ""
		if racer.item_uses > 1:
			_item_name.text += "  x%d" % racer.item_uses
	_energy_lbl.text = "EMERGENCY HOVER - GRAB A POD!" if racer.emergency else "DARK MATTER CORE"
	_energy_lbl.add_theme_color_override("font_color", UiKit.RED if racer.emergency else UiKit.CYAN)
	if _center_t > 0.0:
		_center_t -= dt
		if _center_t <= 0.0:
			_center.text = ""
			_sub.text = ""
	if racer.wrong_way and _center_t <= 0.0:
		_center.text = "WRONG WAY"
		_center.add_theme_color_override("font_color", UiKit.RED)
	elif not racer.wrong_way and _center.text == "WRONG WAY":
		_center.text = ""
	if _lines and _lines.get_meta("on", false):
		var ratio := clampf(racer.fwd_speed / maxf(racer.max_speed, 1.0), 0.0, 1.5)
		var want := clampf((ratio - 0.82) / 0.35, 0.0, 1.0) * 0.55 + (0.55 if racer.boost_time > 0.0 else 0.0)
		_lines_amt = move_toward(_lines_amt, want, dt * 3.0)
		_lines.visible = _lines_amt > 0.01
		if _lines.visible:
			_lines_mat.set_shader_parameter("amount", _lines_amt)
			_lines_mat.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
			_lines_mat.set_shader_parameter("tint", Color(1, 1, 1, 1) if not racer.boost_kind.begins_with("drift") else Color(0.85, 0.75, 1.0, 1.0))
	_overlay.queue_redraw()


## First-person frame: canopy arch with glass glints across the top, a
## dashboard with a speed dial and boost lamp at the bottom, and a blue edge
## glow while the Ion Shield is up (the bubble can't be seen from inside).
func _draw_cockpit(s: Vector2, k: float) -> void:
	var o := _overlay
	var cx := s.x * 0.5
	var rx := s.x * 0.62
	var ry := s.y * 0.95
	var cy := s.y * 0.98
	var arch := PackedVector2Array()
	for i in 49:
		var a := lerpf(PI, TAU, float(i) / 48.0)
		var p := Vector2(cx + cos(a) * rx, cy + sin(a) * ry)
		if p.x >= -2.0 and p.x <= s.x + 2.0:
			arch.append(p)
	if arch.size() >= 3:
		var frame := PackedVector2Array([Vector2(0, 0), Vector2(0, arch[0].y)])
		frame.append_array(arch)
		frame.append_array([Vector2(s.x, arch[arch.size() - 1].y), Vector2(s.x, 0)])
		o.draw_colored_polygon(frame, Color(0.03, 0.03, 0.08, 0.55))
		o.draw_polyline(arch, Color(0.2, 0.21, 0.28, 0.95), 12.0 * k)
		o.draw_polyline(arch, Color(0.3, 0.92, 1.0, 0.35), 2.0 * k)
	for g in [[0.13, 0.17, 0.24, 0.07], [0.18, 0.23, 0.27, 0.11]]:
		o.draw_line(Vector2(s.x * g[0], s.y * g[1]), Vector2(s.x * g[2], s.y * g[3]), Color(1, 1, 1, 0.09), 7.0 * k)
	# Dashboard.
	# The dash spans the middle half in landscape; on a tall screen it's
	# wider (and sits above the touch controls) so the dial and lamp stay
	# clear of the energy cells.
	var tall := s.y > s.x
	var hw := 0.42 if tall else 0.25
	var base_y := s.y - bottom_pad()
	var dh := (s.x * 0.2) if tall else (s.y * 0.13)
	var dash := PackedVector2Array()
	for i in 25:
		var t := float(i) / 24.0
		dash.append(Vector2(lerpf(s.x * (0.5 - hw), s.x * (0.5 + hw), t), base_y - sin(t * PI) * dh - 2.0))
	var fill := dash.duplicate()
	fill.append_array([Vector2(s.x * (0.5 + hw), base_y), Vector2(s.x * (0.5 - hw), base_y)])
	o.draw_colored_polygon(fill, Color(0.04, 0.04, 0.1, 0.72))
	o.draw_polyline(dash, Color(0.3, 0.92, 1.0, 0.55), 3.0 * k)
	# Speed dial on the left of the dash.
	var dr := (s.x * 0.055) if tall else (s.y * 0.04)
	var dc := Vector2(s.x * ((0.5 - hw) + 0.085 if tall else 0.315), base_y - dr * 1.25)
	var a0 := deg_to_rad(150.0)
	var a1 := deg_to_rad(390.0)
	var spd := clampf(racer.fwd_speed / maxf(racer.max_speed * 1.3, 1.0), 0.0, 1.0)
	o.draw_arc(dc, dr, a0, a1, 24, Color(1, 1, 1, 0.25), 3.0 * k)
	o.draw_arc(dc, dr, a0, lerpf(a0, a1, spd), 24, UiKit.CYAN if racer.boost_time <= 0.0 else UiKit.PINK, 4.0 * k)
	var na := lerpf(a0, a1, spd)
	o.draw_line(dc, dc + Vector2(cos(na), sin(na)) * dr * 0.9, Color(1, 0.4, 0.3), 2.5 * k)
	# Boost / drift lamp on the right.
	var lc := Vector2(s.x * ((0.5 + hw) - 0.085 if tall else 0.685), base_y - dr * 1.25)
	var lamp := Color(0.25, 0.25, 0.3)
	if racer.boost_time > 0.0:
		lamp = UiKit.PINK
	elif racer.drift_tier > 0:
		lamp = SaucerModel.SPARK_COLORS[racer.drift_tier - 1]
	o.draw_circle(lc, dr * 0.55, lamp)
	o.draw_arc(lc, dr * 0.75, 0, TAU, 20, Color(1, 1, 1, 0.3), 2.0 * k)
	# Shield glow round the edges.
	if racer.shield_time > 0.0:
		var a := 0.12 + 0.06 * sin(Time.get_ticks_msec() * 0.01)
		for i in 5:
			o.draw_rect(Rect2(Vector2.ZERO, s), Color(0.35, 0.8, 1.0, a / 5.0), false, 14.0 * (i + 1))


func _draw_overlay() -> void:
	var s := _overlay.size
	if s.x < 2.0 or s.y < 2.0:
		return
	var k := 0.72 if compact else 1.0
	if _cockpit and not racer.finished:
		_draw_cockpit(s, k)
	# Energy cells.
	var cells := 10
	var cw := 34.0 * k
	var ch := 18.0 * k
	var gap := 5.0 * k
	if tall():
		cw = 24.0 * k
		ch = 16.0 * k
	var total := cells * cw + (cells - 1) * gap
	var x0 := s.x * 0.5 - total * 0.5
	var y0 := (124.0 * k) if tall() else (s.y - 52.0 * k)
	var frac: float = racer.energy / float(race.tuning.energy_max)
	for i in cells:
		var r := Rect2(x0 + i * (cw + gap), y0, cw, ch)
		_overlay.draw_rect(r.grow(2), Color(0, 0, 0, 0.55))
		var fill := clampf(frac * cells - i, 0.0, 1.0)
		var col := UiKit.CYAN
		if frac < 0.3:
			col = Color(1.0, 0.6, 0.15)
		if frac < 0.12:
			col = UiKit.RED
		if fill > 0.0:
			_overlay.draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), col)
	# Plasma Boost meter (fills while drifting).
	var mw := total
	var my := y0 - 40.0 * k
	_overlay.draw_rect(Rect2(x0 - 2, my - 2, mw + 4, 14 * k + 4), Color(0, 0, 0, 0.55))
	var tiers: PackedFloat32Array = race.tuning.drift_tiers
	var charge := racer.drift_charge / tiers[2]
	if racer.drift_dir != 0:
		var tc: Color = SaucerModel.SPARK_COLORS[clampi(racer.drift_tier - 1, 0, 2)] if racer.drift_tier > 0 else Color(0.6, 0.6, 0.7)
		_overlay.draw_rect(Rect2(x0, my, mw * charge, 14 * k), tc)
	for t in 3:
		var tx := x0 + mw * tiers[t] / tiers[2]
		_overlay.draw_line(Vector2(tx, my - 3), Vector2(tx, my + 14 * k + 3), Color(1, 1, 1, 0.7), 2.0)
	if racer.boost_time > 0.0:
		_overlay.draw_rect(Rect2(x0, my, mw, 14 * k), Color(1, 1, 1, 0.25))
	if racer.boost_time > 0.0 and not (_lines and _lines.get_meta("on", false)):
		# Speed streaks at the screen edges (low graphics).
		var t := Time.get_ticks_msec() * 0.001
		for i in 14:
			var y := fposmod(i * 97.0 + t * 900.0, s.y)
			var side := 0.0 if i % 2 == 0 else s.x
			var dir := 1.0 if side == 0.0 else -1.0
			_overlay.draw_line(Vector2(side, y), Vector2(side + dir * 120.0, y + 6.0), Color(1, 1, 1, 0.22), 3.0)
	# Emergency vignette.
	if racer.emergency:
		var a := 0.18 + 0.12 * sin(Time.get_ticks_msec() * 0.008)
		for i in 6:
			var w := 18.0 * (i + 1)
			_overlay.draw_rect(Rect2(0, 0, s.x, s.y), Color(1, 0.1, 0.05, a / 6.0), false, w)
	# Nebula ink splats.
	if racer.ink_time > 0.0:
		var fade := clampf(racer.ink_time / 1.0, 0.0, 1.0)
		for sp in _splats:
			var c := Vector2(sp.x * s.x, sp.y * s.y)
			var r := sp.z * k
			_overlay.draw_circle(c, r, Color(0.35, 0.1, 0.5, 0.85 * fade))
			for j in 5:
				var a := TAU * j / 5.0 + sp.x * 10.0
				_overlay.draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.9, r * 0.4, Color(0.45, 0.15, 0.6, 0.8 * fade))
	# Meteor warning when targeted.
	for m in race.items.comets:
		if m.target == racer:
			var a := 0.25 + 0.25 * sin(Time.get_ticks_msec() * 0.02)
			_overlay.draw_rect(Rect2(0, 0, s.x, 10), Color(1, 0.3, 0.1, a))
