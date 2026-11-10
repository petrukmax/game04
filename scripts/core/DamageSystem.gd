class_name DamageSystem
extends RefCounted
## Transparent damage pipeline: base -> armour -> resistance -> shield -> health.

static func calculate(base_damage: float, damage_type: String, enemy: Node, armor_penetration: float = 0.0) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	if base_damage <= 0.0:
		return 0.0
	var armor: float = float(enemy.enemy_data.armor) * (1.0 - clampf(armor_penetration, 0.0, 0.95))
	var after_armor: float = maxf(base_damage - armor, base_damage * 0.15)
	var resistance := 1.0
	if enemy.enemy_data.resistances is Dictionary:
		resistance = float(enemy.enemy_data.resistances.get(damage_type, 1.0))
	if enemy.has_method("get_corrode_multiplier"):
		resistance *= enemy.get_corrode_multiplier()
	return maxf(1.0, after_armor * resistance)


static func hit(enemy: Node, base_damage: float, damage_type: String, armor_penetration: float,
		source: Node = null, is_dot: bool = false) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	if enemy.has_method("is_targetable") and not enemy.is_targetable() and not is_dot:
		return 0.0
	var amount := calculate(base_damage, damage_type, enemy, armor_penetration)
	if enemy.has_method("receive_damage"):
		return float(enemy.receive_damage(amount, damage_type, source, is_dot))
	return 0.0


static func splash(enemies: Array, center: Vector2, radius: float, base_damage: float,
		damage_type: String, armor_penetration: float, source: Node, can_hit_air: bool,
		falloff: float = 0.35) -> int:
	var hits := 0
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.flying and not can_hit_air:
			continue
		if not enemy.is_targetable():
			continue
		var distance := center.distance_to(enemy.global_position)
		if distance > radius:
			continue
		var factor := 1.0 - falloff * clampf(distance / maxf(radius, 1.0), 0.0, 1.0)
		hit(enemy, base_damage * factor, damage_type, armor_penetration, source)
		hits += 1
	return hits
