extends Node
## Analytics events: runs, deaths, purchases, unlocks, ads and the onboarding
## funnel. Events go to user://analytics.jsonl and an in-memory buffer; if
## canopy/analytics/endpoint is set they are also POSTed in batches. Swap
## the sender for Firebase/GameAnalytics by replacing `_send_batch`.

signal logged(event: Dictionary)

const LOG := "user://analytics.jsonl"
const FUNNEL := ["first_launch", "tutorial_start", "tutorial_complete", "first_run_end", "first_unlock",
	"first_store_view", "first_purchase"]

var session_id := ""
var buffer: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _http: HTTPRequest
var _endpoint := ""
var _flush_timer := 0.0


func _ready() -> void:
	session_id = "%x%x" % [int(Time.get_unix_time_from_system()), randi()]
	_endpoint = String(ProjectSettings.get_setting("canopy/analytics/endpoint", ""))
	if _endpoint != "":
		_http = HTTPRequest.new()
		add_child(_http)
	if Save.data.get("stats", {}).get("runs", 0) == 0 and not Save.flag("funnel_first_launch"):
		funnel("first_launch")
	event("session_start", {"platform": OS.get_name(), "version": ProjectSettings.get_setting("application/config/version")})


func _process(delta: float) -> void:
	if _endpoint == "" or _pending.is_empty():
		return
	_flush_timer -= delta
	if _flush_timer <= 0.0:
		_flush_timer = 20.0
		_send_batch()


func event(name: String, props: Dictionary = {}) -> void:
	var e := {"name": name, "t": int(Time.get_unix_time_from_system()), "session": session_id, "props": props}
	buffer.append(e)
	if buffer.size() > 300:
		buffer.pop_front()
	_pending.append(e)
	var f: FileAccess
	if FileAccess.file_exists(LOG):
		f = FileAccess.open(LOG, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(LOG, FileAccess.WRITE)
	if f:
		f.store_line(JSON.stringify(e))
		f.close()
	logged.emit(e)


## One-time funnel steps ("first_unlock" etc.), each logged once per install.
func funnel(step: String, props: Dictionary = {}) -> void:
	var key := "funnel_" + step
	if Save.flag(key):
		return
	Save.set_flag(key)
	var p := props.duplicate()
	p["step"] = step
	p["index"] = FUNNEL.find(step)
	event("funnel", p)


func count(name: String) -> int:
	var n := 0
	for e in buffer:
		if e.name == name:
			n += 1
	return n


func _send_batch() -> void:
	if _http == null or _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var batch := _pending.duplicate()
	_pending.clear()
	var err := _http.request(_endpoint, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"events": batch}))
	if err != OK:
		_pending = batch + _pending
