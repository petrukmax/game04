extends Node
## Headless mechanics test suite for Mars Arachnid Defense.
## Run: godot --headless --path . res://tests/TestRunner.tscn
## Every check prints PASS/FAIL; the process exits non-zero on any failure.

const TOWER_IDS: Array[String] = [
	"pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital",
]
const ENEMY_IDS: Array[String] = [
	"scout", "worker", "warrior", "spitter", "healer", "burrower", "shieldbearer", "flyer", "elite", "boss",
]
const ABILITY_IDS: Array[String] = [
	"orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop",
]
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

var checks: int = 0
var failures: int = 0
var results: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		results.append("PASS  " + label)
	else:
		failures += 1
		results.append("FAIL  " + label)


func section(title: String) -> void:
	results.append("")
	results.append("== " + title + " ==")


func _run() -> void:
	section("Script compilation")
	_test_scripts()

	section("Resources")
	_validate_resources()

	section("Level 1 placement, economy and upgrades")
	await _test_level_one()

	section("Damage, shields and statuses")
	await _test_combat()

	section("Tower combat")
	await _test_tower_combat()

	section("Area abilities and boss phases")
	await _test_abilities_and_boss()

	section("Waves, abilities and save validation")
	await _test_waves_abilities_save()

	section("All level scenes")
	await _test_all_levels()

	section("UI scenes")
	_test_ui_scenes()

	for line in results:
		print(line)
	print("")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _test_scripts() -> void:
	var pending: Array[String] = ["res://scripts", "res://tests"]
	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry := dir.get_next()
		while entry != "":
			if not entry.begins_with("."):
				var full_path := dir_path.path_join(entry)
				if dir.current_is_dir():
					pending.append(full_path)
				elif entry.ends_with(".gd"):
					var script: Script = load(full_path)
					check(script != null, "Script compiles: " + full_path)
			entry = dir.get_next()
		dir.list_dir_end()


func _validate_resources() -> void:
	for id in TOWER_IDS:
		var path := "res://resources/towers/tower_%s.tres" % id
		var data: TowerData = load(path) if ResourceLoader.exists(path) else null
		check(data != null, "Tower resource loads: " + id)
		if data == null:
			continue
		check(data.id == id, "Tower id matches filename: " + id)
		check(data.cost > 0, "Tower has a cost: " + id)
		check(data.upgrades.size() == 3, "Tower has three upgrades: " + id)
		check(data.scene_path != "" and ResourceLoader.exists(data.scene_path), "Tower scene exists: " + id)
	for id in ENEMY_IDS:
		var path := "res://resources/enemies/enemy_%s.tres" % id
		var data: EnemyData = load(path) if ResourceLoader.exists(path) else null
		check(data != null, "Enemy resource loads: " + id)
		if data == null:
			continue
		check(data.id == id, "Enemy id matches filename: " + id)
		check(data.max_health > 0 and data.speed > 0, "Enemy has health and speed: " + id)
		check(data.scene_path != "" and ResourceLoader.exists(data.scene_path), "Enemy scene exists: " + id)
		check(data.resistances.size() >= 5, "Enemy defines resistances: " + id)
	for id in ABILITY_IDS:
		var path := "res://resources/abilities/ability_%s.tres" % id
		var data: AbilityData = load(path) if ResourceLoader.exists(path) else null
		check(data != null, "Ability resource loads: " + id)
		if data == null:
			continue
		check(data.cooldown > 0.0, "Ability has cooldown: " + id)
		check(data.display_name != "", "Ability has display name: " + id)
	var expected_difficulties := {"Easy": 5, "Medium": 5, "Very Hard": 5}
	var seen := {"Easy": 0, "Medium": 0, "Very Hard": 0}
	for n in range(1, 16):
		var path := "res://resources/levels/level_%02d.tres" % n
		var data: LevelData = load(path) if ResourceLoader.exists(path) else null
		check(data != null, "Level resource loads: %02d" % n)
		if data == null:
			continue
		check(data.level_number == n, "Level number matches filename: %02d" % n)
		seen[data.difficulty] = int(seen.get(data.difficulty, 0)) + 1
		check(data.wave_data_list.size() >= 5, "Level has at least five waves: %02d" % n)
		check(data.available_towers.size() >= 5, "Level offers at least five towers: %02d" % n)
		check(data.unlocked_abilities.size() >= 2, "Level unlocks at least two abilities: %02d" % n)
		for wave in data.wave_data_list:
			check(wave != null and wave.entries.size() > 0, "Wave has spawn entries: level %02d" % n)
	for difficulty in expected_difficulties.keys():
		check(int(seen.get(difficulty, 0)) == int(expected_difficulties[difficulty]),
			"Campaign has five %s levels" % difficulty)


