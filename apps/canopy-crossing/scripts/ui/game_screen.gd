extends Control
## A run: builds the World and RunSim from content, draws them, reads touch
## (tap to hop, swipe to hop that way), keyboard and gamepad, and runs the
## flow around the crossing: region intro card, tutorial coaching, fail and
## revive offers, results, and the between-run prompts.

const STEP := 1.0 / 60.0
const DEMO_DECIDE := 0.3       # autoplay demo: one move at most every 0.3 s

var cfg: Dictionary = {}
var map: Dictionary = {}
var animal: Dictionary = {}
var world: World
var sim: RunSim
var wv: WorldView
var atm: Atmosphere
var wv3: WorldView3D
var fp_overlay: FirstPersonOverlay
var view := "bird"               # bird | fpv
var eye_btn: Widgets.EyeButton
var canopy_tip: Label
var hud: Control
var overlay: Control
var paused := false
var blocking := false
var started := false
var finished := false
var acc := 0.0
var revive_ad_used := false
var low_life_prompted := false
var last_state := "play"
var tutorial_steps: Array = []
var tut_index := -1
var tut_done := {}
var autoplay := false
var bot_plan: Array = []
var bot_steps := 999
var _touch := {"active": false, "start": Vector2.ZERO, "time": 0.0, "fired": false}

var lbl_rows: Label
var lbl_best: Label
var lbl_score: Label
var lbl_berries: Label
var lbl_combo: Label
var lives_box: HBoxContainer
var ability_btn: Widgets.AbilityButton
var power_btns := {}
var pause_btn: Button
var progress_bar: ProgressBar
var timer_bar: ProgressBar
var toast: Label
var tut_bubble: PanelContainer
var tut_label: Label
var tut_hint: Control
var fps_label: Label
var hud_buttons: Array[Control] = []
var run_items := {}


func setup(args: Dictionary) -> void:
	cfg = args


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	map = Content.map(String(cfg.get("map", "amazon")))
	var aid := String(cfg.get("animal", Save.data.equipped_animal))
	if not Content.animals.has(aid):
		aid = Content.starters()[0]
	animal = Content.animal(aid)
	autoplay = bool(cfg.get("autoplay", false)) or OS.get_cmdline_user_args().has("--autoplay")
	_build_run()
	_build_view()
	_build_hud()
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	Sfx.map_music(String(map.id))
	Ads.in_run = true
	Ads.run_stopped = false
	Analytics.event("run_start", {"mode": cfg.mode, "map": map.id, "stage": cfg.get("stage", 0), "animal": animal.id})
	if cfg.mode == "tutorial":
		Analytics.funnel("tutorial_start")
		tutorial_steps = Content.onboarding.get("tutorial", {}).get("steps", [])
		_start()
	elif not String(map.id) in Save.data.seen_intro and not autoplay:
		_intro_card(true)
	else:
		_start()


func _exit_tree() -> void:
	Ads.in_run = false
	Ads.run_stopped = false


func _build_run() -> void:
	world = World.new()
	world.setup(map, String(cfg.mode), int(cfg.get("stage", 0)), int(cfg.get("seed", 1)))
	var opts := {}
	var lives := 3 if cfg.mode in ["journey", "tutorial"] else 1
	var shields := 0
	var powerups := []
	run_items.clear()
	if cfg.mode != "tutorial" and not autoplay:
		for item in Save.data.get("loadout", []):
			if Save.item_count(String(item)) <= 0:
				continue
			match String(item):
				"extra_life":
					lives += 1
				"shield_totem":
					shields += 1
				"vine_grapple":
					powerups.append({"module": "grapple", "rows": 2, "uses": 1, "cooldown": 1.0})
				"time_slow":
					powerups.append({"module": "time_slow", "duration": 4.0, "uses": 1, "cooldown": 1.0})
				_:
					continue
			Economy.use_item(String(item))
			run_items[String(item)] = true
		Save.data.loadout = Save.data.loadout.filter(func(i): return Save.item_count(String(i)) > 0)
		Save.mark()
	opts.lives = lives
	opts.shields = shields
	opts.powerups = powerups
	var mt := float(map.get("difficulty", {}).get("move_timer", 0))
	opts.move_timer = mt if bool(Save.setting("move_timer", true)) and cfg.mode != "tutorial" else 0.0
	opts.creep = map.get("endless", {}).get("creep", [0.2, 0.8])
	opts.water_restart = bool(Content.rules.get("water_restarts_run", true))
	sim = RunSim.new()
	sim.setup(world, animal, opts)


func _build_view() -> void:
	var skin_id := String(Save.data.equipped_skin.get(String(animal.id), ""))
	var look := {}
	for s in animal.get("skins", []):
		if s.id == skin_id:
			look = AnimalPainter.with_skin(animal.look, s)
	var trail := Content.cosmetic(String(Save.data.get("equipped_trail", "")))
	if not String(Save.data.get("equipped_trail", "")) in Save.data.owned_cosmetics:
		trail = {}
	wv = WorldView.new()
	wv.setup(sim, animal, look, trail)
	add_child(wv)
	atm = Atmosphere.new()
	atm.setup(wv)
	add_child(atm)
	wv.update_view(1.0)
	if String(cfg.get("view", "")) == "fpv" or (bool(Save.setting("first_person", false)) and not autoplay):
		set_view("fpv", false)


