extends Node
## Dense late-campaign simulation benchmark on Sector 15.
## Measures wall-clock cost per fixed 60 Hz physics tick in headless mode
## (simulation only; rendering is excluded). The campaign save is restored.
## Run: godot --headless --path . --fixed-fps 60 res://tests/PerfTest.tscn

const LEVEL_SCENE := "res://scenes/level/Level_15.tscn"
const DAMAGE_TOWERS: Array[String] = [
	"pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "orbital",
]
const FRAME_LIMIT := 9000


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var had_save := FileAccess.file_exists(SaveManager.SAVE_PATH)
	var original: Dictionary = SaveManager.load_payload()

	var level = load(LEVEL_SCENE).instantiate()
	add_child(level)
	await get_tree().process_frame

	var built := _build_defense(level)
	level.set_game_speed(3)
	var samples: Array[float] = []
	var peak_enemies := 0
	var peak_projectiles := 0
	var peak_effects := 0
	var frames := 0
	var last_usec := Time.get_ticks_usec()
	while frames < FRAME_LIMIT and not level.match_finished:
		if not level.waves.has_active_wave() and level.waves.started_waves < level.waves.total_waves:
			level.request_next_wave()
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		if frames >= 180:
			samples.append(float(now - last_usec) / 1000.0)
		last_usec = now
		if frames % 10 == 0:
			peak_enemies = maxi(peak_enemies, get_tree().get_nodes_in_group("enemies").size())
			peak_projectiles = maxi(peak_projectiles, get_tree().get_nodes_in_group("projectiles").size())
			peak_effects = maxi(peak_effects, get_tree().get_nodes_in_group("effects").size())
		frames += 1

	print("")
	print("PERF  Sector 15  towers %d  waves %d/%d  frames %d  samples %d" % [
		built, level.waves.finished_waves, level.waves.total_waves, frames, samples.size(),
	])
	if not samples.is_empty():
		samples.sort()
		var total := 0.0
		for value in samples:
			total += value
		var avg := total / float(samples.size())
		var p95 := samples[clampi(int(float(samples.size()) * 0.95), 0, samples.size() - 1)]
		var p99 := samples[clampi(int(float(samples.size()) * 0.99), 0, samples.size() - 1)]
		var worst := samples[samples.size() - 1]
		print("PERF  avg %.2f ms (%.0f sim FPS)  p95 %.2f ms  p99 %.2f ms  worst %.2f ms" % [
			avg, 1000.0 / maxf(avg, 0.001), p95, p99, worst,
		])
	print("PERF  peak active: enemies %d  projectiles %d  effects %d" % [
		peak_enemies, peak_projectiles, peak_effects,
	])
	print("PERF NOTE: headless simulation benchmark, rendering and GPU cost excluded.")

	level.queue_free()
	await get_tree().process_frame

	if had_save:
		SaveManager.save_payload(original)
	else:
		SaveManager.reset_save()
	GameState.load_from_disk()
	get_tree().quit(0)


func _build_defense(level: Node) -> int:
	level.economy.add_credits(100000, "perf")
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
			var tower_id: String = damage_ids[pick % damage_ids.size()]
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
