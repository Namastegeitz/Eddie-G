class_name Race
extends Node3D
## Runs one race: builds the world from Game.request, spawns racers, runs
## the countdown, ticks everything at a fixed rate, keeps positions and laps,
## handles bumps and slipstream, records ghosts and shows pause/results.

signal race_finished(results: Array)

var req: Dictionary
var tuning: Tuning
var td: TrackData
var racers: Array[Racer] = []
var humans: Array[Racer] = []
var pickups: Pickups
var items: Items
var hazards: Hazards
var racing := false
var done := false
var countdown_left := 4.0
var time := 0.0
var finish_order: Array[Racer] = []
var results: Array = []
var mod_speed := 1.0
var mod_gravity := 1.0
var mod_drain := 1.0
var mod_pod := 1.0
var mod_grip := 1.0
var autopilot := false

var cams: Array[RaceCamera] = []
var huds: Array[Hud] = []
var touch: TouchControls
var ui_layer: CanvasLayer
var _pause_panel: Control
var _results_panel: Control
var _last_count := -1
var _all_done_t := -1.0
var _lap_start := {}
var _led := {}
var _was_short := {}
var ghost_racer: Racer
var _ghost_play := PackedFloat32Array()
var _ghost_rec := PackedFloat32Array()
var _ghost_t := 0.0
var _audio: RaceAudio

const GHOST_HZ := 15.0
const GHOST_STRIDE := 8


func _ready() -> void:
	req = Game.request if not Game.request.is_empty() else Game.quick_request("asteroid_belt", 0, 1)
	tuning = Game.tuning
	autopilot = req.get("autopilot", false)
	var mods: Dictionary = req.get("mods", {})
	mod_speed = mods.get("speed", 1.0)
	mod_gravity = mods.get("gravity", 1.0)
	mod_drain = mods.get("drain", 1.0)
	mod_pod = mods.get("pod", 1.0)
	mod_grip = mods.get("grip", 1.0)
	td = TrackData.make(req.track, req.variant)
	if req.has("laps"):
		td.laps = req.laps
	_build_world()
	_spawn()
	pickups = Pickups.new()
	pickups.name = "Pickups"
	add_child(pickups)
	pickups.setup(self)
	items = Items.new()
	items.name = "Items"
	add_child(items)
	items.setup(self)
	items.only_item = mods.get("only_item", "")
	hazards = Hazards.new()
	hazards.name = "Hazards"
	add_child(hazards)
	hazards.setup(self)
	_setup_views()
	_audio = RaceAudio.new()
	_audio.name = "RaceAudio"
	add_child(_audio)
	_audio.setup(self)
	if req.mode == "tt":
		_setup_ghost()
	countdown_left = 4.0 if not req.get("fast", false) else 0.5
	for c in cams:
		c.intro = 2.4 if countdown_left > 2.0 else 0.0
	InputRouter.calibrate_tilt()
	Events.log_event("race_start", {"mode": req.mode, "track": td.id, "variant": td.variant})
	Audio.music("race")


# ---------------------------------------------------------------- world
func _build_world() -> void:
	var theme := Themes.get_theme(td.theme)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/space_sky.gdshader")
	sm.set_shader_parameter("top_color", theme.sky_top)
	sm.set_shader_parameter("bottom_color", theme.sky_bottom)
	sm.set_shader_parameter("nebula_a", theme.neb_a)
	sm.set_shader_parameter("nebula_b", theme.neb_b)
	sm.set_shader_parameter("nebula_strength", theme.neb)
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = theme.ambient
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	var q := Game.quality()
	env.glow_enabled = q != "low"
	env.glow_intensity = 0.75
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = q != "low"
	env.fog_light_color = theme.fog
	env.fog_density = 0.0011
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = theme.sun
	sun.light_energy = 1.25
	sun.shadow_enabled = false
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, Vector3(theme.sun_dir), Vector3.UP if absf(Vector3(theme.sun_dir).normalized().y) < 0.95 else Vector3.FORWARD)
	var track := Node3D.new()
	track.name = "Track"
	add_child(track)
	TrackBuilder.build(td, track)
	TrackDecor.build(td, track)


