extends Node
## Optional crash reporting (upgrade of 27 Nov 2026):
##  - Sentry, on every platform whose build includes the Sentry add-on
##    (addons/sentry, added by the release workflow), and
##  - Firebase Crashlytics on Android (addons/bugs_crashlytics adds it to the
##    Gradle build when config/google-services.json is present).
## Nothing is sent until the player says yes: the setting "crash_reports" is
## "ask" (the menu asks once), "on" or "off". No personal data is sent.
## Keys come from config/crash_reporting.cfg, which is never committed; a
## build without it (or without the add-ons) simply never reports.

const CONFIG_PATH := "res://config/crash_reporting.cfg"
const CRASHLYTICS_CLASS := "com.google.firebase.crashlytics.FirebaseCrashlytics"

var sentry_dsn := ""
var environment := "production"
var started := false
## Set true by tests to skip the native calls.
var dry_run := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_config(CONFIG_PATH)
	if consent() == "on":
		start()
	GameManager.state_changed.connect(_on_state_changed)


func load_config(path: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	sentry_dsn = String(cfg.get_value("sentry", "dsn", "")).strip_edges()
	environment = String(cfg.get_value("sentry", "environment", "production"))


func consent() -> String:
	return String(SaveSystem.get_setting("crash_reports", "ask"))


func has_sentry() -> bool:
	return sentry_dsn != "" and Engine.has_singleton("SentrySDK")


## The Crashlytics export plugin tags builds it went into.
func has_crashlytics() -> bool:
	return OS.has_feature("android") and OS.has_feature("crashlytics")


## Is there anything that could send a report in this build?
func available() -> bool:
	return has_sentry() or has_crashlytics()


## Should the menu ask the one-time question?
func should_ask() -> bool:
	return available() and consent() == "ask"


func set_consent(yes: bool) -> void:
	SaveSystem.set_setting("crash_reports", "on" if yes else "off")
	SaveSystem.save_game()
	if yes:
		start()
	else:
		stop()


func release_name() -> String:
	return "bugs-eye-view@%s+%s" % [ProjectSettings.get_setting("application/config/version", "1.0.0"), build_number()]


## The store build number (Android version code / iOS build), kept in
## project settings by tools/release/bump_version.py.
func build_number() -> String:
	return str(ProjectSettings.get_setting("application/config/build_number", 1))


func start() -> void:
	if started or dry_run:
		started = started or dry_run
		return
	if has_sentry():
		var sdk := Engine.get_singleton("SentrySDK")
		sdk.call("init", func(options: Object) -> void:
			options.set("dsn", sentry_dsn)
			options.set("release", release_name())
			options.set("environment", environment)
			options.set("send_default_pii", false)
			options.set("attach_screenshot", false)
			options.set("attach_scene_tree", false))
	if has_crashlytics():
		_crashlytics_call("setCrashlyticsCollectionEnabled", [true])
	started = true


func stop() -> void:
	if not started:
		return
	started = false
	if dry_run:
		return
	if has_sentry():
		Engine.get_singleton("SentrySDK").call("close")
	if has_crashlytics():
		_crashlytics_call("setCrashlyticsCollectionEnabled", [false])


## A harmless test event, so you can see reports arrive (Settings button).
## Returns what was sent to, for the button's message.
func send_test_report() -> String:
	if not started:
		return "Crash reports are off."
	var sent: PackedStringArray = []
	if has_sentry():
		Engine.get_singleton("SentrySDK").call("capture_message", "Test report from Settings (%s)" % release_name())
		sent.append("Sentry")
	if has_crashlytics():
		_crashlytics_call("log", ["Test report from Settings"])
		_crashlytics_call("sendUnsentReports", [])
		sent.append("Crashlytics")
	return ("Test report sent to " + " and ".join(sent) + ".") if not sent.is_empty() else "No crash reporter in this build."


## Tag reports with where the player was, so a crash can be reproduced.
func _on_state_changed(state: int) -> void:
	if not started or dry_run or state != GameManager.State.PLAYING:
		return
	var where := {"level": String(GameManager.current_level), "bug": String(GameManager.current_bug)}
	for k: String in where:
		if has_sentry():
			Engine.get_singleton("SentrySDK").call("set_tag", k, where[k])
		if has_crashlytics():
			_crashlytics_call("setCustomKey", [k, where[k]])


func _crashlytics_call(method: String, args: Array) -> void:
	if not Engine.has_singleton("JavaClassWrapper"):
		return
	var wrapper := Engine.get_singleton("JavaClassWrapper")
	var cls: Object = wrapper.call("wrap", CRASHLYTICS_CLASS)
	if cls == null:
		return
	var instance: Object = cls.call("getInstance")
	if instance:
		instance.callv(method, args)
