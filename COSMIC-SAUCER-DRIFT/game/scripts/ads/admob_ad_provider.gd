class_name AdMobAdProvider
extends AdProvider
## Template for Google AdMob. Inactive until an AdMob Android plugin is
## added to the project (see docs/ADS_PLAN.md). It only talks to the plugin
## through Engine.get_singleton, so the game builds and runs without it.
##
## The method names below follow the common Godot AdMob plugins; check them
## against the plugin version you install and adjust here only - the rest of
## the game talks to the Ads autoload and never changes.

const SINGLETON := "PoingGodotAdMob"

var _plugin: Object = null
var _rewarded_cb := Callable()
var _inter_cb := Callable()


func provider_name() -> String:
	return "admob"


func initialize(p_config: AdsConfig) -> void:
	super.initialize(p_config)
	if Engine.has_singleton(SINGLETON):
		_plugin = Engine.get_singleton(SINGLETON)


func available() -> bool:
	return _plugin != null


func request_consent(done: Callable) -> void:
	if not available():
		done.call(false)
		return
	# Plug the UMP consent form in here, then load ads if allowed.
	done.call(true)


func is_rewarded_ready(_placement: String) -> bool:
	return available() and _plugin.has_method("is_rewarded_loaded") and _plugin.call("is_rewarded_loaded")


func show_rewarded(_placement: String, done: Callable) -> void:
	if not is_rewarded_ready(_placement):
		done.call(false)
		return
	_rewarded_cb = done
	_plugin.call("show_rewarded")


func is_interstitial_ready() -> bool:
	return available() and _plugin.has_method("is_interstitial_loaded") and _plugin.call("is_interstitial_loaded")


func show_interstitial(done: Callable) -> void:
	if not is_interstitial_ready():
		done.call()
		return
	_inter_cb = done
	_plugin.call("show_interstitial")


## Wire these to the plugin's signals when you install it.
func on_rewarded_earned() -> void:
	if _rewarded_cb.is_valid():
		_rewarded_cb.call(true)
		_rewarded_cb = Callable()


func on_rewarded_closed_without_reward() -> void:
	if _rewarded_cb.is_valid():
		_rewarded_cb.call(false)
		_rewarded_cb = Callable()


func on_interstitial_closed() -> void:
	if _inter_cb.is_valid():
		_inter_cb.call()
		_inter_cb = Callable()
