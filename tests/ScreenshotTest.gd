extends Node
## Renders the key screens to PNG for the visual audit.
## Run without --headless:
## godot --path . res://tests/ScreenshotTest.tscn

var _shot_dir := "res://tests/screenshots"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var viewport_size := get_viewport().get_visible_rect().size
	_shot_dir = "res://tests/screenshots_%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_shot_dir = arg.trim_prefix("--out=").trim_suffix("/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_dir))
	await get_tree().process_frame

	await _capture_menu("res://scenes/main/MainMenu.tscn", "01_main_menu")
	await _capture_menu("res://scenes/main/LevelSelect.tscn", "02_level_select")
	await _capture_overlay("res://scenes/ui/SettingsPanel.tscn", "03_settings")
	await _capture_overlay("res://scenes/ui/HelpPanel.tscn", "04_help")

	var level = load("res://scenes/level/Level_01.tscn").instantiate()
	add_child(level)
	await _wait(40)
	await _shot("05_level_idle")

	level.economy.add_credits(2000, "screenshot")
	var cells: Array[Vector2i] = level.grid.buildable_cells()
	var built := 0
	for id in ["pulse", "siege", "flame", "cryo", "relay"]:
		if cells.size() <= built:
			break
		level.select_build_type(id)
		if level.build_tower_id == id and level.try_place_tower(cells[built * 2 + 1]):
			built += 1
		level.cancel_build()
	var towers := get_tree().get_nodes_in_group("towers")
	if not towers.is_empty():
		level.select_tower(towers[0])
	await _wait(20)
	await _shot("06_level_towers")

	level.request_next_wave()
	await _wait(180)
	await _shot("07_level_combat")

	level.toggle_pause()
	await _wait(8)
	await _shot("08_pause")
	if level.pause_menu and level.pause_menu.has_method("_on_help"):
		level.pause_menu.call("_on_help")
		await _wait(8)
		await _shot("09_pause_help")
		if level.pause_menu.help_panel:
			level.pause_menu.help_panel.call("close_panel")
	level.toggle_pause()

	var victory: PackedScene = load("res://scenes/main/VictoryScreen.tscn")
	var win = victory.instantiate()
	add_child(win)
	if win.has_method("setup"):
		win.call("setup", {
			"level_number": 1, "stars": 3, "unlocked_next": true, "campaign_complete": false,
			"stats": {"kills": 42, "leaks": 1, "base_health": 88, "base_max": 100,
				"credits_earned": 460, "time": 190.0, "level_name": "Landing Zone"},
		}, level)
	await _wait(10)
	await _shot("10_victory")
	win.queue_free()

	var defeat: PackedScene = load("res://scenes/main/DefeatScreen.tscn")
	var lose = defeat.instantiate()
	add_child(lose)
	if lose.has_method("setup"):
		lose.call("setup", {
			"level_number": 1, "stars": 0, "failed": true,
			"stats": {"kills": 12, "leaks": 9, "base_health": 0, "base_max": 100,
				"credits_earned": 140, "time": 120.0, "level_name": "Landing Zone"},
		}, level)
	await _wait(10)
	await _shot("11_defeat")
	lose.queue_free()

	level.queue_free()
	await _wait(2)

	print("Screenshots written to ", _shot_dir)
	get_tree().quit(0)


func _capture_overlay(path: String, name: String) -> void:
	var scene: PackedScene = load(path)
	var instance = scene.instantiate()
	add_child(instance)
	await _wait(2)
	instance.call("open")
	await _wait(12)
	await _shot(name)
	instance.queue_free()
	await _wait(2)


func _capture_menu(path: String, name: String) -> void:
	var scene: PackedScene = load(path)
	var instance = scene.instantiate()
	add_child(instance)
	await _wait(45)
	await _shot(name)
	instance.queue_free()
	await _wait(2)


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Screenshot failed: " + name)
		return
	var path := _shot_dir.path_join(name + ".png")
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Could not save screenshot: " + path)
	else:
		print("Saved ", path, " ", image.get_width(), "x", image.get_height())
