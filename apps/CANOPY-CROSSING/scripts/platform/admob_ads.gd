extends Node
## AdMob adapter for the Ads autoload. Expects an AdMob Godot plugin that
## exposes a singleton named "AdMob" (e.g. godot-admob-android/ios). Not
## exercised in the sandbox build; ad unit ids go in docs/STORE.md's
## checklist. Rewarded and interstitial only, both shown between runs.

const REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"      # Google's public test unit
const INTERSTITIAL_UNIT := "ca-app-pub-3940256099942544/1033173712"  # Google's public test unit

var _ads: Object = null
var _done: Callable


func _ready() -> void:
	if Engine.has_singleton("AdMob"):
		_ads = Engine.get_singleton("AdMob")
		_ads.connect("rewarded_ad_user_earned_reward", func(_a, _b): _finish(true))
		_ads.connect("rewarded_ad_dismissed_full_screen_content", func(_a): _finish(false))
		_ads.connect("interstitial_ad_dismissed_full_screen_content", func(_a): _finish(true))
		_ads.initialize()
		_ads.load_rewarded_ad(REWARDED_UNIT)
		_ads.load_interstitial_ad(INTERSTITIAL_UNIT)


func available() -> bool:
	return _ads != null


func show(kind: String, done: Callable) -> void:
	_done = done
	if kind == "rewarded":
		_ads.show_rewarded_ad()
	else:
		_ads.show_interstitial_ad()


func _finish(ok: bool) -> void:
	if _done.is_valid():
		var d := _done
		_done = Callable()
		d.call(ok)
	_ads.load_rewarded_ad(REWARDED_UNIT)
	_ads.load_interstitial_ad(INTERSTITIAL_UNIT)
