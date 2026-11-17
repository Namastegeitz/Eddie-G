extends Control
## The store, built from content/store/catalog.json and live_ops.json:
## featured deals, animal packs, map packs, Amber, power-ups, cosmetics and
## the Expedition Pass. Real-money products go through the billing backend
## (sandbox sheet in this build); Berries/Amber items are bought directly.

const SECTIONS := [["featured", "Featured"], ["animals", "Animals"], ["maps", "Maps"], ["amber", "Amber"], ["items", "Power-ups"], ["cosmetics", "Looks"]]

var args: Dictionary = {}
var section := "featured"
var content: VBoxContainer
var tabs := {}
var scroll: ScrollContainer
var focus := ""


func setup(a: Dictionary) -> void:
	args = a
	section = String(a.get("section", "featured"))
	focus = String(a.get("focus", ""))
	if focus != "":
		var p := Content.product(focus)
		if not p.is_empty():
			section = String(p.get("section", "featured"))
			if section == "pass":
				section = "featured"
		elif not Content.cosmetic(focus).is_empty():
			section = "cosmetics"


func _ready() -> void:
	var root := UI.vbox(12)
	var m := UI.margin(root, 24, int(UI.safe_top(self)) + 16, 24, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root.add_child(TopBar.make(self, true, "Store"))
	var ts := ScrollContainer.new()
	ts.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ts.custom_minimum_size.y = 72
	var trow := UI.hbox(8)
	ts.add_child(trow)
	root.add_child(ts)
	for s in SECTIONS:
		var key: String = s[0]
		var b := UI.button(String(s[1]), func(): _show(key), UI.PANEL_2, 24, 64)
		b.custom_minimum_size.x = 120
		trow.add_child(b)
		tabs[key] = b
	if Store.is_sandbox():
		root.add_child(UI.label("Sandbox build: purchases are simulated, no money is charged.", 20, Color("9ad8ff"), false, HORIZONTAL_ALIGNMENT_CENTER))
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	content = UI.vbox(14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	var restore := UI.button("Restore purchases", func(): Store.restore(), UI.PANEL_2, 24, 64)
	root.add_child(restore)
	Store.purchase_finished.connect(_on_purchase)
	tree_exiting.connect(func(): Store.purchase_finished.disconnect(_on_purchase))
	Analytics.event("store_view", {"section": section})
	_show(section)


func _on_purchase(id: String, ok: bool, msg: String) -> void:
	if id == "restore":
		Game.modal(PromptCard.make("Restore purchases", msg, [{"id": "ok", "text": "OK"}]))
	elif ok:
		var p := Content.product(id)
		Sfx.play("purchase")
		Game.modal(PromptCard.make("Thank you!", "%s is yours." % String(p.get("title", id)), [{"id": "ok", "text": "Great", "color": UI.ACCENT}], Widgets.CurrencyIcon.new("amber", 90)))
	elif msg != "" and msg != "Purchase cancelled.":
		Game.modal(PromptCard.make("Purchase didn't go through", msg, [{"id": "ok", "text": "OK"}]))
	_show(section)


func _show(s: String) -> void:
	section = s
	for k in tabs:
		UI.paint(tabs[k], UI.ACCENT if k == s else UI.PANEL_2)
	for ch in content.get_children():
		ch.queue_free()
	match s:
		"featured":
			_featured()
		"animals":
			for p in Store.products("animals"):
				content.add_child(_product_card(p))
		"maps":
			for p in Store.products("maps"):
				content.add_child(_product_card(p))
		"amber":
			for p in Store.products("amber"):
				content.add_child(_product_card(p))
			content.add_child(UI.label("Swap Amber for Berries", 30, UI.ACCENT, true))
			var ex: Array = Content.catalog.get("exchange", [])
			for i in ex.size():
				var e: Dictionary = ex[i]
				var b := UI.button("%d Amber for %d Berries" % [int(e.amber), int(e.berries)], func():
					if Economy.exchange(i):
						Sfx.play("purchase")
						_show(section), UI.PANEL_3, 26, 80)
				b.disabled = Economy.amber() < int(e.amber)
				content.add_child(b)
		"items":
			for c in Content.catalog.get("consumables", []):
				content.add_child(_consumable_card(c))
		"cosmetics":
			for c in Content.catalog.get("cosmetics", []):
				content.add_child(_cosmetic_card(c))
	if focus != "":
		call_deferred("_scroll_to_focus")


func _scroll_to_focus() -> void:
	for ch in content.get_children():
		if ch.has_meta("pid") and String(ch.get_meta("pid")) == focus:
			scroll.ensure_control_visible(ch)
			var tw := create_tween()
			tw.tween_property(ch, "modulate", Color(1.4, 1.4, 1.1), 0.25)
			tw.tween_property(ch, "modulate", Color.WHITE, 0.4)
	focus = ""


func _featured() -> void:
	content.add_child(UI.label("Daily deals", 32, UI.ACCENT, true))
	for d in Store.daily_deals():
		content.add_child(_deal_card(d))
	var aow := Store.animal_of_week()
	if aow != "":
		var a := Content.animal(aow)
		var card := _card()
		var h := UI.hbox(12)
		h.add_child(Widgets.Portrait.new(a, Vector2(120, 120)))
		var v := UI.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.label("Animal of the week", 22, Color("9cf06a"), true))
		v.add_child(UI.label(String(a.name), 30, UI.TEXT, true))
		v.add_child(UI.label("%d%% off this week" % int(Store.animal_discount(aow) * 100), 22, UI.MUTED))
		h.add_child(v)
		h.add_child(UI.button("View", func(): Game.goto("animals", {"animal": aow}), UI.ACCENT, 26, 72))
		card.add_child(h)
		content.add_child(card)
	content.add_child(UI.label("Bundles", 32, UI.ACCENT, true))
	for p in Store.products("featured"):
		content.add_child(_product_card(p))
	for p in Store.products("pass"):
		content.add_child(_product_card(p))


func _card() -> PanelContainer:
	return UI.panel(UI.PANEL_2, 24, 18)


func _product_card(p: Dictionary) -> Control:
	var card := _card()
	card.set_meta("pid", String(p.id))
	var v := UI.vbox(8)
	card.add_child(v)
	var h := UI.hbox(12)
	if p.has("map"):
		h.add_child(Widgets.Flag.new(String(p.map), Vector2(56, 40)))
	elif String(p.get("section", "")) == "amber":
		h.add_child(Widgets.CurrencyIcon.new("amber", 56))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UI.label(String(p.title), 30, UI.TEXT, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(title)
	tv.add_child(UI.wrap_label(String(p.get("desc", "")), 22, UI.MUTED))
	if p.has("map") and Save.owns_map(String(p.map)) and not Store.owns_product(String(p.id)):
		tv.add_child(UI.label("Jungle already open: this pack adds its animals", 22, Color("9cf06a"), true))
	elif p.has("map") and not Save.owns_map(String(p.map)) and bool(Content.rules.get("open_next_jungle", true)):
		tv.add_child(UI.label("Or open it free by clearing the jungle before it", 22, Color("9fd8ff")))
	h.add_child(tv)
	if String(p.get("badge", "")) != "":
		var badge := UI.panel(UI.DANGER, 12, 8)
		badge.add_child(UI.label(String(p.badge), 20, Color.WHITE, true))
		h.add_child(badge)
	v.add_child(h)
	var animals: Array[String] = []
	for g in p.get("grants", []):
		if g.type == "animals":
			animals.append_array(Content.animals_where(g.get("where", {})))
		elif g.type == "animal":
			animals.append(String(g.id))
	if not animals.is_empty() and animals.size() <= 14:
		var ar := UI.hbox(0)
		for aid in animals:
			var pp := Widgets.Portrait.new(Content.animal(aid), Vector2(72, 72))
			pp.animate = false
			pp.silhouette = not Save.owns_animal(aid)
			ar.add_child(pp)
		var sc := ScrollContainer.new()
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		sc.custom_minimum_size.y = 80
		sc.add_child(ar)
		v.add_child(sc)
	elif animals.size() > 14:
		v.add_child(UI.label("All %d animals" % animals.size(), 22, UI.MUTED))
	var owned := Store.owns_product(String(p.id)) or Store.product_redundant(String(p.id))
	var label := "Owned" if owned else Store.price_label(p)
	if not owned and p.has("value_usd"):
		label += "  (worth $%.2f)" % float(p.value_usd)
	var buy := UI.button(label, func(): Store.purchase(String(p.id)), UI.PANEL_3 if owned else UI.ACCENT, 28, 80)
	buy.disabled = owned and String(p.get("type", "")) != "consumable"
	v.add_child(buy)
	return card


func _consumable_card(c: Dictionary) -> Control:
	var card := _card()
	var v := UI.vbox(6)
	card.add_child(v)
	var h := UI.hbox(10)
	var icon: String = {"extra_life": "heart", "shield_totem": "shield"}.get(String(c.id), "berries")
	h.add_child(Widgets.CurrencyIcon.new(icon, 50))
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label("%s  (have %d)" % [String(c.name), Save.item_count(String(c.id))], 28, UI.TEXT, true))
	tv.add_child(UI.wrap_label(String(c.desc), 22, UI.MUTED))
	h.add_child(tv)
	v.add_child(h)
	var row := UI.hbox(10)
	var price := Store.consumable_price(String(c.id))
	for cur in ["berries", "amber"]:
		if not price.has(cur):
			continue
		var b := UI.button("%d %s" % [int(price[cur]), "Berries" if cur == "berries" else "Amber"], func():
			if Economy.buy_consumable(String(c.id), cur):
				Sfx.play("purchase")
				_show(section), UI.ACCENT if cur == "berries" else UI.AMBER, 24, 72)
		b.disabled = not Economy.can_afford({cur: int(price[cur])})
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(row)
	if String(c.id) == "berry_doubler" and int(Save.data.berry_doubler_until) > int(Time.get_unix_time_from_system()):
		var left := (int(Save.data.berry_doubler_until) - int(Time.get_unix_time_from_system())) / 3600
		v.add_child(UI.label("Active: %d h left" % left, 22, Color("9cf06a")))
	return card


func _cosmetic_card(c: Dictionary) -> Control:
	var card := _card()
	card.set_meta("pid", String(c.id))
	var h := UI.hbox(12)
	card.add_child(h)
	if c.type == "skin":
		var a := Content.animal(String(c.animal))
		var look: Dictionary = a.look
		for s in a.get("skins", []):
			if s.id == c.skin:
				look = AnimalPainter.with_skin(a.look, s)
		var p := Widgets.Portrait.new(a, Vector2(110, 110))
		p.look = look
		h.add_child(p)
	else:
		h.add_child(CosmeticIcon.new(c))
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(String(c.name), 28, UI.TEXT, true))
	tv.add_child(UI.label({"skin": "Animal skin", "trail": "Hop trail", "emote": "Idle emote", "flag": "Goal flag"}.get(String(c.type), ""), 22, UI.MUTED))
	h.add_child(tv)
	var owned: bool = String(c.id) in Save.data.owned_cosmetics
	if owned:
		var slot: String = {"trail": "equipped_trail", "emote": "equipped_emote", "flag": "equipped_flag"}.get(String(c.type), "")
		if slot != "":
			var on := String(Save.data.get(slot, "")) == String(c.id)
			h.add_child(UI.button("Equipped" if on else "Equip", func():
				Save.data[slot] = "" if on else String(c.id)
				Save.mark()
				_show(section), UI.PANEL_3 if on else UI.ACCENT, 24, 72))
		else:
			h.add_child(UI.label("Owned", 24, Color("9cf06a"), true))
	else:
		var price := Store.cosmetic_price(String(c.id))
		var b := UI.button("%d Amber" % int(price.get("amber", 0)), func():
			if Economy.buy_cosmetic(String(c.id)):
				Sfx.play("purchase")
				if c.type == "skin":
					Save.data.equipped_skin[String(c.animal)] = String(c.skin)
					Save.mark()
				_show(section)
			else:
				_show("amber"), UI.AMBER, 24, 72)
		h.add_child(b)
	return card


