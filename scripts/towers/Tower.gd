class_name Tower
extends Node2D
## Base tower behaviour shared by all ten tower scenes. Stats are data-driven.

@export var tower_data: TowerData

var level: Node
var cell: Vector2i
var current_level: int = 1
var invested: int = 0
var stats: Dictionary = {}
var targeting_priority: String = "first"
var selected: bool = false
var disabled_timer: float = 0.0
var aim_angle: float = 0.0

var _cooldown: float = 0.0
var _deploy_timer: float = 0.0
var _visual: Node2D
var _range_indicator: Node2D
var _muzzle: Marker2D
var _animation_player: AnimationPlayer
var _audio_player: AudioStreamPlayer

## Support auras change only when a relay is built, upgraded or sold. Rescan
## them a few times per second instead of on every shot from every tower.
var _support_cache: Dictionary = {"damage": 0.0, "rate": 0.0}
var _support_timer: float = 0.0

## Packed projectile scenes are shared by all towers of the same type.
static var _projectile_scene_cache: Dictionary = {}


func _ready() -> void:
	add_to_group("towers")
	_visual = get_node_or_null("Visual")
	_range_indicator = get_node_or_null("RangeIndicator")
	_muzzle = get_node_or_null("Muzzle")
	_animation_player = get_node_or_null("AnimationPlayer")
	_audio_player = get_node_or_null("AudioStreamPlayer")
	if tower_data != null:
		invested = tower_data.cost
		targeting_priority = "first"
		_recalculate_stats()
		if _range_indicator and _range_indicator.has_method("set_range"):
			_range_indicator.set_range(float(stats.attack_range))


func setup(owner_level: Node, grid_cell: Vector2i) -> void:
	level = owner_level
	cell = grid_cell
	global_position = level.grid.cell_to_world(cell)
	z_index = 6
	invested = tower_data.cost
	_cooldown = 0.35
	_deploy_timer = 0.4
	_recalculate_stats()
	if _range_indicator and _range_indicator.has_method("set_range"):
		_range_indicator.set_range(float(stats.attack_range))
	if _range_indicator:
		_range_indicator.visible = false
	if _visual and _visual.has_method("configure"):
		_visual.configure(tower_data)


func _physics_process(delta: float) -> void:
	if level == null or not is_instance_valid(level):
		return
	if not level.simulation_running or level.match_finished:
		return
	var step: float = delta * float(level.game_speed)
	step = minf(step, GameConfig.MAX_DELTA * 3.0)
	_support_timer -= step
	if _support_timer <= 0.0:
		_support_timer = 0.25
		_support_cache = _scan_support_bonus()
	if _animation_player and _animation_player.is_playing():
		pass
	if disabled_timer > 0.0:
		disabled_timer = maxf(0.0, disabled_timer - step)
		if _visual and _visual.has_method("set_disabled"):
			_visual.set_disabled(disabled_timer > 0.0)
		return
	if _visual and _visual.has_method("set_disabled"):
		_visual.set_disabled(false)
	_cooldown -= step
	_deploy_timer -= step

	if tower_data.id == "relay":
		return
	if tower_data.id == "mine":
		if _deploy_timer <= 0.0:
			_try_deploy_mine()
		return
	if _cooldown > 0.0:
		return
	_attack()


func _attack() -> void:
	match tower_data.id:
		"flame":
			_attack_flame()
		"tesla":
			_attack_tesla()
		"rail":
			_attack_rail()
		"orbital":
			_attack_orbital()
		_:
			_attack_projectile()


func _effective_stats() -> Dictionary:
	var buff := _support_cache
	var out := stats.duplicate()
	out["damage"] = float(stats.damage) * (1.0 + float(buff.damage))
	out["attack_rate"] = float(stats.attack_rate) * (1.0 + float(buff.rate))
	return out


func get_support_bonus() -> Dictionary:
	return _scan_support_bonus()


