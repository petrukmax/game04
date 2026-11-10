class_name LevelBase
extends Node2D
## Level orchestrator: managers, placement, input, abilities, victory and defeat.

@export var level_data: LevelData

const TOWER_IDS: Array[String] = ["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"]
const ENEMY_IDS: Array[String] = ["scout", "worker", "warrior", "spitter", "healer", "burrower", "shieldbearer", "flyer", "elite", "boss"]
const ABILITY_SHORTCUTS := {
	"Q": "orbital_strike", "W": "emp", "E": "reinforcement_drones",
	"R": "emergency_repair", "T": "supply_drop",
}
const FX_PATHS := {
	"muzzle": "res://scenes/fx/MuzzleFlash.tscn",
	"explosion": "res://scenes/fx/Explosion.tscn",
	"frost": "res://scenes/fx/FrostBurst.tscn",
	"death": "res://scenes/fx/DeathBurst.tscn",
	"dust": "res://scenes/fx/DustCloud.tscn",
	"heal": "res://scenes/fx/HealBurst.tscn",
	"acid": "res://scenes/fx/AcidSplat.tscn",
	"shield_break": "res://scenes/fx/ShieldBreak.tscn",
	"flame": "res://scenes/fx/FlameBurst.tscn",
	"trail": "res://scenes/fx/MissileTrail.tscn",
	"orbital": "res://scenes/fx/OrbitalBlast.tscn",
	"hit": "res://scenes/fx/ImpactBurst.tscn",
	"emp": "res://scenes/fx/EmpBurst.tscn",
}

var grid: GridManager
var path: PathManager
var economy: EconomyManager
var waves: WaveManager
var abilities: AbilityManager
var hud: CanvasLayer
var pause_menu: CanvasLayer
var camera: Camera2D
var ghost: Node2D
var ability_preview: Node2D
var base_core: Node2D

var tower_registry: Dictionary = {}
var enemy_registry: Dictionary = {}
var tower_container: Node2D
var enemy_container: Node2D
var projectile_container: Node2D
var effect_container: Node2D

var base_health: int = 100
var base_max: int = 100
var game_speed: int = 1
var simulation_running: bool = true
var match_finished: bool = false
var selected_tower: Node = null
var build_tower_id: String = ""
var build_data: TowerData = null
var ability_target_id: String = ""
var hover_cell: Vector2i = Vector2i(-1, -1)
var mouse_world: Vector2 = Vector2.ZERO
var shake_strength: float = 0.0
var level_time: float = 0.0
var stats: Dictionary = {
	"kills": 0, "leaks": 0, "towers_built": 0, "waves_cleared": 0, "credits_earned": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = false
	Engine.time_scale = 1.0
	if level_data == null:
		push_error("Level has no LevelData assigned.")
		return
	GameState.current_level_index = level_data.level_number - 1
	base_max = level_data.base_health
	base_health = base_max
	game_speed = clampi(int(GameState.settings.get("speed", 1)), 1, 3)
	_load_registries()
	_setup_containers()
	_setup_managers()
	_setup_camera()
	_setup_scene_nodes()
	_setup_ghosts()
	hud = get_node_or_null("HUD")
	if hud and hud.has_method("setup"):
		hud.call("setup", self)
	pause_menu = get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("setup"):
		pause_menu.call("setup", self)
	AudioManager.start_ambience()
	EventBus.base_health_changed.emit(base_health, base_max)
	EventBus.credits_changed.emit(economy.credits)
	EventBus.speed_changed.emit(game_speed)
	EventBus.damage_number.connect(_on_damage_number)
	EventBus.notification.emit("Sector %d — %s" % [level_data.level_number, level_data.display_name], GameConfig.AMBER)
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_inside_tree() and not match_finished:
			EventBus.notification.emit(level_data.briefing, GameConfig.OFFWHITE)
	)


func _load_registries() -> void:
	for id in TOWER_IDS:
		var res_path := "res://resources/towers/tower_%s.tres" % id
		if ResourceLoader.exists(res_path):
			tower_registry[id] = load(res_path)
	for id in ENEMY_IDS:
		var res_path := "res://resources/enemies/enemy_%s.tres" % id
		if ResourceLoader.exists(res_path):
			enemy_registry[id] = load(res_path)


func _setup_containers() -> void:
	tower_container = Node2D.new()
	tower_container.name = "Towers"
	tower_container.z_index = 6
	add_child(tower_container)
	enemy_container = Node2D.new()
	enemy_container.name = "Enemies"
	enemy_container.z_index = 12
	add_child(enemy_container)
	projectile_container = Node2D.new()
	projectile_container.name = "Projectiles"
	projectile_container.z_index = 30
	add_child(projectile_container)
	effect_container = Node2D.new()
	effect_container.name = "Effects"
	effect_container.z_index = 40
	add_child(effect_container)


func _setup_managers() -> void:
	path = PathManager.new()
	path.name = "PathManager"
	add_child(path)
	path.setup(level_data)

	grid = GridManager.new()
	grid.name = "GridManager"
	add_child(grid)
	grid.setup(level_data, path.road_cells)

	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)
	economy.setup(level_data)

	waves = WaveManager.new()
	waves.name = "WaveManager"
	add_child(waves)
	waves.setup(self, level_data)

	abilities = AbilityManager.new()
	abilities.name = "AbilityManager"
	add_child(abilities)
	abilities.setup(self, level_data)


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "BattleCamera"
	camera.position = Vector2(800, 440)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 900
	camera.enabled = true
	add_child(camera)


func _setup_scene_nodes() -> void:
	var terrain := get_node_or_null("Terrain")
	if terrain and terrain.has_method("setup"):
		terrain.call("setup", level_data)
	var path_network := get_node_or_null("PathNetwork")
	if path_network and path_network.has_method("setup"):
		path_network.call("setup", self)
	var grid_overlay := get_node_or_null("GridOverlay")
	if grid_overlay and grid_overlay.has_method("setup"):
		grid_overlay.call("setup", self)
	var gate_a := get_node_or_null("SpawnGateA")
	if gate_a and gate_a.has_method("setup"):
		gate_a.call("setup", path.get_start(0), "ENTRY ALPHA")
	var gate_b := get_node_or_null("SpawnGateB")
	if gate_b and gate_b.has_method("setup"):
		gate_b.call("setup", path.get_start(1), "ENTRY BETA")
	base_core = get_node_or_null("BaseCore")
	if base_core and base_core.has_method("setup"):
		var end_a := path.get_end(0)
		var end_b := path.get_end(1)
		var base_pos := Vector2(GameConfig.MAP_ORIGIN.x + 21.0 * GameConfig.CELL_SIZE + 20.0,
			(end_a.y + end_b.y) * 0.5)
		base_core.call("setup", self, base_pos)


func _setup_ghosts() -> void:
	var ghost_script := load("res://scripts/core/PlacementGhost.gd")
	ghost = Node2D.new()
	ghost.set_script(ghost_script)
	ghost.z_index = 25
	ghost.visible = false
	add_child(ghost)
	ghost.call("setup", self)

	var ability_script := load("res://scripts/core/AbilityPreview.gd")
	ability_preview = Node2D.new()
	ability_preview.set_script(ability_script)
	ability_preview.z_index = 24
	ability_preview.visible = false
	add_child(ability_preview)
	ability_preview.call("setup", self)


func _physics_process(delta: float) -> void:
	if match_finished:
		return
	var step: float = minf(delta * float(game_speed), GameConfig.MAX_DELTA * 3.0)
	level_time += step
	waves.tick(step)
	abilities.tick(step)
	_update_shake(delta)
	if ability_target_id != "":
		ability_preview.global_position = get_global_mouse_position()
		ability_preview.queue_redraw()


func _update_shake(delta: float) -> void:
	if shake_strength <= 0.0:
		if camera:
			camera.offset = Vector2.ZERO
		return
	if not GameConfig.as_bool(GameState.settings.get("screen_shake", true)):
		shake_strength = 0.0
		camera.offset = Vector2.ZERO
		return
	shake_strength = maxf(0.0, shake_strength - delta * 18.0)
	camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))


func _unhandled_input(event: InputEvent) -> void:
	if match_finished:
		return
	if event is InputEventMouseMotion:
		mouse_world = get_global_mouse_position()
		_update_hover()
		return
	if event is InputEventMouseButton and event.pressed:
		mouse_world = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_actions()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_on_key(event)


func _on_key(event: InputEventKey) -> void:
	match event.keycode:
		KEY_ESCAPE:
			if build_tower_id != "" or ability_target_id != "" or selected_tower != null:
				_cancel_actions()
			else:
				toggle_pause()
		KEY_SPACE:
			request_next_wave()
		KEY_U:
			upgrade_selected()
		KEY_X, KEY_DELETE:
			sell_selected()
		KEY_TAB:
			cycle_tower_selection()
		KEY_M:
			_toggle_mute()
		KEY_F1:
			set_game_speed(1)
		KEY_F2:
			set_game_speed(2)
		KEY_F3:
			set_game_speed(3)
		KEY_Q:
			begin_ability("orbital_strike")
		KEY_W:
			begin_ability("emp")
		KEY_E:
			begin_ability("reinforcement_drones")
		KEY_R:
			begin_ability("emergency_repair")
		KEY_T:
			begin_ability("supply_drop")
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
			var index := 9 if event.keycode == KEY_0 else event.keycode - KEY_1
			if index >= 0 and index < TOWER_IDS.size():
				select_build_type(TOWER_IDS[index])


func _on_left_click() -> void:
	if ability_target_id != "":
		if abilities.can_use(ability_target_id):
			abilities.use_ability(ability_target_id, get_global_mouse_position())
		else:
			AudioManager.play_ui("ui_error")
		_clear_ability_target()
		return
	if build_tower_id != "":
		var cell := grid.world_to_cell(get_global_mouse_position())
		try_place_tower(cell)
		return
	var cell := grid.world_to_cell(get_global_mouse_position())
	var tower = grid.occupied.get(cell, null)
	if tower != null and is_instance_valid(tower):
		select_tower(tower)
	else:
		clear_selection()


func _update_hover() -> void:
	hover_cell = grid.world_to_cell(mouse_world)
	if build_tower_id != "" and build_data != null:
		ghost.visible = true
		ghost.global_position = grid.cell_to_world(hover_cell)
		var result := grid.can_build(hover_cell, build_data.cost, economy.credits, true)
		ghost.call("update_preview", build_data, GameConfig.as_bool(result.ok), String(result.reason))
	elif ability_target_id != "":
		ghost.visible = false
		ability_preview.visible = true
		ability_preview.global_position = mouse_world
		ability_preview.queue_redraw()
	else:
		ghost.visible = false
		ability_preview.visible = false


func select_build_type(tower_id: String) -> void:
	if not level_data.available_towers.has(tower_id):
		EventBus.notification.emit("This tower is not available in this sector.", GameConfig.WARNING_RED)
		AudioManager.play_ui("ui_error")
		return
	var data: TowerData = tower_registry.get(tower_id, null)
	if data == null:
		return
	if economy.credits < data.cost:
		EventBus.notification.emit("Not enough credits for %s." % data.display_name, GameConfig.WARNING_RED)
		AudioManager.play_ui("ui_error")
		return
	clear_selection()
	build_tower_id = tower_id
	build_data = data
	ability_target_id = ""
	ability_preview.visible = false
	ghost.visible = true
	EventBus.build_mode_changed.emit(tower_id)
	AudioManager.play_ui("ui_click")


func cancel_build() -> void:
	build_tower_id = ""
	build_data = null
	ghost.visible = false
	EventBus.build_mode_changed.emit("")


func try_place_tower(cell: Vector2i) -> bool:
	if build_data == null:
		return false
	var check := grid.can_build(cell, build_data.cost, economy.credits, true)
	if not GameConfig.as_bool(check.ok):
		var reason := String(check.reason)
		EventBus.notification.emit("Cannot build here: %s" % reason, GameConfig.WARNING_RED)
		AudioManager.play_ui("ui_error")
		ghost.call("flash_error")
		return false
	var scene_path := build_data.scene_path
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		EventBus.notification.emit("Tower scene is missing: %s" % scene_path, GameConfig.WARNING_RED)
		return false
	if not economy.spend(build_data.cost):
		return false
	var scene: PackedScene = load(scene_path)
	var tower = scene.instantiate()
	tower_container.add_child(tower)
	tower.call("setup", self, cell)
	grid.mark_occupied(cell, tower)
	stats["towers_built"] = int(stats.towers_built) + 1
	EventBus.tower_placed.emit(tower)
	AudioManager.play_sound("build", 0.6, 1.0)
	spawn_fx_at("dust", grid.cell_to_world(cell), Color(0.8, 0.55, 0.32), 38.0)
	shake(2.0)
	if economy.credits < build_data.cost:
		cancel_build()
	else:
		ghost.call("update_preview", build_data, true, "")
	return true


func select_tower(tower: Node) -> void:
	if selected_tower != null and is_instance_valid(selected_tower) and selected_tower.has_method("set_selected"):
		selected_tower.set_selected(false)
	selected_tower = tower
	if selected_tower and selected_tower.has_method("set_selected"):
		selected_tower.set_selected(true)
	EventBus.tower_selected.emit(selected_tower)
	AudioManager.play_ui("ui_click")


func clear_selection() -> void:
	if selected_tower != null and is_instance_valid(selected_tower) and selected_tower.has_method("set_selected"):
		selected_tower.set_selected(false)
	selected_tower = null
	EventBus.selection_cleared.emit()


func cycle_tower_selection() -> void:
	var towers := get_tree().get_nodes_in_group("towers")
	if towers.is_empty():
		return
	var index := towers.find(selected_tower)
	index = (index + 1) % towers.size()
	select_tower(towers[index])


func upgrade_selected() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		return
	if not selected_tower.can_upgrade():
		AudioManager.play_ui("ui_error")
		EventBus.notification.emit("Upgrade unavailable or not enough credits.", GameConfig.WARNING_RED)
		return
	selected_tower.upgrade()


func sell_selected() -> void:
	if selected_tower == null or not is_instance_valid(selected_tower):
		return
	selected_tower.sell()


func set_targeting_priority(priority: String, tower: Node = null) -> void:
	var target := tower if tower != null else selected_tower
	if target != null and is_instance_valid(target):
		target.targeting_priority = priority


func remove_tower(tower: Node) -> void:
	if tower == null or not is_instance_valid(tower):
		return
	if grid != null:
		grid.clear_occupied(tower.cell)
	if selected_tower == tower:
		clear_selection()
	EventBus.tower_sold.emit(tower)
	spawn_fx_at("dust", tower.global_position, Color(0.8, 0.55, 0.32), 40.0)
	tower.queue_free()


func request_next_wave() -> bool:
	if match_finished:
		return false
	if not waves.start_next_wave():
		return false
	AudioManager.play_sound("wave_start", 0.65, 1.0)
	return true


func on_wave_started(_index: int, _total: int, _wave: WaveData) -> void:
	simulation_running = true


func on_wave_cleared(_index: int, _bonus: int) -> void:
	stats["waves_cleared"] = int(stats.waves_cleared) + 1
	AudioManager.play_sound("wave_complete", 0.65, 1.0)
	var relay_income := 0
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower != null and is_instance_valid(tower) and tower.tower_data != null and tower.tower_data.id == "relay":
			relay_income += int(tower.stats.income_per_wave)
	if relay_income > 0:
		economy.add_credits(relay_income, "relay")
		EventBus.notification.emit("Command Relay stipend: +%d credits" % relay_income, Color(0.55, 0.95, 0.65))


func on_all_waves_cleared() -> void:
	if match_finished:
		return
	_trigger_victory()


func start_next_wave() -> void:
	request_next_wave()


func _trigger_victory() -> void:
	if match_finished:
		return
	match_finished = true
	simulation_running = false
	clear_selection()
	cancel_build()
	_clear_ability_target()
	stats["credits_earned"] = maxi(0, economy.total_earned - economy.starting_credits)
	stats["base_health"] = base_health
	stats["base_max"] = base_max
	stats["time"] = level_time
	stats["level_name"] = level_data.display_name
	stats["level_number"] = level_data.level_number
	var stars := GameState.stars_for_integrity(base_health, base_max)
	var result := GameState.complete_level(stars, stats)
	AudioManager.play_sound("victory", 0.85, 1.0)
	var screen_scene: PackedScene = load("res://scenes/main/VictoryScreen.tscn")
	if screen_scene:
		var screen = screen_scene.instantiate()
		add_child(screen)
		if screen.has_method("setup"):
			screen.call("setup", result, self)


func _trigger_defeat() -> void:
	if match_finished:
		return
	match_finished = true
	simulation_running = false
	clear_selection()
	cancel_build()
	_clear_ability_target()
	stats["base_health"] = base_health
	stats["base_max"] = base_max
	stats["time"] = level_time
	stats["level_name"] = level_data.display_name
	stats["level_number"] = level_data.level_number
	var result := GameState.record_failure(stats)
	AudioManager.play_sound("defeat", 0.8, 1.0)
	var screen_scene: PackedScene = load("res://scenes/main/DefeatScreen.tscn")
	if screen_scene:
		var screen = screen_scene.instantiate()
		add_child(screen)
		if screen.has_method("setup"):
			screen.call("setup", result, self)


func damage_base(amount: int) -> void:
	if amount <= 0 or match_finished:
		return
	base_health = maxi(0, base_health - amount)
	EventBus.base_health_changed.emit(base_health, base_max)
	EventBus.notification.emit("Base integrity -%d" % amount, GameConfig.WARNING_RED)
	AudioManager.play_sound("base_damage", 0.75, 0.95)
	shake(6.0)
	if base_core and base_core.has_method("flash"):
		base_core.call("flash")
	if base_health <= 0:
		_trigger_defeat()


func heal_base(amount: int) -> void:
	if match_finished:
		return
	base_health = mini(base_max, base_health + amount)
	EventBus.base_health_changed.emit(base_health, base_max)
	EventBus.notification.emit("Base repaired +%d integrity" % amount, Color(0.55, 0.95, 0.65))
	if base_core and base_core.has_method("repair_flash"):
		base_core.call("repair_flash")


func handle_enemy_removed(enemy: Node, leaked: bool) -> void:
	if leaked:
		stats["leaks"] = int(stats.leaks) + 1
		damage_base(int(enemy.enemy_data.leak_damage))
	else:
		stats["kills"] = int(stats.kills) + 1
	if waves:
		waves.on_enemy_removed()


func spawn_enemy(enemy_id: String, path_id: int) -> bool:
	if match_finished:
		return false
	var data: EnemyData = enemy_registry.get(enemy_id, null)
	if data == null:
		push_warning("Unknown enemy id: %s" % enemy_id)
		return false
	var scene_path := data.scene_path
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("Missing enemy scene: %s" % scene_path)
		return false
	var scene: PackedScene = load(scene_path)
	var enemy = scene.instantiate()
	enemy_container.add_child(enemy)
	enemy.call("setup", self, path_id)
	if data.is_boss:
		EventBus.notification.emit("BROOD TYRANT DETECTED", GameConfig.WARNING_RED)
		EventBus.boss_phase.emit("The Brood Tyrant enters the field!")
		AudioManager.play_sound("boss_roar", 0.8, 0.9)
	elif data.is_elite:
		EventBus.notification.emit("Arachnid Elite approaching!", GameConfig.WARNING_RED)
	return true


func summon_reinforcements(path_id: int, enemy_id: String, count: int, progress_back: float = 120.0) -> void:
	for i in count:
		var before := get_tree().get_nodes_in_group("enemies").size()
		if spawn_enemy(enemy_id, path_id):
			if waves:
				waves.enemies_alive += 1
			var group := get_tree().get_nodes_in_group("enemies")
			if group.size() > before:
				var newcomer = group[group.size() - 1]
				if newcomer != null and is_instance_valid(newcomer):
					var boss_progress := 0.0
					for candidate in group:
						if candidate != newcomer and candidate.enemy_data.is_boss:
							boss_progress = maxf(boss_progress, candidate.progress)
					newcomer.progress = maxf(0.0, boss_progress - progress_back - float(i) * 24.0)
					newcomer.global_position = path.point_at_distance(path_id, newcomer.progress)


func begin_ability(ability_id: String) -> void:
	if match_finished:
		return
	if not abilities.is_unlocked(ability_id):
		EventBus.notification.emit("Ability not unlocked in this sector.", GameConfig.WARNING_RED)
		AudioManager.play_ui("ui_error")
		return
	if not abilities.can_use(ability_id):
		EventBus.notification.emit("Ability is cooling down or out of charges.", GameConfig.WARNING_RED)
		AudioManager.play_ui("ui_error")
		return
	var ability: AbilityData = abilities.get_ability(ability_id)
	if ability.target_mode == "self":
		abilities.use_ability(ability_id, global_position)
		return
	cancel_build()
	clear_selection()
	ability_target_id = ability_id
	ability_preview.visible = true
	ability_preview.call("set_ability", ability)
	ability_preview.global_position = get_global_mouse_position()
	EventBus.notification.emit("Select a target area for %s." % ability.display_name, ability.color)
	AudioManager.play_ui("ui_confirm")


func _clear_ability_target() -> void:
	ability_target_id = ""
	if ability_preview:
		ability_preview.visible = false


func _cancel_actions() -> void:
	cancel_build()
	clear_selection()
	_clear_ability_target()
	AudioManager.play_ui("ui_cancel")


func ability_orbital_strike(position: Vector2, radius: float, damage: float, delay: float) -> void:
	var scene: PackedScene = load("res://scenes/fx/OrbitalStrike.tscn")
	var strike = scene.instantiate()
	effect_container.add_child(strike)
	strike.call("configure", self, radius, damage, delay, Color(1.0, 0.55, 0.2))
	strike.global_position = position
	AudioManager.play_sound("ability_strike", 0.55, 1.0)


func ability_emp(position: Vector2, radius: float, damage: float, stun: float, slow: float, duration: float) -> void:
	var enemies := TargetingSystem.enemies_in_radius(get_tree(), position, radius, true, true)
	for enemy in enemies:
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(stun)
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(slow, duration)
		enemy.shield_current = 0.0
		DamageSystem.hit(enemy, damage, "electric", 0.5, null)
	spawn_fx_at("emp", position, Color(0.4, 0.8, 1.0), radius)
	shake(5.0)
	AudioManager.play_sound("ability_emp", 0.75, 0.9)


func ability_deploy_drones(position: Vector2, radius: float, duration: float, damage: float) -> void:
	var scene: PackedScene = load("res://scenes/fx/AbilityDrone.tscn")
	for i in 2:
		var drone = scene.instantiate()
		effect_container.add_child(drone)
		drone.call("configure", self, position, radius, duration, damage, i)
		drone.global_position = position
	spawn_fx_at("emp", position, Color(0.55, 1.0, 0.6), radius)
	AudioManager.play_sound("ability_supply", 0.6, 1.1)


func ability_repair_base(amount: int) -> void:
	heal_base(amount)
	if base_core:
		spawn_fx_at("heal", base_core.global_position, Color(0.55, 1.0, 0.65), 60.0)
	AudioManager.play_sound("ability_repair", 0.7, 1.0)


func ability_supply_drop(credits: int) -> void:
	economy.add_credits(credits, "supply drop")
	EventBus.notification.emit("Supply drop recovered: +%d credits" % credits, Color(0.95, 0.8, 0.3))
	if base_core:
		spawn_fx_at("heal", base_core.global_position, Color(0.95, 0.85, 0.35), 55.0)
	AudioManager.play_sound("ability_supply", 0.7, 1.0)


func spawn_orbital_beam(position: Vector2, radius: float, damage: float, delay: float, color: Color) -> void:
	var scene: PackedScene = load("res://scenes/fx/OrbitalStrike.tscn")
	var strike = scene.instantiate()
	effect_container.add_child(strike)
	strike.call("configure", self, radius, damage, delay, color)
	strike.global_position = position


func spawn_mine(position: Vector2, damage: float, radius: float) -> void:
	var scene: PackedScene = load("res://scenes/towers/ProximityMine.tscn")
	var mine = scene.instantiate()
	effect_container.add_child(mine)
	mine.global_position = position
	mine.call("configure", self, damage, radius)


func mine_exists_near(position: Vector2, radius: float) -> bool:
	for mine in get_tree().get_nodes_in_group("mines"):
		if is_instance_valid(mine) and position.distance_to(mine.global_position) <= radius:
			return true
	return false


func add_projectile(projectile: Node) -> void:
	projectile_container.add_child(projectile)


