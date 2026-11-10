class_name Enemy
extends Node2D
## Path-following arachnid with shields, statuses, healing, spitting and boss phases.

@export var enemy_data: EnemyData

var level: Node
var path_id: int = 0
var health: float = 1.0
var max_health: float = 1.0
var shield_current: float = 0.0
var max_shield: float = 0.0
var progress: float = 0.0
var dead: bool = false
var removed: bool = false
var reward_granted: bool = false
var flying: bool = false

var speed_mult: float = 1.0
var slow_factor: float = 0.0
var slow_timer: float = 0.0
var stun_timer: float = 0.0
var freeze_timer: float = 0.0
var corrode_timer: float = 0.0
var burn_dps: float = 0.0
var burn_timer: float = 0.0
var burn_source: Node = null
var burn_tick: float = 0.0

var time_since_damage: float = 0.0
var heal_timer: float = 0.0
var spit_timer: float = 0.0
var spit_stop_timer: float = 0.0
var burrow_active: bool = false
var burrow_timer: float = 0.0
var burrow_was_active: bool = false
var elite_burst_timer: float = 0.0
var boss_phase: int = 0
var moving: bool = false
var hit_flash: float = 0.0

var lane_offset: Vector2 = Vector2.ZERO
var _number_timer: float = 0.0
var _pending_damage: float = 0.0
var _pending_kind: String = "kinetic"
var _visual: Node2D
var _health_bar: Node2D

## Lightweight opt-in profiler used by tests/StressTest.gd.
static var prof_enabled: bool = false
static var prof_calls: int = 0
static var prof_total_usec: int = 0
static var prof_path_usec: int = 0
static var prof_status_usec: int = 0
static var prof_visual_usec: int = 0


func _ready() -> void:
	add_to_group("enemies")
	_visual = get_node_or_null("Visual")
	_health_bar = get_node_or_null("HealthBar")
	if enemy_data != null:
		max_health = enemy_data.max_health
		health = max_health
		flying = enemy_data.flying
		max_shield = enemy_data.shield
		shield_current = max_shield
		if _visual and _visual.has_method("configure"):
			_visual.configure(enemy_data)
		if _health_bar and _health_bar.has_method("configure"):
			_health_bar.configure(enemy_data)


func setup(owner_level: Node, assigned_path: int) -> void:
	level = owner_level
	path_id = assigned_path
	max_health = enemy_data.max_health
	health = max_health
	max_shield = enemy_data.shield
	shield_current = max_shield
	flying = enemy_data.flying
	progress = 0.0
	z_index = 20 if flying else 12
	lane_offset = Vector2(randf_range(-7.0, 7.0), randf_range(-8.0, 8.0))
	global_position = level.path.get_start(path_id) + lane_offset
	if enemy_data.burrowed:
		burrow_timer = 2.5
		burrow_active = false
	if _visual and _visual.has_method("configure"):
		_visual.configure(enemy_data)
	if _health_bar and _health_bar.has_method("configure"):
		_health_bar.configure(enemy_data)
	spit_timer = randf_range(0.5, float(enemy_data.ranged_interval))
	heal_timer = randf_range(0.2, float(enemy_data.heal_interval))
	AudioManager.play_sound("enemy_spawn", 0.28, randf_range(0.9, 1.1))


