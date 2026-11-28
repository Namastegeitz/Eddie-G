@tool
extends EditorExportPlugin
## Firebase Crashlytics for the Android Gradle build, without Google's Gradle
## plugins: the Firebase values from config/google-services.json are written
## as Android string resources, the Crashlytics libraries are added as Gradle
## dependencies, and collection is off until CrashReporter turns it on after
## the player agrees. Without the JSON file nothing is added at all (no
## Firebase, no INTERNET permission).

const JSON_PATH := "res://config/google-services.json"
const CRASHLYTICS := "com.google.firebase:firebase-crashlytics-ndk:21.1.0"
const FirebaseValues := preload("res://addons/bugs_crashlytics/firebase_values.gd")
const VALUES_FILE := "res://android/build/res/values/bugs_firebase_values.xml"


func _get_name() -> String:
	return "BugsEyeViewCrashlytics"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _enabled() -> bool:
	return FileAccess.file_exists(JSON_PATH)


func _get_export_features(platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray(["crashlytics"]) if _supports_platform(platform) and _enabled() else PackedStringArray()


func _get_android_dependencies(platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	return PackedStringArray([CRASHLYTICS]) if _supports_platform(platform) and _enabled() else PackedStringArray()


func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, _debug: bool) -> String:
	if not (_supports_platform(platform) and _enabled()):
		return ""
	# Off until the player says yes; no build ID (Google's Gradle plugin isn't used).
	return "\n".join([
		'<meta-data android:name="firebase_crashlytics_collection_enabled" android:value="false" />',
		'<meta-data android:name="com.google.firebase.crashlytics.RequireBuildId" android:value="false" />',
		'<meta-data android:name="firebase_analytics_collection_deactivated" android:value="true" />',
	])


func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	if not features.has("android"):
		return
	if FileAccess.file_exists(VALUES_FILE):
		DirAccess.remove_absolute(VALUES_FILE)
	if not _enabled():
		print("Crashlytics: config/google-services.json not found - building without Crashlytics.")
		return
	var package := String(get_option("package/unique_name"))
	var xml := FirebaseValues.values_xml(FileAccess.get_file_as_string(JSON_PATH), package)
	if xml == "":
		push_error("Crashlytics: config/google-services.json has no Android app for package %s." % package)
		return
	DirAccess.make_dir_recursive_absolute(VALUES_FILE.get_base_dir())
	var f := FileAccess.open(VALUES_FILE, FileAccess.WRITE)
	f.store_string(xml)
	f.close()
	print("Crashlytics: added for ", package)
