class_name Projectile
extends Node2D
## Homing projectile with splash, slow and splash-air filtering.

var level: Node
var source: Node
var target: Node
var damage: float = 0.0
var damage_type: String = "kinetic"
var speed: float = 700.0
var splash: float = 0.0
var slow: float = 0.0
var slow_duration: float = 0.0
var freeze_chance: float = 0.0
var freeze_duration: float = 0.0
var corrode_duration: float = 0.0
var armor_penetration: float = 0.0
var can_hit_air: bool = false
var crit: bool = false
var color: Color = Color(1, 1, 1)
var projectile_style: String = "pulse"
var lifetime: float = 3.0
var direction: Vector2 = Vector2.RIGHT
var trail_points: Array[Vector2] = []
var _trail_timer: float = 0.0
var _dead: bool = false


func _ready() -> void:
	add_to_group("projectiles")
	z_index = 40


func configure(config: Dictionary) -> void:
	level = config.get("level")
	source = config.get("source")
	target = config.get("target")
	set("damage", float(config.get("damage", 0.0)))
	damage_type = String(config.get("damage_type", "kinetic"))
	speed = float(config.get("speed", 700.0))
	splash = float(config.get("splash", 0.0))
	slow = float(config.get("slow", 0.0))
	slow_duration = float(config.get("slow_duration", 0.0))
	freeze_chance = float(config.get("freeze_chance", 0.0))
	freeze_duration = float(config.get("freeze_duration", 0.0))
	corrode_duration = float(config.get("corrode_duration", 0.0))
	armor_penetration = float(config.get("armor_penetration", 0.0))
	can_hit_air = GameConfig.as_bool(config.get("can_hit_air", false))
	crit = GameConfig.as_bool(config.get("crit", false))
	color = config.get("color", Color(1, 1, 1))
	projectile_style = String(config.get("style", "pulse"))
	global_position = config.get("position", global_position)
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = Vector2.RIGHT
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step: float = delta
	if level != null and is_instance_valid(level):
		step *= float(level.game_speed)
	lifetime -= step
	if lifetime <= 0.0:
		_expire()
		return
	if is_instance_valid(target) and target.is_targetable():
		var desired: Vector2 = (target.global_position - global_position)
		if desired.length() > 0.1:
			var desired_dir: Vector2 = desired.normalized()
			direction = direction.lerp(desired_dir, clampf(step * 9.0, 0.0, 1.0)).normalized()
		rotation = direction.angle()
	global_position += direction * speed * step
	_trail_timer -= step
	if _trail_timer <= 0.0:
		_trail_timer = 0.035
		trail_points.append(global_position)
		if trail_points.size() > 7:
			trail_points.pop_front()
		if projectile_style == "missile" and level:
			level.call("spawn_fx_at", "trail", global_position, Color(0.6, 0.55, 0.5, 0.6), 6.0)
	queue_redraw()
	if is_instance_valid(target) and target.is_targetable():
		var hit_radius := 13.0
		var enemy_data: Variant = target.get("enemy_data")
		if enemy_data != null:
			hit_radius += 7.0 * float(enemy_data.body_scale)
		if global_position.distance_to(target.global_position) <= hit_radius:
			_impact(target.global_position)
			return
	if is_instance_valid(level) and level.is_position_on_map(global_position) == false:
		_expire()


func _impact(at: Vector2) -> void:
	if _dead:
		return
	_dead = true
	if is_instance_valid(target) and target.is_targetable():
		DamageSystem.hit(target, damage, damage_type, armor_penetration, source)
		if slow > 0.0 and target.has_method("apply_slow"):
			target.apply_slow(slow, slow_duration)
		if freeze_chance > 0.0 and randf() < freeze_chance and target.has_method("apply_freeze"):
			target.apply_freeze(freeze_duration)
		if corrode_duration > 0.0 and target.has_method("apply_corrode"):
			target.apply_corrode(corrode_duration)
	if splash > 0.0 and level != null:
		var enemies := TargetingSystem.enemies_in_radius(get_tree(), at, splash, true, true)
		DamageSystem.splash(enemies, at, splash, damage, damage_type, armor_penetration, source, can_hit_air)
		for enemy in enemies:
			if enemy.flying and not can_hit_air:
				continue
			if at.distance_to(enemy.global_position) > splash:
				continue
			if slow > 0.0 and enemy.has_method("apply_slow"):
				enemy.apply_slow(slow, slow_duration)
			if freeze_chance > 0.0 and randf() < freeze_chance * 0.6 and enemy.has_method("apply_freeze"):
				enemy.apply_freeze(freeze_duration)
			if corrode_duration > 0.0 and enemy.has_method("apply_corrode"):
				enemy.apply_corrode(corrode_duration * 0.75)
	var fx_style := "explosion" if splash > 0.0 and damage_type == "explosive" else "hit"
	if damage_type == "frost":
		fx_style = "frost"
	elif damage_type == "explosive" and splash <= 0.0:
		fx_style = "hit"
	level.call("spawn_fx_at", fx_style, at, color, maxf(20.0, splash))
	if crit:
		level.call("spawn_damage_text", at, "CRIT", Color(1.0, 0.8, 0.3))
	queue_free()


func _expire() -> void:
	if _dead:
		return
	_dead = true
	queue_free()


func _draw() -> void:
	if projectile_style == "missile":
		draw_line(Vector2.ZERO, -direction * 16.0, Color(0.7, 0.65, 0.6, 0.35), 3.0, true)
		draw_circle(Vector2.ZERO, 4.0, color)
		draw_circle(Vector2.ZERO, 2.0, Color(1, 0.95, 0.8))
	elif projectile_style == "cryo":
		draw_circle(Vector2.ZERO, 5.0, Color(0.75, 0.95, 1.0, 0.85))
		for i in 4:
			var a := TAU * float(i) / 4.0 + Time.get_ticks_msec() * 0.006
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 9.0, Color(0.8, 0.97, 1.0, 0.7), 1.5, true)
	else:
		draw_line(Vector2.ZERO, -direction * 12.0, Color(color.r, color.g, color.b, 0.35), 3.0, true)
		draw_circle(Vector2.ZERO, 4.0, color)
		draw_circle(Vector2.ZERO, 1.8, Color(1, 1, 1, 0.95))
