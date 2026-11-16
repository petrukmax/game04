extends Node
## Campaign state, unlocks, settings and scene transitions.

const LEVEL_SCENES: Array[String] = [
	"res://scenes/level/Level_01.tscn",
	"res://scenes/level/Level_02.tscn",
	"res://scenes/level/Level_03.tscn",
	"res://scenes/level/Level_04.tscn",
	"res://scenes/level/Level_05.tscn",
	"res://scenes/level/Level_06.tscn",
	"res://scenes/level/Level_07.tscn",
	"res://scenes/level/Level_08.tscn",
	"res://scenes/level/Level_09.tscn",
	"res://scenes/level/Level_10.tscn",
	"res://scenes/level/Level_11.tscn",
	"res://scenes/level/Level_12.tscn",
	"res://scenes/level/Level_13.tscn",
	"res://scenes/level/Level_14.tscn",
	"res://scenes/level/Level_15.tscn",
]

const LEVEL_DATA_PATHS: Array[String] = [
	"res://resources/levels/level_01.tres",
	"res://resources/levels/level_02.tres",
	"res://resources/levels/level_03.tres",
	"res://resources/levels/level_04.tres",
	"res://resources/levels/level_05.tres",
	"res://resources/levels/level_06.tres",
	"res://resources/levels/level_07.tres",
	"res://resources/levels/level_08.tres",
	"res://resources/levels/level_09.tres",
	"res://resources/levels/level_10.tres",
	"res://resources/levels/level_11.tres",
	"res://resources/levels/level_12.tres",
	"res://resources/levels/level_13.tres",
	"res://resources/levels/level_14.tres",
	"res://resources/levels/level_15.tres",
]

var unlocked_level: int = 1
var completed: Dictionary = {}
var best_stars: Dictionary = {}
var total_credits: int = 0
var total_kills: int = 0
var total_levels: int = 0
var campaign_started: bool = false
var settings: Dictionary = {}
var current_level_index: int = 0
var last_result: Dictionary = {}
var selected_level_for_briefing: int = 0
## Snapshot of the run at the end of the last cleared wave (towers, credits,
## statistics). It lives only in memory: the defeat screen uses it to offer a
## retry that skips the waves the player already survived.
var wave_checkpoint: Dictionary = {}
## One-shot flag: set only when the player explicitly retries from a checkpoint.
## LevelBase consumes it in _ready, so a normal fresh level never restores old
## state (for example after restarting a sector or entering another one).
var wave_checkpoint_pending: bool = false


func _ready() -> void:
	load_from_disk()
	call_deferred("_apply_audio_settings")


func load_from_disk() -> void:
	var payload := SaveManager.load_payload()
	unlocked_level = int(payload.get("unlocked_level", 1))
	completed = payload.get("completed", {}).duplicate(true)
	best_stars = payload.get("best_stars", {}).duplicate(true)
	total_credits = int(payload.get("total_credits", 0))
	total_kills = int(payload.get("total_kills", 0))
	total_levels = int(payload.get("total_levels", 0))
	campaign_started = GameConfig.as_bool(payload.get("campaign_started", false))
	settings = payload.get("settings", {}).duplicate(true)
	if SaveManager.last_error != "":
		# Loc is registered after GameState, so during the very first boot the
		# autoload may not exist yet. Fall back to the raw message in that case.
		var message := SaveManager.last_error
		if has_node("/root/Loc"):
			message = get_node("/root/Loc").call("t", message)
		EventBus.notification.emit(message, GameConfig.WARNING_RED)


func save_to_disk() -> void:
	var payload := {
		"version": SaveManager.SAVE_VERSION,
		"unlocked_level": unlocked_level,
		"completed": completed,
		"best_stars": best_stars,
		"total_credits": total_credits,
		"total_kills": total_kills,
		"total_levels": total_levels,
		"campaign_started": campaign_started,
		"settings": settings,
	}
	SaveManager.save_payload(payload)


func _apply_audio_settings() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").refresh_from_settings(settings)


func is_level_unlocked(index: int) -> bool:
	return index + 1 <= unlocked_level


func level_stars(index: int) -> int:
	return int(best_stars.get(str(index + 1), 0))


func level_is_completed(index: int) -> bool:
	return GameConfig.as_bool(completed.get(str(index + 1), false))