func _test_level_one() -> void:
	var packed: PackedScene = load(LEVEL_SCENES[0])
	var level = packed.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame

	check(level.grid != null and level.path != null, "Level managers initialise")
	check(level.economy.credits == level.level_data.starting_credits, "Starting credits match data")
	check(level.base_health == level.level_data.base_health, "Base health matches data")
	check(level.waves.total_waves == level.level_data.wave_data_list.size(), "Wave manager knows all waves")
	check(level.grid.buildable_cells().size() > 20, "Level has a usable build area")

	var road_cell := Vector2i(-1, -1)
	for cell in level.grid.cells.keys():
		if int(level.grid.cells[cell]) == GridManager.CellState.ROAD:
			road_cell = cell
			break
	check(road_cell.x >= 0, "At least one road cell exists")
	var buildable: Vector2i = level.grid.find_nearest_buildable(road_cell)
	check(buildable.x >= 0, "A buildable cell sits near the road")

	var before_credits: int = level.economy.credits
	level.select_build_type("pulse")
	check(level.build_tower_id == "pulse", "Build mode selects the Pulse Turret")
	var road_result: Dictionary = level.grid.can_build(road_cell, 100, before_credits, true)
	check(not GameConfig.as_bool(road_result.ok), "Road cells are rejected for building")
	var road_placed: bool = level.try_place_tower(road_cell)
	check(not road_placed and level.economy.credits == before_credits, "Road placement costs nothing")

	var placed: bool = level.try_place_tower(buildable)
	check(placed, "Buildable cell accepts a tower")
	check(level.economy.credits == before_credits - 100, "Placing a Pulse Turret costs 100 credits")
	var tower = level.grid.occupied.get(buildable, null)
	check(tower != null and is_instance_valid(tower), "Placed tower is registered on the grid")
	if tower == null:
		level.queue_free()
		return
	check(tower.invested == 100, "Tower tracks invested credits")
	var blocked: bool = level.try_place_tower(buildable)
	check(not blocked, "Occupied cells reject a second tower")

	level.economy.add_credits(1000, "test")
	level.select_tower(tower)
	var damage_before := float(tower.stats.damage)
	var range_before := float(tower.stats.attack_range)
	check(tower.can_upgrade(), "Tower can upgrade when affordable")
	var upgraded: bool = tower.upgrade()
	check(upgraded and tower.current_level == 2, "Upgrade raises the tower to Mk 2")
	check(float(tower.stats.damage) > damage_before, "Upgrade increases damage")
	check(float(tower.stats.attack_range) > range_before, "Upgrade increases range")
	check(tower.invested > 100, "Upgrade increases invested value")

	var credits_before_sell: int = level.economy.credits
	var refund: int = tower.sell_value()
	tower.sell()
	await get_tree().process_frame
	check(not level.grid.occupied.has(buildable), "Selling clears the occupied cell")
	check(level.economy.credits == credits_before_sell + refund, "Selling refunds the documented value")
	check(level.stats.towers_built == 1, "Placement stat increments once")

	# Rebuild one turret for the wave test, then kill incoming enemies directly.
	level.economy.add_credits(1000, "test")
	level.select_build_type("pulse")
	level.try_place_tower(buildable)
	level.set_game_speed(3)
	var wave_ok: bool = level.request_next_wave()
	check(wave_ok, "First wave can be started")
	var frames := 0
	while frames < 900 and level.waves.finished_waves < 1:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(enemy) and not enemy.dead:
				enemy.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame
		frames += 1
	check(level.waves.finished_waves >= 1, "First wave completes after all spawns are cleared")
	check(int(level.stats.kills) > 0, "Killing enemies records kill statistics")
	check(level.waves.has_active_wave() == false, "No stale active wave remains after completion")

	level.set_game_speed(1)
	level.queue_free()
	await get_tree().process_frame


