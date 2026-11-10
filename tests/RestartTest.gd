extends Node
## Verifies the real restart action: the pause menu's Restart button must reload
## the active scene and leave the tree running. A user:// marker survives the
## reload so the second boot can report success.
## Run: godot --headless --path . res://tests/RestartTest.tscn

const LEVEL_SCENE := "res://scenes/level/Level_01.tscn"
const MARKER := "user://restart_probe.marker"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(MARKER):
		await _first_boot()
	else:
		_second_boot()


func _first_boot() -> void:
	var marker := FileAccess.open(MARKER, FileAccess.WRITE)
	if marker == null:
		print("FAIL  could not write restart marker")
		get_tree().quit(1)
		return
	marker.store_string("1")
	marker.close()

	var level = load(LEVEL_SCENE).instantiate()
	add_child(level)
	for i in 8:
		await get_tree().process_frame

	level.toggle_pause()
	if not get_tree().paused:
		print("FAIL  pause did not engage before restart")
		get_tree().quit(1)
		return

	var restart := _find_button(level.pause_menu, "RESTART SECTOR")
	if restart == null:
		print("FAIL  Restart Sector button was not found")
		get_tree().quit(1)
		return
	print("PASS  Restart Sector button found; invoking it")
	# The reload frees this node immediately, so keep the SceneTree reference and
	# set an independent watchdog instead of awaiting on self afterwards.
	var tree := get_tree()
	var watchdog := tree.create_timer(8.0)
	watchdog.timeout.connect(func():
		if FileAccess.file_exists(MARKER):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(MARKER))
			print("FAIL  scene was not reloaded by the restart action")
			tree.quit(1)
	)
	restart.emit_signal("pressed")


func _second_boot() -> void:
	var marker := FileAccess.open(MARKER, FileAccess.READ)
	var token := ""
	if marker != null:
		token = marker.get_as_text()
		marker.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(MARKER))

	var ok := true
	ok = ok and token == "1"
	ok = ok and not get_tree().paused
	ok = ok and is_equal_approx(Engine.time_scale, 1.0)
	ok = ok and get_tree().current_scene != null
	ok = ok and get_tree().current_scene.scene_file_path == "res://tests/RestartTest.tscn"
	print("%s  restart reloaded the active scene (current=%s, paused=%s, time_scale=%.1f)" % [
		"PASS" if ok else "FAIL",
		get_tree().current_scene.scene_file_path if get_tree().current_scene != null else "<none>",
		str(get_tree().paused), Engine.time_scale,
	])
	print("")
	print("RESTART RESULT: %s" % ("OK" if ok else "FAILED"))
	get_tree().quit(0 if ok else 1)


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for button in root.find_children("*", "Button", true, false):
		if button is Button and button.text == text:
			return button
	return null