func _physics_process(delta: float) -> void:
	var prof_start := Time.get_ticks_usec() if prof_enabled else 0
	if dead or removed or level == null:
		return
	if not level.simulation_running or level.match_finished:
		return
	var step: float = delta * float(level.game_speed)
	step = minf(step, GameConfig.MAX_DELTA * 3.0)
	time_since_damage += step
	hit_flash = maxf(0.0, hit_flash - step)
	_number_timer -= step

	_update_statuses(step)
	_update_shield(step)
	_update_healer(step)
	_update_spitter(step)
	_update_burrow(step)
	_update_boss(step)

	if prof_enabled:
		var after_status := Time.get_ticks_usec()
		prof_status_usec += after_status - prof_start
		prof_start = after_status
	if stun_timer > 0.0 or freeze_timer > 0.0:
		moving = false
		_tick_visual()
		return
	if spit_stop_timer > 0.0:
		spit_stop_timer -= step
		moving = false
		_tick_visual()
		return
	var speed_scale := 1.0
	if slow_timer > 0.0:
		speed_scale *= 1.0 - slow_factor
	if burrow_active:
		speed_scale *= 1.35
	if elite_burst_timer > 0.0:
		speed_scale *= 1.5
	var move_speed := float(enemy_data.speed) * speed_scale * speed_mult
	progress += move_speed * step
	moving = move_speed > 1.0
	var total: float = level.path.total_length(path_id)
	if progress >= total:
		_leak()
		return
	var point: Vector2 = level.path.point_at_distance(path_id, progress)
	var bob := 0.0
	if flying:
		bob = sin(progress * 0.035) * 7.0 - 20.0
	global_position = point + lane_offset + Vector2(0, bob)
	var ahead: Vector2 = level.path.point_at_distance(path_id, minf(total, progress + 8.0))
	if _visual:
		_visual.rotation = (ahead - point).angle()
	_tick_visual()
	if prof_enabled:
		var after_path := Time.get_ticks_usec()
		prof_path_usec += after_path - prof_start
		prof_calls += 1


func _tick_visual() -> void:
	if _visual and _visual.has_method("set_state"):
		_visual.set_state(moving, stun_timer > 0.0 or freeze_timer > 0.0, hit_flash > 0.0, burrow_active)


func _update_statuses(step: float) -> void:
	if slow_timer > 0.0:
		slow_timer = maxf(0.0, slow_timer - step)
		if slow_timer <= 0.0:
			slow_factor = 0.0
	if stun_timer > 0.0:
		stun_timer = maxf(0.0, stun_timer - step)
	if freeze_timer > 0.0:
		freeze_timer = maxf(0.0, freeze_timer - step)
	if corrode_timer > 0.0:
		corrode_timer = maxf(0.0, corrode_timer - step)
	if burn_timer > 0.0:
		burn_timer = maxf(0.0, burn_timer - step)
		burn_tick += step
		if burn_tick >= 0.35:
			burn_tick = 0.0
			if burn_dps > 0.0:
				receive_damage(burn_dps * 0.35, "fire", burn_source, true)
			if burn_timer <= 0.0:
				burn_dps = 0.0
	if _number_timer <= 0.0 and _pending_damage > 0.0:
		EventBus.damage_number.emit(global_position + Vector2(0, -30), _pending_damage, _pending_kind)
		_pending_damage = 0.0
		_number_timer = 0.2


func _update_shield(step: float) -> void:
	if max_shield <= 0.0 or shield_current >= max_shield:
		return
	if time_since_damage >= float(enemy_data.shield_delay):
		shield_current = minf(max_shield, shield_current + float(enemy_data.shield_regen) * step)


func _update_healer(step: float) -> void:
	if float(enemy_data.heal_amount) <= 0.0:
		return
	heal_timer -= step
	if heal_timer > 0.0:
		return
	heal_timer = float(enemy_data.heal_interval)
	var healed := 0
	var heal_radius_sq := float(enemy_data.heal_radius) * float(enemy_data.heal_radius)
	for other in TargetingSystem.enemies(get_tree()):
		if other == null or not is_instance_valid(other) or other == self or other.dead:
			continue
		if global_position.distance_squared_to(other.global_position) > heal_radius_sq:
			continue
		if other.health >= other.max_health:
			continue
		other.health = minf(other.max_health, other.health + float(enemy_data.heal_amount))
		level.call("spawn_fx_at", "heal", other.global_position, Color(0.55, 1.0, 0.6), 18.0)
		healed += 1
		if healed >= 4:
			break
	if healed > 0:
		level.call("spawn_fx_at", "heal", global_position, Color(0.55, 1.0, 0.6), 26.0)


