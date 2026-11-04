extends Node
## The store: catalog from content/store/catalog.json, live ops from
## content/store/live_ops.json, purchases through a BillingBackend (sandbox
## mock by default; Google Play / App Store behind canopy/billing/backend),
## grants, restore, and downloadable content packs.

signal purchase_finished(product_id: String, ok: bool, message: String)
signal confirm_requested(product: Dictionary)
signal changed

var backend: BillingBackend
var day_override := -1
var _busy := ""


func _ready() -> void:
	var mode := String(ProjectSettings.get_setting("canopy/billing/backend", "mock"))
	if mode == "platform" and OS.get_name() == "Android" and Engine.has_singleton("GodotGooglePlayBilling"):
		backend = load("res://scripts/platform/google_play_billing.gd").new()
	elif mode == "platform" and OS.get_name() == "iOS" and Engine.has_singleton("InAppStore"):
		backend = load("res://scripts/platform/app_store_billing.gd").new()
	else:
		backend = load("res://scripts/platform/mock_billing.gd").new()
	add_child(backend)
	backend.purchased.connect(_on_purchased)
	backend.failed.connect(_on_failed)
	backend.restored.connect(_on_restored)
	backend.prices_ready.connect(func(_p): changed.emit())
	if backend.has_signal("confirm_requested"):
		backend.connect("confirm_requested", func(p): confirm_requested.emit(p))
	backend.init_catalog(Content.catalog.get("products", []))


func is_sandbox() -> bool:
	return backend.name_label == "sandbox"


# ------------------------------------------------------------------ catalog

func products(section: String) -> Array:
	var out := []
	for p in Content.catalog.get("products", []):
		if p.get("section", "") == section:
			out.append(p)
	return out


func price_label(product: Dictionary) -> String:
	var local := backend.localized_price(String(product.id))
	if local != "":
		return local
	return "$%.2f" % float(product.get("price_usd", 0.0))


func owns_product(id: String) -> bool:
	var p := Content.product(id)
	if p.get("type", "") == "season":
		return bool(Save.data.pass.get("premium", false)) and Save.data.pass.get("season", "") == Progress.current_season().get("id", "")
	return id in Save.data.owned_products


## True when every animal/map the product grants is already owned (no point buying).
func product_redundant(id: String) -> bool:
	var p := Content.product(id)
	if p.get("type", "") == "consumable":
		return false
	if owns_product(id):
		return true
	for g in p.get("grants", []):
		match String(g.type):
			"animal":
				if not Save.owns_animal(String(g.id)):
					return false
			"animals":
				for a in Content.animals_where(g.get("where", {})):
					if not Save.owns_animal(a):
						return false
			"map":
				if not Save.owns_map(String(g.id)):
					return false
			"maps":
				for m in Content.maps_where(g.get("where", {})):
					if not Save.owns_map(m):
						return false
			_:
				return false
	return true


func purchase(id: String) -> void:
	var p := Content.product(id)
	if p.is_empty():
		purchase_finished.emit(id, false, "Unknown product.")
		return
	if _busy != "":
		return
	if p.get("type", "") != "consumable" and owns_product(id):
		purchase_finished.emit(id, false, "Already owned.")
		return
	_busy = id
	Analytics.event("purchase_start", {"product": id, "price_usd": p.get("price_usd", 0.0)})
	backend.purchase(p)


## Sandbox sheet answer.
func confirm_sandbox(id: String, ok: bool) -> void:
	if backend.has_method("confirm"):
		backend.confirm(id, ok)


func _on_purchased(id: String, token: String) -> void:
	_busy = ""
	var p := Content.product(id)
	if p.is_empty():
		return
	grant_product(p, "purchase")
	Analytics.event("purchase", {"product": id, "price_usd": p.get("price_usd", 0.0), "backend": backend.name_label,
		"token": token.substr(0, 24)})
	Analytics.funnel("first_purchase", {"product": id})
	purchase_finished.emit(id, true, "")
	changed.emit()