func _spawn() -> void:
	var entries: Array = req.racers
	var holder := Node3D.new()
	holder.name = "Racers"
	add_child(holder)
	for k in entries.size():
		var e: Dictionary = entries[k]
		var r := Racer.new()
		r.name = "Racer%d" % k
		holder.add_child(r)
		r.setup(self, k, e.look, e.get("upgrades", {}))
		r.is_human = e.get("human", false) and not autopilot
		r.slot = e.get("slot", -1) if r.is_human else -1
		if r.is_human:
			r.controller = PlayerDriver.new(r.slot)
			humans.append(r)
		else:
			var ai := AIDriver.new(e.get("style", r.pilot.style), e.get("skill", 0.7), hash(r.name) + k * 977)
			r.controller = ai
			r.speed_mult = e.get("speed", 1.0)
		r.place_at(td.grid_transform(k))
		r.event.connect(_on_racer_event.bind(r))
		racers.append(r)
		_lap_start[r.idx] = 0.0
		_led[r.idx] = false
		_was_short[r.idx] = false
	if autopilot and not racers.is_empty():
		humans.append(racers[0])


func _setup_views() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	var view_racers: Array[Racer] = []
	for h in humans:
		view_racers.append(h)
	if view_racers.is_empty():
		view_racers.append(racers[0])
	if view_racers.size() == 1:
		var cam := RaceCamera.new()
		add_child(cam)
		cam.target = view_racers[0]
		cam.current = true
		cam.snap()
		cams.append(cam)
		var hud := Hud.new()
		ui_layer.add_child(hud)
		hud.setup(self, view_racers[0], false)
		huds.append(hud)
		if InputRouter.touch_seen and not autopilot:
			touch = TouchControls.new()
			touch.racer = view_racers[0]
			ui_layer.add_child(touch)
			hud.add_child(_pause_button())
	else:
		var split := VBoxContainer.new()
		split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		split.add_theme_constant_override("separation", 4)
		var bg_layer := CanvasLayer.new()
		bg_layer.layer = 0
		add_child(bg_layer)
		bg_layer.add_child(split)
		for r in view_racers:
			var svc := SubViewportContainer.new()
			svc.stretch = true
			svc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			split.add_child(svc)
			var sv := SubViewport.new()
			sv.audio_listener_enable_3d = r == view_racers[0]
			svc.add_child(sv)
			var cam := RaceCamera.new()
			sv.add_child(cam)
			cam.target = r
			cam.current = true
			cams.append(cam)
			var hud := Hud.new()
			svc.add_child(hud)
			hud.setup(self, r, true)
			huds.append(hud)
		get_viewport().disable_3d = true
		for c in cams:
			c.snap()


func _pause_button() -> Control:
	var b := Button.new()
	b.text = "II"
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(70, 64)
	UiKit.place(b, Vector2(1, 0), Vector2(-90, 256), Vector2(70, 64))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(toggle_pause)
	return b


func hud_for(r: Racer) -> Hud:
	for h in huds:
		if h.racer == r:
			return h
	return null


func cam_for(r: Racer) -> RaceCamera:
	for c in cams:
		if c.target == r:
			return c
	return null


# ---------------------------------------------------------------- loop
func _physics_process(dt: float) -> void:
	if done:
		return
	if not racing:
		countdown_left -= dt
		var n := ceili(countdown_left)
		if n != _last_count and n <= 3 and n >= 1:
			_last_count = n
			for h in huds:
				h.big(str(n), "Hold GAS right on GO for a rocket start" if n == 3 and req.mode != "tt" else "", 0.9, UiKit.CYAN)
			Audio.play("count")
		if countdown_left <= 0.0:
			racing = true
			for h in huds:
				h.big("GO!", "", 0.8, UiKit.GREEN)
			Audio.play("go")
			for r in racers:
				r.on_go()
				_lap_start[r.idx] = 0.0
	else:
		time += dt
	for r in racers:
		r.tick(dt)
	if racing:
		_bumps()
		_slipstream(dt)
		_rubber_band()
	pickups.tick(dt)
	items.tick(dt)
	hazards.tick(dt)
	_rank()
	_laps()
	_ghost_tick(dt)
	if _all_done_t >= 0.0:
		_all_done_t -= dt
		if _all_done_t <= 0.0:
			_finish_race()