func _scan_support_bonus() -> Dictionary:
	var damage := 0.0
	var rate := 0.0
	if level == null:
		return {"damage": 0.0, "rate": 0.0}
	for other in TargetingSystem.towers(get_tree()):
		if other == self or not is_instance_valid(other):
			continue
		if other.tower_data == null or other.tower_data.id != "relay":
			continue
		if other.global_position.distance_to(global_position) <= float(other.stats.support_radius):
			damage += float(other.stats.support_buff)
			rate += float(other.stats.support_buff) * 0.5
	return {"damage": damage, "rate": rate}


func _attack_projectile() -> void:
	var eff := _effective_stats()
	var target := TargetingSystem.acquire(self, float(eff.attack_range), targeting_priority,
		GameConfig.as_bool(stats.get("anti_air", false)), tower_data.can_target_ground)
	if target == null:
		return
	set_aim_towards(target.global_position)
	var damage := float(eff.damage)
	var crit := false
	if tower_data.crit_chance > 0.0 and randf() < tower_data.crit_chance:
		damage *= 1.75
		crit = true
	_fire_projectile(target, damage, crit)
	_cooldown = 1.0 / maxf(0.05, float(eff.attack_rate))


func _fire_projectile(target: Node, damage: float, crit: bool) -> void:
	var path := tower_data.projectile_scene_path
	var scene: PackedScene = _projectile_scene_cache.get(path)
	if path == "" or (scene == null and not ResourceLoader.exists(path)):
		DamageSystem.hit(target, damage, tower_data.damage_type,
			float(stats.armor_penetration), self)
		_spawn_hit_fx(target.global_position, tower_data.damage_type)
		return
	if scene == null:
		scene = load(path)
		_projectile_scene_cache[path] = scene
	var missiles := maxi(1, int(stats.missiles))
	for i in missiles:
		var projectile := scene.instantiate()
		level.add_projectile(projectile)
		var aim_target := target
		if i > 0:
			var alternative := _nearest_other_target(target, i)
			if alternative != null:
				aim_target = alternative
		var spread := Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)) if missiles > 1 else Vector2.ZERO
		projectile.call("configure", {
			"level": level,
			"source": self,
			"target": aim_target,
			"position": _muzzle_position() + spread,
			"damage": damage,
			"damage_type": tower_data.damage_type,
			"speed": float(stats.projectile_speed),
			"splash": float(stats.splash_radius),
			"slow": float(stats.slow_amount),
			"slow_duration": float(stats.slow_duration),
			"freeze_chance": float(stats.freeze_chance),
			"freeze_duration": float(stats.freeze_duration),
			"corrode_duration": float(stats.corrode_duration),
			"armor_penetration": float(stats.armor_penetration),
			"can_hit_air": GameConfig.as_bool(stats.get("anti_air", false)),
			"crit": crit,
			"color": tower_data.primary_color,
			"style": tower_data.visual_style,
		})
	_flash_muzzle()
	_play_attack_sound()


func _nearest_other_target(exclude: Node, start_index: int) -> Node:
	var best: Node = null
	var best_distance := 1.0e20
	for enemy in TargetingSystem.enemies(get_tree()):
		if enemy == exclude or not is_instance_valid(enemy):
			continue
		if not enemy.is_targetable():
			continue
		if enemy.flying and not GameConfig.as_bool(stats.get("anti_air", false)):
			continue
		var d: float = global_position.distance_squared_to(enemy.global_position)
		if d < best_distance:
			best_distance = d
			best = enemy
	return best


func _attack_flame() -> void:
	var eff := _effective_stats()
	var enemies := TargetingSystem.enemies_in_radius(get_tree(), global_position,
		float(eff.attack_range), false)
	if enemies.is_empty():
		return
	set_aim_towards(enemies[0].global_position)
	for enemy in enemies:
		DamageSystem.hit(enemy, float(eff.damage), "fire", float(stats.armor_penetration), self)
		if enemy.has_method("apply_burn"):
			enemy.apply_burn(float(stats.burn_dps), float(stats.burn_duration) + _flame_bonus_duration(), self)
	_spawn_fx_at("flame", global_position, tower_data.primary_color, float(eff.attack_range))
	_play_attack_sound(0.7)
	_cooldown = 1.0 / maxf(0.05, float(eff.attack_rate))


