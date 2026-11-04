class_name BugSelect
extends Control
## Pick your bug. Each card shows the bug's picture; bugs you haven't unlocked
## yet stand in the shade - a dark silhouette - with what brings them out
## (escape a room as the bug before them). New arrivals are marked NEW.


func _ready() -> void:
	UIKit.setup_root(self)
	UIKit.background(self)
	var wide := get_viewport_rect().size.x > 1000.0
	var col := UIKit.column(self, 1100.0 if wide else 620.0, 12)
	col.add_child(UIKit.title("CHOOSE YOUR BUG", 44))
	var cfg := GameManager.get_level(GameManager.current_level)
	if cfg:
		col.add_child(UIKit.label("%s  -  %s" % [cfg.display_name, String(GameManager.current_time_slot).capitalize()], 20, UIKit.DIM))
	var unlocked := 0
	for id in GameManager.BUG_IDS:
		if SaveSystem.is_bug_unlocked(id):
			unlocked += 1
	col.add_child(UIKit.label("%d of %d bugs out of the shade" % [unlocked, GameManager.BUG_IDS.size()], 16, UIKit.DIM))
	var grid := GridContainer.new()
	grid.name = "Cards"
	grid.columns = 2 if wide else 1
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	for id in GameManager.BUG_IDS:
		var stats := GameManager.get_bug_stats(id)
		if stats:
			var card := card_for(stats)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(card)
	col.add_child(UIKit.button("Back", func() -> void: GameManager.goto("level_select")))


## One bug's card (public so tests can inspect it).
static func card_for(s: BugStats) -> Control:
	var unlocked := SaveSystem.is_bug_unlocked(s.id)
	var p := UIKit.panel()
	p.name = "Card_" + String(s.id)
	var row := UIKit.hbox(14)
	p.add_child(row)
	var img := TextureRect.new()
	img.name = "Portrait"
	img.texture = BugGuide.portrait(s.id)
	img.custom_minimum_size = Vector2(112, 112)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not unlocked:
		# In the shade: a dark silhouette.
		img.self_modulate = Color(0.0, 0.0, 0.0, 0.92)
	row.add_child(img)
	var v := UIKit.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	var name_row := UIKit.hbox(8)
	v.add_child(name_row)
	var title := UIKit.label(s.display_name.to_upper(), 26, UIKit.GOLD if unlocked else UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "Name"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_row.add_child(title)
	if unlocked and SaveSystem.is_bug_new(s.id):
		var badge := UIKit.label("NEW", 14, UIKit.INK)
		badge.name = "New"
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		var bg := PanelContainer.new()
		bg.add_theme_stylebox_override("panel", UIKit._box(UIKit.GREEN, UIKit.GREEN, 1, 8))
		bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bg.add_child(badge)
		name_row.add_child(bg)
	if unlocked and SaveSystem.is_bug_completed(s.id):
		var done := UIKit.label("ESCAPED", 13, UIKit.GREEN)
		done.autowrap_mode = TextServer.AUTOWRAP_OFF
		done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(done)
	if unlocked:
		var tag := UIKit.label(s.tagline if s.tagline != "" else s.description, 17, UIKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(tag)
		for r in [["Speed", s.rating_speed], ["Stealth", s.rating_stealth], ["Toughness", s.rating_toughness]]:
			var bar_row := UIKit.hbox(10)
			var l := UIKit.label(String(r[0]), 14, UIKit.DIM, HORIZONTAL_ALIGNMENT_LEFT)
			l.custom_minimum_size.x = 92
			bar_row.add_child(l)
			var b := UIKit.bar(float(r[1]), UIKit.GOLD, 10.0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			bar_row.add_child(b)
			v.add_child(bar_row)
		var play := UIKit.button("Play as %s" % s.display_name, func() -> void:
			SaveSystem.mark_bug_played(s.id)
			GameManager.start_level(GameManager.current_level, s.id, GameManager.current_time_slot), 56.0)
		play.name = "Play"
		v.add_child(play)
	else:
		var hint := UIKit.label(shade_text(s), 16, UIKit.RED, HORIZONTAL_ALIGNMENT_LEFT)
		hint.name = "Hint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
	return p


## What brings a bug out of the shade.
static func shade_text(s: BugStats) -> String:
	var prev := GameManager.get_bug_stats(s.unlock_after_bug)
	var prev_name := prev.display_name if prev else String(s.unlock_after_bug).capitalize()
	if prev and not SaveSystem.is_bug_unlocked(prev.id):
		return "In the shade. Bring the %s out first." % prev_name
	return "In the shade - escape any room as the %s to bring it out." % prev_name