func _update_spitter(step: float) -> void:
	if float(enemy_data.ranged_range) <= 0.0:
		return
	spit_timer -= step
	if spit_timer > 0.0:
		return
	var target: Node = null
	var best := float(enemy_data.ranged_range) * float(enemy_data.ranged_range)
	for tower in TargetingSystem.towers(get_tree()):
		if tower == null or not is_instance_valid(tower):
			continue
		var d: float = global_position.distance_squared_to(tower.global_position)
		if d < best:
			best = d
			target = tower
	if target == null:
		spit_timer = 0.5
		return
	spit_timer = float(enemy_data.ranged_interval)
	spit_stop_timer = 0.75
	if target.has_method("apply_disable"):
		target.apply_disable(2.4)
	level.call("spawn_beam", global_position, target.global_position, Color(0.55, 1.0, 0.3), 0.4)
	level.call("spawn_fx_at", "acid", target.global_position, Color(0.55, 1.0, 0.3), 26.0)
	AudioManager.play_sound("shot_frost", 0.35, 0.75)


func _update_burrow(step: float) -> void:
	if not enemy_data.burrowed:
		return
	burrow_timer -= step
	if burrow_timer <= 0.0:
		burrow_active = not burrow_active
		burrow_timer = 3.0 if burrow_active else 2.6
		if burrow_active:
			AudioManager.play_sound("burrow", 0.4, 1.0)
			level.call("spawn_fx_at", "dust", global_position, Color(0.7, 0.5, 0.3), 30.0)
		else:
			AudioManager.play_sound("emerge", 0.4, 1.0)
			level.call("spawn_fx_at", "dust", global_position, Color(0.85, 0.6, 0.35), 40.0)
	if burrow_active and not burrow_was_active:
		if _health_bar:
			_health_bar.visible = false
	elif not burrow_active and burrow_was_active:
		if _health_bar:
			_health_bar.visible = true
	burrow_was_active = burrow_active


func _update_boss(step: float) -> void:
	if elite_burst_timer > 0.0:
		elite_burst_timer = maxf(0.0, elite_burst_timer - step)
		if elite_burst_timer <= 0.0:
			speed_mult = 1.0
	if enemy_data.is_elite and not enemy_data.is_boss and boss_phase == 0:
		if health / maxf(1.0, max_health) <= 0.5:
			boss_phase = 1
			elite_burst_timer = 4.0
			speed_mult = 1.0
			EventBus.boss_phase.emit("Elite frenzy — it is charging!")
			AudioManager.play_sound("boss_roar", 0.55, 1.1)


func receive_damage(amount: float, damage_type: String, source: Node = null, is_dot: bool = false) -> float:
	if dead or removed:
		return 0.0
	if not is_targetable() and not is_dot:
		return 0.0
	if amount <= 0.0:
		return 0.0
	time_since_damage = 0.0
	if not is_dot:
		hit_flash = 0.1
		if source is Tower:
			source.set_aim_towards(global_position)
	var remaining := amount
	var absorbed := 0.0
	if shield_current > 0.0:
		var shield_damage := amount
		if damage_type == "electric":
			shield_damage *= 1.35
		absorbed = minf(shield_current, shield_damage)
		shield_current -= absorbed
		remaining = maxf(0.0, amount - absorbed / (1.35 if damage_type == "electric" else 1.0))
		if shield_current <= 0.0:
			level.call("spawn_fx_at", "shield_break", global_position, Color(0.45, 0.85, 1.0), 42.0)
			AudioManager.play_sound("shield_break", 0.55, 0.9)
	var applied := remaining
	health -= remaining
	if applied > 0.0:
		# Aggregate rapid hits into one floating number per enemy instead of
		# creating a Label for every single hit.
		_pending_damage += applied
		_pending_kind = damage_type
	if not is_dot:
		AudioManager.play_sound("enemy_hit", 0.22, randf_range(0.9, 1.12))
	if enemy_data.is_boss:
		_check_boss_phase()
	if health <= 0.0:
		_die(source)
	return applied + absorbed