func _test_combat() -> void:
	var packed: PackedScene = load(LEVEL_SCENES[0])
	var level = packed.instantiate()
	add_child(level)
	await get_tree().process_frame

	check(level.spawn_enemy("shieldbearer", 0), "Shieldbearer can spawn")
	await get_tree().process_frame
	var shield_enemy = _last_enemy()
	check(shield_enemy != null, "Spawned shieldbearer joins the enemy group")
	if shield_enemy != null:
		var shield_before: float = shield_enemy.shield_current
		var health_before: float = shield_enemy.health
		DamageSystem.hit(shield_enemy, 40.0, "electric", 0.9, null)
		check(shield_enemy.shield_current < shield_before, "Shield absorbs incoming damage")
		check(is_equal_approx(shield_enemy.health, health_before), "Health is untouched while the shield holds")
		DamageSystem.hit(shield_enemy, 500.0, "electric", 0.9, null)
		check(shield_enemy.shield_current <= 0.0, "Electric damage overloads the shield")
		check(shield_enemy.health < health_before or shield_enemy.dead, "Health drops once the shield breaks")
		if not shield_enemy.dead:
			shield_enemy.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame

	var kill_credits_before: int = level.economy.credits
	check(level.spawn_enemy("scout", 1), "Scout can spawn")
	await get_tree().process_frame
	var scout = _last_enemy()
	if scout != null:
		var expected := DamageSystem.calculate(100.0, "kinetic", scout, 0.0)
		var applied: float = DamageSystem.hit(scout, 100.0, "kinetic", 0.0, null)
		check(applied > 0.0 and applied == expected, "Damage pipeline reports applied damage")
		if not scout.dead:
			scout.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame
		check(level.economy.credits > kill_credits_before, "Killing an enemy pays its bounty")

	check(level.spawn_enemy("burrower", 0), "Burrower can spawn")
	await get_tree().process_frame
	var burrower = _last_enemy()
	if burrower != null:
		burrower.burrow_active = true
		check(not burrower.is_targetable(), "Burrowed enemies cannot be targeted")
		burrower.burrow_active = false
		check(burrower.is_targetable(), "Surfacing enemies become targetable again")
		burrower.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame

	check(level.spawn_enemy("flyer", 0), "Flyer can spawn")
	await get_tree().process_frame
	var flyer = _last_enemy()
	if flyer != null:
		check(flyer.flying, "Flyer is flagged as airborne")
		flyer.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame

	level.queue_free()
	await get_tree().process_frame


