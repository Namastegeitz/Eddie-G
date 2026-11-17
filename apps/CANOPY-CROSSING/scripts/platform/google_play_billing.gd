extends BillingBackend
## Google Play Billing through the official GodotGooglePlayBilling Android
## plugin (v2+). Enabled when canopy/billing/backend = "platform" and the
## plugin singleton is present in an Android build. Not exercised in the
## sandbox build: see docs/STORE.md for the setup and test checklist.

var _plugin: Object = null
var _products: Array = []
var _prices := {}


func _init() -> void:
	name_label = "google_play"


func available() -> bool:
	return _plugin != null


func _ready() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		return
	_plugin = Engine.get_singleton("GodotGooglePlayBilling")
	_plugin.connect("connected", _on_connected)
	_plugin.connect("purchases_updated", _on_purchases_updated)
	_plugin.connect("purchase_error", _on_purchase_error)
	_plugin.connect("product_details_query_completed", _on_details)
	_plugin.connect("query_purchases_response", _on_query_purchases)
	_plugin.startConnection()


func init_catalog(products: Array) -> void:
	_products = products


func _on_connected() -> void:
	var inapp := []
	for p in _products:
		inapp.append(String(p.store_ids.google))
	_plugin.queryProductDetails(inapp, "inapp")
	_plugin.queryPurchases("inapp")


func _on_details(details: Array) -> void:
	for d in details:
		_prices[_local_id(String(d.get("product_id", d.get("id", ""))))] = String(d.get("one_time_purchase_offer_details", {}).get("formatted_price", ""))
	prices_ready.emit(_prices)


func purchase(product: Dictionary) -> void:
	if _plugin == null:
		failed.emit(String(product.id), "Google Play is not available.")
		return
	_plugin.purchase(String(product.store_ids.google))


func _on_purchases_updated(purchases: Array) -> void:
	for pu in purchases:
		var token := String(pu.get("purchase_token", ""))
		for sku in pu.get("products", pu.get("skus", [])):
			var id := _local_id(String(sku))
			var prod: Dictionary = Content.product(id)
			if String(prod.get("type", "")) == "consumable":
				_plugin.consumePurchase(token)
			elif not bool(pu.get("is_acknowledged", false)):
				_plugin.acknowledgePurchase(token)
			purchased.emit(id, token)


func _on_purchase_error(code: int, message: String) -> void:
	failed.emit("", "Google Play error %d: %s" % [code, message])


func restore() -> void:
	if _plugin:
		_plugin.queryPurchases("inapp")
	else:
		restored.emit([])


func _on_query_purchases(result: Dictionary) -> void:
	var ids := []
	for pu in result.get("purchases", []):
		for sku in pu.get("products", pu.get("skus", [])):
			ids.append(_local_id(String(sku)))
	restored.emit(ids)


func localized_price(product_id: String) -> String:
	return String(_prices.get(product_id, ""))


func _local_id(store_id: String) -> String:
	for p in _products:
		if String(p.store_ids.google) == store_id:
			return String(p.id)
	return store_id
