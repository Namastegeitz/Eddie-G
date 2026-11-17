class_name StoreProvider
extends RefCounted
## Interface for a real-money purchase backend. The game only talks to the
## Store autoload, which talks to one of these.

var config: StoreConfig


func initialize(p_config: StoreConfig) -> void:
	config = p_config


func provider_name() -> String:
	return "none"


func ready() -> bool:
	return false


## Localised price text from the store, or "" if unknown.
func price_text(_product_id: String) -> String:
	return ""


## Start a purchase; call done(ok: bool) when it finishes.
func purchase(_product_id: String, done: Callable) -> void:
	done.call(false)


## Product ids the player already owns (non-consumables), for restore.
func owned_products(done: Callable) -> void:
	done.call([])