func _flame_bonus_duration() -> float:
	# The level-3 White-Hot Vent upgrade extends burn duration via slow_duration_add.
	var bonus := 0.0
	for i in range(current_level - 1):
		if i < tower_data.upgrades.size():
			bonus += float(tower_data.upgrades[i].slow_duration_add)
	return bonus


func _attack_tesla() -> void:
	var eff := _effective_stats()
	var target := TargetingSystem.acquire(self, float(eff.attack_range), targeting_priority, true, true)
	if target == null:
		return
	var chain_count := int(stats.chain_count) + 1
	var hit_list: Array = []
	var current: Node = target
	var from: Vector2 = _muzzle_position()
	var damage := float(eff.damage)
	for i in chain_count:
		if current == null or not is_instance_valid(current):
			break
		hit_list.append(current)
		DamageSystem.hit(current, damage, "electric", float(stats.armor_penetration), self)
		if randf() < float(stats.stun_chance) and current.has_method("apply_stun"):
			current.apply_stun(float(stats.stun_duration))
		_spawn_beam(from, current.global_position, tower_data.primary_color, 0.12)
		from = current.global_position
		current = _next_chain_target(current, hit_list)
		damage *= 0.78
	_cooldown = 1.0 / maxf(0.05, float(eff.attack_rate))
	_flash_muzzle()
	_play_attack_sound()


func _next_chain_target(from: Node, already_hit: Array) -> Node:
	var best: Node = null
	var best_distance := 115.0 * 115.0
	for enemy in TargetingSystem.enemies(get_tree()):
		if enemy == from or already_hit.has(enemy) or not is_instance_valid(enemy):
			continue
		if not enemy.is_targetable():
			continue
		var d: float = from.global_position.distance_squared_to(enemy.global_position)
		if d < best_distance:
			best_distance = d
			best = enemy
	return best


func _attack_rail() -> void:
	var eff := _effective_stats()
	var target := TargetingSystem.acquire(self, float(eff.attack_range), "strongest", true, true)
	if target == null:
		return
	set_aim_towards(target.global_position)
	var damage := float(eff.damage)
	var crit := tower_data.crit_chance > 0.0 and randf() < tower_data.crit_chance
	if crit:
		damage *= 1.8
	if current_level >= 4 and target.health / maxf(1.0, target.max_health) < 0.25:
		damage *= 1.5
	_spawn_beam(_muzzle_position(), target.global_position, tower_data.primary_color, 0.22)
	DamageSystem.hit(target, damage, "kinetic", float(stats.armor_penetration), self)
	_spawn_hit_fx(target.global_position, "kinetic")
	_cooldown = 1.0 / maxf(0.05, float(eff.attack_rate))
	_play_attack_sound()


func _attack_orbital() -> void:
	var eff := _effective_stats()
	var target := _densest_cluster(float(eff.attack_range))
	if target == null:
		return
	var strike_position: Vector2 = target.global_position
	level.call("spawn_orbital_beam", strike_position, float(stats.splash_radius),
		float(eff.damage), 1.1, tower_data.primary_color)
	AudioManager.play_sound("orbital_charge", 0.5, 0.9)
	_flash_muzzle()
	_cooldown = 1.0 / maxf(0.05, float(eff.attack_rate))


func _densest_cluster(attack_range: float) -> Node:
	var best: Node = null
	var best_score := -1
	var candidates: Array = []
	for enemy in TargetingSystem.enemies(get_tree()):
		if not is_instance_valid(enemy) or not enemy.is_targetable():
			continue
		if enemy.flying and not GameConfig.as_bool(stats.get("anti_air", false)):
			continue
		if global_position.distance_squared_to(enemy.global_position) <= attack_range * attack_range:
			candidates.append(enemy)
	for candidate in candidates:
		var score := 0
		var splash_sq := float(stats.splash_radius) * float(stats.splash_radius)
		for other in candidates:
			if candidate.global_position.distance_squared_to(other.global_position) <= splash_sq:
				score += 1
		if score > best_score:
			best_score = score
			best = candidate
	return best