func _bumps() -> void:
	var n := racers.size()
	for a in n:
		var ra := racers[a]
		if ra.is_ghost or ra.rescue_time > 0.0:
			continue
		for b in range(a + 1, n):
			var rb := racers[b]
			if rb.is_ghost or rb.rescue_time > 0.0:
				continue
			var d := rb.global_position - ra.global_position
			var dist := d.length()
			if dist > 2.75 or dist < 0.01:
				continue
			var nrm := (d - ra.up * d.dot(ra.up))
			if nrm.length() < 0.01:
				continue
			nrm = nrm.normalized()
			var wa := ra.weight * (1.6 if ra.pilot.passive == "bumper" else 1.0)
			var wb := rb.weight * (1.6 if rb.pilot.passive == "bumper" else 1.0)
			var tot := wa + wb
			var push := 2.75 - dist
			ra.global_position -= nrm * push * wb / tot
			rb.global_position += nrm * push * wa / tot
			var rel := (rb.velocity - ra.velocity).dot(nrm)
			if rel < 0.0:
				var imp := -rel * 1.3 + 2.0
				ra.velocity -= nrm * imp * wb / tot
				rb.velocity += nrm * imp * wa / tot
				if -rel > 5.0:
					ra.emit_signal("event", "bump", {"impact": -rel})
					rb.emit_signal("event", "bump", {"impact": -rel})


func _slipstream(dt: float) -> void:
	for r in racers:
		if r.is_ghost or r.finished:
			continue
		var right := r.heading.cross(r.up)
		var close := false
		for o in racers:
			if o == r or o.is_ghost or o.fwd_speed < 20.0:
				continue
			var d := o.global_position - r.global_position
			var along := d.dot(r.heading)
			if along > 2.5 and along < tuning.slip_range and absf(d.dot(right)) < tuning.slip_width:
				close = true
				break
		r.update_slip(dt, close)


## AI near the humans race a little harder or softer so the pack stays close.
func _rubber_band() -> void:
	if humans.is_empty() or autopilot or req.mode == "tt":
		return
	var lead := -INF
	for h in humans:
		lead = maxf(lead, h.race_dist)
	var base_cls: Dictionary = Catalog.AI_CLASSES[clampi(req.get("ai_class", 1), 0, 3)]
	for r in racers:
		if r.is_human or r.is_ghost:
			continue
		var diff := r.race_dist - lead
		var band := clampf(-diff / 500.0, -0.07, 0.08)
		if req.mode == "boss":
			band = clampf(-diff / 700.0, -0.04, 0.05)
		r.speed_mult = float(base_cls.speed) * (1.0 + band) * float(req.get("boss_edge", 1.0) if req.mode == "boss" else 1.0)


func _rank() -> void:
	var order := racers.duplicate()
	order = order.filter(func(r: Racer) -> bool: return not r.is_ghost)
	order.sort_custom(func(a: Racer, b: Racer) -> bool:
		if a.finished and b.finished:
			return a.finish_time < b.finish_time
		if a.finished != b.finished:
			return a.finished
		return a.race_dist > b.race_dist)
	for k in order.size():
		var r: Racer = order[k]
		r.place = k + 1
		if r.place != 1:
			_led[r.idx] = false


func _laps() -> void:
	if not racing:
		return
	var L := td.main.length
	for r in racers:
		if r.finished or r.is_ghost:
			continue
		if r.on_shortcut and not _was_short[r.idx]:
			r.stats.shortcuts += 1
			if r.is_human:
				var fs: Dictionary = Save.data.get("found_short", {})
				fs[td.id] = true
				Save.data["found_short"] = fs
				Save.mark()
				var h := hud_for(r)
				if h:
					h.toast("SECRET SHORTCUT!", UiKit.GOLD)
		_was_short[r.idx] = r.on_shortcut
		var new_lap := maxi(1, floori(r.race_dist / L) + 1)
		if new_lap > r.lap:
			r.lap = new_lap
			var lap_time := time - float(_lap_start[r.idx])
			_lap_start[r.idx] = time
			if _led[r.idx]:
				r.stats.lead_laps += 1
			_led[r.idx] = r.place == 1
			if r.is_human:
				_on_human_lap(r, lap_time)
			if new_lap > td.laps:
				_finish(r)
			elif r.is_human:
				var h := hud_for(r)
				if h:
					if new_lap == td.laps:
						h.big("FINAL LAP", "Lap %s" % UiKit.time_str(lap_time), 1.6, UiKit.GOLD)
					else:
						h.big("LAP %d" % new_lap, "Lap %s" % UiKit.time_str(lap_time), 1.2, UiKit.CYAN)


