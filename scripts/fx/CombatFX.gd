class_name CombatFX
extends Node2D
## Shared short-lived 2D effect. Each scene selects a style via exported field.

@export var style: String = "hit"

var level: Node
var color: Color = Color(1.0, 0.7, 0.3)
var radius: float = 20.0
var duration: float = 0.45
var age: float = 0.0
var _seed: int = 0


func _ready() -> void:
	add_to_group("effects")
	z_index = 45
	_seed = randi()


func configure(owner_level: Node, fx_color: Color, fx_radius: float = 20.0, life: float = -1.0) -> void:
	level = owner_level
	color = fx_color
	radius = fx_radius
	if life > 0.0:
		duration = life
	if style == "muzzle":
		duration = 0.14
	elif style == "beam_hit":
		duration = 0.18
	elif style == "explosion":
		duration = 0.5
	elif style == "orbital":
		duration = 0.9
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()


func _draw() -> void:
	var t := clampf(age / maxf(duration, 0.01), 0.0, 1.0)
	var fade := 1.0 - t
	match style:
		"muzzle":
			draw_circle(Vector2.ZERO, radius * (1.0 + t * 0.4), Color(color.r, color.g, color.b, fade * 0.8))
			for i in 4:
				var a := TAU * float(i) / 4.0 + 0.4
				draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * radius * (1.4 + t), Color(1, 0.9, 0.7, fade), 2.0, true)
		"explosion":
			draw_circle(Vector2.ZERO, radius * (0.35 + t * 0.75), Color(color.r, color.g, color.b, fade * 0.35))
			draw_arc(Vector2.ZERO, radius * (0.4 + t), 0, TAU, 36, Color(1.0, 0.72, 0.32, fade * 0.9), 3.0, true)
			for i in 8:
				var a := TAU * float(i) / 8.0 + float(_seed % 10)
				var d := radius * (0.3 + t)
				draw_circle(Vector2(cos(a), sin(a)) * d, 3.0 * fade + 1.0, Color(1.0, 0.55, 0.2, fade))
		"frost":
			draw_circle(Vector2.ZERO, radius * (0.3 + t * 0.7), Color(0.55, 0.85, 1.0, fade * 0.25))
			draw_arc(Vector2.ZERO, radius * (0.3 + t), 0, TAU, 36, Color(0.75, 0.96, 1.0, fade), 2.5, true)
			for i in 7:
				var a := TAU * float(i) / 7.0 + float(_seed % 7) + t
				draw_circle(Vector2(cos(a), sin(a)) * radius * (0.2 + t * 0.8), 2.5, Color(0.85, 0.98, 1.0, fade))
		"death":
			draw_circle(Vector2.ZERO, radius * (0.25 + t * 0.9), Color(color.r, color.g, color.b, fade * 0.2))
			for i in 10:
				var a := TAU * float(i) / 10.0 + float(_seed % 5)
				var d := radius * t
				draw_circle(Vector2(cos(a), sin(a)) * d, 4.0 * fade + 1.0, Color(color.r * 0.8, color.g * 0.4, color.b * 0.3, fade))
			draw_circle(Vector2.ZERO, 6.0 * fade, Color(1.0, 0.8, 0.5, fade))
		"dust":
			for i in 7:
				var a := TAU * float(i) / 7.0 + float(_seed % 9)
				var d := radius * (0.2 + t) * (0.6 + 0.3 * sin(float(i) + float(_seed)))
				draw_circle(Vector2(cos(a), sin(a)) * d, 7.0 * fade + 2.0, Color(0.55, 0.36, 0.24, fade * 0.55))
		"heal":
			draw_circle(Vector2.ZERO, radius * (0.2 + 0.5 * t), Color(0.5, 1.0, 0.6, fade * 0.25))
			var rise := -22.0 * t
			draw_line(Vector2(0, rise - 7), Vector2(0, rise + 7), Color(0.7, 1.0, 0.75, fade), 3.0, true)
			draw_line(Vector2(-7, rise), Vector2(7, rise), Color(0.7, 1.0, 0.75, fade), 3.0, true)
		"acid":
			for i in 6:
				var a := TAU * float(i) / 6.0 + float(_seed % 4)
				draw_circle(Vector2(cos(a), sin(a)) * radius * (0.25 + t * 0.5), 4.0 * fade + 1.0, Color(0.55, 1.0, 0.3, fade * 0.8))
			draw_circle(Vector2.ZERO, radius * 0.3 * (1.0 + t), Color(0.4, 0.9, 0.2, fade * 0.25))
		"shield_break":
			draw_arc(Vector2.ZERO, radius * (0.5 + t * 0.6), 0, TAU, 40, Color(0.5, 0.9, 1.0, fade), 3.0, true)
			for i in 8:
				var a := TAU * float(i) / 8.0 + t * 2.0
				draw_line(Vector2(cos(a), sin(a)) * radius * 0.5, Vector2(cos(a), sin(a)) * radius * (0.6 + t * 0.5),
					Color(0.7, 0.95, 1.0, fade), 2.0, true)
		"flame":
			draw_circle(Vector2.ZERO, radius * (0.6 + t * 0.4), Color(1.0, 0.35, 0.1, fade * 0.15))
			draw_arc(Vector2.ZERO, radius * (0.55 + 0.45 * t), 0, TAU, 40, Color(1.0, 0.5, 0.14, fade * 0.7), 2.0, true)
			for i in 9:
				var a := TAU * float(i) / 9.0 + float(_seed % 6)
				var d := radius * (0.35 + 0.4 * (0.5 + 0.5 * sin(t * 8.0 + float(i))))
				draw_circle(Vector2(cos(a), sin(a)) * d, 4.0 * fade + 1.0, Color(1.0, 0.7, 0.2, fade * 0.8))
		"trail":
			draw_circle(Vector2.ZERO, radius * 0.5 * (1.0 - t), Color(0.7, 0.65, 0.6, fade * 0.3))
		"orbital":
			var beam_width := radius * (0.25 + 0.15 * sin(age * 18.0))
			draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, fade * 0.18))
			draw_rect(Rect2(-beam_width * 0.35, -radius * 1.6, beam_width * 0.7, radius * 1.6), Color(1.0, 0.85, 0.9, fade * 0.9))
			draw_circle(Vector2.ZERO, radius * (0.35 + t * 0.6), Color(1.0, 0.7, 0.85, fade * 0.22))
			draw_arc(Vector2.ZERO, radius * (0.5 + t * 0.7), 0, TAU, 48, Color(1.0, 0.75, 0.9, fade), 4.0, true)
		_:
			draw_circle(Vector2.ZERO, radius * (0.4 + t * 0.3), Color(color.r, color.g, color.b, fade * 0.55))
			draw_arc(Vector2.ZERO, radius * (0.5 + t * 0.3), 0, TAU, 24, Color(1.0, 0.85, 0.7, fade), 2.0, true)
