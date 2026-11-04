extends Node
## Real-money store layer (switched off in v1). Premium craft are always
## unlockable with Race Credits; when the store is on they can also be bought.
## Which backend (if any) is used is set in resources/store_config.tres.
## The game asks: enabled(), can_buy(id), price_text(id), buy(id, done),
## restore(). Grants happen here so every backend behaves the same.

signal purchased(product_id: String)

const PRODUCTS := [
	{"id": "craft_sail", "type": "craft", "grant": "sail", "price": "$2.99"},
	{"id": "craft_phantom", "type": "craft", "grant": "phantom", "price": "$2.99"},
	{"id": "craft_dragon", "type": "craft", "grant": "dragon", "price": "$3.99"},
	{"id": "craft_dyson", "type": "craft", "grant": "dyson", "price": "$3.99"},
	{"id": "premium_fleet", "type": "bundle", "grant": ["sail", "phantom", "dragon", "dyson"], "price": "$9.99"},
	{"id": "credits_5k", "type": "credits", "grant": 5000, "price": "$0.99"},
	{"id": "credits_30k", "type": "credits", "grant": 30000, "price": "$4.99"},
	{"id": "remove_ads", "type": "entitlement", "grant": "remove_ads", "price": "$2.99"},
]

var config: StoreConfig
var provider: StoreProvider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = load("res://resources/store_config.tres")
	use_provider(config.provider)


func use_provider(kind: String) -> void:
	match kind:
		"debug":
			var d := DebugStoreProvider.new()
			d.host = self
			provider = d
		"play_billing":
			provider = PlayBillingStoreProvider.new()
		_:
			provider = StoreProvider.new()
	provider.initialize(config)


func enabled() -> bool:
	return config.enabled and config.provider != "none" and provider.ready()


func product(id: String) -> Dictionary:
	for p in PRODUCTS:
		if p.id == id:
			return p
	return {}


func owned(id: String) -> bool:
	var p := product(id)
	match String(p.get("type", "")):
		"craft":
			return Save.has_saucer(p.grant)
		"bundle":
			for c in p.grant:
				if not Save.has_saucer(c):
					return false
			return true
		"entitlement":
			return Ads.removed() if p.grant == "remove_ads" else false
	return false


func can_buy(id: String) -> bool:
	return enabled() and not product(id).is_empty() and not owned(id)


func price_text(id: String) -> String:
	var t := provider.price_text(id)
	return t if t != "" else String(product(id).get("price", ""))


func buy(id: String, done: Callable) -> void:
	if not can_buy(id):
		done.call(false)
		return
	Events.log_event("purchase_start", {"product": id})
	provider.purchase(id, func(ok: bool) -> void:
		if ok:
			_grant(product(id))
			Events.log_event("purchase", {"product": id, "real_money": true})
			emit_signal("purchased", id)
		done.call(ok))


func _grant(p: Dictionary) -> void:
	match String(p.type):
		"craft":
			Save.unlock_saucer(p.grant)
		"bundle":
			for c in p.grant:
				Save.unlock_saucer(c)
		"credits":
			Save.add_credits(int(p.grant))
		"entitlement":
			if p.grant == "remove_ads":
				Ads.set_removed(true)
	Save.flush()


## Re-grant non-consumables (new phone, reinstall).
func restore(done: Callable) -> void:
	if not enabled():
		done.call(0)
		return
	provider.owned_products(func(ids: Array) -> void:
		var n := 0
		for id in ids:
			var p := product(id)
			if not p.is_empty() and p.type != "credits" and not owned(id):
				_grant(p)
				n += 1
		done.call(n))