func _try_deploy_mine() -> void:
	var candidates: Array = []
	for cell in level.path.road_cells.keys():
		var world: Vector2 = level.grid.cell_to_world(cell)
		if global_position.distance_to(world) <= float(tower_data.attack_range):
			if not level.mine_exists_near(world, 24.0):
				candidates.append(world)
	if candidates.is_empty():
		_deploy_timer = 1.0
		return
	var chosen: Vector2 = candidates[randi() % candidates.size()]
	level.call("spawn_mine", chosen, float(stats.mine_damage), 62.0)
	_deploy_timer = maxf(1.2, float(stats.deploy_interval))
	AudioManager.play_sound("mine_deploy", 0.45, 1.0)


func _muzzle_position() -> Vector2:
	if _muzzle:
		return _muzzle.global_position
	return global_position + Vector2(20, 0).rotated(aim_angle)


func _flash_muzzle() -> void:
	if _visual and _visual.has_method("kick"):
		_visual.kick()
	level.call("spawn_fx_at", "muzzle", _muzzle_position(), tower_data.primary_color, 18.0)


func _spawn_beam(from: Vector2, to: Vector2, beam_color: Color, duration: float) -> void:
	level.call("spawn_beam", from, to, beam_color, duration)


func _spawn_hit_fx(at: Vector2, kind: String) -> void:
	level.call("spawn_hit_fx", at, kind, tower_data.primary_color)


func _spawn_fx_at(style: String, at: Vector2, fx_color: Color, radius: float) -> void:
	level.call("spawn_fx_at", style, at, fx_color, radius)


func _play_attack_sound(volume: float = 0.6) -> void:
	var sound := "shot_kinetic"
	match tower_data.id:
		"siege":
			sound = "shot_cannon"
		"flame":
			sound = "shot_flame"
		"tesla":
			sound = "shot_tesla"
		"missile":
			sound = "shot_missile"
		"cryo":
			sound = "shot_frost"
		"rail":
			sound = "shot_rail"
		"orbital":
			sound = "orbital_charge"
		_:
			sound = "shot_kinetic"
	AudioManager.play_sound(sound, volume, randf_range(0.94, 1.06))