func _on_failed(id: String, message: String) -> void:
	var pid := id if id != "" else _busy
	_busy = ""
	Analytics.event("purchase_failed", {"product": pid, "message": message})
	purchase_finished.emit(pid, false, message)


func restore() -> void:
	Analytics.event("restore_start")
	backend.restore()


func _on_restored(ids: Array) -> void:
	var n := 0
	for id in ids:
		var p := Content.product(String(id))
		if p.is_empty() or p.get("type", "") == "consumable":
			continue
		if not owns_product(String(id)) or not product_redundant(String(id)):
			grant_product(p, "restore")
			n += 1
	Analytics.event("restore", {"count": n})
	purchase_finished.emit("restore", true, "Restored %d purchase%s." % [n, "" if n == 1 else "s"])
	changed.emit()


func grant_product(p: Dictionary, source: String) -> void:
	var id := String(p.id)
	if p.get("type", "") != "consumable" and not id in Save.data.owned_products and p.get("type", "") != "season":
		Save.data.owned_products.append(id)
	for g in p.get("grants", []):
		match String(g.type):
			"flag":
				Save.set_flag(String(g.id))
			"amber":
				Economy.add("amber", int(g.amount), source + ":" + id)
			"berries":
				Economy.add("berries", int(g.amount), source + ":" + id)
			"animal":
				Economy.give_animal(String(g.id), source + ":" + id)
			"animals":
				for a in Content.animals_where(g.get("where", {})):
					Economy.give_animal(a, source + ":" + id)
			"map":
				Economy.give_map(String(g.id), source + ":" + id)
			"maps":
				for m in Content.maps_where(g.get("where", {})):
					Economy.give_map(m, source + ":" + id)
			"pass_premium":
				Progress.set_premium()
			"item":
				Economy.give_item(String(g.id), int(g.get("count", 1)), source)
			"cosmetic":
				Economy.give_cosmetic(String(g.id), source)
	Save.mark()


# ------------------------------------------------------------------ packs

## The product that unlocks a pack-locked animal: its map pack if there is
## one, otherwise its regional animal pack.
func pack_product_for_animal(animal_id: String) -> String:
	var a := Content.animal(animal_id)
	var pack := String(a.get("pack", ""))
	for p in products("maps"):
		for g in p.get("grants", []):
			if g.type == "animals" and String(g.get("where", {}).get("pack", "")) == pack:
				return String(p.id)
	for p in products("animals"):
		if String(p.get("pack", "")) == pack:
			return String(p.id)
	return ""


func map_product(map_id: String) -> String:
	return String(Content.map(map_id).get("access", {}).get("product", ""))


func animal_pack_product(pack: String) -> String:
	for p in products("animals"):
		if String(p.get("pack", "")) == pack:
			return String(p.id)
	return ""


# ------------------------------------------------------------------ live ops

func today() -> int:
	return Progress.today()


func is_weekend() -> bool:
	var days: Array = Content.live_ops.get("weekend", {}).get("days", [6, 0])
	var wd := (today() + 4) % 7   # 1970-01-01 was a Thursday (4); 0 = Sunday
	return Progress.has_int(days, wd)


func animal_of_week() -> String:
	var rules: Dictionary = Content.live_ops.get("animal_of_week", {})
	var pool: Array[String] = []
	for id in Content.animal_order:
		var a: Dictionary = Content.animals[id]
		if String(a.rarity) in rules.get("exclude_rarity", []):
			continue
		if rules.get("exclude_starters", true) and a.get("starter", false):
			continue
		pool.append(id)
	if pool.is_empty():
		return ""
	var week := (today() + 3) / 7
	return pool[absi(hash(["aow", week])) % pool.size()]


