extends Node
## Fair-economy autoplay probe.
## Uses only starting credits, wave income and bounties. Builds progressively,
## upgrades when affordable and uses abilities automatically. Reported outcomes
## describe how a straightforward scripted player fares on each sector.
##
## Run: godot --headless --path . --fixed-fps 60 res://tests/FairPlayTest.tscn

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
const ANTI_AIR: Array[String] = ["missile", "cryo", "tesla", "rail", "orbital"]
const FRAME_LIMIT := 60000

var state: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


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
	print("FAIR PLAYTHROUGH COMPLETE")
	get_tree().quit(0)


func _play_level(index: int) -> void:
	var level = load(LEVEL_SCENES[index]).instantiate()
	add_child(level)
	await get_tree().process_frame

	state = {"pool": _make_pool(level), "pool_index": 0, "built": 0, "pick": 0}
	_spend(level)
	level.set_game_speed(3)
	var frames := 0
	var last_spend_wave := -1
	while frames < FRAME_LIMIT and not level.match_finished:
		if int(level.waves.finished_waves) != last_spend_wave:
			last_spend_wave = int(level.waves.finished_waves)
			_spend(level)
		_use_abilities(level)
		if not level.waves.has_active_wave() and level.waves.started_waves < level.waves.total_waves:
			level.request_next_wave()
		await get_tree().physics_frame
		frames += 1

	var outcome := "STALEMATE"
	if level.match_finished:
		outcome = "VICTORY" if level.base_health > 0 else "DEFEAT"
	print("%s  %02d %-20s base %3d/%-3d  waves %2d/%-2d  towers %2d  kills %4d  frames %5d" % [
		outcome, index + 1, level.level_data.display_name, level.base_health, level.base_max,
		level.waves.finished_waves, level.waves.total_waves, int(state["built"]),
		int(level.stats.kills), frames,
	])
	level.queue_free()
	await get_tree().process_frame


func _spend(level: Node) -> void:
	var guard := 0
	while guard < 40:
		guard += 1
		var target_count: int = mini(22, 4 + int(level.waves.finished_waves) * 2)
		if int(state["built"]) < target_count:
			var tower_id := _choose_tower(level)
			if tower_id != "":
				var cell := _next_cell(level)
				if cell.x >= 0 and _build(level, tower_id, cell):
					state["built"] = int(state["built"]) + 1
					continue
		var best_tower = null
		var best_cost := 999999
		for tower in get_tree().get_nodes_in_group("towers"):
			if tower == null or not is_instance_valid(tower):
				continue
			if not tower.can_upgrade():
				continue
			var cost: int = tower.next_upgrade_cost()
			if cost < best_cost:
				best_cost = cost
				best_tower = tower
		if best_tower != null:
			best_tower.upgrade()
			continue
		break


func _choose_tower(level: Node) -> String:
	var available: Array[String] = []
	for id in DAMAGE_TOWERS:
		if level.level_data.available_towers.has(id):
			available.append(id)
	if available.is_empty():
		return ""
	var next_wave: WaveData = level.waves.next_wave_data()
	if next_wave != null and _wave_has_flyer(next_wave):
		var current_aa := 0
		for tower in get_tree().get_nodes_in_group("towers"):
			if tower != null and is_instance_valid(tower) and tower.tower_data.anti_air:
				current_aa += 1
		if current_aa < 2:
			for id in ANTI_AIR:
				if available.has(id):
					var data: TowerData = load("res://resources/towers/tower_%s.tres" % id)
					if data != null and level.economy.credits >= data.cost:
						return id
	for offset in available.size():
		var id := available[(int(state["pick"]) + offset) % available.size()]
		var data: TowerData = load("res://resources/towers/tower_%s.tres" % id)
		if data != null and level.economy.credits >= data.cost:
			state["pick"] = int(state["pick"]) + offset + 1
			return id
	return ""


func _wave_has_flyer(wave: WaveData) -> bool:
	for entry in wave.entries:
		if entry != null and entry.enemy_id == "flyer":
			return true
	return false


func _next_cell(level: Node) -> Vector2i:
	var pool: Array = state["pool"]
	var index: int = int(state["pool_index"])
	while index < pool.size():
		var cell: Vector2i = pool[index]
		index += 1
		state["pool_index"] = index
		if not level.grid.is_occupied(cell):
			return cell
	return Vector2i(-1, -1)


func _make_pool(level: Node) -> Array:
	var pool: Array = []
	var seen: Dictionary = {}
	for path_id in [0, 1]:
		var total: float = level.path.total_length(path_id)
		for step in range(1, 13):
			var point: Vector2 = level.path.point_at_distance(path_id, total * float(step) / 13.0)
			var cell := _nearest_buildable(level, point, seen)
			if cell.x >= 0:
				seen[cell] = true
				pool.append(cell)
	for cell in level.grid.buildable_cells():
		if not seen.has(cell) and pool.size() < 26:
			seen[cell] = true
			pool.append(cell)
	return pool


func _nearest_buildable(level: Node, point: Vector2, used: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 300.0 * 300.0
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
	level.cancel_build()
	return true


func _use_abilities(level: Node) -> void:
	if level.abilities == null or level.match_finished:
		return
	if level.abilities.can_use("emergency_repair") and level.base_health < level.base_max * 0.65:
		level.abilities.use_ability("emergency_repair", Vector2.ZERO)
	if level.abilities.can_use("supply_drop"):
		level.abilities.use_ability("supply_drop", Vector2.ZERO)
	var enemies: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != null and is_instance_valid(enemy) and enemy.is_targetable():
			enemies.append(enemy)
	if enemies.size() < 3:
		return
	var center := Vector2.ZERO
	for enemy in enemies:
		center += enemy.global_position
	center /= float(enemies.size())
	if level.abilities.can_use("orbital_strike"):
		level.abilities.use_ability("orbital_strike", center)
	elif level.abilities.can_use("emp"):
		level.abilities.use_ability("emp", center)
	elif level.abilities.can_use("reinforcement_drones"):
		level.abilities.use_ability("reinforcement_drones", center)
