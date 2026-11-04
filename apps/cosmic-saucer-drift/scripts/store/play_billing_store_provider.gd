class_name PlayBillingStoreProvider
extends StoreProvider
## Template for Google Play Billing. Inactive until a Godot Google Play
## Billing plugin is added (see docs/STORE_PLAN.md). It only reaches the
## plugin through Engine.get_singleton, so the game builds without it.
##
## Method and signal names follow the Godot Google Play Billing plugin; check
## them against the version you install and adjust here only.

const SINGLETON := "GodotGooglePlayBilling"

var _plugin: Object = null
var _prices := {}
var _pending := {}        # product id -> Callable


func provider_name() -> String:
	return "play_billing"


func initialize(p_config: StoreConfig) -> void:
	super.initialize(p_config)
	if Engine.has_singleton(SINGLETON):
		_plugin = Engine.get_singleton(SINGLETON)
		# Connect the plugin's signals here, e.g. "connected" ->
		# query product details for Store.PRODUCTS, "purchases_updated" ->
		# _on_purchases_updated, then call _plugin.startConnection().


func ready() -> bool:
	return _plugin != null


func price_text(product_id: String) -> String:
	return _prices.get(product_id, "")


func purchase(product_id: String, done: Callable) -> void:
	if not ready():
		done.call(false)
		return
	_pending[product_id] = done
	_plugin.call("purchase", product_id)


## Wire to the plugin's purchase-updated signal. Acknowledge non-consumables
## and consume credit packs on the plugin side, then report success.
func on_purchase_result(product_id: String, ok: bool) -> void:
	var cb: Callable = _pending.get(product_id, Callable())
	_pending.erase(product_id)
	if cb.is_valid():
		cb.call(ok)


func on_price(product_id: String, text: String) -> void:
	_prices[product_id] = text
