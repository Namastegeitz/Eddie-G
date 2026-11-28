@tool
extends EditorPlugin
## Adds the CanopyCrashlytics Android library (and Firebase Crashlytics) to
## Gradle-built Android exports (the Google Play .aab). It does nothing for
## other platforms, for the plain APK export, or when the library hasn't been
## built (tools/build_crashlytics.sh, run by the release workflow when the
## Firebase config is set). See docs/CRASH_REPORTING.md.

var _export: CrashlyticsExport


func _enter_tree() -> void:
	_export = CrashlyticsExport.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class CrashlyticsExport extends EditorExportPlugin:
	const NAME := "CanopyCrashlytics"
	const AAR := "canopy_crashlytics/bin/CanopyCrashlytics-release.aar"   # under res://addons/
	const CRASHLYTICS := "21.1.0"

	func _get_name() -> String:
		return NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _active() -> bool:
		if not FileAccess.file_exists("res://addons/" + AAR):
			return false
		return bool(get_option("gradle_build/use_gradle_build"))

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([AAR]) if _active() else PackedStringArray()

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not _active():
			return PackedStringArray()
		return PackedStringArray([
			"com.google.firebase:firebase-crashlytics:" + CRASHLYTICS,
			"com.google.firebase:firebase-crashlytics-ndk:" + CRASHLYTICS,
		])
