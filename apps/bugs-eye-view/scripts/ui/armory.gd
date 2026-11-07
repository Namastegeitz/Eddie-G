extends Control
## The Armory: spend credits (from gem shards in the mini maps, and from gems
## and treasures) on add-ons - strength, defense and tactics - raise them to
## level 3, and load them into your revolver's six chambers.

var chamber := 0
var _col: VBoxContainer
var _credits: Label
var _chambers: HBoxContainer
var _list: VBoxContainer


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	_col = UIKit.column(self, 720.0, 12)
	_col.add_child(UIKit.title("ARMORY", 44))
	_credits = UIKit.label("", 24, UIKit.GOLD)
	_col.add_child(_credits)
	_col.add_child(UIKit.label("Earn credits from gem shards in the mini maps (and from gems and treasures in the rooms). " +
		"Load add-ons into your revolver's six chambers, then in play open it (TOOLS / Tab), turn to one and fire.", 16, UIKit.DIM))
	_col.add_child(UIKit.label("YOUR REVOLVER  -  pick a chamber, then Load an add-on into it", 18, UIKit.TEXT))
	_chambers = UIKit.hbox(6)
	_chambers.alignment = BoxContainer.ALIGNMENT_CENTER
	_col.add_child(_chambers)
	_list = UIKit.vbox(10)
	_col.add_child(_list)
	_col.add_child(UIKit.button("Back", func() -> void: GameManager.goto("main_menu")))
	refresh()


func refresh() -> void:
	_credits.text = "Credits: %d" % SaveSystem.credits()
	for c in _chambers.get_children():
		c.queue_free()
	var rev := SaveSystem.revolver()
	for i in AddOns.CHAMBERS:
		var id := StringName(rev[i])
		var b := Button.new()
		b.name = "Chamber%d" % (i + 1)
		b.custom_minimum_size = Vector2(98, 92)
		b.toggle_mode = true
		b.button_pressed = i == chamber
		b.icon = AddOns.icon(id) if id != &"" else null
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.text = "%d  %s" % [i + 1, AddOns.display_name(id).get_slice(" ", 0) if id != &"" else "empty"]
		b.add_theme_font_size_override("font_size", 14)
		if id != &"":
			b.add_theme_color_override("icon_normal_color", AddOns.color(id))
			b.add_theme_color_override("icon_pressed_color", AddOns.color(id))
		var idx := i
		b.pressed.connect(func() -> void:
			chamber = idx
			AudioManager.play(&"revolver_click", -6.0)
			refresh())
		_chambers.add_child(b)
	for c in _list.get_children():
		c.queue_free()
	for kind in ["strength", "defense", "tactic"]:
		_list.add_child(UIKit.label(String(AddOns.KIND_NAMES[kind]).to_upper(), 22, AddOns.KIND_COLORS[kind]))
		for id in AddOns.ids():
			if AddOns.kind(id) == kind:
				_list.add_child(_row(id))


func _row(id: StringName) -> Control:
	var lvl := SaveSystem.addon_level(id)
	var p := UIKit.panel()
	p.name = "Row_%s" % id
	var h := UIKit.hbox(10)
	p.add_child(h)
	var icon := TextureRect.new()
	icon.texture = AddOns.icon(id)
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = AddOns.color(id) if lvl > 0 else Color(0.45, 0.45, 0.45)
	h.add_child(icon)
	var v := UIKit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var title := AddOns.display_name(id) + ("   Lv %d/%d" % [lvl, AddOns.MAX_LEVEL] if lvl > 0 else "")
	v.add_child(UIKit.label(title, 20, UIKit.GOLD if lvl > 0 else UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(UIKit.label(AddOns.blurb(id), 15, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT))
	var info := "%s  -  %d uses a run" % [AddOns.detail(id, maxi(lvl, 1)), AddOns.charges(maxi(lvl, 1))]
	v.add_child(UIKit.label(info, 14, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT))
	var btns := UIKit.vbox(4)
	h.add_child(btns)
	if lvl < AddOns.MAX_LEVEL:
		var cost := AddOns.price(id, lvl + 1)
		var buy := UIKit.button(("Buy  %d" if lvl == 0 else "Upgrade  %d") % cost, func() -> void: buy_addon(id), 48.0)
		buy.name = "Buy"
		buy.custom_minimum_size.x = 150
		buy.disabled = SaveSystem.credits() < cost
		btns.add_child(buy)
	else:
		btns.add_child(UIKit.label("MAX", 16, UIKit.GOLD))
	if lvl > 0:
		var rev := SaveSystem.revolver()
		var at := rev.find(String(id))
		var load_b := UIKit.button("In chamber %d" % (at + 1) if at == chamber else "Load into %d" % (chamber + 1),
			func() -> void: load_into(chamber, id), 48.0)
		load_b.name = "Load"
		load_b.custom_minimum_size.x = 150
		load_b.disabled = at == chamber
		btns.add_child(load_b)
	return p


func buy_addon(id: StringName) -> bool:
	var ok := SaveSystem.buy_addon(id)
	if ok:
		AudioManager.play(&"gem", -4.0)
		# Bought something new: put it straight into an empty chamber.
		if SaveSystem.addon_level(id) == 1 and not SaveSystem.revolver().has(String(id)):
			var rev := SaveSystem.revolver()
			var empty := rev.find("")
			if empty >= 0:
				SaveSystem.set_chamber(empty, id)
		SaveSystem.save_game()
	refresh()
	return ok


func load_into(i: int, id: StringName) -> void:
	SaveSystem.set_chamber(i, id)
	SaveSystem.save_game()
	AudioManager.play(&"revolver_click", -4.0)
	refresh()
