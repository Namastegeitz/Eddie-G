class_name TopBar
extends RefCounted
## Back button (optional), title, and live Berries / Amber chips. Tapping
## Amber opens the store.


static func make(owner: Control, back := true, title := "") -> HBoxContainer:
	var bar := UI.hbox(12)
	if back:
		var b := UI.button("‹ Back", func(): Game.back(), UI.PANEL_2, 28, 72)
		b.custom_minimum_size.x = 150
		bar.add_child(b)
	if title != "":
		var t := UI.label(title, 40, UI.ACCENT, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(t)
	else:
		bar.add_child(UI.spacer(0, 1))
		bar.get_child(bar.get_child_count() - 1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var berries := Widgets.currency_chip("berries", str(Economy.berries()), 28)
	var amber := Widgets.currency_chip("amber", str(Economy.amber()), 28)
	var amber_btn := Button.new()
	amber_btn.flat = true
	amber_btn.custom_minimum_size = Vector2(0, 60)
	amber_btn.add_child(amber)
	amber.set_anchors_preset(Control.PRESET_FULL_RECT)
	amber_btn.custom_minimum_size.x = 120
	amber_btn.pressed.connect(func(): Game.goto("store", {"section": "amber"}))
	bar.add_child(berries)
	bar.add_child(amber_btn)
	var refresh := func():
		if is_instance_valid(berries):
			(berries.get_node("Value") as Label).text = str(Economy.berries())
			(amber.get_node("Value") as Label).text = str(Economy.amber())
	Economy.currency_changed.connect(refresh)
	owner.tree_exiting.connect(func(): Economy.currency_changed.disconnect(refresh))
	return bar
