extends Control
## Animal select: a swipeable carousel over every animal file, filterable by
## region, rarity and ownership. Each card shows the animal, its region
## flag, rarity gem, signature ability, conservation status and a fact, and
## its state: Equipped / Equip / price to unlock / which pack has it.

var args: Dictionary = {}
var list: Array[String] = []
var index := 0
var region_filter := ""
var rarity_filter := ""
var owned_only := false
var card_box: VBoxContainer
var strip: HBoxContainer
var strip_scroll: ScrollContainer
var portrait: Widgets.Portrait
var counter: Label
var _drag_from := Vector2.INF
var _card_area: Control


func setup(a: Dictionary) -> void:
	args = a


func _ready() -> void:
	var root := UI.vbox(12)
	var m := UI.margin(root, 24, int(UI.safe_top(self)) + 16, 24, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root.add_child(TopBar.make(self, true, "Animals"))
	# filters
	var fscroll := ScrollContainer.new()
	fscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	fscroll.custom_minimum_size.y = 70
	var frow := UI.hbox(8)
	fscroll.add_child(frow)
	root.add_child(fscroll)
	frow.add_child(_chip("All", func(): _set_region("")))
	var regions := []
	for id in Content.animal_order:
		var r := String(Content.animals[id].region)
		if not r in regions:
			regions.append(r)
	for r in regions:
		frow.add_child(_chip(String(Content.map(r).get("name", r)).replace(" Basin", "").replace(" Highlands", ""), func(): _set_region(r), UI.region_color(r)))
	var rrow := UI.hbox(8)
	for r2 in ["", "common", "rare", "epic", "legendary"]:
		var lbl := "Any" if r2 == "" else String(Content.rarities[r2].name)
		var c := UI.PANEL_2 if r2 == "" else UI.rarity_color(r2).darkened(0.35)
		var b := _chip(lbl, func(): _set_rarity(r2), c)
		rrow.add_child(b)
	var own := _chip("Owned", func(): pass, UI.PANEL_2)
	own.toggle_mode = true
	own.toggled.connect(func(on):
		owned_only = on
		_rebuild(true))
	rrow.add_child(own)
	var rscroll := ScrollContainer.new()
	rscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rscroll.custom_minimum_size.y = 70
	rscroll.add_child(rrow)
	root.add_child(rscroll)
	# card
	_card_area = Control.new()
	_card_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_area.gui_input.connect(_card_input)
	root.add_child(_card_area)
	var panel := UI.panel(UI.PANEL, 32, 22)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_card_area.add_child(panel)
	var cscroll := ScrollContainer.new()
	cscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cscroll.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(cscroll)
	card_box = UI.vbox(10)
	card_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cscroll.add_child(card_box)
	# nav
	var nav := UI.hbox(10)
	var prev := UI.button("‹", func(): _go(-1), UI.PANEL_2, 44, 80)
	prev.custom_minimum_size.x = 110
	nav.add_child(prev)
	counter = UI.label("", 28, UI.MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(counter)
	var next := UI.button("›", func(): _go(1), UI.PANEL_2, 44, 80)
	next.custom_minimum_size.x = 110
	nav.add_child(next)
	root.add_child(nav)
	strip_scroll = ScrollContainer.new()
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_scroll.custom_minimum_size.y = 120
	strip = UI.hbox(6)
	strip_scroll.add_child(strip)
	root.add_child(strip_scroll)
	_rebuild(false)
	var start := String(Save.data.equipped_animal)
	if args.get("filter_affordable", false):
		for id in list:
			var o := Economy.animal_offer(id)
			if o.get("kind", "") == "berries" and Economy.can_afford(o.price):
				start = id
				break
	if args.has("animal"):
		start = String(args.animal)
	index = maxi(0, list.find(start))
	_show()
	Economy.unlocked.connect(_on_unlocked)
	tree_exiting.connect(func(): Economy.unlocked.disconnect(_on_unlocked))


func _on_unlocked(_k: String, _id: String) -> void:
	_rebuild(false)
	_show()


func _chip(text: String, cb: Callable, c := UI.PANEL_2) -> Button:
	var b := UI.button(text, cb, c, 24, 60)
	b.custom_minimum_size.x = 96
	return b


func _set_region(r: String) -> void:
	region_filter = r
	_rebuild(true)


func _set_rarity(r: String) -> void:
	rarity_filter = r
	_rebuild(true)


func _rebuild(reset: bool) -> void:
	var cur := list[index] if index < list.size() else ""
	list.clear()
	for id in Content.animal_order:
		var a: Dictionary = Content.animals[id]
		if region_filter != "" and String(a.region) != region_filter:
			continue
		if rarity_filter != "" and String(a.rarity) != rarity_filter:
			continue
		if owned_only and not Save.owns_animal(id):
			continue
		list.append(id)
	index = 0 if reset else maxi(0, list.find(cur))
	for ch in strip.get_children():
		ch.queue_free()
	for i in list.size():
		var id2: String = list[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(100, 108)
		b.add_theme_stylebox_override("normal", UI.box(UI.PANEL_2, 18, 0, Color.TRANSPARENT, 4))
		b.add_theme_stylebox_override("hover", UI.box(UI.PANEL_3, 18, 0, Color.TRANSPARENT, 4))
		b.add_theme_stylebox_override("pressed", UI.box(UI.PANEL_3, 18, 0, Color.TRANSPARENT, 4))
		var p := Widgets.Portrait.new(Content.animal(id2), Vector2(96, 96))
		p.animate = false
		p.silhouette = not Save.owns_animal(id2)
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(p)
		var idx := i
		b.pressed.connect(func():
			index = idx
			_show())
		b.name = "T%d" % i
		strip.add_child(b)
	_show()


func _go(d: int) -> void:
	if list.is_empty():
		return
	index = wrapi(index + d, 0, list.size())
	Sfx.play("swipe")
	_show()


func _card_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			_drag_from = event.position
		elif _drag_from != Vector2.INF:
			var dx: float = event.position.x - _drag_from.x
			_drag_from = Vector2.INF
			if absf(dx) > 70.0:
				_go(-1 if dx > 0 else 1)


func _show() -> void:
	for ch in card_box.get_children():
		ch.queue_free()
	if list.is_empty():
		card_box.add_child(UI.label("No animals match.", 30, UI.MUTED, true, HORIZONTAL_ALIGNMENT_CENTER))
		counter.text = ""
		return
	index = clampi(index, 0, list.size() - 1)
	var id: String = list[index]
	var a := Content.animal(id)
	var owned := Save.owns_animal(id)
	counter.text = "%d / %d   (#%d of 50)" % [index + 1, list.size(), int(a.number)]
	for i in strip.get_child_count():
		var t: Button = strip.get_child(i)
		t.add_theme_stylebox_override("normal", UI.box(UI.ACCENT if i == index else UI.PANEL_2, 18, 0, Color.TRANSPARENT, 4))
	if strip.get_child_count() > index:
		strip_scroll.call_deferred("ensure_control_visible", strip.get_child(index))
	# header
	var head := UI.hbox(10)
	head.add_child(Widgets.Flag.new(String(a.region), Vector2(56, 40)))
	var nm := UI.label(String(a.name), 40, UI.TEXT, true)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(nm)
	head.add_child(Widgets.Gem.new(String(a.rarity), 40))
	head.add_child(UI.label(String(Content.rarities[a.rarity].name), 24, UI.rarity_color(String(a.rarity)), true))
	card_box.add_child(head)
	card_box.add_child(UI.label("%s · %s" % [String(a.home), String(Content.map(String(a.region)).get("location", ""))], 24, UI.MUTED))
	portrait = Widgets.Portrait.new(a, Vector2(340, 300))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var skin := String(Save.data.equipped_skin.get(id, ""))
	for s in a.get("skins", []):
		if s.id == skin:
			portrait.look = AnimalPainter.with_skin(a.look, s)
	portrait.silhouette = false
	if not owned:
		portrait.modulate = Color(1, 1, 1, 0.92)
	card_box.add_child(portrait)
	var ab := UI.panel(UI.PANEL_2, 22, 18)
	var abv := UI.vbox(4)
	ab.add_child(abv)
	abv.add_child(UI.label("Ability: " + String(a.ability.name), 30, UI.ACCENT, true))
	abv.add_child(UI.wrap_label(String(a.ability.summary), 26, UI.TEXT))
	var st: Dictionary = a.get("stats", {})
	var speed := "quick" if float(st.get("hop_time", 0.14)) <= 0.13 else ("slow" if float(st.get("hop_time", 0.14)) >= 0.18 else "steady")
	abv.add_child(UI.label("Hop: %s · %s" % [speed, "has a button" if _has_button(a) else "always on"], 22, UI.MUTED))
	card_box.add_child(ab)
	card_box.add_child(UI.wrap_label(String(a.get("fact", "")), 25, UI.TEXT))
	var cons := UI.hbox(8)
	cons.add_child(UI.label(String(Content.onboarding.get("facts_ui", {}).get("conservation_label", "Status")) + ":", 24, UI.MUTED))
	cons.add_child(UI.label(String(a.get("conservation", "")), 24, _status_color(String(a.get("conservation", ""))), true))
	card_box.add_child(cons)
	if owned and not a.get("skins", []).is_empty():
		_skin_row(a)
	card_box.add_child(_action(a))


func _has_button(a: Dictionary) -> bool:
	for m in a.ability.modules:
		if Ability.exists(String(m.module)) and Ability.create(String(m.module), m, null).has_button():
			return true
	return false


func _status_color(s: String) -> Color:
	if s.begins_with("Critically"):
		return Color("ff6a5a")
	if s.begins_with("Endangered"):
		return Color("ff9a5a")
	if s.begins_with("Vulnerable"):
		return Color("ffd25a")
	if s.begins_with("Near"):
		return Color("d8e86a")
	return Color("9ae06a")


func _skin_row(a: Dictionary) -> void:
	var row := UI.hbox(8)
	row.add_child(UI.label("Look:", 24, UI.MUTED))
	var cur := String(Save.data.equipped_skin.get(String(a.id), ""))
	var def := UI.button("Default", func():
		Save.data.equipped_skin.erase(String(a.id))
		Save.mark()
		_show(), UI.ACCENT if cur == "" else UI.PANEL_2, 22, 56)
	row.add_child(def)
	for s in a.skins:
		var cid := ""
		for c in Content.catalog.get("cosmetics", []):
			if c.get("type") == "skin" and c.get("animal") == a.id and c.get("skin") == s.id:
				cid = String(c.id)
		var owned: bool = cid in Save.data.owned_cosmetics
		var sid := String(s.id)
		var b := UI.button(String(s.name) if owned else "%s · %d Amber" % [String(s.name), int(Content.cosmetic(cid).get("price", {}).get("amber", 0))],
			func():
				if owned:
					Save.data.equipped_skin[String(a.id)] = sid
					Save.mark()
					_show()
				else:
					Game.goto("store", {"section": "cosmetics", "focus": cid}),
			UI.ACCENT if cur == sid else UI.PANEL_2, 22, 56)
		row.add_child(b)
	var sc := ScrollContainer.new()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.y = 64
	sc.add_child(row)
	card_box.add_child(sc)


func _action(a: Dictionary) -> Control:
	var id := String(a.id)
	var box := UI.vbox(8)
	var offer := Economy.animal_offer(id)
	var disc := float(offer.get("discount", 0.0))
	if disc > 0.0:
		box.add_child(UI.label("%d%% off today%s" % [int(disc * 100), " — Animal of the week!" if Store.animal_of_week() == id else ""], 26, Color("9cf06a"), true, HORIZONTAL_ALIGNMENT_CENTER))
	match String(offer.get("kind", "")):
		"owned":
			var eq := String(Save.data.equipped_animal) == id
			var b := UI.button("Equipped" if eq else "Equip", func():
				Save.data.equipped_animal = id
				Save.mark()
				Sfx.play("equip")
				_show(), UI.PANEL_3 if eq else UI.ACCENT, 32, 96)
			b.disabled = eq
			box.add_child(b)
			if eq:
				box.add_child(UI.button("Play with %s" % String(a.name), func(): Game.goto("world"), UI.PANEL_3, 28, 84))
		"berries", "amber":
			var price: Dictionary = offer.price
			var cur := "berries" if offer.kind == "berries" else "amber"
			var can := Economy.can_afford(price)
			var b2 := UI.button("Unlock · %d %s" % [int(price[cur]), "Berries" if cur == "berries" else "Amber"], func(): _unlock(id), UI.ACCENT if can else UI.LOCK, 32, 96)
			box.add_child(b2)
			if not can:
				var short := int(price[cur]) - (Economy.berries() if cur == "berries" else Economy.amber())
				box.add_child(UI.label("%d more %s needed — earn them in runs%s" % [short, "Berries" if cur == "berries" else "Amber", "" if cur == "berries" else " or the store"], 22, UI.MUTED, false, HORIZONTAL_ALIGNMENT_CENTER))
				if cur == "amber":
					box.add_child(UI.button("Get Amber", func(): Game.goto("store", {"section": "amber"}), UI.PANEL_3, 26, 76))
		"pack":
			var prod := Content.product(String(offer.get("product", "")))
			var price2: Dictionary = offer.price
			box.add_child(UI.label("Comes with the %s" % String(prod.get("title", "pack")), 24, UI.MUTED, false, HORIZONTAL_ALIGNMENT_CENTER))
			box.add_child(UI.button("Get the pack · %s" % Store.price_label(prod), func(): Game.goto("store", {"focus": String(prod.get("id", ""))}), UI.ACCENT, 30, 92))
			var can2 := Economy.can_afford(price2)
			box.add_child(UI.button("Or unlock alone · %d Amber" % int(price2.amber), func(): _unlock(id), UI.AMBER if can2 else UI.LOCK, 26, 80))
	return box


func _unlock(id: String) -> void:
	var a := Content.animal(id)
	var offer := Economy.animal_offer(id)
	if not Economy.can_afford(offer.get("price", {})):
		var cur := "amber" if offer.get("price", {}).has("amber") else "berries"
		var card := PromptCard.make("%s is locked" % String(a.name), "Not enough %s yet." % ("Amber" if cur == "amber" else "Berries"),
			[{"id": "store", "text": "Visit the store", "color": UI.ACCENT}, {"id": "ok", "text": "OK"}])
		card.closed.connect(func(c):
			if c == "store":
				Game.goto("store", {"section": "amber" if cur == "amber" else "featured"}))
		Game.modal(card)
		return
	if Economy.unlock_animal(id):
		Sfx.play("unlock")
		Save.data.equipped_animal = id
		Save.mark()
		var card2 := PromptCard.make("New animal!", "%s joins your crew and is equipped.\n%s: %s" % [String(a.name), String(a.ability.name), String(a.ability.summary)],
			[{"id": "play", "text": "Play now", "color": UI.ACCENT}, {"id": "ok", "text": "Nice!"}], Widgets.Portrait.new(a, Vector2(220, 220)))
		card2.closed.connect(func(c):
			if c == "play":
				Game.goto("world"))
		Game.modal(card2)
