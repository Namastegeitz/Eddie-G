class_name AdProvider
extends RefCounted
## Interface every ad network wrapper implements. The game only talks to the
## Ads autoload, which talks to one of these.

var config: AdsConfig


func initialize(p_config: AdsConfig) -> void:
	config = p_config


func provider_name() -> String:
	return "none"


## Ask for consent (GDPR/UMP) before loading ads; call done(can_show_ads).
func request_consent(done: Callable) -> void:
	done.call(false)


func is_rewarded_ready(_placement: String) -> bool:
	return false


## Show a rewarded ad; call done(granted: bool) when it closes.
func show_rewarded(_placement: String, done: Callable) -> void:
	done.call(false)


func is_interstitial_ready() -> bool:
	return false


## Show an interstitial; call done() when it closes (or straight away).
func show_interstitial(done: Callable) -> void:
	done.call()
