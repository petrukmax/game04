extends Control
## Small tower silhouette used on shop cards and the inspection panel.

var style: String = "pulse"
var color: Color = Color(0.95, 0.64, 0.24)


func configure(tower_style: String, tower_color: Color) -> void:
	style = tower_style
	color = tower_color
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var metal := Color(0.36, 0.37, 0.4)
	var dark := Color(0.14, 0.15, 0.17)
	draw_circle(center + Vector2(1, 3), minf(size.x, size.y) * 0.32, Color(0, 0, 0, 0.35))
	draw_circle(center, minf(size.x, size.y) * 0.3, dark)
	draw_circle(center, minf(size.x, size.y) * 0.24, metal)
	match style:
		"pulse":
			draw_line(center + Vector2(-4, -4), center + Vector2(14, -4), color, 3.0, true)
			draw_line(center + Vector2(-4, 4), center + Vector2(14, 4), color, 3.0, true)
			draw_circle(center, 5.0, color)
		"cannon":
			draw_line(center, center + Vector2(17, 0), Color(0.55, 0.47, 0.33), 8.0, true)
			draw_circle(center, 9.0, Color(0.28, 0.27, 0.25))
			draw_arc(center, 9.0, 0, TAU, 18, color, 2.0, true)
		"flame":
			for i in range(-2, 3):
				draw_line(center, center + Vector2(16, float(i) * 3.2), color, 3.0, true)
			draw_circle(center, 8.0, Color(0.3, 0.22, 0.15))
		"tesla":
			for i in range(1, 4):
				draw_arc(center, 3.0 + i * 3.0, 0, TAU, 18, Color(0.55, 0.85, 1.0), 1.5, true)
			draw_circle(center, 3.0, Color(0.9, 1.0, 1.0))
		"missile":
			draw_rect(Rect2(center - Vector2(10, 9), Vector2(20, 18)), Color(0.3, 0.3, 0.27))
			for x in [-6, 0, 6]:
				draw_circle(center + Vector2(x, -2), 2.5, color)
		"cryo":
			draw_circle(center, 9.0, Color(0.46, 0.68, 0.75))
			for i in 5:
				var a := TAU * float(i) / 5.0
				draw_line(center + Vector2(cos(a), sin(a)) * 4, center + Vector2(cos(a), sin(a)) * 13, Color(0.8, 0.97, 1.0), 2.0, true)
		"rail":
			draw_line(center, center + Vector2(19, 0), Color(0.7, 0.75, 0.78), 4.0, true)
			draw_circle(center, 7.0, color)
			draw_circle(center, 3.0, Color(1, 1, 1))
		"relay":
			draw_line(center + Vector2(0, 6), center + Vector2(0, -14), Color(0.65, 0.7, 0.66), 2.0, true)
			for i in 3:
				draw_arc(center + Vector2(0, -10 + i * 4), 4.0 + i * 3.0, PI + 0.4, TAU - 0.4, 10, color, 1.4, true)
			draw_circle(center + Vector2(0, -16), 3.0, color)
		"mine":
			draw_rect(Rect2(center - Vector2(12, 8), Vector2(24, 16)), Color(0.28, 0.26, 0.22))
			for i in 3:
				draw_circle(center + Vector2(-7 + i * 7, 0), 2.5, color)
			draw_circle(center + Vector2(0, 10), 2.5, Color(1.0, 0.4, 0.15))
		"orbital":
			draw_circle(center, 10.0, Color(0.28, 0.2, 0.3))
			for i in 3:
				draw_arc(center, 5.0 + i * 4.0, -0.9, 0.9, 12, color, 1.8, true)
			draw_circle(center, 3.0, Color(1, 0.8, 0.9))
		_:
			draw_circle(center, 7.0, color)
