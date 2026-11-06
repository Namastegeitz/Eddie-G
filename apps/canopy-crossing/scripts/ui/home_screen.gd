extends Control
## Home: the equipped animal, the three ways to play, currencies, and soft
## nudges (daily reward, daily challenge, animal of the week, pass progress).

var _nudge_shown := false


func _ready() -> void:
	Sfx.menu_music()
	var bg := HomeBackdrop.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := UI.vbox(16)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(UI.margin(root, 28, int(UI.safe_top(self)) + 20, 28, 28))
	# after add_child: set offsets too, or the box keeps its minimum size and
	# sits left of centre on tall phone screens
	root.get_parent().set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(TopBar.make(self, false))
	var title := UI.label("Canopy Crossing", 68, UI.ACCENT, true, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_outline_color", Color("0a2012"))
	root.add_child(title)
	var a := Content.animal(String(Save.data.equipped_animal))
	var hero := Widgets.Portrait.new(a, Vector2(320, 320))
	var skin := String(Save.data.equipped_skin.get(String(a.id), ""))
	for s in a.get("skins", []):
		if s.id == skin:
			hero.look = AnimalPainter.with_skin(a.look, s)
	hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(hero)
	var who := UI.label("%s · %s" % [String(a.name), String(a.ability.name)], 28, UI.TEXT, true, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(who)
	root.add_child(UI.spacer())
	var sel := String(Save.data.get("selected_map", "amazon"))
	var journey := UI.button("Journey: %s" % String(Content.map(sel).get("name", "")), func(): Game.goto("world"), UI.ACCENT, 38, 120)
	root.add_child(journey)
	var row := UI.hbox(14)
	var endless := UI.button("Endless", func(): Game.goto("world", {"mode": "endless"}), UI.PANEL_3, 32, 104)
	endless.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(endless)
	var dc := Progress.daily_challenge()
	var daily := UI.button("Daily: %s" % String(Content.map(String(dc.get("map", ""))).get("name", "")), func(): Game.start_daily(), Color("2a6a8a"), 28, 104)
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(daily)
	root.add_child(row)
	var row2 := UI.hbox(14)
	for item in [["Animals", "animals", Color("6a4a8a")], ["Store", "store", Color("8a5a2a")], ["Pass", "pass", Color("2a5a8a")], ["Settings", "settings", UI.PANEL_2]]:
		var target: String = item[1]
		var b := UI.button(String(item[0]), func(): Game.goto(target), item[2], 26, 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if target == "pass" and Progress.claimable_count() > 0:
			b.text = "Pass (%d)" % Progress.claimable_count()
		row2.add_child(b)
	root.add_child(row2)
	var info := UI.label(_status_line(), 22, UI.MUTED, false, HORIZONTAL_ALIGNMENT_CENTER)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)
	call_deferred("_nudges")


func _status_line() -> String:
	var parts := []
	if Store.is_weekend():
		parts.append(String(Content.live_ops.get("weekend", {}).get("label", "Weekend: 2x Berries")))
	if int(Save.data.berry_doubler_until) > int(Time.get_unix_time_from_system()):
		parts.append("Berry Doubler active")
	var aow := Store.animal_of_week()
	if aow != "":
		parts.append("Animal of the week: %s" % String(Content.animal(aow).name))
	var s := Progress.current_season()
	if not s.is_empty():
		parts.append("%s · tier %d/30 · %d days left" % [String(s.name), Progress.pass_tier(), Progress.season_days_left()])
	return "  ·  ".join(parts)


func _nudges() -> void:
	if Game.has_modal() or _nudge_shown:
		return
	_nudge_shown = true
	if Progress.daily_reward_ready() and bool(Save.data.get("tutorial_done", false)):
		var entry := Progress.daily_reward()
		var nd: Dictionary = Content.onboarding.get("nudges", {}).get("daily_reward", {})
		var card := PromptCard.make(String(nd.get("title", "Daily reward")),
			String(nd.get("text", "")).format({"day": int(entry.get("day", 1))}) + "\n\n" + _reward_text(entry.get("reward", {})),
			[{"id": "claim", "text": "Claim", "color": UI.ACCENT}, {"id": "later", "text": "Later"}], Widgets.CurrencyIcon.new("berries", 90))
		card.closed.connect(func(c):
			if c == "claim":
				Progress.claim_daily_reward()
				Sfx.play("unlock")
				Game.goto("home", {}, false))
		Game.modal(card)
		return
	# First unlock guide: right after the tutorial, point at the animals.
	if bool(Save.data.get("tutorial_done", false)) and Save.data.owned_animals.size() <= Content.starters().size() \
			and Economy.berries() >= 250 and not Save.flag("guide_first_unlock"):
		Save.set_flag("guide_first_unlock")
		var card2 := PromptCard.make("Unlock a new animal", "You have %d Berries — enough for a Common animal. Each one crosses differently." % Economy.berries(),
			[{"id": "go", "text": "Choose an animal", "color": UI.ACCENT}, {"id": "later", "text": "Later"}], Widgets.CurrencyIcon.new("berries", 90))
		card2.closed.connect(func(c):
			if c == "go":
				Game.goto("animals", {"filter_affordable": true}))
		Game.modal(card2)


static func _reward_text(r: Dictionary) -> String:
	if r.has("berries"):
		return "+%d Berries" % int(r.berries)
	if r.has("amber"):
		return "+%d Amber" % int(r.amber)
	if r.has("item"):
		return "+%d %s" % [int(r.get("count", 1)), String(Content.consumable(String(r.item)).get("name", r.item))]
	if r.has("animal"):
		return "New animal: %s" % String(Content.animal(String(r.animal)).get("name", ""))
	if r.has("cosmetic"):
		return String(Content.cosmetic(String(r.cosmetic)).get("name", ""))
	return ""


class HomeBackdrop extends Control:
	var t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _draw() -> void:
		var s := size
		draw_rect(Rect2(Vector2.ZERO, s), Color("0e3a22"))
		for i in 6:
			var y := s.y * (0.55 + i * 0.09)
			var col := Color("1a5a32").lerp(Color("2a7a3a"), i / 6.0)
			draw_rect(Rect2(0, y, s.x, s.y * 0.09 + 1), col if i % 2 == 0 else col.darkened(0.08))
		var water := Rect2(0, s.y * 0.73, s.x, s.y * 0.09)
		draw_rect(water, Color("3a6a8a"))
		for i in 8:
			var x := fposmod(i * 140.0 + t * 30.0, s.x + 200) - 100
			Draw.rrect(self, Rect2(x, water.position.y + 12, 120, water.size.y - 24), 20, Color("7a5232"))
		for side in [0.0, 1.0]:
			for i in 9:
				var base := Vector2(side * s.x, i * s.y / 8.0)
				for j in 3:
					var d := Vector2((1.0 - side * 2.0) * (0.6 + j * 0.2), sin(t * 0.8 + i + j) * 0.2 - 0.3)
					Draw.leaf(self, base, d, 140 + j * 30, 46, Color("164a28").lerp(Color("2a7a3a"), j / 3.0))
		for k in int(s.x / 80.0) + 2:
			Draw.leaf(self, Vector2(k * 80.0, 0), Vector2(sin(k * 1.7) * 0.4, 1), 90 + 30 * sin(k * 2.3), 30, Color("123e22"))
