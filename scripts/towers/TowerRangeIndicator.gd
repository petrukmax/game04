extends Node2D
## Range indicator for a selected/placed tower. Hidden unless selected.

var radius: float = 0.0
var fill_color: Color = Color(0.98, 0.65, 0.2, 0.07)
var line_color: Color = Color(0.98, 0.65, 0.2, 0.72)


func set_range(value: float) -> void:
	radius = value
	queue_redraw()


func set_colors(fill: Color, line: Color) -> void:
	fill_color = fill
	line_color = line
	queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(Vector2.ZERO, radius, fill_color)
	var segments := 48
	for i in segments:
		if i % 2 == 0:
			continue
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		draw_line(Vector2(cos(a0), sin(a0)) * radius, Vector2(cos(a1), sin(a1)) * radius, line_color, 2.0, true)
