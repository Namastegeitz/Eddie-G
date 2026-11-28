class_name ReviewPrompt
extends RefCounted
## Asks for a store rating with Google Play's and Apple's own rating card
## (the In-app Review plugin by Godot Mobile Plugins, MIT, installed on the
## build machine by tools/install_review.sh; Android .aab and iOS only).
##
## Asked only at a happy moment: right after clearing a Journey level, never
## after a failed run, and only when
##   - the player has cleared at least MIN_CLEARED levels in all,
##   - the game was installed at least MIN_DAYS days ago,
##   - the last ask was at least GAP_DAYS days ago and there were fewer than MAX_ASKS,
##   - the remote switch "review_prompt" is on.
## The stores also limit how often the card really appears, and may show nothing.

const SINGLETON := "InappReviewPlugin"
const MIN_CLEARED := 5
const MIN_DAYS := 2
const GAP_DAYS := 120
const MAX_ASKS := 3


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


static func cleared_total() -> int:
	var n := 0
	for m in Content.playable_maps():
		n += Progress.stages_cleared(String(m))
	return n


## Whether to ask now, given the run that just ended.
static func due(stage_cleared: bool, mode: String, now_day := -1) -> bool:
	if not stage_cleared or mode != "journey" or not RemoteConfig.enabled("review_prompt"):
		return false
	var day := Progress.today() if now_day < 0 else now_day
	var created := int(Save.data.get("created", 0))
	var installed_days := int((Time.get_unix_time_from_system() - created) / 86400.0) if created > 0 else 999
	var asks := int(Save.data.prompts.get("review_asks", 0))
	var last := int(Save.data.prompts.get("review_day", -9999))
	return cleared_total() >= MIN_CLEARED and installed_days >= MIN_DAYS and asks < MAX_ASKS and day - last >= GAP_DAYS


## Prepare and show the store's card (nothing happens without the plugin).
static func ask() -> void:
	Save.data.prompts["review_day"] = Progress.today()
	Save.data.prompts["review_asks"] = int(Save.data.prompts.get("review_asks", 0)) + 1
	Save.mark()
	Analytics.event("review_prompt", {"asks": int(Save.data.prompts.review_asks), "cleared": cleared_total()})
	if not available():
		return
	var plugin: Object = Engine.get_singleton(SINGLETON)
	if plugin.has_signal("review_info_generated") and not plugin.is_connected("review_info_generated", _launch):
		plugin.connect("review_info_generated", _launch, CONNECT_ONE_SHOT)
	plugin.call("generate_review_info")


static func _launch() -> void:
	if available():
		Engine.get_singleton(SINGLETON).call("launch_review_flow")