func _deal_card(d: Dictionary) -> Control:
	var card := _card()
	var h := UI.hbox(12)
	card.add_child(h)
	var disc := int(float(d.get("discount", 0.0)) * 100)
	var title := ""
	var act: Callable
	match String(d.kind):
		"consumable":
			var c := Content.consumable(String(d.id))
			var price := Store.consumable_price(String(d.id))
			var cur := String(d.get("currency", "berries"))
			title = "%s · %d %s" % [String(c.name), int(price.get(cur, 0)), "Berries" if cur == "berries" else "Amber"]
			act = func():
				if Economy.buy_consumable(String(d.id), cur):
					Sfx.play("purchase")
					_show(section)
		"animal":
			var a := Content.animal(String(d.id))
			h.add_child(Widgets.Portrait.new(a, Vector2(90, 90)))
			title = String(a.name)
			act = func(): Game.goto("animals", {"animal": String(d.id)})
		"cosmetic":
			var cc := Content.cosmetic(String(d.id))
			title = "%s %s · %d Amber" % [String(cc.name), {"trail": "trail", "emote": "emote", "flag": "flag", "skin": "skin"}.get(String(cc.type), ""), int(Store.cosmetic_price(String(d.id)).get("amber", 0))]
			act = func():
				if Economy.buy_cosmetic(String(d.id)):
					Sfx.play("purchase")
					_show(section)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.label(title, 26, UI.TEXT, true))
	tv.add_child(UI.label("-%d%% today" % disc, 22, Color("9cf06a"), true))
	h.add_child(tv)
	h.add_child(UI.button("Get", act, UI.ACCENT, 26, 72))
	return card


