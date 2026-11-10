class_name OrbitalStrike
extends Node2D
## Telegraphed delayed orbital beam, used by the tower and the ability.

var level: Node
var radius: float = 110.0
var damage: float = 170.0
var delay: float = 1.1
var beam_color: Color = Color(1.0, 0.5, 0.7)
var timer: float = 0.0
var _impacted: bool = false


func _ready() -> void:
	add_to_group("effects")
	z_index = 3


func configure(owner_level: Node, strike_radius: float, strike_damage: float, strike_delay: float, color: Color) -> void:
	level = owner_level
	radius = strike_radius
	damage = strike_damage
	delay = strike_delay
	beam_color = color
	AudioManager.play_sound("orbital_charge", 0.5, 0.75)


func _physics_process(delta: float) -> void:
	if _impacted or level == null:
		return
	var step := delta * float(level.game_speed)
	timer += step
	queue_redraw()
	if timer >= delay:
		_impact()


func _impact() -> void:
	_impacted = true
	var enemies := TargetingSystem.enemies_in_radius(get_tree(), global_position, radius, true, true)
	DamageSystem.splash(enemies, global_position, radius, damage, "energy", 0.35, null, true, 0.15)
	level.call("spawn_fx_at", "orbital", global_position, beam_color, radius)
	level.call("shake", 9.0)
	AudioManager.play_sound("orbital_impact", 0.85, 0.8)
	queue_free()


func _draw() -> void:
	var progress := clampf(timer / maxf(delay, 0.01), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(beam_color.r, beam_color.g, beam_color.b, 0.08 + 0.1 * progress))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 56, Color(beam_color.r, beam_color.g, beam_color.b, 0.75), 2.5, true)
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 48, Color(1.0, 0.9, 0.95, 0.8), 3.0, true)
	for i in 4:
		var a := TAU * float(i) / 4.0 + timer * 2.0
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * radius, Color(beam_color.r, beam_color.g, beam_color.b, 0.18), 2.0, true)
	draw_circle(Vector2.ZERO, 18.0 + 10.0 * sin(timer * 12.0), Color(beam_color.r, beam_color.g, beam_color.b, 0.25))
