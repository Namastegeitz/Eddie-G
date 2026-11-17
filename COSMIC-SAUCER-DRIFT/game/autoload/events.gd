extends Node
## Game-event log with a hook for a future analytics / ad-campaign
## conversion provider (e.g. Firebase -> Google Ads app campaigns).
## v1 keeps the last events in memory only: nothing is stored or sent.

## Key events a campaign would optimise for are logged with these names:
## first_open, tutorial_complete, race_start, race_finish, cup_complete,
## unlock, purchase, achievement, daily_complete, ad_* (once ads are on).

var recent: Array = []
var provider: Object = null   # anything with send(name: String, params: Dictionary)
const KEEP := 200


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not Save.data.get("first_open_logged", false):
		Save.data["first_open_logged"] = true
		Save.mark()
		log_event("first_open", {})


func log_event(event_name: String, params: Dictionary) -> void:
	recent.append({"t": Time.get_unix_time_from_system(), "name": event_name, "params": params})
	if recent.size() > KEEP:
		recent.pop_front()
	if provider and provider.has_method("send"):
		provider.call("send", event_name, params)


func on_racer_event(_kind: String, _d: Dictionary) -> void:
	pass
