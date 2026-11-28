extends RefCounted
## Pure helper (no editor classes) so tests can check it.

## The Android string resources Firebase reads at start-up, built from a
## google-services.json (what Google's google-services Gradle plugin makes).
static func values_xml(json_text: String, package: String) -> String:
	var json := JSON.new()
	if json.parse(json_text) != OK or not (json.data is Dictionary):
		return ""
	var d: Dictionary = json.data
	var info: Dictionary = d.get("project_info", {})
	for client: Dictionary in d.get("client", []):
		var ci: Dictionary = client.get("client_info", {})
		if String(ci.get("android_client_info", {}).get("package_name", "")) != package:
			continue
		var keys: Array = client.get("api_key", [])
		var api_key := String((keys[0] as Dictionary).get("current_key", "")) if keys.size() > 0 else ""
		var values := {
			"google_app_id": String(ci.get("mobilesdk_app_id", "")),
			"gcm_defaultSenderId": String(info.get("project_number", "")),
			"project_id": String(info.get("project_id", "")),
			"google_storage_bucket": String(info.get("storage_bucket", "")),
			"google_api_key": api_key,
			"google_crash_reporting_api_key": api_key,
		}
		if values["google_app_id"] == "" or api_key == "":
			return ""
		var lines := PackedStringArray(['<?xml version="1.0" encoding="utf-8"?>', "<resources>"])
		for k: String in values:
			if values[k] != "":
				lines.append('    <string name="%s" translatable="false">%s</string>' % [k, String(values[k]).xml_escape()])
		lines.append("</resources>")
		return "\n".join(lines) + "\n"
	return ""
