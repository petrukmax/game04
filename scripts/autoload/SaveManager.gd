extends Node
## Versioned, validated local JSON save. Corrupt or partial data never blocks play.

const SAVE_PATH := "user://mars_arachnid_save.json"
const SAVE_VERSION := 2

var last_error: String = ""


func _default_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"unlocked_level": 1,
		"completed": {},
		"best_stars": {},
		"total_credits": 0,
		"total_kills": 0,
		"total_levels": 0,
		"campaign_started": false,
		"settings": {
			"master_volume": 0.8,
			"sfx_volume": 0.85,
			"music_volume": 0.5,
			"muted": false,
			"screen_shake": true,
			"colorblind": false,
			"speed": 1,
		},
	}


func load_payload() -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_payload()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_error = "Save file could not be opened. Defaults loaded."
		return _default_payload()
	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Save file was unreadable. Defaults loaded."
		_quarantine_bad_save()
		return _default_payload()
	return _validate(parsed)


func save_payload(payload: Dictionary) -> bool:
	var data := _validate(payload)
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_error = "Save file could not be written."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	last_error = ""


func _validate(data: Dictionary) -> Dictionary:
	var base := _default_payload()
	var out := base.duplicate(true)
	var version := int(data.get("version", 0))
	if version <= 0 or version > SAVE_VERSION:
		last_error = "Save version was unsupported; safe defaults were used."
	out["version"] = SAVE_VERSION
	out["unlocked_level"] = clampi(int(data.get("unlocked_level", 1)), 1, 15)
	out["campaign_started"] = GameConfig.as_bool(data.get("campaign_started", false))
	out["total_credits"] = maxi(0, int(data.get("total_credits", 0)))
	out["total_kills"] = maxi(0, int(data.get("total_kills", 0)))
	out["total_levels"] = maxi(0, int(data.get("total_levels", 0)))

	var completed: Dictionary = {}
	var raw_completed: Variant = data.get("completed", {})
	if typeof(raw_completed) == TYPE_DICTIONARY:
		for key in raw_completed.keys():
			var idx := int(key)
			if idx >= 1 and idx <= 15 and GameConfig.as_bool(raw_completed[key]):
				completed[str(idx)] = true
	out["completed"] = completed

	var best: Dictionary = {}
	var raw_best: Variant = data.get("best_stars", {})
	if typeof(raw_best) == TYPE_DICTIONARY:
		for key in raw_best.keys():
			var idx := int(key)
			if idx >= 1 and idx <= 15:
				var stars := clampi(int(raw_best[key]), 0, 3)
				if stars > 0:
					best[str(idx)] = stars
	out["best_stars"] = best

	var raw_settings: Variant = data.get("settings", {})
	if typeof(raw_settings) == TYPE_DICTIONARY:
		var s: Dictionary = out["settings"]
		s["master_volume"] = clampf(float(raw_settings.get("master_volume", 0.8)), 0.0, 1.0)
		s["sfx_volume"] = clampf(float(raw_settings.get("sfx_volume", 0.85)), 0.0, 1.0)
		s["music_volume"] = clampf(float(raw_settings.get("music_volume", 0.5)), 0.0, 1.0)
		s["muted"] = GameConfig.as_bool(raw_settings.get("muted", false))
		s["screen_shake"] = GameConfig.as_bool(raw_settings.get("screen_shake", true))
		s["colorblind"] = GameConfig.as_bool(raw_settings.get("colorblind", false))
		s["speed"] = clampi(int(raw_settings.get("speed", 1)), 1, 3)
		out["settings"] = s
	return out


func _quarantine_bad_save() -> void:
	var bad_path := SAVE_PATH + ".bad"
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(bad_path))
