class_name StoreConfig
extends Resource
## Switches for the real-money store. v1 ships with enabled = false and
## provider = "none": no billing library, no purchases, nothing collected.
## Every premium craft can still be unlocked with Race Credits.
## See docs/STORE_PLAN.md before switching it on.

@export var enabled := false
## "none" | "debug" (fake purchase sheet, debug builds only) | "play_billing"
@export var provider := "none"
## Show the "Store" button on the home screen when enabled.
@export var show_store_button := true
