extends Node
## Crowd stress benchmark: many enemies alive at once, towers firing.
## Measures wall-clock cost per fixed physics tick (headless = simulation,
## windowed = simulation + rendering). Campaign save is untouched.
##
## Run:
##   godot --headless --path . --fixed-fps 60 res://tests/StressTest.tscn
##   godot --path . res://tests/StressTest.tscn
##
## Optional user args: -- --enemies=160 --frames=900 --speed=1

const LEVEL_SCENE := "res://scenes/level/Level_15.tscn"
const DAMAGE_TOWERS: Array[String] = [
	"pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "orbital",
]
const DEFAULT_ENEMIES := 140
const DEFAULT_FRAMES := 900

var _enemy_count := DEFAULT_ENEMIES
var _frames := DEFAULT_FRAMES
var _speed := 1
var _no_tower_ai := false
var _no_enemy_ai := false
var _no_visuals := false
var _no_map := false
var _no_hud := false
var _no_towers := false
var _no_bars := false
var _no_legs := false
var _no_body := false
var _no_visual_process := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--enemies="):
			_enemy_count = maxi(1, int(arg.substr(10)))
		elif arg.begins_with("--frames="):
			_frames = maxi(120, int(arg.substr(9)))
		elif arg.begins_with("--speed="):
			_speed = clampi(int(arg.substr(8)), 1, 3)
		elif arg == "--no-tower-ai":
			_no_tower_ai = true
		elif arg == "--no-enemy-ai":
			_no_enemy_ai = true
		elif arg == "--no-visuals":
			_no_visuals = true
		elif arg == "--no-map":
			_no_map = true
		elif arg == "--no-hud":
			_no_hud = true
		elif arg == "--no-towers":
			_no_towers = true
		elif arg == "--no-bars":
			_no_bars = true
		elif arg == "--no-legs":
			_no_legs = true
		elif arg == "--no-body":
			_no_body = true
		elif arg == "--no-visual-process":
			_no_visual_process = true
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	var level = load(LEVEL_SCENE).instantiate()
	add_child(level)
	await get_tree().process_frame

	var built := _build_defense(level)
	level.set_game_speed(_speed)
	if _no_map:
		for node_name in ["Terrain", "GridOverlay", "PathNetwork", "SpawnGateA", "SpawnGateB", "BaseCore"]:
			var node = level.get_node_or_null(node_name)
			if node:
				node.visible = false
	if _no_hud:
		var hud = level.get_node_or_null("HUD")
		if hud:
			hud.visible = false
	if _no_legs:
		var legs_layer = level.get_node_or_null("EnemyLegsLayer")
		if legs_layer:
			legs_layer.visible = false
	if _no_tower_ai:
		for tower in get_tree().get_nodes_in_group("towers"):
			tower.set_physics_process(false)
	if _no_towers:
		for tower in get_tree().get_nodes_in_group("towers"):
			tower.visible = false

	# Keep the crowd alive and on the field so the benchmark measures steady
	# state instead of a single burst that towers delete in two seconds.
	var ids: Array[String] = ["scout", "warrior", "shieldbearer", "flyer", "spitter", "healer"]
	var spawned := 0
	for i in _enemy_count:
		var id: String = ids[i % ids.size()]
		if not level.spawn_enemy(id, i % 2):
			continue
		var group := get_tree().get_nodes_in_group("enemies")
		var enemy = group[group.size() - 1]
		enemy.max_health = 100000.0
		enemy.health = 100000.0
		enemy.speed_mult = 0.35
		if _no_enemy_ai:
			enemy.set_physics_process(false)
		if _no_visuals:
			for child_name in ["Visual", "HealthBar"]:
				var child = enemy.get_node_or_null(child_name)
				if child:
					child.queue_free()
		if _no_bars:
			var bar = enemy.get_node_or_null("HealthBar")
			if bar:
				bar.visible = false
		if _no_legs:
			var visual = enemy.get_node_or_null("Visual")
			var legs = visual.get_node_or_null("Legs") if visual else null
			if legs:
				legs.visible = false
		if _no_body:
			var body_visual = enemy.get_node_or_null("Visual")
			if body_visual:
				body_visual.visible = false
		if _no_visual_process:
			var static_visual = enemy.get_node_or_null("Visual")
			if static_visual:
				static_visual.set_process(false)
				var static_legs = static_visual.get_node_or_null("Legs")
				if static_legs:
					static_legs.set_process(false)
		spawned += 1

	var samples: Array[float] = []
	var peak_enemies := 0
	var peak_projectiles := 0
	var peak_effects := 0
	Enemy.prof_calls = 0
	Enemy.prof_total_usec = 0
	Enemy.prof_path_usec = 0
	Enemy.prof_status_usec = 0
	Enemy.prof_visual_usec = 0
	var peak_draws := 0
	var draw_total := 0
	var draw_samples := 0
	var process_total := 0.0
	var physics_total := 0.0
	var monitor_samples := 0
	var last_usec := Time.get_ticks_usec()
	var frame := 0
	while frame < _frames:
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		if frame >= 60:
			samples.append(float(now - last_usec) / 1000.0)
			process_total += float(Performance.get_monitor(Performance.TIME_PROCESS))
			physics_total += float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
			monitor_samples += 1
		if frame == 60:
			Enemy.prof_enabled = true
		last_usec = now
		if frame % 10 == 0:
			peak_enemies = maxi(peak_enemies, get_tree().get_nodes_in_group("enemies").size())
			peak_projectiles = maxi(peak_projectiles, get_tree().get_nodes_in_group("projectiles").size())
			peak_effects = maxi(peak_effects, get_tree().get_nodes_in_group("effects").size())
			if DisplayServer.get_name() != "headless":
				var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				peak_draws = maxi(peak_draws, draws)
				draw_total += draws
				draw_samples += 1
		frame += 1

	Enemy.prof_enabled = false
	if Enemy.prof_calls > 0:
		print("STRESS  enemy profile: %d calls  status %.2f us  path+visual %.2f us per call" % [
			Enemy.prof_calls,
			float(Enemy.prof_status_usec) / float(Enemy.prof_calls),
			float(Enemy.prof_path_usec) / float(Enemy.prof_calls),
		])

	print("")
	print("STRESS  sector 15  towers %d  enemies spawned %d  frames %d  speed %dx" % [
		built, spawned, frame, _speed,
	])
	if not samples.is_empty():
		samples.sort()
		var total := 0.0
		for value in samples:
			total += value
		var avg := total / float(samples.size())
		var p50 := samples[clampi(int(float(samples.size()) * 0.50), 0, samples.size() - 1)]
		var p95 := samples[clampi(int(float(samples.size()) * 0.95), 0, samples.size() - 1)]
		var p99 := samples[clampi(int(float(samples.size()) * 0.99), 0, samples.size() - 1)]
		var worst := samples[samples.size() - 1]
		print("STRESS  avg %.2f ms (%.0f FPS)  p50 %.2f  p95 %.2f  p99 %.2f  worst %.2f" % [
			avg, 1000.0 / maxf(avg, 0.001), p50, p95, p99, worst,
		])
	print("STRESS  peak active: enemies %d  projectiles %d  effects %d" % [
		peak_enemies, peak_projectiles, peak_effects,
	])
	if monitor_samples > 0:
		print("STRESS  engine monitors: _process %.2f ms  _physics_process %.2f ms" % [
			process_total / float(monitor_samples) * 1000.0,
			physics_total / float(monitor_samples) * 1000.0,
		])
	if draw_samples > 0:
		print("STRESS  draw calls: avg %d  peak %d" % [draw_total / draw_samples, peak_draws])
	else:
		print("STRESS NOTE: headless simulation benchmark, rendering excluded.")
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