func _recalculate_stats() -> void:
	if tower_data == null:
		return
	stats = {
		"damage": tower_data.damage,
		"attack_rate": tower_data.attack_rate,
		"attack_range": tower_data.attack_range,
		"projectile_speed": tower_data.projectile_speed,
		"splash_radius": tower_data.splash_radius,
		"slow_amount": tower_data.slow_amount,
		"slow_duration": tower_data.slow_duration,
		"freeze_chance": tower_data.freeze_chance,
		"freeze_duration": tower_data.freeze_duration,
		"corrode_duration": tower_data.corrode_duration,
		"armor_penetration": tower_data.armor_penetration,
		"chain_count": tower_data.chain_count,
		"burn_dps": tower_data.burn_dps,
		"burn_duration": tower_data.burn_duration,
		"missiles": tower_data.missiles,
		"crit_chance": tower_data.crit_chance,
		"stun_chance": tower_data.stun_chance,
		"stun_duration": tower_data.stun_duration,
		"support_radius": tower_data.support_radius,
		"support_buff": tower_data.support_buff,
		"income_per_wave": tower_data.income_per_wave,
		"deploy_interval": tower_data.deploy_interval,
		"mine_damage": tower_data.mine_damage,
		"anti_air": tower_data.anti_air,
	}
	for i in range(current_level - 1):
		if i >= tower_data.upgrades.size():
			break
		var upgrade: UpgradeData = tower_data.upgrades[i]
		stats["damage"] = float(stats.damage) + upgrade.damage_add
		stats["attack_range"] = float(stats.attack_range) + upgrade.range_add
		stats["attack_rate"] = float(stats.attack_rate) + upgrade.rate_add
		stats["splash_radius"] = float(stats.splash_radius) + upgrade.splash_add
		stats["projectile_speed"] = float(stats.projectile_speed) + upgrade.projectile_speed_add
		stats["armor_penetration"] = clampf(float(stats.armor_penetration) + upgrade.armor_pen_add, 0.0, 0.95)
		stats["slow_amount"] = clampf(float(stats.slow_amount) + upgrade.slow_add, 0.0, 0.85)
		stats["slow_duration"] = float(stats.slow_duration) + upgrade.slow_duration_add
		stats["freeze_chance"] = clampf(float(stats.freeze_chance) + upgrade.freeze_chance_add, 0.0, 0.9)
		stats["freeze_duration"] = float(stats.freeze_duration) + upgrade.freeze_duration_add
		stats["corrode_duration"] = float(stats.corrode_duration) + upgrade.corrode_duration_add
		stats["chain_count"] = int(stats.chain_count) + upgrade.chain_add
		stats["burn_dps"] = float(stats.burn_dps) + upgrade.burn_add
		stats["income_per_wave"] = int(stats.income_per_wave) + upgrade.income_add
		stats["support_buff"] = float(stats.support_buff) + upgrade.buff_add
		stats["support_radius"] = float(stats.support_radius) + upgrade.range_add
		stats["deploy_interval"] = maxf(0.9, float(stats.deploy_interval) + upgrade.deploy_interval_add)
		stats["mine_damage"] = float(stats.mine_damage) + upgrade.mine_damage_add
		stats["missiles"] = int(stats.missiles) + upgrade.missiles_add
		if upgrade.unlock_air:
			stats["anti_air"] = true
	if _range_indicator and _range_indicator.has_method("set_range"):
		_range_indicator.set_range(float(stats.attack_range))


func next_upgrade() -> UpgradeData:
	if tower_data == null or current_level >= tower_data.max_level:
		return null
	var index := current_level - 1
	if index < 0 or index >= tower_data.upgrades.size():
		return null
	return tower_data.upgrades[index]


func next_upgrade_cost() -> int:
	var upgrade := next_upgrade()
	return upgrade.cost if upgrade != null else 0


func can_upgrade() -> bool:
	var upgrade := next_upgrade()
	if upgrade == null:
		return false
	return level != null and level.economy.credits >= upgrade.cost


func upgrade() -> bool:
	if level == null or not can_upgrade():
		return false
	var upgrade := next_upgrade()
	if not level.economy.spend(upgrade.cost):
		return false
	invested += upgrade.cost
	current_level += 1
	_recalculate_stats()
	if _visual and _visual.has_method("on_upgrade"):
		_visual.on_upgrade()
	EventBus.tower_upgraded.emit(self)
	AudioManager.play_sound("upgrade", 0.65, 1.0)
	EventBus.notification.emit("%s upgraded to Mk %d" % [tower_data.display_name, current_level], GameConfig.AMBER)
	return true


func sell_value() -> int:
	if tower_data == null:
		return 0
	return int(floor(float(invested) * tower_data.sell_ratio))


func sell() -> void:
	if level == null:
		return
	level.economy.refund(sell_value())
	AudioManager.play_sound("sell", 0.6, 1.0)
	level.call("remove_tower", self)


func set_selected(value: bool) -> void:
	selected = value
	if _range_indicator:
		_range_indicator.visible = value
	if _visual:
		_visual.set_selected(value)


func apply_disable(duration: float) -> void:
	disabled_timer = maxf(disabled_timer, duration)
	EventBus.tower_disabled.emit(self, duration)
	AudioManager.play_sound("shot_frost", 0.35, 0.7)


func set_aim_towards(target_position: Vector2) -> void:
	aim_angle = (target_position - global_position).angle()
	if _visual and _visual.has_method("set_aim"):
		_visual.set_aim(aim_angle)


func get_range() -> float:
	return float(stats.get("attack_range", 0.0))