func _test_tower_combat() -> void:
	var packed: PackedScene = load(LEVEL_SCENES[0])
	var level = packed.instantiate()
	add_child(level)
	await get_tree().process_frame
	var cells: Array[Vector2i] = level.grid.buildable_cells()
	check(cells.size() >= 12, "Enough build cells for tower tests")
	var slot := 0

	for id in ["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "orbital"]:
		if slot >= cells.size():
			break
		var tower = _place_tower(level, id, cells[slot])
		slot += 1
		check(tower != null, "Tower instantiates: " + id)
		if tower == null:
			continue
		var enemy = _spawn_dummy(level, tower.global_position + Vector2(92, 0), "warrior")
		check(enemy != null, "Dummy target spawns for " + id)
		if enemy == null:
			continue
		var before: float = enemy.health
		tower.call("_attack")
		for i in 150:
			await get_tree().physics_frame
			if enemy == null or not is_instance_valid(enemy) or enemy.dead or enemy.health < before:
				break
		var damaged: bool = not is_instance_valid(enemy) or enemy.dead or enemy.health < before
		check(damaged, "Tower deals damage: " + id)
		if id == "cryo" and is_instance_valid(enemy):
			check(enemy.slow_timer > 0.0, "Cryo Tower applies slow on impact")
		if id == "flame" and is_instance_valid(enemy):
			check(enemy.burn_timer > 0.0, "Flame Tower applies burn")
		_kill_enemy(enemy)
		await get_tree().physics_frame

	# Anti-air rules: a Pulse Turret cannot engage a flyer, a Missile Battery can.
	var pulse = _place_tower(level, "pulse", cells[slot])
	slot += 1
	var flyer = _spawn_dummy(level, pulse.global_position + Vector2(80, 0), "flyer")
	if flyer != null:
		var flyer_hp: float = flyer.health
		pulse.call("_attack")
		for i in 45:
			await get_tree().physics_frame
		check(is_instance_valid(flyer) and is_equal_approx(flyer.health, flyer_hp),
			"Ground-only tower cannot damage a flyer")
		_kill_enemy(flyer)
		await get_tree().physics_frame
	var missile = _place_tower(level, "missile", cells[slot])
	slot += 1
	var flyer_two = _spawn_dummy(level, missile.global_position + Vector2(80, 0), "flyer")
	if flyer_two != null:
		var flyer_two_hp: float = flyer_two.health
		missile.call("_attack")
		for i in 90:
			await get_tree().physics_frame
			if not is_instance_valid(flyer_two) or flyer_two.dead or flyer_two.health < flyer_two_hp:
				break
		check(not is_instance_valid(flyer_two) or flyer_two.dead or flyer_two.health < flyer_two_hp,
			"Anti-air tower engages a flyer")
		_kill_enemy(flyer_two)
		await get_tree().physics_frame

	# Relay support aura.
	var relay = _place_tower(level, "relay", cells[slot])
	slot += 1
	var supported = _place_tower(level, "pulse", cells[slot])
	slot += 1
	if relay != null and supported != null:
		supported.global_position = relay.global_position + Vector2(30, 0)
		var bonus: Dictionary = supported.get_support_bonus()
		check(float(bonus["damage"]) > 0.0, "Command Relay buffs nearby tower damage")
		check(float(bonus["rate"]) > 0.0, "Command Relay buffs nearby tower fire rate")

	# Mine layer deploys a proximity mine which damages a nearby enemy.
	var mine_tower = _place_tower(level, "mine", cells[slot])
	if mine_tower != null:
		mine_tower.call("_try_deploy_mine")
		await get_tree().process_frame
		var mines := get_tree().get_nodes_in_group("mines")
		check(mines.size() > 0, "Mine Layer deploys a proximity mine")
		if not mines.is_empty():
			var mine = mines[mines.size() - 1]
			mine.set("armed", true)
			var victim = _spawn_dummy(level, mine.global_position, "warrior")
			if victim != null:
				var victim_hp: float = victim.health
				for i in 40:
					await get_tree().physics_frame
					if not is_instance_valid(victim) or victim.dead or victim.health < victim_hp:
						break
				check(not is_instance_valid(victim) or victim.dead or victim.health < victim_hp,
					"Proximity mine explodes and damages enemies")
				_kill_enemy(victim)
				await get_tree().physics_frame

	level.queue_free()
	await get_tree().process_frame


func _test_abilities_and_boss() -> void:
	# EMP on level 2.
	var emp_level = load(LEVEL_SCENES[1]).instantiate()
	add_child(emp_level)
	await get_tree().process_frame
	var center := Vector2(820, 420)
	var shielded = _spawn_dummy(emp_level, center, "shieldbearer")
	var grounded = _spawn_dummy(emp_level, center + Vector2(28, 0), "warrior")
	if shielded != null and grounded != null:
		var shield_before: float = shielded.shield_current
		var health_before: float = grounded.health
		emp_level.abilities.cooldowns["emp"] = 0.0
		var emp_used: bool = emp_level.abilities.use_ability("emp", center)
		check(emp_used, "EMP Pulse can be used where unlocked")
		check(shielded.shield_current <= 0.0 and shield_before > 0.0, "EMP overloads energy shields")
		check(shielded.stun_timer > 0.0, "EMP stuns enemies")
		check(grounded.slow_timer > 0.0, "EMP slows enemies")
		check(grounded.health < health_before, "EMP deals electric damage")
		_kill_enemy(shielded)
		_kill_enemy(grounded)
		await get_tree().physics_frame
	emp_level.queue_free()
	await get_tree().process_frame

	# Reinforcement drones on level 6.
	var drone_level = load(LEVEL_SCENES[5]).instantiate()
	add_child(drone_level)
	await get_tree().process_frame
	var drone_center := Vector2(860, 440)
	var drone_target = _spawn_dummy(drone_level, drone_center, "warrior")
	var drones_before := get_tree().get_nodes_in_group("drones").size()
	drone_level.abilities.cooldowns["reinforcement_drones"] = 0.0
	var drones_used: bool = drone_level.abilities.use_ability("reinforcement_drones", drone_center)
	check(drones_used, "Reinforcement Drones can be deployed")
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group("drones").size() >= drones_before + 2,
		"Reinforcement Drones deploy two drones")
	if drone_target != null:
		var drone_hp: float = drone_target.health
		for i in 120:
			await get_tree().physics_frame
			if not is_instance_valid(drone_target) or drone_target.dead or drone_target.health < drone_hp:
				break
		check(not is_instance_valid(drone_target) or drone_target.dead or drone_target.health < drone_hp,
			"Reinforcement Drones damage nearby enemies")
		_kill_enemy(drone_target)
		await get_tree().physics_frame
	drone_level.queue_free()
	await get_tree().process_frame

	# Supply Drop on level 4.
	var supply_level = load(LEVEL_SCENES[3]).instantiate()
	add_child(supply_level)
	await get_tree().process_frame
	var credits_before: int = supply_level.economy.credits
	supply_level.abilities.cooldowns["supply_drop"] = 0.0
	var supply_used: bool = supply_level.abilities.use_ability("supply_drop", Vector2.ZERO)
	check(supply_used, "Supply Drop can be used where unlocked")
	check(supply_level.economy.credits == credits_before + 150, "Supply Drop grants 150 credits")
	check(supply_level.abilities.uses_remaining("supply_drop") == 1, "Supply Drop consumes one charge")
	supply_level.queue_free()
	await get_tree().process_frame

	# Boss phases and bounty.
	var boss_level = load(LEVEL_SCENES[0]).instantiate()
	add_child(boss_level)
	await get_tree().process_frame
	check(boss_level.spawn_enemy("boss", 0), "Brood Tyrant can spawn")
	await get_tree().process_frame
	var boss = _last_enemy()
	if boss != null:
		boss.set_physics_process(false)
		var enemies_before: int = get_tree().get_nodes_in_group("enemies").size()
		boss.health = boss.max_health * 0.728
		DamageSystem.hit(boss, 60.0, "kinetic", 0.95, null)
		check(boss.boss_phase == 1, "Boss enters phase 2 at 72% health")
		check(get_tree().get_nodes_in_group("enemies").size() > enemies_before,
			"Boss phase 2 summons brood reinforcements")
		boss.health = boss.max_health * 0.458
		boss.shield_current = 0.0
		DamageSystem.hit(boss, 60.0, "kinetic", 0.95, null)
		check(boss.boss_phase == 2, "Boss enters phase 3 at 45% health")
		check(boss.shield_current > 0.0, "Boss phase 3 raises a shield surge")
		boss.shield_current = 0.0
		boss.health = boss.max_health * 0.208
		DamageSystem.hit(boss, 60.0, "kinetic", 0.95, null)
		check(boss.boss_phase == 3, "Boss enters final fury at 20% health")
		check(boss.speed_mult > 1.0, "Boss final fury increases speed")
		var bounty_before: int = boss_level.economy.credits
		boss.shield_current = 0.0
		boss.receive_damage(999999.0, "kinetic", null, true)
		await get_tree().physics_frame
		check(boss_level.economy.credits >= bounty_before + 400, "Boss awards its 400 credit bounty")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.receive_damage(999999.0, "kinetic", null, true)
	await get_tree().physics_frame
	boss_level.queue_free()
	await get_tree().process_frame


