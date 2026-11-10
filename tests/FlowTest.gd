extends Node
## Focused runtime checks for settings persistence, audio mute, pause/resume and
## the victory/defeat overlay wiring. The campaign save is backed up and restored.
## Run: godot --headless --path . res://tests/FlowTest.tscn

const LEVEL_SCENE := "res://scenes/level/Level_01.tscn"

var checks: int = 0
var failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS  " + label)
	else:
		failures += 1
		print("FAIL  " + label)


func _run() -> void:
	var had_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
	var original: Dictionary = SaveManager.load_payload()

	await _test_settings_persistence()
	await _test_audio_mute()
	await _test_settings_panel()
	await _test_pause_and_victory()
	await _test_defeat_overlay()

	if had_save:
		SaveManager.save_payload(original)
	else:
		SaveManager.reset_save()
	GameState.load_from_disk()
	AudioManager.refresh_from_settings(GameState.settings)

	print("")
	print("FLOW RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _test_settings_persistence() -> void:
	GameState.update_setting("master_volume", 0.42)
	GameState.update_setting("muted", true)
	GameState.save_to_disk()

	var file := FileAccess.open(SaveManager.SAVE_PATH, FileAccess.READ)
	check(file != null, "Settings save file is written")
	var raw := ""
	if file != null:
		raw = file.get_as_text()
		file.close()
	var parsed: Variant = JSON.parse_string(raw)
	check(typeof(parsed) == TYPE_DICTIONARY, "Settings save file is valid JSON")
	if typeof(parsed) == TYPE_DICTIONARY:
		var disk_settings: Dictionary = parsed.get("settings", {})
		check(is_equal_approx(float(disk_settings.get("master_volume", -1.0)), 0.42),
			"Master volume persists to disk")
		check(GameConfig.as_bool(disk_settings.get("muted", false)),
			"Mute flag persists to disk")

	var reloaded: Dictionary = SaveManager.load_payload()
	var loaded_settings: Dictionary = reloaded.get("settings", {})
	check(is_equal_approx(float(loaded_settings.get("master_volume", -1.0)), 0.42),
		"Reloaded save returns the persisted volume")
	check(GameConfig.as_bool(loaded_settings.get("muted", false)),
		"Reloaded save returns the persisted mute flag")
	await get_tree().process_frame


func _test_audio_mute() -> void:
	AudioManager.set_muted(true)
	check(AudioManager.get("_muted") == true, "Audio manager accepts mute")
	AudioManager.play_sound("ui_click")
	var any_playing := false
	for player in AudioManager.get("_players"):
		if player.playing:
			any_playing = true
			break
	check(not any_playing, "Muted audio starts no SFX player")

	AudioManager.set_muted(false)
	check(AudioManager.get("_muted") == false, "Audio manager can unmute")
	check(AudioManager._sfx_db(1.0) > -80.0, "Unmuted effects bus has audible gain")
	await get_tree().process_frame


func _test_settings_panel() -> void:
	var panel = load("res://scenes/ui/SettingsPanel.tscn").instantiate()
	add_child(panel)
	await get_tree().process_frame
	panel.call("open")
	await get_tree().process_frame
	check(panel.visible, "Settings panel opens")

	var sliders: Array = panel.find_children("*", "HSlider", true, false)
	check(sliders.size() == 3, "Settings panel exposes three volume sliders")
	if sliders.size() == 3:
		sliders[0].value = 33.0
		await get_tree().process_frame
		check(is_equal_approx(float(GameState.settings.get("master_volume", -1.0)), 0.33),
			"Slider change updates the live setting")

	var checks_boxes: Array = panel.find_children("*", "CheckButton", true, false)
	check(checks_boxes.size() == 3, "Settings panel exposes three toggles")
	panel.call("close_panel")
	await get_tree().process_frame
	check(not panel.visible, "Settings panel closes")
	panel.queue_free()
	await get_tree().process_frame


func _test_pause_and_victory() -> void:
	var level = load(LEVEL_SCENE).instantiate()
	add_child(level)
	await _wait(10)

	check(not get_tree().paused, "New level starts unpaused")
	level.toggle_pause()
	check(get_tree().paused, "Pause freezes the scene tree")
	check(level.pause_menu != null and level.pause_menu.visible, "Pause menu becomes visible")

	var resume := _find_button(level.pause_menu, "RESUME")
	check(resume != null, "Pause menu has a Resume button")
	if resume != null:
		resume.emit_signal("pressed")
		await get_tree().process_frame
	check(not get_tree().paused, "Resume unfreezes the scene tree")
	check(not level.pause_menu.visible, "Resume hides the pause menu")

	var pause_buttons: Array = level.pause_menu.find_children("*", "Button", true, false)
	var connected := 0
	for button in pause_buttons:
		if button.pressed.get_connections().size() > 0:
			connected += 1
	check(connected >= 6, "Every pause-menu action is connected")

	level.call("_trigger_victory")
	await get_tree().process_frame
	var victory = level.find_child("VictoryScreen", true, false)
	check(victory != null, "Victory creates the victory overlay")
	if victory != null:
		var victory_buttons: Array = victory.find_children("*", "Button", true, false)
		check(victory_buttons.size() >= 3, "Victory overlay exposes navigation buttons")
		var victory_connected := 0
		for button in victory_buttons:
			if button.pressed.get_connections().size() > 0:
				victory_connected += 1
		check(victory_connected == victory_buttons.size(), "Every victory action is connected")
		check(_find_button(victory, "MAIN MENU") != null, "Victory has a Main Menu action")
		check(_find_button(victory, "REPLAY") != null, "Victory has a Replay action")
	check(GameState.level_is_completed(0), "Victory records level completion")
	check(GameState.unlocked_level >= 2, "Victory unlocks the next sector")
	level.queue_free()
	await get_tree().process_frame


func _test_defeat_overlay() -> void:
	var level = load(LEVEL_SCENE).instantiate()
	add_child(level)
	await _wait(10)
	level.damage_base(9999)
	await get_tree().process_frame
	check(level.base_health == 0, "Lethal base damage reaches zero")
	check(level.match_finished, "Lethal base damage ends the match")
	var defeat = level.find_child("DefeatScreen", true, false)
	check(defeat != null, "Defeat creates the defeat overlay")
	if defeat != null:
		var defeat_buttons: Array = defeat.find_children("*", "Button", true, false)
		check(defeat_buttons.size() >= 3, "Defeat overlay exposes navigation buttons")
		var defeat_connected := 0
		for button in defeat_buttons:
			if button.pressed.get_connections().size() > 0:
				defeat_connected += 1
		check(defeat_connected == defeat_buttons.size(), "Every defeat action is connected")
		check(_find_button(defeat, "RETRY SECTOR") != null, "Defeat has a Retry action")
	level.queue_free()
	await get_tree().process_frame


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for button in root.find_children("*", "Button", true, false):
		if button is Button and button.text == text:
			return button
	return null


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame
