extends Node
## Crash and error reporting, sent to two free services when they are set up:
##
##   Sentry                (every platform; the official Sentry SDK for Godot,
##                          installed by the build machine when SENTRY_DSN is set)
##   Firebase Crashlytics  (Android, iOS; the CanopyCrashlytics plugin, built
##                          into the app when the Firebase config files are set)
##
## Without either, this does nothing at all, so local and test builds behave
## exactly as before. See docs/CRASH_REPORTING.md for how to switch them on.
##
## Privacy: reports carry the game version, platform, device model, graphics
## level and what the player was doing (screen, jungle, level, view), never a
## name, account, email, advertising id or IP address. The player can turn
## reports off in Settings > Send crash reports (on by default), and the
## choice reaches both services at once.

const MAX_ERRORS := 25            # script errors forwarded per session (the rest are counted only)
const CRUMBS := 40                # recent steps kept for the next report

var sentry: Object = null         # the SentrySDK singleton, when installed and configured
var crashlytics: Object = null    # the CanopyCrashlytics plugin singleton (Android / iOS)
var crumbs: Array[String] = []    # recent steps, newest last (also what a report shows)
var errors_seen := 0
var errors_sent := 0
var _seen: Dictionary = {}        # error text -> times, so one error repeating doesn't flood
var _queue: Array[Dictionary] = []
var _lock := Mutex.new()
var _logger: ErrorForwarder = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("SentrySDK"):
		sentry = Engine.get_singleton("SentrySDK")
		# the build turns Sentry's auto-start off (tools/install_sentry.sh), so it
		# starts here, and only if the player allows crash reports
		if allowed() and sentry.has_method("is_enabled") and not sentry.call("is_enabled"):
			sentry.call("init", _configure_sentry)
	if Engine.has_singleton("CanopyCrashlytics"):
		crashlytics = Engine.get_singleton("CanopyCrashlytics")
	apply_consent()
	set_context("version", String(ProjectSettings.get_setting("application/config/version", "")))
	set_context("platform", OS.get_name())
	set_context("device", OS.get_model_name())
	set_context("graphics", Gfx.level())
	if active():
		# Sentry reads the engine's errors itself; Crashlytics gets them from here
		_logger = ErrorForwarder.new()
		_logger.owner_ref = weakref(self)
		OS.add_logger(_logger)
	if Analytics.has_signal("logged"):
		Analytics.logged.connect(_on_event)
	Save.changed.connect(apply_consent)


func _exit_tree() -> void:
	if _logger != null:
		OS.remove_logger(_logger)
		_logger = null


## True when at least one service is installed and the player allows reports.
func active() -> bool:
	return (sentry != null or crashlytics != null) and allowed()


func allowed() -> bool:
	return bool(Save.setting("crash_reports", true)) and RemoteConfig.enabled("crash_reports")


## Pass the player's Settings choice to both services. Crashlytics stores it;
## Sentry checks it before every report (_sentry_before_send), and starts on
## the next launch if reports were off when the game started.
func apply_consent() -> void:
	if crashlytics != null and crashlytics.has_method("setCollectionEnabled"):
		crashlytics.call("setCollectionEnabled", allowed())


## Sentry's options: no personal data, no screenshots or scene dumps, the
## game's version as the release, and the Settings switch checked last.
func _configure_sentry(options: Object) -> void:
	var version := String(ProjectSettings.get_setting("application/config/version", "0"))
	var build := String(ProjectSettings.get_setting("canopy/build_number", ""))
	options.set("release", "canopy-crossing@" + version + ("+" + build if build != "" else ""))
	options.set("environment", "debug" if OS.is_debug_build() else "production")
	options.set("send_default_pii", false)
	options.set("attach_screenshot", false)
	options.set("attach_scene_tree", false)
	options.set("traces_sample_rate", 0.0)
	options.set("before_send", _sentry_before_send)


func _sentry_before_send(event: Object) -> Object:
	return event if allowed() else null