func _place_tower(level: Node, id: String, cell: Vector2i) -> Node:
	var data: TowerData = load("res://resources/towers/tower_%s.tres" % id)
	if data == null:
		return null
	var scene: PackedScene = load(data.scene_path)
	if scene == null:
		return null
	var tower = scene.instantiate()
	level.tower_container.add_child(tower)
	tower.call("setup", level, cell)
	tower.set_physics_process(false)
	return tower


func _spawn_dummy(level: Node, position: Vector2, enemy_id: String) -> Node:
	if not level.spawn_enemy(enemy_id, 0):
		return null
	var enemy = _last_enemy()
	if enemy != null:
		enemy.set_physics_process(false)
		enemy.global_position = position
	return enemy


func _kill_enemy(enemy: Node) -> void:
	if enemy != null and is_instance_valid(enemy) and not enemy.dead:
		enemy.receive_damage(999999.0, "kinetic", null, true)


func _test_waves_abilities_save() -> void:
	var packed: PackedScene = load(LEVEL_SCENES[0])
	var level = packed.instantiate()
	add_child(level)
	await get_tree().process_frame

	level.damage_base(20)
	check(level.base_health == level.base_max - 20, "Base damage reduces integrity")
	var health_before: int = level.base_health
	var used: bool = level.abilities.use_ability("emergency_repair", Vector2.ZERO)
	check(used, "Emergency Repair can be used")
	if used:
		check(level.base_health == mini(level.base_max, health_before + 25), "Emergency Repair heals 25 integrity")
		check(level.abilities.uses_remaining("emergency_repair") == 1, "Repair consumes one charge")
		check(level.abilities.cooldown_left("emergency_repair") > 0.0, "Repair starts its cooldown")
		check(not level.abilities.can_use("emergency_repair"), "Abilities cannot be used during cooldown")
	level.abilities.cooldowns["emergency_repair"] = 0.0
	level.abilities.use_ability("emergency_repair", Vector2.ZERO)
	level.abilities.cooldowns["emergency_repair"] = 0.0
	check(not level.abilities.can_use("emergency_repair"), "Limited-use abilities stop at zero charges")

	check(not level.abilities.is_unlocked("emp"), "Emp is locked on level 1")
	check(not level.abilities.use_ability("emp", Vector2.ZERO), "Locked abilities cannot be used")

	level.abilities.cooldowns["orbital_strike"] = 0.0
	var strike_used: bool = level.abilities.use_ability("orbital_strike", Vector2(800, 400))
	check(strike_used, "Orbital Strike can be targeted at an area")
	check(level.abilities.cooldown_left("orbital_strike") > 0.0, "Orbital Strike starts its cooldown")

	# Save validation: bad values must be clamped or discarded, never crash.
	var validated: Dictionary = SaveManager._validate({
		"version": 999,
		"unlocked_level": 99,
		"completed": {"1": true, "2": false, "99": true},
		"best_stars": {"1": 9, "2": -4, "30": 3},
		"settings": {"master_volume": 5.0, "speed": 99, "muted": "yes"},
	})
	check(int(validated["unlocked_level"]) == 15, "Save clamps unlocked level to 15")
	var saved_completed: Dictionary = validated["completed"]
	var saved_stars: Dictionary = validated["best_stars"]
	var saved_settings: Dictionary = validated["settings"]
	check(GameConfig.as_bool(saved_completed.get("1", false)), "Save keeps valid completion flags")
	check(not GameConfig.as_bool(saved_completed.get("2", false)), "Save drops false completion flags")
	check(not saved_completed.has("99"), "Save drops out-of-range completion flags")
	check(int(saved_stars.get("1", 0)) == 3, "Save clamps star ratings to 3")
	check(not saved_stars.has("2"), "Save drops zero star ratings")
	check(not saved_stars.has("30"), "Save drops out-of-range star ratings")
	check(is_equal_approx(float(saved_settings["master_volume"]), 1.0), "Save clamps volume to 1.0")
	check(int(saved_settings["speed"]) == 3, "Save clamps speed to 3")
	check(SaveManager.last_error != "", "Unsupported save version reports a warning")

	level.queue_free()
	await get_tree().process_frame


