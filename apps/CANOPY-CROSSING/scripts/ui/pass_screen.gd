extends Control
## Expedition Pass: the season's 30-tier reward track (free and premium),
## XP progress and claims. Tiers and rewards come from content/season/.

var list: VBoxContainer


func _ready() -> void:
	var root := UI.vbox(12)
	var m := UI.margin(root, 24, int(UI.safe_top(self)) + 16, 24, 24)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	root.add_child(TopBar.make(self, true, "Expedition Pass"))
	var s := Progress.current_season()
	var def := Progress.pass_def()
	var head := UI.panel(UI.region_color(String(s.get("featured_map", "amazon"))).darkened(0.3), 26, 20)
	var hv := UI.vbox(6)
	head.add_child(hv)
	hv.add_child(UI.label(String(s.get("name", "Season")), 36, UI.ACCENT, true))
	hv.add_child(UI.label("%d days left · tier %d of %d · %d XP" % [Progress.season_days_left(), Progress.pass_tier(), def.get("tiers", []).size(), Progress.pass_xp()], 24, UI.TEXT))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 18
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UI.box(Color(0, 0, 0, 0.35), 9, 0, Color.TRANSPARENT, 0))
	bar.add_theme_stylebox_override("fill", UI.box(UI.ACCENT, 9, 0, Color.TRANSPARENT, 0))
	var per := int(def.get("xp_per_tier", 120))
	bar.value = 100.0 * float(Progress.pass_xp() % per) / per
	hv.add_child(bar)
	hv.add_child(UI.label("Every row you cross earns XP. Clearing stages and the daily challenge earn more.", 20, UI.MUTED))
	if not Progress.is_premium():
		var prod := Content.product("expedition_pass")
		hv.add_child(UI.button("Unlock premium track · %s" % Store.price_label(prod), func(): Store.purchase("expedition_pass"), UI.ACCENT, 28, 84))
	else:
		hv.add_child(UI.label("Premium track unlocked", 26, Color("9cf06a"), true))
	root.add_child(head)
	var claim_all := UI.button("Claim all (%d)" % Progress.claimable_count(), func():
		for t in range(1, Progress.pass_tier() + 1):
			Progress.claim(t, "free")
			Progress.claim(t, "premium")
		Sfx.play("unlock")
		Game.goto("pass", {}, false), UI.ACCENT, 26, 72)
	claim_all.visible = Progress.claimable_count() > 0
	root.add_child(claim_all)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	list = UI.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var hdr := UI.hbox(8)
	hdr.add_child(UI.label("Tier", 22, UI.MUTED, true))
	var f := UI.label("Free", 22, UI.MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(f)
	var p := UI.label("Premium", 22, UI.AMBER, true, HORIZONTAL_ALIGNMENT_CENTER)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(p)
	list.add_child(hdr)
	for tier in def.get("tiers", []):
		list.add_child(_row(tier))
	Store.purchase_finished.connect(_on_purchase)
	tree_exiting.connect(func(): Store.purchase_finished.disconnect(_on_purchase))


func _on_purchase(id: String, ok: bool, _msg: String) -> void:
	if ok and id == "expedition_pass":
		Game.goto("pass", {}, false)


func _row(tier: Dictionary) -> Control:
	var t := int(tier.tier)
	var reached := t <= Progress.pass_tier()
	var row := UI.hbox(8)
	var n := UI.label(str(t), 30, UI.ACCENT if reached else UI.MUTED, true, HORIZONTAL_ALIGNMENT_CENTER)
	n.custom_minimum_size.x = 60
	row.add_child(n)
	for track in ["free", "premium"]:
		var r: Dictionary = tier.get(track, {})
		var claimed: bool = Progress.has_int(Save.data.pass.get("claimed_" + track, []), t)
		var txt := String(HomeScreenText.reward(r))
		var can := Progress.can_claim(t, track)
		var color := UI.PANEL_2
		if claimed:
			txt = "Got: " + txt
		elif can:
			color = UI.ACCENT if track == "free" else UI.AMBER
		elif track == "premium" and not Progress.is_premium():
			color = Color("3a3a2a")
		var b := UI.button(txt, func():
			var got := Progress.claim(t, track)
			if not got.is_empty():
				Sfx.play("unlock")
				Game.goto("pass", {}, false), color, 20, 70)
		b.disabled = not can
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		row.add_child(b)
	return row


class HomeScreenText:
	static func reward(r: Dictionary) -> String:
		if r.has("berries"):
			return "%d Berries" % int(r.berries)
		if r.has("amber"):
			return "%d Amber" % int(r.amber)
		if r.has("item"):
			return "%d× %s" % [int(r.get("count", 1)), String(Content.consumable(String(r.item)).get("name", r.item))]
		if r.has("animal"):
			return String(Content.animal(String(r.animal)).get("name", ""))
		if r.has("cosmetic"):
			return String(Content.cosmetic(String(r.cosmetic)).get("name", ""))
		return "-"
