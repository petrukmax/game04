class_name ProximityMine
extends Node2D
## Road mine laid by the Mine Layer tower.

var level: Node
var damage: float = 80.0
var radius: float = 62.0
var armed: bool = false
var arm_timer: float = 0.5
var age: float = 0.0
var _dead: bool = false


func _ready() -> void:
	add_to_group("mines")
	z_index = 8


func configure(owner_level: Node, mine_damage: float, blast_radius: float) -> void:
	level = owner_level
	damage = mine_damage
	radius = blast_radius
	AudioManager.play_sound("mine_deploy", 0.3, 1.15)


func _physics_process(delta: float) -> void:
	if _dead or level == null:
		return
	var step := delta * float(level.game_speed)
	age += step
	if not armed:
		arm_timer -= step
		if arm_timer <= 0.0:
			armed = true
		return
	if age > 90.0:
		_dead = true
		queue_free()
		return
	for enemy in TargetingSystem.enemies(get_tree()):
		if enemy == null or not is_instance_valid(enemy):
			continue
		if enemy.dead or enemy.burrow_active or enemy.flying:
			continue
		if global_position.distance_squared_to(enemy.global_position) <= 28.0 * 28.0:
			_explode()
			return


func _explode() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("mines")
	var enemies := TargetingSystem.enemies_in_radius(get_tree(), global_position, radius, false, true)
	DamageSystem.splash(enemies, global_position, radius, damage, "explosive", 0.25, null, false)
	level.call("spawn_fx_at", "explosion", global_position, Color(1.0, 0.55, 0.2), radius)
	level.call("shake", 3.0)
	AudioManager.play_sound("shot_cannon", 0.35, 0.8)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2(0, 2), 9, Color(0, 0, 0, 0.35))
	draw_circle(Vector2.ZERO, 8.0, Color(0.22, 0.21, 0.18))
	draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.3, 0.22))
	var pulse := 0.5 + 0.5 * sin(age * 8.0)
	draw_circle(Vector2.ZERO, 2.2, Color(1.0, 0.45, 0.15, 0.5 + pulse * 0.5))
	if armed:
		draw_arc(Vector2.ZERO, 11.0, 0, TAU, 16, Color(1.0, 0.5, 0.2, 0.45), 1.0, true)
