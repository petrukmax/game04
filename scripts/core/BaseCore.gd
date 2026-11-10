extends Node2D
## Human outpost core at the right edge. Its integrity lights mirror base health.

var level: LevelBase
var _time: float = 0.0
var _flash: float = 0.0
var _repair_flash: float = 0.0


func setup(owner_level: LevelBase, world_position: Vector2) -> void:
	level = owner_level
	position = world_position
	z_index = -2
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta * 1.8)
	_repair_flash = maxf(0.0, _repair_flash - delta * 1.2)
	queue_redraw()


func flash() -> void:
	_flash = 1.0


func repair_flash() -> void:
	_repair_flash = 1.0


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 1.7)
	# Landing pad.
	draw_circle(Vector2(0, 0), 88.0, Color(0.14, 0.14, 0.13, 0.85))
	draw_circle(Vector2(0, 0), 80.0, Color(0.22, 0.22, 0.2))
	draw_arc(Vector2(0, 0), 74.0, 0, TAU, 40, Color(0.9, 0.6, 0.2, 0.35), 3.0, true)
	# Habitat domes.
	draw_circle(Vector2(-32, -26), 28.0, Color(0.33, 0.35, 0.35))
	draw_circle(Vector2(-32, -31), 24.0, Color(0.46, 0.48, 0.47))
	draw_circle(Vector2(30, -22), 22.0, Color(0.29, 0.31, 0.32))
	draw_circle(Vector2(30, -26), 18.0, Color(0.41, 0.43, 0.42))
	for i in 3:
		draw_circle(Vector2(-32, -31), 15.0 - i * 4.5, Color(0.26 + i * 0.06, 0.28 + i * 0.06, 0.29 + i * 0.06, 0.8))
	# Antenna mast and dishes.
	draw_line(Vector2(-4, 2), Vector2(-4, -52), Color(0.55, 0.57, 0.55), 3.0, true)
	draw_line(Vector2(-12, -36), Vector2(4, -36), Color(0.55, 0.57, 0.55), 2.0, true)
	draw_circle(Vector2(-4, -55), 4.0, Color(1.0, 0.35, 0.2, 0.6 + 0.4 * pulse))
	draw_arc(Vector2(40, -46), 12.0, PI + 0.5, TAU - 0.5, 16, Color(0.6, 0.62, 0.6), 2.5, true)
	# Solar wing.
	draw_rect(Rect2(-76, 24, 48, 26), Color(0.11, 0.16, 0.23))
	for i in 3:
		draw_line(Vector2(-74 + i * 15, 26), Vector2(-74 + i * 15, 48), Color(0.28, 0.45, 0.65, 0.6), 1.0)
	draw_rect(Rect2(-76, 24, 48, 26), Color(0.45, 0.47, 0.45), false, 1.5)
	# Cargo containers.
	draw_rect(Rect2(16, 20, 34, 22), Color(0.3, 0.3, 0.27))
	draw_rect(Rect2(20, 24, 12, 14), Color(0.72, 0.45, 0.14))
	draw_rect(Rect2(34, 24, 12, 14), Color(0.22, 0.24, 0.25))
	# Shield dome.
	draw_arc(Vector2.ZERO, 64.0, 0, TAU, 48, Color(0.35, 0.75, 1.0, 0.18 + 0.08 * pulse), 2.5, true)
	draw_circle(Vector2.ZERO, 64.0, Color(0.35, 0.75, 1.0, 0.025))
	# Integrity segments.
	var ratio := 1.0
	if level != null and level.base_max > 0:
		ratio = clampf(float(level.base_health) / float(level.base_max), 0.0, 1.0)
	for i in 10:
		var segment_color := Color(0.45, 0.95, 0.45) if float(i) / 10.0 < ratio else Color(0.35, 0.1, 0.08)
		draw_rect(Rect2(-56 + i * 11.5, 58, 8, 5), segment_color)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-80, 78), "FIRST BASTION", HORIZONTAL_ALIGNMENT_CENTER, 160, 11,
		Color(0.95, 0.82, 0.55, 0.85))
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 64.0, Color(1.0, 0.15, 0.1, _flash * 0.3))
		draw_arc(Vector2.ZERO, 64.0, 0, TAU, 48, Color(1.0, 0.2, 0.1, _flash), 5.0, true)
	if _repair_flash > 0.0:
		draw_circle(Vector2.ZERO, 64.0, Color(0.4, 1.0, 0.5, _repair_flash * 0.22))
		draw_arc(Vector2.ZERO, 64.0, 0, TAU, 48, Color(0.4, 1.0, 0.5, _repair_flash), 4.0, true)
