class_name BillingBackend
extends Node
## Interface every billing backend implements. The Store talks only to this.
## Backends emit `purchased(product_id, token)` when the platform confirms a
## payment, `failed(product_id, message)` otherwise, and `restored(ids)` with
## every non-consumable the account owns.

signal purchased(product_id: String, token: String)
signal failed(product_id: String, message: String)
signal restored(product_ids: Array)
signal prices_ready(prices: Dictionary)

var name_label := "none"


func available() -> bool:
	return false


func init_catalog(_products: Array) -> void:
	pass


func purchase(product: Dictionary) -> void:
	failed.emit(String(product.get("id", "")), "Purchases are not available on this device.")


func consume(_product_id: String, _token: String) -> void:
	pass


func restore() -> void:
	restored.emit([])


func localized_price(_product_id: String) -> String:
	return ""
