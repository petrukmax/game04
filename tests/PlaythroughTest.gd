extends Node
## Campaign autoplay/balance harness.
## Builds a scripted max-upgrade defence on every level, plays all waves at 3x
## speed and verifies each level reaches a real victory. Test-only credits are
## used here; this harness measures scenario integrity, not player economy.
##
## Run: godot --headless --path . --fixed-fps 60 res://tests/PlaythroughTest.tscn

const LEVEL_SCENES: Array[String] = [
	"res://scenes/level/Level_01.tscn", "res://scenes/level/Level_02.tscn",
	"res://scenes/level/Level_03.tscn", "res://scenes/level/Level_04.tscn",
	"res://scenes/level/Level_05.tscn", "res://scenes/level/Level_06.tscn",
	"res://scenes/level/Level_07.tscn", "res://scenes/level/Level_08.tscn",
	"res://scenes/level/Level_09.tscn", "res://scenes/level/Level_10.tscn",
	"res://scenes/level/Level_11.tscn", "res://scenes/level/Level_12.tscn",
	"res://scenes/level/Level_13.tscn", "res://scenes/level/Level_14.tscn",
	"res://scenes/level/Level_15.tscn",
]
const DAMAGE_TOWERS: Array[String] = [
	"pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "orbital",
]
const FRAME_LIMIT := 40000

var failures: int = 0


func _ready() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS  " + label)
	else:
		failures += 1
		print("FAIL  " + label)


func _run() -> void:
	var had_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
	var original: Dictionary = SaveManager.load_payload()

	for index in LEVEL_SCENES.size():
		await _play_level(index)

	if had_save:
		SaveManager.save_payload(original)
	else:
		SaveManager.reset_save()
	GameState.load_from_disk()

	print("")
	print("PLAYTHROUGH RESULT: %d level(s) failed" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _play_level(index: int) -> void:
	var packed: PackedScene = load(LEVEL_SCENES[index])
	if packed == null:
		check(false, "Level scene load: %02d" % (index + 1))
		return
	var level = packed.instantiate()
	add_child(level)
	await get_tree().process_frame

	var built := _build_defense(level)
	var label := "%02d %s" % [index + 1, level.level_data.display_name]
	check(built >= 10, "%s builds a defence (%d towers)" % [label, built])

	level.set_game_speed(3)
	var frames := 0
	while frames < FRAME_LIMIT and not level.match_finished:
		if not level.waves.has_active_wave() and level.waves.started_waves < level.waves.total_waves:
			level.request_next_wave()
		await get_tree().physics_frame
		frames += 1

	var complete: bool = level.match_finished and level.base_health > 0
	var waves_done: int = level.waves.finished_waves
	check(complete, "%s reaches victory (base %d/%d, waves %d/%d, %d frames)" % [
		label, level.base_health, level.base_max, waves_done, level.waves.total_waves, frames,
	])
	check(waves_done == level.waves.total_waves, "%s clears every wave" % label)
	check(int(level.stats.kills) > 0, "%s records kills (%d)" % [label, int(level.stats.kills)])
	check(GameConfig.as_bool(GameState.completed.get(str(index + 1), false)), "%s records campaign completion" % label)

	level.queue_free()
	await get_tree().process_frame


func _build_defense(level: Node) -> int:
	level.economy.add_credits(100000, "autoplay")
	var damage_ids: Array[String] = []
	for id in DAMAGE_TOWERS:
		if level.level_data.available_towers.has(id):
			damage_ids.append(id)
	if damage_ids.is_empty():
		return 0
	var used: Dictionary = {}
	var built := 0
	var pick := 0
	for path_id in [0, 1]:
		var total: float = level.path.total_length(path_id)
		for step in range(1, 9):
			var point: Vector2 = level.path.point_at_distance(path_id, total * float(step) / 9.0)
			var cell := _nearest_buildable(level, point, used)
			if cell.x < 0:
				continue
			used[cell] = true
			var tower_id := damage_ids[pick % damage_ids.size()]
			pick += 1
			if _build(level, tower_id, cell):
				built += 1

	if level.level_data.available_towers.has("relay"):
		var relay_cell := _nearest_buildable(level, Vector2(800, 430), used)
		if relay_cell.x >= 0:
			used[relay_cell] = true
			if _build(level, "relay", relay_cell):
				built += 1
	if level.level_data.available_towers.has("mine"):
		var mine_cell := _nearest_buildable(level, Vector2(700, 500), used)
		if mine_cell.x >= 0:
			used[mine_cell] = true
			if _build(level, "mine", mine_cell):
				built += 1
	return built


func _nearest_buildable(level: Node, point: Vector2, used: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 260.0 * 260.0
	for cell in level.grid.buildable_cells():
		if used.has(cell):
			continue
		var world: Vector2 = level.grid.cell_to_world(cell)
		var distance: float = point.distance_squared_to(world)
		if distance < best_distance:
			best_distance = distance
			best = cell
	return best


func _build(level: Node, tower_id: String, cell: Vector2i) -> bool:
	level.select_build_type(tower_id)
	if level.build_tower_id != tower_id:
		level.cancel_build()
		return false
	if not level.try_place_tower(cell):
		level.cancel_build()
		return false
	var tower = level.grid.occupied.get(cell, null)
	if tower != null and is_instance_valid(tower):
		while tower.current_level < tower.tower_data.max_level:
			if not tower.upgrade():
				break
	level.cancel_build()
	return tower != null and is_instance_valid(tower)
