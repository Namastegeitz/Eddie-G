extends Control
## Settings: audio, haptics, handedness, colour-blind hazard markers,
## reduced motion, the per-move timer, ad personalisation, restore
## purchases, replay the tutorial, reset progress, credits.


func _ready() -> void:
	var root := UI.vbox(12)
	var m := UI.margin(root, 24, int(UI.safe_top(self)) + 16, 24, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root.add_child(TopBar.make(self, true, "Settings"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var box := UI.vbox(14)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	box.add_child(_slider("Music", "music"))
	box.add_child(_slider("Sound effects", "sfx"))
	box.add_child(_toggle("Haptics", "haptics", "Light vibration on hops and hits."))
	box.add_child(_toggle("Left-handed controls", "left_handed", "Ability button on the left."))
	box.add_child(_toggle("Colour-blind hazard markers", "colorblind", "Warning triangles on deadly things, outlines on safe rides."))
	box.add_child(_toggle("Reduce motion", "reduce_motion", "No screen shake."))
	box.add_child(_toggle("Per-move timer on harder maps", "move_timer", "Some regions (like Bwindi) time each forward move."))
	box.add_child(_toggle("Personalised ads", "ads_personalised", "Off by default. Only affects optional ads."))
	box.add_child(UI.label("Controls", 30, UI.ACCENT, true))
	box.add_child(UI.wrap_label("Tap anywhere to hop forward. Swipe up, down, left or right to hop that way. The round button uses your animal's ability. Keyboard: arrows/WASD, Space for the ability, Q/E for power-ups, R to restart, Esc to pause.", 24, UI.TEXT))
	box.add_child(UI.button("Replay the tutorial", func(): Game.start_tutorial(), UI.PANEL_3, 26, 80))
	box.add_child(UI.button("Restore purchases", func():
		Store.restore()
		Game.modal(PromptCard.make("Restore purchases", "Asked the store for your purchases. Anything found is restored.", [{"id": "ok", "text": "OK"}])), UI.PANEL_3, 26, 80))
	box.add_child(UI.button("Reset all progress", func():
		var card := PromptCard.make("Reset everything?", "Animals, maps, Berries and Amber you earned will be wiped. Purchases can be restored afterwards.",
			[{"id": "reset", "text": "Reset", "color": UI.DANGER}, {"id": "cancel", "text": "Cancel"}])
		card.closed.connect(func(c):
			if c == "reset":
				Save.wipe()
				Game.boot())
		Game.modal(card), Color("5a2a22"), 26, 80))
	box.add_child(UI.label("About", 30, UI.ACCENT, true))
	box.add_child(UI.wrap_label("Canopy Crossing %s. Animals and places are real; facts are simplified for play. Conservation statuses follow the IUCN Red List where available.\nFont: Fredoka (SIL Open Font License). Globe outline: Natural Earth (public domain)." % String(ProjectSettings.get_setting("application/config/version")), 22, UI.MUTED))
	box.add_child(UI.label("Analytics events this session: %d · billing: %s · ads: %s" % [Analytics.buffer.size(), Store.backend.name_label, Ads.backend], 20, UI.MUTED))


func _slider(label: String, key: String) -> Control:
	var row := UI.hbox(12)
	var l := UI.label(label, 28)
	l.custom_minimum_size.x = 250
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Save.setting(key, 0.7))
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 60
	s.value_changed.connect(func(v):
		Save.set_setting(key, v)
		if key == "sfx":
			Sfx.play("tap"))
	row.add_child(s)
	return row


func _toggle(label: String, key: String, hint: String) -> Control:
	var v := UI.vbox(2)
	var c := CheckButton.new()
	c.text = label
	c.button_pressed = bool(Save.setting(key, false))
	c.custom_minimum_size.y = 64
	c.toggled.connect(func(on): Save.set_setting(key, on))
	v.add_child(c)
	v.add_child(UI.label(hint, 20, UI.MUTED))
	return v