func spawn_fx_at(style: String, position: Vector2, color: Color, radius: float = 24.0) -> void:
	var path := String(FX_PATHS.get(style, FX_PATHS["hit"]))
	if not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path)
	var fx = scene.instantiate()
	effect_container.add_child(fx)
	fx.global_position = position
	if fx.has_method("configure"):
		fx.call("configure", self, color, radius)


func spawn_beam(from: Vector2, to: Vector2, color: Color, duration: float, style: String = "beam") -> void:
	var path := "res://scenes/fx/TeslaArc.tscn" if style == "tesla" else "res://scenes/fx/Beam.tscn"
	if not ResourceLoader.exists(path):
		return
	var scene: PackedScene = load(path)
	var beam = scene.instantiate()
	effect_container.add_child(beam)
	beam.set("style", style)
	beam.call("configure", self, from, to, color, duration)


func spawn_hit_fx(position: Vector2, kind: String, color: Color) -> void:
	match kind:
		"frost":
			spawn_fx_at("frost", position, color, 26.0)
		"explosive":
			spawn_fx_at("explosion", position, color, 30.0)
		_:
			spawn_fx_at("hit", position, color, 18.0)


func spawn_damage_text(position: Vector2, text: String, color: Color) -> void:
	var scene: PackedScene = load("res://scenes/ui/DamageNumber.tscn")
	if scene == null:
		return
	var label = scene.instantiate()
	effect_container.add_child(label)
	label.global_position = position
	label.call("setup", text, color)


func _on_damage_number(world_position: Vector2, amount: float, kind: String) -> void:
	if match_finished or amount <= 0.0:
		return
	var color := GameConfig.OFFWHITE
	match kind:
		"fire":
			color = Color(1.0, 0.55, 0.18)
		"frost":
			color = Color(0.65, 0.92, 1.0)
		"electric":
			color = Color(0.55, 0.9, 1.0)
		"explosive":
			color = Color(1.0, 0.7, 0.25)
		"corrosive":
			color = Color(0.6, 1.0, 0.3)
		"energy":
			color = Color(1.0, 0.6, 0.85)
	var text := "%d" % int(roundf(amount)) if amount >= 10.0 else "%.1f" % amount
	spawn_damage_text(world_position, text, color)


func shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)


func set_game_speed(speed: int) -> void:
	game_speed = clampi(speed, 1, 3)
	GameState.settings["speed"] = game_speed
	GameState.save_to_disk()
	EventBus.speed_changed.emit(game_speed)
	EventBus.notification.emit("Game speed: %dx" % game_speed, GameConfig.AMBER)


func toggle_pause() -> void:
	if match_finished:
		return
	var new_state := not get_tree().paused
	get_tree().paused = new_state
	EventBus.game_paused.emit(new_state)
	if pause_menu and pause_menu.has_method("set_visible_state"):
		pause_menu.call("set_visible_state", new_state)


func set_paused(paused: bool) -> void:
	if match_finished:
		return
	get_tree().paused = paused
	EventBus.game_paused.emit(paused)
	if pause_menu and pause_menu.has_method("set_visible_state"):
		pause_menu.call("set_visible_state", paused)


func _toggle_mute() -> void:
	var now_muted := not GameConfig.as_bool(GameState.settings.get("muted", false))
	GameState.update_setting("muted", now_muted)
	AudioManager.set_muted(now_muted)
	EventBus.notification.emit("Audio muted" if now_muted else "Audio unmuted", GameConfig.AMBER)


func is_position_on_map(position: Vector2) -> bool:
	var rect := Rect2(GameConfig.MAP_ORIGIN - Vector2(120, 120),
		Vector2(level_data.grid_width * GameConfig.CELL_SIZE + 240, level_data.grid_height * GameConfig.CELL_SIZE + 240))
	return rect.has_point(position)


func get_available_towers() -> Array:
	return level_data.available_towers


func get_all_tower_data() -> Array:
	var out: Array = []
	for id in TOWER_IDS:
		if tower_registry.has(id):
			out.append(tower_registry[id])
	return out


func get_ability_manager() -> AbilityManager:
	return abilities


func restart_level() -> void:
	GameState.restart_level()


func go_to_menu() -> void:
	GameState.goto_main_menu()


func go_to_level_select() -> void:
	GameState.goto_level_select()


func next_level() -> void:
	GameState.next_level()
