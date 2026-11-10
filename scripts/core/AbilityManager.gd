class_name AbilityManager
extends Node
## Cooldown/charge ownership for player abilities. Effects live in LevelBase.

const ABILITY_IDS: Array[String] = ["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"]

var level: Node
var data_by_id: Dictionary = {}
var cooldowns: Dictionary = {}
var uses_left: Dictionary = {}
var unlocked: Dictionary = {}


func setup(owner_level: Node, level_data: LevelData) -> void:
	level = owner_level
	data_by_id.clear()
	cooldowns.clear()
	uses_left.clear()
	unlocked.clear()
	for id in ABILITY_IDS:
		var path := "res://resources/abilities/ability_%s.tres" % id
		if ResourceLoader.exists(path):
			var ability: AbilityData = load(path)
			data_by_id[id] = ability
			cooldowns[id] = 0.0
			uses_left[id] = ability.uses_per_level
	for id in level_data.unlocked_abilities:
		unlocked[String(id)] = true
	EventBus.ability_state_changed.emit()


func tick(delta: float) -> void:
	for id in cooldowns.keys():
		if float(cooldowns[id]) > 0.0:
			cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta)
	if not cooldowns.is_empty():
		EventBus.ability_state_changed.emit()


func get_ability(id: String) -> AbilityData:
	return data_by_id.get(id, null)


func get_display_order() -> Array[String]:
	return ABILITY_IDS


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func cooldown_ratio(id: String) -> float:
	var ability: AbilityData = get_ability(id)
	if ability == null or ability.cooldown <= 0.0:
		return 0.0
	return clampf(float(cooldowns.get(id, 0.0)) / ability.cooldown, 0.0, 1.0)


func cooldown_left(id: String) -> float:
	return float(cooldowns.get(id, 0.0))


func uses_remaining(id: String) -> int:
	return int(uses_left.get(id, 0))


func can_use(id: String) -> bool:
	if not unlocked.has(id) or not data_by_id.has(id):
		return false
	if float(cooldowns.get(id, 0.0)) > 0.0:
		return false
	if int(uses_left.get(id, 0)) == 0:
		return false
	return true


func use_ability(id: String, position: Vector2) -> bool:
	if not can_use(id):
		return false
	var ability: AbilityData = data_by_id[id]
	match id:
		"orbital_strike":
			level.call("ability_orbital_strike", position, ability.radius, ability.damage, ability.delay)
		"emp":
			level.call("ability_emp", position, ability.radius, ability.damage, ability.stun_duration,
				ability.slow_amount, ability.duration)
		"reinforcement_drones":
			level.call("ability_deploy_drones", position, ability.radius, ability.duration, ability.damage)
		"emergency_repair":
			level.call("ability_repair_base", ability.heal_amount)
		"supply_drop":
			level.call("ability_supply_drop", ability.credits)
	cooldowns[id] = ability.cooldown
	if int(uses_left[id]) > 0:
		uses_left[id] = int(uses_left[id]) - 1
	EventBus.ability_used.emit(id)
	EventBus.ability_state_changed.emit()
	return true