func _on_human_lap(r: Racer, lap_time: float) -> void:
	if r.lap <= 1:
		return
	r.stats["best_lap"] = minf(float(r.stats.get("best_lap", INF)), lap_time)


func _finish(r: Racer) -> void:
	r.finished = true
	r.finish_time = time
	finish_order.append(r)
	if r.controller is PlayerDriver or autopilot and r == racers[0]:
		var ai := AIDriver.new(r.pilot.style, 0.8, r.idx)
		ai.cruise = true
		r.controller = ai
	if r.is_human:
		var h := hud_for(r)
		if h:
			var place := 0
			for o in racers:
				if o == r:
					place = o.place
			h.big("FINISHED!", UiKit.ordinal(place) + " place  " + UiKit.time_str(time), 3.0, UiKit.GOLD if place == 1 else Color.WHITE)
		Audio.play("finish")
	var all_humans_done := true
	for h in humans:
		if not h.finished:
			all_humans_done = false
	var everyone := true
	for o in racers:
		if not o.finished and not o.is_ghost:
			everyone = false
	if autopilot and req.get("fast", false):
		if everyone:
			_all_done_t = 0.01
	elif (all_humans_done and _all_done_t < 0.0) or everyone:
		_all_done_t = 2.5


func _finish_race() -> void:
	if done:
		return
	done = true
	racing = false
	# Estimate times for anyone still racing.
	var L := td.main.length * td.laps
	var est: Array = []
	for r in racers:
		if r.is_ghost:
			continue
		var t := r.finish_time
		if not r.finished:
			var left := maxf(L - r.race_dist, 0.0)
			t = time + left / maxf(r.max_speed * 0.8, 20.0)
		est.append({"r": r, "t": t, "fin": r.finished})
	est.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.t < b.t)
	results.clear()
	for k in est.size():
		var r: Racer = est[k].r
		results.append({"idx": r.idx, "name": r.display_name, "pilot": r.pilot.id, "saucer": r.saucer.id,
			"human": r.is_human, "slot": r.slot, "time": est[k].t, "place": k + 1, "stats": r.stats.duplicate()})
	_save_ghost()
	emit_signal("race_finished", results)
	if autopilot and req.get("fast", false):
		return
	Game.on_race_finished(self, results)


# ---------------------------------------------------------------- events
func _on_racer_event(kind: String, d: Dictionary, r: Racer) -> void:
	var cam := cam_for(r)
	match kind:
		"hit":
			if cam:
				cam.add_shake(0.8)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.9, 0.35)
			Audio.play_at("hit", r.global_position)
		"wall":
			if cam and d.impact > 10.0:
				cam.add_shake(0.35)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.4, 0.12)
		"bump":
			if cam:
				cam.add_shake(0.3)
			if r.is_human:
				InputRouter.rumble(r.slot, 0.5, 0.1)
			Audio.play_at("bump", r.global_position)
		"land":
			if r.is_human and d.impact > 8.0:
				InputRouter.rumble(r.slot, 0.35, 0.08)
				if cam:
					cam.add_shake(0.2)
		"boost":
			if r.is_human:
				Audio.play("boost")
		"pod":
			if r.is_human:
				Audio.play("pod")
		"item_roll":
			if r.is_human:
				Audio.play("crate")
		"item_used":
			Audio.play_at("item_" + str(d.item), r.global_position)
		"trick":
			if r.is_human:
				Audio.play("trick")
		"emergency":
			if r.is_human:
				Audio.play("alarm")
				InputRouter.rumble(r.slot, 0.6, 0.4)
		"drift_tier":
			if r.is_human and d.tier > 0:
				Audio.play("tier", -4.0, 1.0 + 0.15 * d.tier)
		"near_miss", "slipstream":
			if r.is_human:
				Audio.play("whoosh")
	if r.is_human:
		Events.on_racer_event(kind, d)


func on_shard(r: Racer, slot: int) -> bool:
	var new_one := Save.take_shard(td.id, slot)
	if new_one:
		Save.add_stardust(50)
	Audio.play("shard")
	return new_one


func shake_all(amount: float) -> void:
	for c in cams:
		c.add_shake(amount)