func start_level(index: int) -> void:
	if index < 0 or index >= LEVEL_SCENES.size():
		return
	current_level_index = index
	last_result = {}
	clear_wave_checkpoint()
	campaign_started = true
	get_tree().paused = false
	Engine.time_scale = 1.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").stop_all_sfx()
	get_tree().change_scene_to_file(LEVEL_SCENES[index])


func restart_level() -> void:
	last_result = {}
	clear_wave_checkpoint()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


## Stores a snapshot of the run at the end of a cleared wave. The player can
## return to it from the defeat screen without losing the whole sector.
func store_wave_checkpoint(snapshot: Dictionary) -> void:
	wave_checkpoint = snapshot.duplicate(true)
	wave_checkpoint_pending = false


func has_wave_checkpoint() -> bool:
	return not wave_checkpoint.is_empty()


func clear_wave_checkpoint() -> void:
	wave_checkpoint.clear()
	wave_checkpoint_pending = false


## Reloads the active sector level; LevelBase restores the stored snapshot in
## _ready. Returns false when there is nothing to restore for this sector.
func resume_wave_checkpoint() -> bool:
	if wave_checkpoint.is_empty():
		return false
	if int(wave_checkpoint.get("level_index", -1)) != current_level_index:
		return false
	wave_checkpoint_pending = true
	last_result = {}
	get_tree().paused = false
	Engine.time_scale = 1.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").stop_all_sfx()
	get_tree().reload_current_scene()
	return true


func goto_main_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	last_result = {}
	clear_wave_checkpoint()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").stop_all_sfx()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")


func goto_level_select() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	last_result = {}
	clear_wave_checkpoint()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").stop_all_sfx()
	get_tree().change_scene_to_file("res://scenes/main/LevelSelect.tscn")


func next_level() -> void:
	var next_index := current_level_index + 1
	if next_index < LEVEL_SCENES.size():
		start_level(next_index)
	else:
		goto_level_select()


func complete_level(stars: int, stats: Dictionary) -> Dictionary:
	var number := current_level_index + 1
	var was_completed := GameConfig.as_bool(completed.get(str(number), false))
	completed[str(number)] = true
	var previous := level_stars(current_level_index)
	best_stars[str(number)] = maxi(previous, stars)
	unlocked_level = maxi(unlocked_level, mini(15, number + 1))
	total_credits += maxi(0, int(stats.get("credits_earned", 0)))
	total_kills += maxi(0, int(stats.get("kills", 0)))
	if not was_completed:
		total_levels += 1
	var unlocked_next := number < 15 and unlocked_level >= number + 1
	last_result = {
		"level_index": current_level_index,
		"level_number": number,
		"stars": stars,
		"stats": stats.duplicate(true),
		"unlocked_next": unlocked_next,
		"campaign_complete": number == 15,
	}
	clear_wave_checkpoint()
	save_to_disk()
	EventBus.level_completed.emit(stars)
	return last_result


func record_failure(stats: Dictionary) -> Dictionary:
	last_result = {
		"level_index": current_level_index,
		"level_number": current_level_index + 1,
		"stars": 0,
		"stats": stats.duplicate(true),
		"unlocked_next": false,
		"failed": true,
	}
	EventBus.level_failed.emit()
	return last_result


func stars_for_integrity(current: int, maximum: int) -> int:
	if maximum <= 0:
		return 1
	var ratio := float(current) / float(maximum)
	if ratio >= 0.8:
		return 3
	if ratio >= 0.45:
		return 2
	return 1


func update_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_to_disk()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").refresh_from_settings(settings)


func set_settings(new_settings: Dictionary) -> void:
	for key in new_settings.keys():
		settings[key] = new_settings[key]
	save_to_disk()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").refresh_from_settings(settings)


func reset_campaign() -> void:
	unlocked_level = 1
	completed.clear()
	best_stars.clear()
	total_credits = 0
	total_kills = 0
	total_levels = 0
	campaign_started = false
	last_result = {}
	clear_wave_checkpoint()
	save_to_disk()


func level_title(index: int) -> String:
	if index < 0 or index >= LEVEL_DATA_PATHS.size():
		return Loc.t("Unknown Sector")
	var res := load(LEVEL_DATA_PATHS[index])
	if res is LevelData:
		return Loc.t(res.display_name)
	return Loc.tf("Sector %d", [index + 1])
