extends Control
## Animated procedural Mars backdrop used by the main menu and level select.

var _time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _stars: Array[Vector3] = []
var _dust: Array[Vector4] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 90210
	for i in 170:
		_stars.append(Vector3(_rng.randf_range(0.0, 1600.0), _rng.randf_range(0.0, 560.0), _rng.randf_range(0.6, 2.2)))
	for i in 60:
		_dust.append(Vector4(_rng.randf_range(0.0, 1600.0), _rng.randf_range(410.0, 900.0),
			_rng.randf_range(8.0, 42.0), _rng.randf_range(0.4, 1.0)))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := maxf(size.x, 1600.0)
	var h := maxf(size.y, 900.0)
	# Sky gradient bands.
	var sky_top := Color(0.018, 0.018, 0.032)
	var sky_bottom := Color(0.19, 0.07, 0.055)
	var bands := 28
	for i in bands:
		var t := float(i) / float(bands - 1)
		var y := t * h * 0.72
		draw_rect(Rect2(0, y, w, h * 0.72 / float(bands) + 1.0), sky_top.lerp(sky_bottom, t))
	# Stars with slow twinkle.
	for star in _stars:
		var twinkle := 0.35 + 0.35 * sin(_time * 1.3 + star.x * 0.07)
		draw_circle(Vector2(star.x, star.z), star.z, Color(0.92, 0.9, 0.84, twinkle * 0.65))
	# Distant Phobos.
	draw_circle(Vector2(1210, 132), 54, Color(0.35, 0.24, 0.2))
	draw_circle(Vector2(1196, 122), 49, Color(0.46, 0.33, 0.27))
	draw_circle(Vector2(1178, 112), 8, Color(0.35, 0.24, 0.2, 0.5))
	draw_circle(Vector2(1226, 152), 12, Color(0.31, 0.21, 0.18, 0.5))
	draw_circle(Vector2(1214, 118), 5, Color(0.3, 0.2, 0.16, 0.5))
	# Mars limb.
	draw_circle(Vector2(w * 0.5, h * 1.78), h * 0.98, Color(0.22, 0.075, 0.045))
	draw_arc(Vector2(w * 0.5, h * 1.78), h * 0.98, PI + 0.25, TAU - 0.25, 96, Color(0.55, 0.2, 0.1, 0.35), 3.0, true)
	# Atmospheric haze at the horizon.
	for i in 8:
		var y := h * 0.66 + i * 7.0
		draw_rect(Rect2(0, y, w, 7), Color(0.65, 0.25, 0.12, 0.055 - i * 0.005))
	# Dune silhouettes.
	_draw_ridge(h * 0.74, Color(0.15, 0.065, 0.05), 0.0)
	_draw_ridge(h * 0.8, Color(0.11, 0.05, 0.04), 1.8)
	_draw_ridge(h * 0.87, Color(0.075, 0.035, 0.03), 3.1)
	# Distant outpost domes and masts.
	_draw_outpost(Vector2(250, h * 0.77), 1.0)
	_draw_outpost(Vector2(1290, h * 0.75), 0.8)
	# Dust streaks.
	for particle in _dust:
		var x := fmod(particle.x + _time * particle.z, w + 120.0) - 60.0
		var y := particle.y + sin(_time * 0.4 + particle.x) * 9.0
		draw_line(Vector2(x, y), Vector2(x + particle.z * 1.8, y - 2.0),
			Color(0.8, 0.45, 0.28, 0.05 * particle.w), 1.5, true)
	# Console scan lines.
	for i in range(0, int(h), 4):
		draw_line(Vector2(0, i), Vector2(w, i), Color(0, 0, 0, 0.035), 1.0)
	# Vignette.
	draw_rect(Rect2(0, 0, w, 90), Color(0, 0, 0, 0.28))
	draw_rect(Rect2(0, h - 120, w, 120), Color(0, 0, 0, 0.32))


func _draw_ridge(base_y: float, color: Color, phase: float) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(0, base_y + 40))
	var x := 0.0
	while x <= 1660.0:
		var y := base_y + sin(x * 0.0032 + phase) * 18.0 + sin(x * 0.0091 + phase * 2.0) * 7.0
		points.append(Vector2(x, y))
		x += 40.0
	points.append(Vector2(1660, base_y + 40))
	draw_colored_polygon(points, color)


func _draw_outpost(center: Vector2, scale_factor: float) -> void:
	var dome := Color(0.16, 0.17, 0.18)
	var light := Color(0.95, 0.55, 0.2, 0.8)
	draw_circle(center, 30.0 * scale_factor, Color(0.05, 0.03, 0.03, 0.55))
	draw_circle(center + Vector2(-16, -9) * scale_factor, 15.0 * scale_factor, dome)
	draw_circle(center + Vector2(12, -6) * scale_factor, 11.0 * scale_factor, dome.lightened(0.08))
	draw_line(center + Vector2(2, 2) * scale_factor, center + Vector2(2, -40) * scale_factor,
		Color(0.35, 0.36, 0.35), 2.0, true)
	draw_circle(center + Vector2(2, -42) * scale_factor, 2.5 * scale_factor, light)
	draw_rect(Rect2(center + Vector2(-46, 6) * scale_factor, Vector2(92, 4) * scale_factor),
		Color(0.12, 0.12, 0.12, 0.9))
