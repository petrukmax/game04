extends Node2D
## Hostile entry gate art at the start of a road.

var gate_label: String = "ENTRY"
var _time: float = 0.0


func setup(world_position: Vector2, label_text: String = "ENTRY") -> void:
	position = world_position
	gate_label = label_text
	z_index = -3
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(Vector2.ZERO, 30.0, Color(0.1, 0.08, 0.08, 0.35))
	# Top-down gate brackets.
	draw_rect(Rect2(-30, -30, 10, 60), Color(0.19, 0.19, 0.18))
	draw_rect(Rect2(20, -30, 10, 60), Color(0.19, 0.19, 0.18))
	for i in 4:
		draw_rect(Rect2(-29, -26 + i * 14, 8, 6), Color(0.75, 0.5, 0.12, 0.8))
		draw_rect(Rect2(21, -26 + i * 14, 8, 6), Color(0.75, 0.5, 0.12, 0.8))
	draw_circle(Vector2(-25, -31), 3.0, Color(1.0, 0.2, 0.15, 0.5 + pulse * 0.5))
	draw_circle(Vector2(25, -31), 3.0, Color(1.0, 0.2, 0.15, 0.5 + pulse * 0.5))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-52, -38), gate_label, HORIZONTAL_ALIGNMENT_CENTER, 104, 11, Color(1.0, 0.45, 0.35, 0.9))
	# Chevrons pointing inward.
	for i in 3:
		var alpha := 0.25 + 0.2 * pulse
		var x := 6.0 + i * 8.0
		draw_line(Vector2(x, -10), Vector2(x + 6, 0), Color(1.0, 0.45, 0.2, alpha), 2.0, true)
		draw_line(Vector2(x + 6, 0), Vector2(x, 10), Color(1.0, 0.45, 0.2, alpha), 2.0, true)
