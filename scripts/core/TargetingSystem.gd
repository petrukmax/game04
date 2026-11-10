class_name TargetingSystem
extends RefCounted
## Target acquisition and priority rules. Visual nodes never decide targeting.


static func acquire(source: Node2D, attack_range: float, priority: String, anti_air: bool,
		can_hit_ground: bool = true) -> Node:
	var candidates: Array = []
	for enemy in source.get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.is_targetable():
			continue
		if enemy.flying and not anti_air:
			continue
		if not enemy.flying and not can_hit_ground:
			continue
		if source.global_position.distance_to(enemy.global_position) > attack_range:
			continue
		candidates.append(enemy)
	if candidates.is_empty():
		return null
	var chosen: Node = candidates[0]
	for enemy in candidates:
		if _better(enemy, chosen, priority, source):
			chosen = enemy
	return chosen


static func _better(a: Node, b: Node, priority: String, source: Node2D) -> bool:
	match priority:
		"last":
			return a.progress > b.progress
		"strongest":
			return a.health + a.shield_current > b.health + b.shield_current
		"weakest":
			return a.health + a.shield_current < b.health + b.shield_current
		"closest":
			return source.global_position.distance_squared_to(a.global_position) < source.global_position.distance_squared_to(b.global_position)
		"highest_health":
			return a.health > b.health
		"lowest_health":
			return a.health < b.health
		"flying_first":
			if a.flying != b.flying:
				return a.flying
			return a.progress > b.progress
		_:
			return a.progress > b.progress


static func enemies_in_radius(tree: SceneTree, center: Vector2, radius: float,
		can_hit_air: bool = true, targetable_only: bool = true) -> Array:
	var out: Array = []
	for enemy in tree.get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if targetable_only and not enemy.is_targetable():
			continue
		if enemy.flying and not can_hit_air:
			continue
		if center.distance_to(enemy.global_position) <= radius:
			out.append(enemy)
	return out