func daily_deals() -> Array:
	var cfg: Dictionary = Content.live_ops.get("daily_deals", {})
	var pool: Array = cfg.get("pool", [])
	var out := []
	if pool.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["deals", today()])
	var picks := []
	var guard := 0
	while picks.size() < mini(int(cfg.get("count", 3)), pool.size()) and guard < 40:
		guard += 1
		var i := rng.randi() % pool.size()
		if i in picks:
			continue
		picks.append(i)
	for i in picks:
		var deal: Dictionary = pool[i].duplicate()
		match String(deal.kind):
			"animal":
				var cands: Array[String] = []
				for id in Content.animal_order:
					var a: Dictionary = Content.animals[id]
					if a.rarity == deal.rarity and a.unlock.type in ["berries", "amber"]:
						cands.append(id)
				if cands.is_empty():
					continue
				deal["id"] = cands[rng.randi() % cands.size()]
			"cosmetic":
				var cs := []
				for c in Content.catalog.get("cosmetics", []):
					if c.type == deal.get("type", ""):
						cs.append(c.id)
				if cs.is_empty():
					continue
				deal["id"] = cs[rng.randi() % cs.size()]
		out.append(deal)
	return out


func _deal_for(kind: String, id: String) -> Dictionary:
	for d in daily_deals():
		if d.kind == kind and String(d.get("id", "")) == id:
			return d
	return {}


func animal_discount(id: String) -> float:
	var best := 0.0
	if animal_of_week() == id:
		best = float(Content.live_ops.get("animal_of_week", {}).get("discount", 0.3))
	var d := _deal_for("animal", id)
	if not d.is_empty():
		best = maxf(best, float(d.discount))
	return best


func consumable_price(id: String) -> Dictionary:
	var c := Content.consumable(id)
	var price: Dictionary = c.get("price", {}).duplicate()
	var d := _deal_for("consumable", id)
	if not d.is_empty():
		var cur := String(d.get("currency", ""))
		if price.has(cur):
			price[cur] = maxi(1, int(roundf(int(price[cur]) * (1.0 - float(d.discount)))))
	return price


func cosmetic_price(id: String) -> Dictionary:
	var c := Content.cosmetic(id)
	var price: Dictionary = c.get("price", {}).duplicate()
	var d := _deal_for("cosmetic", id)
	if not d.is_empty():
		for k in price:
			price[k] = maxi(1, int(roundf(int(price[k]) * (1.0 - float(d.discount)))))
	return price


# ------------------------------------------------------------------ downloadable packs

## Map packs can ship as a downloadable zip of content files (and art). A
## map whose file has "dlc": {"url": ...} is downloaded on first unlock and
## unpacked into user://, where Content picks it up. Bundled maps skip this.
func needs_download(map_id: String) -> bool:
	var dlc: Dictionary = Content.map(map_id).get("dlc", {})
	return not dlc.is_empty() and not FileAccess.file_exists("user://dlc/%s.done" % map_id)


func download_pack(map_id: String, done: Callable) -> void:
	var dlc: Dictionary = Content.map(map_id).get("dlc", {})
	var http := HTTPRequest.new()
	add_child(http)
	DirAccess.make_dir_recursive_absolute("user://dlc")
	http.download_file = "user://dlc/%s.zip" % map_id
	http.request_completed.connect(func(result, code, _h, _b):
		http.queue_free()
		var ok: bool = result == HTTPRequest.RESULT_SUCCESS and code == 200 and install_zip("user://dlc/%s.zip" % map_id)
		if ok:
			FileAccess.open("user://dlc/%s.done" % map_id, FileAccess.WRITE).store_string("ok")
		Analytics.event("dlc_download", {"map": map_id, "ok": ok})
		done.call(ok))
	if http.request(String(dlc.get("url", ""))) != OK:
		http.queue_free()
		done.call(false)


## Unpack a content zip (paths like content/maps/x.json) into user:// and reload content.
func install_zip(path: String) -> bool:
	var zip := ZIPReader.new()
	if zip.open(path) != OK:
		return false
	for f in zip.get_files():
		if f.ends_with("/") or f.contains(".."):
			continue
		var dest := "user://" + f
		DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
		var out := FileAccess.open(dest, FileAccess.WRITE)
		if out == null:
			zip.close()
			return false
		out.store_buffer(zip.read_file(f))
		out.close()
	zip.close()
	Content.reload()
	return true