func _test_all_levels() -> void:
	for index in LEVEL_SCENES.size():
		var packed: PackedScene = load(LEVEL_SCENES[index])
		check(packed != null, "Level scene loads: %02d" % (index + 1))
		if packed == null:
			continue
		var level = packed.instantiate()
		add_child(level)
		await get_tree().process_frame
		check(level.level_data != null, "Level scene has data: %02d" % (index + 1))
		if level.level_data != null:
			check(level.grid.buildable_cells().size() >= 12, "Level has build space: %02d" % (index + 1))
			check(level.path.total_length(0) > 400.0, "Path A has length: %02d" % (index + 1))
			check(level.path.total_length(1) > 400.0, "Path B has length: %02d" % (index + 1))
			var road_blocked := true
			for cell in level.path.road_cells.keys():
				var result: Dictionary = level.grid.can_build(cell, 100, 99999, true)
				if GameConfig.as_bool(result.ok):
					road_blocked = false
					break
			check(road_blocked, "No road cell is buildable: %02d" % (index + 1))
			check(level.waves.total_waves == level.level_data.wave_data_list.size(),
				"All waves registered: %02d" % (index + 1))
			check(level.spawn_enemy("scout", 0), "Enemy spawning works: %02d" % (index + 1))
			await get_tree().physics_frame
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(enemy):
					enemy.receive_damage(999999.0, "kinetic", null, true)
			await get_tree().physics_frame
		level.queue_free()
		await get_tree().process_frame


func _test_ui_scenes() -> void:
	var scenes := [
		"res://scenes/main/Boot.tscn", "res://scenes/main/MainMenu.tscn",
		"res://scenes/main/LevelSelect.tscn", "res://scenes/main/VictoryScreen.tscn",
		"res://scenes/main/DefeatScreen.tscn", "res://scenes/ui/HUD.tscn",
		"res://scenes/ui/PauseMenu.tscn", "res://scenes/ui/SettingsPanel.tscn",
		"res://scenes/ui/HelpPanel.tscn", "res://scenes/ui/Tooltip.tscn",
		"res://scenes/ui/WaveBanner.tscn", "res://scenes/ui/AbilityBar.tscn",
	]
	for path in scenes:
		check(ResourceLoader.exists(path), "UI scene exists: " + path)
		if ResourceLoader.exists(path):
			var packed: PackedScene = load(path)
			var instance = packed.instantiate()
			check(instance != null, "UI scene instantiates: " + path)
			if instance != null:
				instance.free()


func _last_enemy() -> Node:
	var enemies := get_tree().get_nodes_in_group("enemies")
	return enemies[enemies.size() - 1] if not enemies.is_empty() else null