func _check_boss_phase() -> void:
	var ratio := health / maxf(1.0, max_health)
	if boss_phase == 0 and ratio <= 0.72:
		boss_phase = 1
		EventBus.boss_phase.emit("Brood Tyrant: Hatchlings! It calls the brood.")
		EventBus.notification.emit("The Brood Tyrant summons its brood!", GameConfig.WARNING_RED)
		AudioManager.play_sound("boss_roar", 0.7, 0.9)
		level.call("summon_reinforcements", path_id, "worker", 6, 140.0)
	elif boss_phase == 1 and ratio <= 0.45:
		boss_phase = 2
		shield_current += 450.0
		max_shield = maxf(max_shield, shield_current)
		speed_mult = 1.15
		EventBus.boss_phase.emit("Brood Tyrant: Carapace Surge! Shields online.")
		EventBus.notification.emit("The Brood Tyrant hardens its carapace!", GameConfig.WARNING_RED)
		AudioManager.play_sound("shield_break", 0.7, 0.7)
	elif boss_phase == 2 and ratio <= 0.2:
		boss_phase = 3
		speed_mult = 1.45
		EventBus.boss_phase.emit("Brood Tyrant: FINAL FURY — it is enraged!")
		EventBus.notification.emit("The Brood Tyrant is enraged. Finish it!", GameConfig.WARNING_RED)
		AudioManager.play_sound("boss_roar", 0.85, 0.75)


func apply_burn(dps: float, duration: float, source: Node = null) -> void:
	burn_dps = maxf(burn_dps, dps)
	burn_timer = maxf(burn_timer, duration)
	if burn_source == null or source != null:
		burn_source = source


func apply_slow(amount: float, duration: float) -> void:
	if amount >= slow_factor or slow_timer <= 0.0:
		slow_factor = clampf(amount, 0.0, 0.85)
	slow_timer = maxf(slow_timer, duration)


func apply_stun(duration: float) -> void:
	stun_timer = maxf(stun_timer, duration)


func apply_freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)


func is_frozen() -> bool:
	return freeze_timer > 0.0


func apply_corrode(duration: float) -> void:
	corrode_timer = maxf(corrode_timer, duration)


func get_corrode_multiplier() -> float:
	return 1.25 if corrode_timer > 0.0 else 1.0


func is_targetable() -> bool:
	if dead or removed:
		return false
	if burrow_active:
		return false
	return true


func _leak() -> void:
	if dead or removed:
		return
	removed = true
	remove_from_group("enemies")
	AudioManager.play_sound("base_damage", 0.75, 1.0)
	level.call("spawn_fx_at", "dust", global_position, Color(0.9, 0.35, 0.2), 55.0)
	EventBus.enemy_leaked.emit(enemy_data.display_name, enemy_data.leak_damage)
	level.call("handle_enemy_removed", self, true)
	queue_free()


func _die(source: Node) -> void:
	if dead:
		return
	if _pending_damage > 0.0:
		EventBus.damage_number.emit(global_position + Vector2(0, -30), _pending_damage, _pending_kind)
		_pending_damage = 0.0
	dead = true
	removed = true
	health = 0.0
	remove_from_group("enemies")
	if _health_bar:
		_health_bar.visible = false
	if not reward_granted:
		reward_granted = true
		if level != null:
			level.economy.add_credits(int(enemy_data.bounty), "bounty")
			EventBus.enemy_killed.emit(enemy_data.display_name, int(enemy_data.bounty))
	AudioManager.play_sound("enemy_death", 0.4, randf_range(0.9, 1.1))
	if level != null:
		level.call("spawn_fx_at", "death", global_position, enemy_data.body_color, 40.0 if not enemy_data.is_boss else 110.0)
		if enemy_data.is_boss:
			EventBus.notification.emit("The Brood Tyrant has fallen!", GameConfig.AMBER)
			AudioManager.play_sound("victory", 0.7, 1.0)
		level.call("handle_enemy_removed", self, false)
	queue_free()


func health_ratio() -> float:
	return health / maxf(1.0, max_health)