func shake_near(pos: Vector3, amount: float) -> void:
	for c in cams:
		if c.target and c.target.global_position.distance_to(pos) < 40.0:
			c.add_shake(amount)


# ---------------------------------------------------------------- ghost (time trial)
func ghost_key() -> String:
	return "%s_%d" % [td.id, td.variant]


func _setup_ghost() -> void:
	_ghost_play = Save.load_ghost(ghost_key())
	if _ghost_play.is_empty():
		return
	ghost_racer = Racer.new()
	ghost_racer.name = "Ghost"
	ghost_racer.is_ghost = true
	$Racers.add_child(ghost_racer)
	var look: Dictionary = Save.player_look()
	ghost_racer.setup(self, racers.size(), look, {})
	ghost_racer.collision_layer = 0
	ghost_racer.collision_mask = 0
	ghost_racer.display_name = "Ghost"
	_ghostify(ghost_racer.model)
	racers.append(ghost_racer)
	ghost_racer.place_at(td.grid_transform(0))


func _ghostify(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.7, 0.9, 1.0, 0.25)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			c.material_override = m
		elif c is CPUParticles3D:
			c.visible = false
		_ghostify(c)


func _ghost_tick(dt: float) -> void:
	if req.mode != "tt" or not racing:
		return
	_ghost_t += dt
	var me: Racer = humans[0] if not humans.is_empty() else null
	var frame := int(_ghost_t * GHOST_HZ)
	if me and not me.finished and _ghost_rec.size() / GHOST_STRIDE <= frame:
		var p := me.global_position
		var q := me.global_basis.get_rotation_quaternion()
		_ghost_rec.append_array([_ghost_t, p.x, p.y, p.z, q.x, q.y, q.z, q.w])
	if ghost_racer and not _ghost_play.is_empty():
		var n := _ghost_play.size() / GHOST_STRIDE
		var f := _ghost_t * GHOST_HZ
		var i := mini(int(f), n - 2)
		if i < 0 or n < 2:
			return
		var t := clampf(f - float(i), 0.0, 1.0)
		var a := i * GHOST_STRIDE
		var b := (i + 1) * GHOST_STRIDE
		var pa := Vector3(_ghost_play[a + 1], _ghost_play[a + 2], _ghost_play[a + 3])
		var pb := Vector3(_ghost_play[b + 1], _ghost_play[b + 2], _ghost_play[b + 3])
		var qa := Quaternion(_ghost_play[a + 4], _ghost_play[a + 5], _ghost_play[a + 6], _ghost_play[a + 7])
		var qb := Quaternion(_ghost_play[b + 4], _ghost_play[b + 5], _ghost_play[b + 6], _ghost_play[b + 7])
		ghost_racer.global_transform = Transform3D(Basis(qa.slerp(qb, t)), pa.lerp(pb, t))
		ghost_racer.track_idx = td.main.nearest(ghost_racer.global_position, ghost_racer.track_idx, 30)


func _save_ghost() -> void:
	if req.mode != "tt" or humans.is_empty():
		return
	var me := humans[0]
	if not me.finished:
		return
	var best: float = Save.data.best_time.get(ghost_key(), INF)
	if me.finish_time <= best + 0.001:
		Save.save_ghost(ghost_key(), _ghost_rec)


# ---------------------------------------------------------------- pause
func _unhandled_input(e: InputEvent) -> void:
	if done:
		return
	var pause := false
	if e is InputEventKey and e.pressed and not e.echo:
		pause = e.physical_keycode == KEY_ESCAPE or e.physical_keycode == KEY_P
	elif e is InputEventJoypadButton and e.pressed:
		pause = e.button_index == JOY_BUTTON_START
	if pause:
		toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not done and not get_tree().paused:
		toggle_pause()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and racing and not done and not get_tree().paused and OS.has_feature("mobile"):
		toggle_pause()


func toggle_pause() -> void:
	if done:
		return
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		if _pause_panel:
			_pause_panel.queue_free()
			_pause_panel = null
		return
	tree.paused = true
	_pause_panel = Game.pause_menu(self)
	ui_layer.add_child(_pause_panel)


func show_panel(p: Control) -> void:
	if _results_panel:
		_results_panel.queue_free()
	_results_panel = p
	ui_layer.add_child(p)
	if touch:
		touch.visible = false
