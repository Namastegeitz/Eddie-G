extends BillingBackend
## Apple In-App Purchase through the godot-ios-plugins "InAppStore"
## singleton. Enabled when canopy/billing/backend = "platform" on iOS with
## the plugin compiled in. Not exercised in the sandbox build: see
## docs/STORE.md for the StoreKit sandbox test checklist.

var _store: Object = null
var _products: Array = []
var _prices := {}


func _init() -> void:
	name_label = "app_store"


func available() -> bool:
	return _store != null


func _ready() -> void:
	if not Engine.has_singleton("InAppStore"):
		return
	_store = Engine.get_singleton("InAppStore")
	_store.set_auto_finish_transaction(true)


func init_catalog(products: Array) -> void:
	_products = products
	if _store == null:
		return
	var ids := PackedStringArray()
	for p in products:
		ids.append(String(p.store_ids.apple))
	_store.request_product_info({"product_ids": ids})


func _process(_delta: float) -> void:
	if _store == null:
		return
	while _store.get_pending_event_count() > 0:
		var ev: Dictionary = _store.pop_pending_event()
		match String(ev.get("type", "")):
			"product_info":
				var ids: Array = ev.get("ids", [])
				var prices: Array = ev.get("localized_prices", [])
				for i in ids.size():
					_prices[_local_id(String(ids[i]))] = String(prices[i]) if i < prices.size() else ""
				prices_ready.emit(_prices)
			"purchase":
				if String(ev.get("result", "")) == "ok":
					purchased.emit(_local_id(String(ev.product_id)), String(ev.get("transaction_id", "")))
				else:
					failed.emit(_local_id(String(ev.get("product_id", ""))), String(ev.get("error", "Purchase failed.")))
			"restore":
				if String(ev.get("result", "")) == "ok":
					restored.emit([_local_id(String(ev.product_id))])


func purchase(product: Dictionary) -> void:
	if _store == null:
		failed.emit(String(product.id), "The App Store is not available.")
		return
	_store.purchase({"product_id": String(product.store_ids.apple)})


func restore() -> void:
	if _store:
		_store.restore_purchases()
	else:
		restored.emit([])


func localized_price(product_id: String) -> String:
	return String(_prices.get(product_id, ""))


func _local_id(store_id: String) -> String:
	for p in _products:
		if String(p.store_ids.apple) == store_id:
			return String(p.id)
	return store_id