class CosmeticIcon extends Control:
	var c: Dictionary
	var t := 0.0

	func _init(def: Dictionary) -> void:
		c = def
		custom_minimum_size = Vector2(110, 110)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(dt: float) -> void:
		t += dt
		queue_redraw()

	func _draw() -> void:
		var cc := size * 0.5
		Draw.rrect(self, Rect2(Vector2.ZERO, size), 20, Color(1, 1, 1, 0.06))
		var cols: Array = c.get("art", {}).get("colors", ["#ffffff", "#cccccc"])
		match String(c.type):
			"trail":
				for i in 7:
					var k := fposmod(t * 0.7 + i / 7.0, 1.0)
					var p := cc + Vector2(-40 + k * 80, sin(k * 6.0) * 16)
					var col := Color(String(cols[i % cols.size()]))
					match String(c.get("art", {}).get("shape", "")):
						"leaf":
							Draw.leaf(self, p, Vector2(1, -0.5), 18, 6, col)
						"petal":
							Draw.ellipse(self, p, 8, 4, col, k * 4.0)
						"bubble":
							Draw.ellipse_line(self, p, 7, 7, col, 2)
						_:
							Draw.star(self, p, 7, col, 4, 0.35)
			"emote":
				if c.get("anim") == "hearts":
					Draw.heart(self, cc + Vector2(0, sin(t * 3.0) * 6), 24, Color("ef5a7a"))
				else:
					Draw.star(self, cc, 28, UI.ACCENT, 5, 0.45, t)
			"flag":
				draw_line(cc + Vector2(-20, -40), cc + Vector2(-20, 40), Color("e8e0c8"), 4)
				draw_colored_polygon(PackedVector2Array([cc + Vector2(-18, -38), cc + Vector2(36, -22 + sin(t * 3.0) * 4), cc + Vector2(-18, -6)]), Color(String(cols[0])))
				Draw.ellipse(self, cc + Vector2(2, -22), 7, 7, Color(String(cols[1])))
