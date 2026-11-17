extends Node
## Ads-ready layer. The game asks this autoload whether it may offer an ad
## and asks it to show one; which network (if any) sits behind it is set in
## resources/ads_config.tres. v1: enabled = false -> every check returns false,
## no ad buttons appear, interstitials are skipped, nothing touches the network.
##
## Placements wired into the game:
##   double_credits  rewarded, results screen: double this race's Race Credits
##   free_item        rewarded, before a race: start holding a random item
##   cup_interstitial interstitial between cup races (capped, never mid-race)

signal rewarded_finished(placement: String, granted: bool)

var config: AdsConfig
var provider: AdProvider
var consent_ok := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	config = load("res://resources/ads_config.tres")
	match config.provider:
		"debug":
			var d := DebugAdProvider.new()
			d.host = self
			provider = d
		"admob":
			provider = AdMobAdProvider.new()
		_:
			provider = AdProvider.new()
	provider.initialize(config)
	if enabled():
		if config.require_consent:
			provider.request_consent(func(ok: bool) -> void: consent_ok = ok)
		else:
			consent_ok = true


func enabled() -> bool:
	return config.enabled and config.provider != "none" and not removed()


## True once the player owns "remove ads" (future in-app purchase).
func removed() -> bool:
	return bool(Save.data.ads.get("removed", false))


func set_removed(v: bool) -> void:
	Save.data.ads.removed = v
	Save.mark()


func can_offer(placement: String) -> bool:
	return enabled() and consent_ok and placement in config.rewarded_placements and provider.is_rewarded_ready(placement)


func show_rewarded(placement: String, done: Callable) -> void:
	if not can_offer(placement):
		done.call(false)
		return
	Events.log_event("ad_rewarded_start", {"placement": placement})
	provider.show_rewarded(placement, func(granted: bool) -> void:
		Events.log_event("ad_rewarded_end", {"placement": placement, "granted": granted})
		emit_signal("rewarded_finished", placement, granted)
		done.call(granted))


## Between cup races only. Calls then() straight away when no ad is due.
func maybe_interstitial(where: String, then: Callable) -> void:
	var a: Dictionary = Save.data.ads
	var due := enabled() and consent_ok and config.interstitial_between_cup_races and where == "cup_interstitial" \
		and int(a.sessions) >= config.min_sessions_before_interstitial \
		and int(a.races) >= config.min_races_before_interstitial \
		and int(a.since_interstitial) >= config.races_between_interstitials \
		and provider.is_interstitial_ready()
	a.since_interstitial = int(a.since_interstitial) + 1
	if not due:
		then.call()
		return
	a.since_interstitial = 0
	Save.mark()
	Events.log_event("ad_interstitial", {"where": where})
	provider.show_interstitial(then)
