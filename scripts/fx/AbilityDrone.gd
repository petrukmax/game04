class_name AbilityDrone
extends Node2D
## Temporary autonomous reinforcement drone.

var level: Node
var center: Vector2
var patrol_radius: float = 150.0
var duration: float = 14.0
var damage: float = 22.0
var age: float = 0.0
var fire_timer: float = 0.0
var orbit_angle: float = 0.0
var index: int = 0


func _ready() -> void:
	add_to_group("drones")
	z_index = 35


func configure(owner_level: Node, orbit_center: Vector2, radius: float, life: float, hit_damage: float, drone_index: int) -> void:
	level = owner_level
	center = orbit_center
	patrol_radius = radius
	duration = life
	damage = hit_damage
	index = drone_index
	orbit_angle = TAU * float(index) / 2.0
	global_position = center


func _physics_process(delta: float) -> void:
	if level == null:
		return
	var step := delta * float(level.game_speed)
	age += step
	if age >= duration:
		queue_free()
		return
	orbit_angle += step * 0.9
	global_position = center + Vector2(cos(orbit_angle), sin(orbit_angle)) * 60.0
	fire_timer -= step
	if fire_timer <= 0.0:
		fire_timer = 0.55
		var target := _find_target()
		if target != null:
			DamageSystem.hit(target, damage, "kinetic", 0.2, self)
			level.call("spawn_beam", global_position, target.global_position, Color(0.6, 1.0, 0.65), 0.1)
			AudioManager.play_sound("drone_shot", 0.28, randf_range(0.95, 1.08))
	queue_redraw()


func _find_target() -> Node:
	var best: Node = null
	var best_distance := patrol_radius * patrol_radius
	for enemy in TargetingSystem.enemies(get_tree()):
		if enemy == null or not is_instance_valid(enemy) or not enemy.is_targetable():
			continue
		var d: float = center.distance_squared_to(enemy.global_position)
		if d < best_distance:
			best_distance = d
			best = enemy
	return best


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(age * 8.0)
	draw_circle(Vector2(0, 4), 8, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, 7.0, Color(0.25, 0.42, 0.3))
	draw_rect(Rect2(-9, -2, 18, 4), Color(0.45, 0.55, 0.48))
	draw_circle(Vector2(-10, 0), 3.0, Color(0.7, 0.9, 0.7, 0.45 + 0.2 * pulse))
	draw_circle(Vector2(10, 0), 3.0, Color(0.7, 0.9, 0.7, 0.45 + 0.2 * pulse))
	draw_circle(Vector2(0, -3), 2.0, Color(0.6, 1.0, 0.65))
