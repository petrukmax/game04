class_name TargetingSystem
extends RefCounted
## Target acquisition and priority rules. Visual nodes never decide targeting.

## Every tower, projectile and drone used to call get_nodes_in_group() several
## times per frame. The group arrays are cached for the duration of one physics
## frame; dead entries are filtered by is_targetable() at the call site.
static var _enemy_cache: Array = []
static var _enemy_frame: int = -1
static var _tower_cache: Array = []
static var _tower_frame: int = -1


static func enemies(tree: SceneTree) -> Array:
	var frame := Engine.get_physics_frames()
	if frame != _enemy_frame:
		_enemy_frame = frame
		_enemy_cache = tree.get_nodes_in_group("enemies")
	return _enemy_cache


static func towers(tree: SceneTree) -> Array:
	var frame := Engine.get_physics_frames()
	if frame != _tower_frame:
		_tower_frame = frame
		_tower_cache = tree.get_nodes_in_group("towers")
	return _tower_cache


static func acquire(source: Node2D, attack_range: float, priority: String, anti_air: bool,
		can_hit_ground: bool = true) -> Node:
	var best: Node = null
	var best_range_sq := attack_range * attack_range
	var origin := source.global_position
	for enemy in enemies(source.get_tree()):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.is_targetable():
			continue
		if enemy.flying and not anti_air:
			continue
		if not enemy.flying and not can_hit_ground:
			continue
		if origin.distance_squared_to(enemy.global_position) > best_range_sq:
			continue
		if best == null or _better(enemy, best, priority, source):
			best = enemy
	return best


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
	var radius_sq := radius * radius
	for enemy in enemies(tree):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if targetable_only and not enemy.is_targetable():
			continue
		if enemy.flying and not can_hit_air:
			continue
		if center.distance_squared_to(enemy.global_position) <= radius_sq:
			out.append(enemy)
	return out
