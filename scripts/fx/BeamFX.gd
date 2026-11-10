class_name BeamFX
extends Node2D
## Short-lived line/arc effect used by tesla chains, rail shots and spitter acid.

@export var style: String = "beam"

var level: Node
var from_point: Vector2
var to_point: Vector2
var color: Color = Color(1, 1, 1)
var duration: float = 0.15
var age: float = 0.0
var width: float = 2.0


func _ready() -> void:
	add_to_group("effects")
	z_index = 50


func configure(owner_level: Node, from_pos: Vector2, to_pos: Vector2, beam_color: Color, life: float = 0.15) -> void:
	level = owner_level
	from_point = from_pos
	to_point = to_pos
	color = beam_color
	duration = life
	queue_redraw()


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age >= duration:
		queue_free()


func _draw() -> void:
	var t := clampf(age / maxf(duration, 0.01), 0.0, 1.0)
	var fade := 1.0 - t
	var a := to_local(from_point)
	var b := to_local(to_point)
	if style == "tesla":
		var points := PackedVector2Array()
		var segments := 9
		for i in range(segments + 1):
			var p := a.lerp(b, float(i) / float(segments))
			if i > 0 and i < segments:
				var normal := (b - a).orthogonal().normalized()
				p += normal * randf_range(-7.0, 7.0)
			points.append(p)
		draw_polyline(points, Color(color.r, color.g, color.b, fade * 0.4), 6.0, true)
		draw_polyline(points, Color(0.9, 0.98, 1.0, fade), 2.0, true)
	elif style == "rail":
		draw_line(a, b, Color(color.r, color.g, color.b, fade * 0.3), 8.0, true)
		draw_line(a, b, Color(1.0, 1.0, 1.0, fade), 2.0, true)
		draw_circle(b, 7.0 * fade + 2.0, Color(1.0, 0.95, 0.8, fade * 0.8))
	elif style == "acid":
		draw_line(a, b, Color(0.5, 0.95, 0.25, fade * 0.5), width + 2.0, true)
		draw_line(a, b, Color(0.75, 1.0, 0.5, fade), width, true)
		draw_circle(b, 8.0 * fade + 2.0, Color(0.5, 1.0, 0.3, fade * 0.5))
	else:
		draw_line(a, b, Color(color.r, color.g, color.b, fade * 0.35), width + 3.0, true)
		draw_line(a, b, Color(1.0, 0.95, 0.85, fade), width, true)