## Something the player just did, kept for the next report ("screen: store").
func breadcrumb(category: String, message: String) -> void:
	var line := "%s: %s" % [category, message]
	crumbs.append(line)
	if crumbs.size() > CRUMBS:
		crumbs.remove_at(0)
	if not active():
		return
	if crashlytics != null:
		crashlytics.call("log", line)
	if sentry != null and sentry.has_method("add_breadcrumb"):
		_sentry_breadcrumb(category, message)


## A fact about the current session that every report should carry.
func set_context(key: String, value: String) -> void:
	if crashlytics != null:
		crashlytics.call("setKey", key, value)
	if sentry != null and sentry.has_method("set_tag"):
		sentry.call("set_tag", key, value)


## A handled problem worth knowing about (a failed download, a bad save file).
func report(message: String, details := "") -> void:
	if not active():
		return
	if crashlytics != null:
		crashlytics.call("recordError", message, details + "\n" + "\n".join(crumbs.slice(-12)))
	if sentry != null and sentry.has_method("capture_message"):
		sentry.call("capture_message", message + ("\n" + details if details != "" else ""), 2)


func _sentry_breadcrumb(category: String, message: String) -> void:
	# The Sentry SDK's breadcrumb API takes a SentryBreadcrumb object; build one
	# if the class is there, otherwise skip (never fail the game over a report).
	if not ClassDB.class_exists("SentryBreadcrumb"):
		return
	var b: Object = ClassDB.class_call_static("SentryBreadcrumb", "create", message)
	if b == null:
		return
	b.set("category", category)
	sentry.call("add_breadcrumb", b)


func _on_event(e: Dictionary) -> void:
	var name := String(e.get("name", ""))
	var props: Dictionary = e.get("props", {})
	if name in ["run_start", "run_end", "death", "purchase", "purchase_failed", "restore", "unlock", "view", "screen", "dlc_download", "ad_shown", "settings_graphics"]:
		var bits: Array[String] = []
		for k in props:
			if k in ["map", "stage", "mode", "view", "to", "product", "cause", "screen", "name", "ok", "level", "quality", "rows"]:
				bits.append("%s=%s" % [k, str(props[k])])
		breadcrumb(name, " ".join(bits))
	if name == "run_start":
		set_context("map", str(props.get("map", "")))
		set_context("level", str(int(props.get("stage", 0)) + 1))
	elif name == "screen":
		set_context("screen", str(props.get("name", props.get("screen", ""))))
	elif name == "settings_graphics":
		set_context("graphics", Gfx.level())


## Script errors arrive from the engine on any thread; they are queued here
## and sent from the main thread.
func _queue_error(message: String, where: String, trace: String) -> void:
	_lock.lock()
	errors_seen += 1
	var n := int(_seen.get(message, 0)) + 1
	_seen[message] = n
	if n == 1 and errors_sent + _queue.size() < MAX_ERRORS:
		_queue.append({"message": message, "where": where, "trace": trace})
	_lock.unlock()


func _process(_dt: float) -> void:
	if _queue.is_empty():
		return
	_lock.lock()
	var batch := _queue.duplicate()
	_queue.clear()
	_lock.unlock()
	for q in batch:
		errors_sent += 1
		if crashlytics != null and allowed():
			crashlytics.call("recordError", String(q.message), "%s\n%s\n%s" % [q.where, q.trace, "\n".join(crumbs.slice(-12))])


## Hands the engine's error messages to CrashReport (Godot 4.5+ Logger).
class ErrorForwarder extends Logger:
	var owner_ref: WeakRef

	func _log_error(function: String, file: String, line: int, _code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		var cr = owner_ref.get_ref() if owner_ref != null else null
		if cr == null:
			return
		var trace := ""
		for bt in script_backtraces:
			trace += bt.format()
		cr._queue_error(rationale if rationale != "" else function, "%s:%d in %s" % [file, line, function], trace)

	func _log_message(_message: String, _error: bool) -> void:
		pass