# ------------------------------------------------------------------ HUD

func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var top := UI.safe_top(self) + 18.0
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = top
	bar.offset_left = 20
	bar.offset_right = -20
	bar.add_theme_constant_override("separation", 12)
	hud.add_child(bar)
	pause_btn = UI.button("II", _pause, Color(0, 0, 0, 0.35), 34, 76)
	pause_btn.custom_minimum_size = Vector2(76, 76)
	bar.add_child(pause_btn)
	hud_buttons.append(pause_btn)
	bar.add_child(UI.spacer())
	var mid := UI.vbox(0)
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	lbl_rows = UI.label("0", 72, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_rows.add_theme_constant_override("outline_size", 10)
	lbl_rows.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	mid.add_child(lbl_rows)
	lbl_best = UI.label("", 22, UI.MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_best.add_theme_constant_override("outline_size", 6)
	lbl_best.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	mid.add_child(lbl_best)
	bar.add_child(mid)
	bar.add_child(UI.spacer())
	var right := UI.vbox(4)
	var chip := Widgets.currency_chip("berries", "0", 30)
	lbl_berries = chip.get_node("Value")
	lbl_berries.add_theme_constant_override("outline_size", 6)
	lbl_berries.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	chip.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(chip)
	lives_box = UI.hbox(2)
	lives_box.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(lives_box)
	lbl_score = UI.label("", 22, UI.MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(lbl_score)
	right.custom_minimum_size.x = 150
	bar.add_child(right)
	var under := UI.vbox(6)
	under.set_anchors_preset(Control.PRESET_TOP_WIDE)
	under.offset_top = top + 130
	under.offset_left = 120
	under.offset_right = -120
	under.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(under)
	progress_bar = _bar(Color("9cf06a"))
	progress_bar.visible = world.goal_row > 0 and cfg.mode == "journey"
	under.add_child(progress_bar)
	timer_bar = _bar(Color("ffb74a"))
	timer_bar.visible = sim.move_limit > 0.0
	under.add_child(timer_bar)
	lbl_combo = UI.label("", 34, UI.ACCENT, true, HORIZONTAL_ALIGNMENT_CENTER)
	lbl_combo.add_theme_constant_override("outline_size", 8)
	lbl_combo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	under.add_child(lbl_combo)
	toast = UI.label("", 34, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-300, top + 260)
	toast.size = Vector2(600, 50)
	toast.add_theme_constant_override("outline_size", 10)
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	toast.modulate.a = 0.0
	hud.add_child(toast)
	# ability + power-ups, on the thumb's side
	var left_handed := bool(Save.setting("left_handed", false))
	# view switch on the other side from the ability button
	var eyebox := UI.vbox(6)
	eyebox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if left_handed else Control.PRESET_BOTTOM_LEFT)
	eyebox.grow_horizontal = Control.GROW_DIRECTION_BEGIN if left_handed else Control.GROW_DIRECTION_END
	eyebox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	eyebox.offset_bottom = -40
	if left_handed:
		eyebox.offset_right = -28
	else:
		eyebox.offset_left = 28
	hud.add_child(eyebox)
	canopy_tip = UI.wrap_label(String(Content.onboarding.get("store_prompts", {}).get("canopy_tip", {}).get("text", "Dense canopy ahead: tap the eye")), 24, Color.WHITE)
	canopy_tip.custom_minimum_size.x = 300
	canopy_tip.add_theme_font_override("font", UI.font(true))
	canopy_tip.add_theme_constant_override("outline_size", 8)
	canopy_tip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	canopy_tip.visible = false
	eyebox.add_child(canopy_tip)
	eye_btn = Widgets.EyeButton.new(124)
	eye_btn.fpv = view == "fpv"
	eye_btn.pressed.connect(toggle_view)
	eye_btn.size_flags_horizontal = Control.SIZE_SHRINK_END if left_handed else Control.SIZE_SHRINK_BEGIN
	eyebox.add_child(eye_btn)
	hud_buttons.append(eye_btn)
	var col := UI.vbox(14)
	col.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if left_handed else Control.PRESET_BOTTOM_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_END if left_handed else Control.GROW_DIRECTION_BEGIN
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.offset_bottom = -40
	if left_handed:
		col.offset_left = 28
	else:
		col.offset_right = -28
	col.alignment = BoxContainer.ALIGNMENT_END
	hud.add_child(col)
	for a in sim.powerups:
		var label := "Grapple" if a.id == "grapple" else "Time Slow"
		var b := Widgets.AbilityButton.new(label, 112, Color("8ad0ff"))
		b.pressed.connect(func(): sim.use_powerup(a.id))
		b.size_flags_horizontal = Control.SIZE_SHRINK_END if not left_handed else Control.SIZE_SHRINK_BEGIN
		col.add_child(b)
		power_btns[a.id] = b
		hud_buttons.append(b)
	var ab := sim.button_ability()
	if ab:
		ability_btn = Widgets.AbilityButton.new(String(animal.ability.name), 168, UI.ACCENT)
		ability_btn.pressed.connect(func(): sim.use_ability())
		col.add_child(ability_btn)
		hud_buttons.append(ability_btn)
	# tutorial bubble
	tut_bubble = UI.panel(Color(0.04, 0.12, 0.08, 0.86), 30, 26)
	tut_bubble.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tut_bubble.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tut_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tut_bubble.offset_bottom = -230
	tut_bubble.offset_left = -270
	tut_bubble.offset_right = 270
	tut_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tv := UI.hbox(16)
	tut_hint = TutHint.new()
	tv.add_child(tut_hint)
	tut_label = UI.wrap_label("", 34, Color.WHITE)
	tut_label.add_theme_font_override("font", UI.font(true))
	tut_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(tut_label)
	tut_bubble.add_child(tv)
	tut_bubble.visible = false
	hud.add_child(tut_bubble)
	if bool(Save.setting("show_fps", false)):
		fps_label = UI.label("", 22, Color(1, 1, 1, 0.8), true)
		fps_label.position = Vector2(24, top + 96)
		hud.add_child(fps_label)
	_refresh_lives()


func _bar(c: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.custom_minimum_size = Vector2(0, 12)
	p.show_percentage = false
	p.add_theme_stylebox_override("background", UI.box(Color(0, 0, 0, 0.35), 6, 0, Color.TRANSPARENT, 0))
	p.add_theme_stylebox_override("fill", UI.box(c, 6, 0, Color.TRANSPARENT, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _refresh_lives() -> void:
	for ch in lives_box.get_children():
		ch.queue_free()
	if cfg.mode in ["journey", "tutorial"] or sim.lives > 1:
		for i in maxi(0, sim.lives):
			lives_box.add_child(Widgets.CurrencyIcon.new("heart", 30))
	var sh := sim.shields
	for a in sim.abilities:
		if a.id == "shield":
			sh += a.charges
	for i in sh:
		lives_box.add_child(Widgets.CurrencyIcon.new("shield", 30))


func _update_hud() -> void:
	lbl_rows.text = str(sim.max_row)
	match String(cfg.mode):
		"journey":
			lbl_best.text = "%s · level %d" % [String(map.name).to_upper(), int(cfg.get("stage", 0)) + 1]
			progress_bar.value = 100.0 * sim.max_row / maxf(1.0, float(world.goal_row))
		"endless":
			lbl_best.text = "BEST %d" % Progress.best_rows(String(map.id))
		"daily":
			lbl_best.text = "DAILY · BEST %d" % Progress.daily_best()
		"tutorial":
			lbl_best.text = "TRAINING"
	lbl_berries.text = str(sim.berries)
	lbl_score.text = "%d pts" % sim.score
	lbl_combo.text = ("COMBO x%s" % str(sim.multiplier())) if sim.multiplier() > 1.0 else ""
	if fps_label:
		fps_label.text = "%d fps" % Engine.get_frames_per_second()
	if timer_bar.visible:
		timer_bar.value = 100.0 * (1.0 - sim.no_progress / maxf(0.1, sim.move_limit))
	if ability_btn:
		var a := sim.button_ability()
		ability_btn.set_state(a.progress(), a.can_use(), a.is_active(), a.badge())
	for a2 in sim.powerups:
		var b: Widgets.AbilityButton = power_btns.get(a2.id)
		if b:
			b.set_state(1.0 if a2.uses_left != 0 else 0.0, a2.can_use(), a2.is_active(), str(a2.uses_left) if a2.uses_left > 0 else "")
			b.modulate.a = 1.0 if a2.uses_left != 0 else 0.4


func _toast(text: String, c := Color.WHITE) -> void:
	toast.text = text
	toast.add_theme_color_override("font_color", c)
	toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)


# ------------------------------------------------------------------ loop

func _start() -> void:
	started = true
	blocking = false
	if cfg.mode == "tutorial":
		_tutorial_update()


func _process(dt: float) -> void:
	if not started or paused or blocking or finished:
		_update_views(dt)
		return
	acc += minf(dt, 0.1)
	while acc >= STEP:
		acc -= STEP
		if autoplay:
			_autoplay_tick()
		sim.step(STEP)
		_drain_fx()
		if sim.state != last_state:
			_on_state(sim.state)
			last_state = sim.state
			if blocking or finished:
				break
	_update_views(dt)
	_update_hud()
	if cfg.mode == "tutorial":
		_tutorial_update()


# ------------------------------------------------------------------ views

func _update_views(dt: float) -> void:
	if view == "fpv":
		wv3.update_view(dt)
	else:
		wv.update_view(dt)
	if canopy_tip:
		var ahead := false
		for k in 4:
			if world.lane(sim.row + k).covered:
				ahead = true
		canopy_tip.visible = ahead and view == "bird" and not finished and not tut_bubble.visible
		eye_btn.pulse = ahead and view == "bird" and not finished


func toggle_view() -> void:
	set_view("bird" if view == "fpv" else "fpv")


## Bird's-eye (2D, top-down) or first person (3D, through the animal's eyes).
func set_view(v: String, remember := true) -> void:
	if v == view:
		return
	view = v
	if v == "fpv":
		if wv3 == null:
			wv3 = WorldView3D.new()
			wv3.setup(sim, animal)
			add_child(wv3)
			move_child(wv3, atm.get_index())
			fp_overlay = FirstPersonOverlay.new()
			fp_overlay.setup(sim, animal)
			add_child(fp_overlay)
			move_child(fp_overlay, atm.get_index() + 1)
		wv3.visible = true
		fp_overlay.visible = true
		wv.visible = false
		atm.fpv = true
		wv3.update_view(0.016)
	else:
		if wv3:
			wv3.visible = false
			fp_overlay.visible = false
		wv.visible = true
		atm.fpv = false
		wv.update_view(1.0)
	if eye_btn:
		eye_btn.fpv = v == "fpv"
	Sfx.play("whoosh", 1.2, -6.0)
	if remember:
		Save.set_setting("first_person", v == "fpv")
		Analytics.event("view", {"view": v, "map": map.id, "row": sim.row, "covered": world.lane(sim.row + 1).covered})


func _on_state(st: String) -> void:
	match st:
		"respawn":
			_refresh_lives()
		"play":
			_refresh_lives()
			if cfg.mode == "journey" and sim.lives == 1 and not low_life_prompted:
				_low_lives_prompt()
		"dead":
			_refresh_lives()
			_revive_offer()
		"restart":
			_water_restart()
		"won", "over":
			_finish()


func _drain_fx() -> void:
	for f in sim.fx:
		var p := wv.px(float(f.x), float(f.row))
		match String(f.type):
			"hop":
				Sfx.play("hop", randf_range(0.94, 1.08), -4.0)
				Sfx.haptic(8)
				wv.fx.burst(p + Vector2(0, 14), Color(1, 1, 1, 0.5), 4, 60.0, "dot", 4.0)
			"land":
				if f.get("surface", "") == "platform":
					Sfx.play("land", 0.9, -6.0)
			"splash", "swim", "float":
				Sfx.play("splash", 1.0 if f.type == "splash" else 1.2, 0.0 if f.type == "splash" else -6.0)
				wv.fx.ring(p, Color(1, 1, 1, 0.9), 10, 50)
				wv.fx.burst(p, Color(0.75, 0.9, 1.0), 10, 200, "dot", 5, 120)
			"progress":
				if float(f.get("mult", 1.0)) > 1.0 and sim.combo % 5 == 0:
					wv.fx.text(p + Vector2(0, -70), "x%s" % str(f.mult), UI.ACCENT, 34)
					Sfx.play("combo", 1.0 + 0.05 * sim.combo / 5.0, -4.0)
			"collect":
				var ip := wv.px(float(f.ix), float(f.irow))
				var def := Content.collectible(String(f.id))
				var rw: Dictionary = def.get("reward", {})
				Sfx.play("collect", 1.0 + 0.1 * float(rw.get("berries", 1)) / 3.0)
				wv.fx.burst(ip + Vector2(0, -10), Color(1, 0.95, 0.6), 10, 180, "star", 6, 60)
				wv.fx.text(ip + Vector2(0, -50), "+%d" % int(rw.get("berries", rw.get("amber", 1))), UI.AMBER if rw.has("amber") else Color.WHITE, 30)
			"die":
				var cause := String(f.cause)
				Sfx.play({"crushed": "crush", "eaten": "chomp", "drowned": "splash", "burned": "burn", "fell": "fall", "swept": "fall", "timeout": "fall"}.get(cause, "crush"))
				Sfx.haptic(70)
				wv.shake = 0.8
				wv.fx.burst(p + Vector2(0, -30), Color(1, 1, 1), 14, 280, "star", 6, 80)
				_toast(sim.cause_text, Color("ffd0c0"))
			"absorb":
				Sfx.play("shield")
				wv.fx.ring(p + Vector2(0, -30), Color(0.6, 0.9, 1.0), 20, 70, 0.4, 1.0)
				_toast({"stealth": "Unseen!", "toxic": "Too toxic to eat!"}.get(String(f.get("style", "")), "Blocked!"), Color("bfe8ff"))
			"shield_break":
				Sfx.play("shield")
				wv.fx.ring(p + Vector2(0, -30), Color(0.6, 0.9, 1.0), 20, 80, 0.4, 1.0)
				_toast("Shield used!", Color("bfe8ff"))
			"ability", "powerup":
				Sfx.play("ability")
				Sfx.haptic(20)
				wv.fx.burst(p + Vector2(0, -30), UI.ACCENT, 12, 220, "star", 6)
			"leap":
				Sfx.play("whoosh")
			"goal":
				Sfx.play("goal")
				wv.fx.burst(p + Vector2(0, -40), Color("ffe066"), 30, 380, "star", 8, 200)
				wv.fx.burst(p + Vector2(0, -40), Color("9cf06a"), 20, 300, "leaf", 6, 200)
			"gust":
				Sfx.play("wind")
			"mudslide":
				Sfx.play("mud")
				wv.shake = 0.3
			"near_miss":
				Sfx.play("whoosh", 1.35, -8.0)
				Sfx.haptic(12)
				wv.fx.text(p + Vector2(0, -80), "Close call! +2", Color("ffe9a0"), 28)
			"bump":
				Sfx.play("bump", 1.0, -6.0)
				wv.shake = 0.12
			"respawn":
				Sfx.play("respawn")
				wv.fx.ring(p + Vector2(0, -20), Color(1, 1, 0.7), 10, 60)
			"smash", "scare", "plow":
				Sfx.play("smash" if f.type != "scare" else "ability")
				var sp := wv.px(float(f.x), float(f.get("srow", f.row)))
				wv.fx.burst(sp, Color(0.85, 0.75, 0.55), 14, 260, "dot", 6, 80)
				wv.shake = 0.25
	sim.fx.clear()


func _autoplay_tick() -> void:
	bot_steps += 1
	if sim.state != "play":
		bot_plan.clear()
		return
	if sim.hopping and bot_steps < 40:
		return
	if bot_steps * STEP < DEMO_DECIDE - 0.0001 and bot_steps < 40:
		return
	if bot_plan.is_empty():
		var bot := PathBot.new()
		bot.decide = DEMO_DECIDE
		bot.max_nodes = 4000
		var goal := sim.row + 8
		if world.goal_row >= 0:
			goal = mini(goal, world.goal_row)
		bot_plan = bot.plan(sim, goal)
		if bot_plan.is_empty():
			bot_plan = [Vector2i.ZERO]
	var mv: Vector2i = bot_plan.pop_front()
	if mv != Vector2i.ZERO:
		sim.hop(mv)
	bot_steps = 0


# ------------------------------------------------------------------ input

func _over_hud(pos: Vector2) -> bool:
	for c in hud_buttons:
		if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().grow(8).has_point(pos):
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				if not finished and not blocking:
					_pause()
				return
			KEY_R:
				if not blocking:
					Game.restart_run()
				return
	if not started or paused or blocking or finished or autoplay:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				sim.hop(Vector2i(0, 1))
			KEY_DOWN, KEY_S:
				sim.hop(Vector2i(0, -1))
			KEY_LEFT, KEY_A:
				sim.hop(Vector2i(-1, 0))
			KEY_RIGHT, KEY_D:
				sim.hop(Vector2i(1, 0))
			KEY_V:
				toggle_view()
			KEY_SPACE, KEY_SHIFT:
				sim.use_ability()
			KEY_Q:
				sim.use_powerup("grapple")
			KEY_E:
				sim.use_powerup("time_slow")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				sim.hop(Vector2i(0, 1))
			JOY_BUTTON_DPAD_DOWN:
				sim.hop(Vector2i(0, -1))
			JOY_BUTTON_DPAD_LEFT:
				sim.hop(Vector2i(-1, 0))
			JOY_BUTTON_DPAD_RIGHT:
				sim.hop(Vector2i(1, 0))
			JOY_BUTTON_A:
				sim.hop(Vector2i(0, 1))
			JOY_BUTTON_X, JOY_BUTTON_B:
				sim.use_ability()
			JOY_BUTTON_Y:
				toggle_view()
			JOY_BUTTON_START:
				_pause()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _over_hud(event.position):
				return
			_touch = {"active": true, "start": event.position, "time": Time.get_ticks_msec(), "fired": false}
		elif _touch.active:
			if not _touch.fired and not _over_hud(event.position):
				sim.hop(Vector2i(0, 1))
			_touch.active = false
	elif event is InputEventScreenDrag and _touch.active and not _touch.fired:
		var d: Vector2 = event.position - _touch.start
		if d.length() > 36.0:
			_touch.fired = true
			if absf(d.x) > absf(d.y):
				sim.hop(Vector2i(1 if d.x > 0 else -1, 0))
			else:
				sim.hop(Vector2i(0, 1 if d.y < 0 else -1))


# ------------------------------------------------------------------ overlays

func _pause() -> void:
	if finished or blocking or paused:
		return
	paused = true
	var card := PromptCard.make("Paused", "", [
		{"id": "resume", "text": "Resume", "color": UI.ACCENT},
		{"id": "restart", "text": "Restart"},
		{"id": "about", "text": "About %s" % String(map.name)},
		{"id": "quit", "text": "Quit run"}])
	card.closed.connect(_on_pause_choice)
	overlay.add_child(card)


func _on_pause_choice(c: String) -> void:
	paused = false
	match c:
		"restart":
			Game.restart_run()
		"about":
			_intro_card(false)
		"quit":
			_quit_run()


func _quit_run() -> void:
	if cfg.mode == "tutorial":
		Save.data.tutorial_done = true
		Save.mark()
	Game.goto("world" if cfg.mode == "journey" else "home")


func _intro_card(first: bool) -> void:
	blocking = true
	var card := IntroCard.make(String(map.id))
	card.closed.connect(func():
		blocking = false
		if first:
			if not String(map.id) in Save.data.seen_intro:
				Save.data.seen_intro.append(String(map.id))
				Save.mark()
			_start())
	overlay.add_child(card)


func _low_lives_prompt() -> void:
	low_life_prompted = true
	var cfgp: Dictionary = Content.onboarding.get("store_prompts", {}).get("low_lives", {})
	if not _prompt_ready("low_lives", int(cfgp.get("cooldown_runs", 2))):
		return
	var owned := Save.item_count("extra_life")
	var price := Store.consumable_price("extra_life")
	if owned <= 0 and not Economy.can_afford(Economy.price_in(price, "berries")):
		return
	blocking = true
	_mark_prompt("low_lives")
	var btns := []
	if owned > 0:
		btns.append({"id": "use", "text": "Use Extra Life (%d)" % owned, "color": UI.ACCENT})
	else:
		btns.append({"id": "buy", "text": "Buy one: %d Berries" % int(price.get("berries", 0)), "color": UI.ACCENT})
	btns.append({"id": "no", "text": "Keep going"})
	var card := PromptCard.make(String(cfgp.get("title", "Last life")), String(cfgp.get("text", "")), btns, Widgets.CurrencyIcon.new("heart", 80), Color("ef7a8a"))
	card.closed.connect(func(c):
		if c == "buy" and Economy.buy_consumable("extra_life", "berries"):
			c = "use"
		if c == "use" and Economy.use_item("extra_life"):
			sim.lives += 1
			_refresh_lives()
		blocking = false)
	overlay.add_child(card)


func _revive_offer() -> void:
	blocking = true
	Ads.run_stopped = true
	if cfg.mode == "tutorial" or autoplay:
		if cfg.mode == "tutorial":
			sim.revive()
			blocking = false
			Ads.run_stopped = false
			return
		sim.finish()
		blocking = false
		_finish()
		return
	var sp: Dictionary = Content.onboarding.get("store_prompts", {})
	var rv: Dictionary = sp.get("revive", {})
	var cost := int(Content.consumable("revive").get("price", {}).get("amber", 1))
	var btns := []
	if Save.item_count("revive") > 0:
		btns.append({"id": "item", "text": "Use a Revive (%d)" % Save.item_count("revive"), "color": UI.ACCENT})
	btns.append({"id": "amber", "text": "Revive: %d Amber" % cost, "color": UI.AMBER, "disabled": Economy.amber() < cost})
	if not revive_ad_used:
		btns.append({"id": "ad", "text": "Watch a video to revive", "color": UI.BLUE})
	btns.append({"id": "no", "text": "No thanks"})
	var text := String(sim.cause_text) + "\n" + String(rv.get("text", "")).format({"cost": cost})
	var card := PromptCard.make(String(rv.get("title", "Keep going?")), text, btns, Widgets.Portrait.new(animal, Vector2(150, 150)))
	card.closed.connect(_on_revive_choice.bind(cost))
	overlay.add_child(card)


func _on_revive_choice(c: String, cost: int) -> void:
	match c:
		"item":
			Economy.use_item("revive")
			_do_revive("item")
		"amber":
			if Economy.spend({"amber": cost}, "revive"):
				_do_revive("amber")
			else:
				_end_after_death()
		"ad":
			revive_ad_used = true
			Ads.rewarded("revive", _on_revive_ad)
		_:
			_end_after_death()


func _on_revive_ad(ok: bool) -> void:
	if ok:
		_do_revive("ad")
	else:
		_end_after_death()


func _do_revive(how: String) -> void:
	Analytics.event("revive", {"how": how, "map": map.id, "row": sim.row})
	sim.revive()
	last_state = sim.state
	blocking = false
	Ads.run_stopped = false
	_refresh_lives()


func _end_after_death() -> void:
	sim.finish()
	last_state = sim.state
	blocking = false
	_finish()


func _prompt_ready(key: String, cooldown_runs: int) -> bool:
	var last := int(Save.data.prompts.get(key, -9999))
	return int(Save.data.stats.get("runs", 0)) - last >= cooldown_runs


func _mark_prompt(key: String) -> void:
	Save.data.prompts[key] = int(Save.data.stats.get("runs", 0))
	Save.mark()


# ------------------------------------------------------------------ results

func _finish() -> void:
	if finished:
		return
	finished = true
	Ads.run_stopped = true
	var won := sim.state == "won"
	var settled := _settle(won)
	tut_bubble.visible = false
	for c in hud.get_children():
		c.visible = false
	var card := ResultsCard.make(self, won, sim.max_row, int(settled.earned), sim.amber, settled.rec, settled.extra)
	overlay.add_child(card)


## Fell into the water: keep what was earned, splash, and start the run over.
func _water_restart() -> void:
	if finished:
		return
	finished = true
	blocking = true
	Ads.run_stopped = true
	var earned := 0
	if cfg.mode != "tutorial":
		earned = int(_settle(false).earned)
	Analytics.event("water_restart", {"mode": cfg.mode, "map": map.id, "stage": cfg.get("stage", 0), "row": sim.row})
	tut_bubble.visible = false
	_toast("Splash! Back to the start" + ("  +%d Berries" % earned if earned > 0 else ""), Color("bfe8ff"))
	get_tree().create_timer(float(Content.rules.get("restart_delay", 1.2))).timeout.connect(_restart_now)


func _restart_now() -> void:
	if is_inside_tree():
		Game.restart_run()


## Pay out and record a finished run: {"earned", "rec", "extra"}.
func _settle(won: bool) -> Dictionary:
	sim.finish()
	var rows := sim.max_row
	var collected := sim.taken.size()
	var earned := 0
	var extra := []
	earned = Economy.run_berries(sim.berries, rows, won)
	if not autoplay:
		if cfg.mode == "tutorial":
			earned += 250
			extra.append("Welcome gift: 250 Berries")
		if cfg.mode == "daily" and not bool(Save.data.daily_challenge.get("rewarded", false)) and int(Save.data.daily_challenge.get("day", -1)) in [-1, Progress.today()]:
			earned += 50
			Save.data.daily_challenge["rewarded"] = true
			Save.data.daily_challenge["day"] = Progress.today()
			extra.append("Daily challenge bonus: 50 Berries")
		Economy.add("berries", earned, "run")
		Economy.add("amber", sim.amber, "run_pickup")
	var rec := {}
	if not autoplay:
		rec = Progress.record_run({"map": map.id, "mode": cfg.mode, "stage": int(cfg.get("stage", 0)), "rows": rows, "score": sim.score,
			"won": won, "cause": sim.cause if not won else "", "collected": collected, "best_combo": sim.combo})
		Analytics.event("run_end", {"mode": cfg.mode, "map": map.id, "stage": cfg.get("stage", 0), "animal": animal.id, "rows": rows,
			"score": sim.score, "won": won, "berries": earned, "deaths": sim.deaths, "revives": sim.revives, "near_misses": sim.near_misses, "time": snappedf(sim.t, 0.1)})
		if sim.cause != "" and not won:
			Analytics.event("death", {"cause": sim.cause, "hazard": sim.cause_hazard, "map": map.id, "row": sim.row})
		Analytics.funnel("first_run_end")
		Ads.note_run_finished()
		if cfg.mode == "tutorial":
			Save.data.tutorial_done = true
			Save.mark()
			Analytics.funnel("tutorial_complete")
	return {"earned": earned, "rec": rec, "extra": extra}


## Called by the results card when the player picks where to go.
func leave(target: String) -> void:
	var go := func():
		match target:
			"retry":
				Game.restart_run()
			"next":
				Game.start_journey(String(map.id), int(cfg.get("stage", 0)) + 1)
			"animals":
				Game.goto("animals")
			"world":
				Game.goto("world")
			"store":
				Game.goto("store")
			_:
				Game.goto("home")
	if cfg.mode == "tutorial" or autoplay:
		go.call()
		return
	if _milestone_due():
		_milestone(go)
		return
	Ads.maybe_interstitial(go)


func _milestone_due() -> bool:
	if cfg.mode != "journey" or not Progress.map_complete(String(map.id)):
		return false
	var nxt := Progress.next_map(String(map.id))
	if nxt == "" or Save.owns_map(nxt):
		return false
	var cd := int(Content.onboarding.get("store_prompts", {}).get("milestone", {}).get("cooldown_runs", 3))
	return _prompt_ready("milestone_" + nxt, cd)


func _milestone(go: Callable) -> void:
	var nxt := Progress.next_map(String(map.id))
	var nm := Content.map(nxt)
	_mark_prompt("milestone_" + nxt)
	var mp: Dictionary = Content.onboarding.get("store_prompts", {}).get("milestone", {})
	var prod := Content.product(Store.map_product(nxt))
	var card := PromptCard.make(String(mp.get("title", "")).format({"region": nm.name}),
		String(mp.get("text", "")).format({"product": prod.get("title", "pack")}),
		[{"id": "store", "text": "See the %s" % String(prod.get("title", "pack")), "color": UI.ACCENT}, {"id": "no", "text": "Not now"}],
		Widgets.Flag.new(nxt, Vector2(120, 84)), UI.region_color(nxt))
	card.closed.connect(func(c):
		Analytics.event("prompt", {"kind": "milestone", "map": nxt, "choice": c})
		if c == "store":
			Game.goto("store", {"focus": String(prod.get("id", ""))})
		else:
			go.call())
	overlay.add_child(card)


func double_berries(amount: int, done: Callable) -> void:
	Ads.rewarded("double_rewards", func(ok):
		if ok:
			Economy.add("berries", amount, "double_ad")
		done.call(ok))


# ------------------------------------------------------------------ tutorial

func _tutorial_update() -> void:
	if tutorial_steps.is_empty():
		return
	if tut_index >= 0 and tut_index < tutorial_steps.size():
		var st: Dictionary = tutorial_steps[tut_index]
		if _cond(String(st.get("until", ""))):
			tut_done[tut_index] = true
			Analytics.event("tutorial_step", {"id": st.id})
			if not String(st.id) in Save.data.tutorial_steps:
				Save.data.tutorial_steps.append(String(st.id))
				Save.mark()
			tut_index = -1
			tut_bubble.visible = false
	if tut_index < 0:
		for i in tutorial_steps.size():
			if tut_done.has(i):
				continue
			var st2: Dictionary = tutorial_steps[i]
			if _cond(String(st2.get("trigger", ""))) and not _cond(String(st2.get("until", ""))):
				tut_index = i
				tut_label.text = String(st2.text)
				(tut_hint as TutHint).kind = String(st2.get("hint", "tap"))
				tut_bubble.visible = true
				tut_bubble.modulate.a = 0.0
				create_tween().tween_property(tut_bubble, "modulate:a", 1.0, 0.25)
				break
			elif _cond(String(st2.get("until", ""))):
				tut_done[i] = true


func _cond(c: String) -> bool:
	if c.contains("|"):
		for part in c.split("|"):
			if _cond(part):
				return true
		return false
	if c.contains("&"):
		for part in c.split("&"):
			if not _cond(part):
				return false
		return true
	if c == "fpv":
		return view == "fpv"
	if c == "birdseye":
		return view == "bird"
	if c == "next_covered":
		return world.lane(sim.row + 1).covered
	if c == "" or c == "start":
		return c == "start"
	if c == "goal":
		return sim.state == "won"
	if c.begins_with("row>="):
		return sim.max_row >= int(c.substr(5))
	if c.begins_with("next_lane:"):
		return world.lane(sim.row + 1).type == c.substr(10)
	return false


class TutHint extends Control:
	var kind := "tap"
	var t := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(96, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		match kind:
			"tap":
				var k := fposmod(t * 1.2, 1.0)
				Draw.ellipse_line(self, c + Vector2(0, -10), 10 + k * 26, 10 + k * 26, Color(1, 1, 1, 1.0 - k), 3)
				_finger(c + Vector2(6, 14 - sin(k * PI) * 8))
			"wait":
				Draw.ellipse_line(self, c, 34, 34, Color.WHITE, 4)
				draw_line(c, c + Vector2(0, -24), Color.WHITE, 4)
				draw_line(c, c + Vector2(cos(t * 3.0), sin(t * 3.0)) * 20, UI.ACCENT, 4)
			"swipe":
				var k2 := fposmod(t, 1.2) / 1.2
				_finger(c + Vector2(lerpf(-26, 26, k2), 10))
				draw_line(c + Vector2(-34, -24), c + Vector2(34, -24), Color(1, 1, 1, 0.7), 4)
				draw_colored_polygon(PackedVector2Array([c + Vector2(40, -24), c + Vector2(26, -34), c + Vector2(26, -14)]), Color(1, 1, 1, 0.7))
			"goal":
				Draw.star(self, c, 34 + sin(t * 4.0) * 4.0, Color("9cf06a"), 5, 0.45)
			"eye":
				var r := 30.0 + sin(t * 4.0) * 3.0
				var pts := PackedVector2Array()
				for i in 13:
					var a := PI * i / 12.0
					pts.append(c + Vector2(-cos(a) * r, -sin(a) * r * 0.6))
				for i in range(1, 12):
					var a2 := PI * i / 12.0
					pts.append(c + Vector2(cos(a2) * r, sin(a2) * r * 0.6))
				draw_colored_polygon(pts, Color.WHITE)
				Draw.ellipse(self, c, r * 0.36, r * 0.36, Color("2a6fe0"))
				Draw.ellipse(self, c, r * 0.16, r * 0.16, Color.BLACK)

	func _finger(p: Vector2) -> void:
		Draw.ellipse(self, p + Vector2(0, 18), 16, 22, Color("f2d0b0"))
		Draw.rrect(self, Rect2(p + Vector2(-8, -22), Vector2(16, 36)), 8, Color("f2d0b0"))
		Draw.ellipse(self, p + Vector2(0, -16), 6, 6, Color("e8b8a0"))
