extends Node
## Crash reporting (autoload "Crash"): Sentry on desktop and phones, Firebase
## Crashlytics on Android and iOS, both free plans. Strictly opt-in:
## - the SDKs only exist in builds made after tools/crash/install_crash_sdks.sh
##   (CI does this; this cloud computer can't download them);
## - Sentry needs a DSN in content/crash_reporting.json, Firebase needs its
##   google-services.json / GoogleService-Info.plist in the export;
## - and the player must say yes (first-run question or Settings).
## With any of those missing every call here does nothing.

const CONFIG := "res://content/crash_reporting.json"
const SENTRY := "SentrySDK"
const FB_CORE := "GodotxFirebaseCore"
const FB_CRASH := "GodotxFirebaseCrashlytics"

var cfg := {}
var sentry_on := false
var firebase_on := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cfg = {"sentry": {"dsn": "", "environment": "production", "sample_rate": 1.0, "attach_log": false},
		"firebase": {"enabled": true}, "ask_players": true}
	if FileAccess.file_exists(CONFIG):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
		if d is Dictionary:
			cfg.merge(d, true)
	apply_consent()


## Something here could send reports (an SDK is in this build and set up).
func available() -> bool:
	return _sentry_ready() or _firebase_ready()


func _sentry_ready() -> bool:
	return Engine.has_singleton(SENTRY) and String(cfg.sentry.get("dsn", "")) != ""


func _firebase_ready() -> bool:
	return bool(cfg.firebase.get("enabled", true)) and Engine.has_singleton(FB_CRASH)


## "ask" (not answered yet: nothing is sent), "on" or "off".
func consent() -> String:
	return String(Save.setting("crash_reports"))


## Should the game show the one-time question now?
func should_ask() -> bool:
	return available() and bool(cfg.get("ask_players", true)) and consent() == "ask"


func set_consent(on: bool) -> void:
	Save.set_setting("crash_reports", "on" if on else "off")
	apply_consent()


## Start or stop both SDKs to match the player's choice.
func apply_consent() -> void:
	var on := consent() == "on"
	if _sentry_ready():
		var s: Object = Engine.get_singleton(SENTRY)
		if on and not sentry_on:
			s.call("init", _configure_sentry)
			sentry_on = true
		elif not on and sentry_on:
			s.call("close")
			sentry_on = false
	# Crashlytics keeps its on/off switch across launches, so "off" is sent
	# every start; "ask" touches nothing (the build's default is off). Firebase
	# itself must be started first or the Android plugin throws.
	if _firebase_ready() and (on or firebase_on or consent() == "off"):
		var fc: Object = Engine.get_singleton(FB_CRASH)
		if Engine.has_singleton(FB_CORE):
			Engine.get_singleton(FB_CORE).call("initialize")
		if on and not firebase_on:
			fc.call("initialize")
		fc.call("set_crashlytics_collection_enabled", on)
		firebase_on = on


func _configure_sentry(o: Object) -> void:
	var sc: Dictionary = cfg.sentry
	o.set("dsn", String(sc.get("dsn", "")))
	o.set("environment", String(sc.get("environment", "production")))
	o.set("release", "cosmic-saucer-drift@%s" % String(ProjectSettings.get_setting("application/config/version", "1.0.0")))
	o.set("sample_rate", float(sc.get("sample_rate", 1.0)))
	o.set("attach_log", bool(sc.get("attach_log", false)))
	o.set("send_default_pii", false)
	o.set("debug", false)


## A short note that rides along with the next crash report (no personal data).
func breadcrumb(text: String) -> void:
	if sentry_on and Engine.has_singleton(SENTRY) and ClassDB.class_exists("SentryBreadcrumb"):
		var crumb: Variant = ClassDB.class_call_static("SentryBreadcrumb", "create", text)
		Engine.get_singleton(SENTRY).call("add_breadcrumb", crumb)
	if firebase_on and Engine.has_singleton(FB_CRASH):
		Engine.get_singleton(FB_CRASH).call("log_message", text)
