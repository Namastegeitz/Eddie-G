extends Control
## Your showcase: every treasure and crumb gem in the house, room by room.
## Found pieces shine in their rarity's colour; missing ones are dark
## silhouettes with a hint of where to look.

const CARD_W := 132.0


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	var col := UIKit.column(self, 760.0, 12)
	col.add_child(UIKit.title("SHOWCASE", 44))
	col.add_child(UIKit.label(Collection.summary(), 22, UIKit.TEXT))
	var r := Collection.by_rarity()
	var tally := GridContainer.new()
	tally.columns = 4 if get_viewport_rect().size.x >= 640.0 else 2
	tally.add_theme_constant_override("h_separation", 24)
	for i in 4:
		var l := UIKit.label("%s %d/%d" % [ItemDef.RARITY_NAMES[i], r[i][0], r[i][1]], 17, ItemDef.RARITY_COLORS[i])
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		tally.add_child(l)
	var tally_center := CenterContainer.new()
	tally_center.add_child(tally)
	col.add_child(tally_center)
	col.add_child(UIKit.label("Treasures and gems hide high up: climb the towers, ride the bounce pads, scale the furniture.", 16, UIKit.DIM))
	for room in Collection.ROOMS:
		col.add_child(UIKit.label(room.to_upper(), 24, UIKit.GOLD))
		var grid := GridContainer.new()
		var w := get_viewport_rect().size.x if is_inside_tree() else 720.0
		grid.columns = clampi(int((minf(760.0, w - 48.0)) / (CARD_W + 10.0)), 2, 4)
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		var center := CenterContainer.new()
		center.add_child(grid)
		col.add_child(center)
		for id: StringName in Collection.IDS[room]:
			grid.add_child(_card(id))
	col.add_child(UIKit.button("Back", func() -> void: GameManager.goto("main_menu")))


func _card(id: StringName) -> Control:
	var d := Collection.def_of(id)
	var found := Collection.is_found(id)
	var card := PanelContainer.new()
	card.name = "Card_%s" % id
	card.custom_minimum_size = Vector2(CARD_W, 0)
	var sb := StyleBoxFlat.new()
	var tint := d.rarity_color() if d else UIKit.DIM
	sb.bg_color = Color(0.1, 0.088, 0.07, 0.94) if found else Color(0.07, 0.06, 0.05, 0.9)
	sb.border_color = tint if found else Color(tint, 0.35)
	sb.set_border_width_all(3 if found else 2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", sb)
	var v := UIKit.vbox(2)
	card.add_child(v)
	var tex := TextureRect.new()
	tex.texture = Collection.icon(id)
	tex.custom_minimum_size = Vector2(96, 96)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not found:
		tex.modulate = Color(0.0, 0.0, 0.0, 0.75)
	v.add_child(tex)
	var name_label := UIKit.label(d.display_name if found and d else "???", 15, UIKit.TEXT if found else UIKit.DIM)
	v.add_child(name_label)
	v.add_child(UIKit.label(d.rarity_name() if d else "", 13, tint if found else Color(tint, 0.6)))
	if found:
		var times := int(SaveSystem.treasures_found().get(String(id), SaveSystem.gems_found().get(String(id), 1)))
		if times > 1:
			v.add_child(UIKit.label("found x%d" % times, 12, UIKit.DIM))
	else:
		v.add_child(UIKit.label("Somewhere in the %s" % (d.found_in if d else "house"), 12, UIKit.DIM))
	return card
