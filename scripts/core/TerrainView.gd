extends Node2D
## Procedural Martian terrain. Props only appear on blocked cells, so nothing
## decorative can be mistaken for a buildable square.

var data: LevelData
var _rng := RandomNumberGenerator.new()


func setup(level_data: LevelData) -> void:
	data = level_data
	_rng.seed = data.prop_seed
	z_index = -20
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var origin := GameConfig.MAP_ORIGIN
	var size := Vector2(data.grid_width * GameConfig.CELL_SIZE, data.grid_height * GameConfig.CELL_SIZE)
	var outer := Rect2(origin - Vector2(96, 76), size + Vector2(192, 152))
	draw_rect(outer, Color(0.16, 0.09, 0.075))
	draw_rect(Rect2(origin, size), data.ground_color)
	# Broad regolith bands and dust washes.
	for i in 26:
		var y := origin.y + _rng.randf_range(0.0, size.y)
		var thickness := _rng.randf_range(10.0, 46.0)
		var tint := data.ground_color.lightened(_rng.randf_range(0.02, 0.09))
		draw_rect(Rect2(origin.x, y, size.x, thickness), Color(tint.r, tint.g, tint.b, 0.18))
	for i in 14:
		var start := origin + Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y))
		var end := start + Vector2(_rng.randf_range(-260, 260), _rng.randf_range(-110, 110))
		draw_line(start, end, Color(data.dust_color.r, data.dust_color.g, data.dust_color.b, 0.06), _rng.randf_range(20, 55), true)
	# Speckle noise.
	for i in 620:
		var pos := origin + Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y))
		var radius := _rng.randf_range(0.7, 3.4)
		var brightness := _rng.randf_range(-0.09, 0.12)
		var tint := Color(
			clampf(data.ground_color.r + brightness, 0.0, 1.0),
			clampf(data.ground_color.g + brightness * 0.7, 0.0, 1.0),
			clampf(data.ground_color.b + brightness * 0.5, 0.0, 1.0),
			_rng.randf_range(0.18, 0.55))
		draw_circle(pos, radius, tint)
	# Cracks.
	for i in 24:
		var p := origin + Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y))
		var points := PackedVector2Array([p])
		var direction := _rng.randf_range(0.0, TAU)
		for j in 4:
			direction += _rng.randf_range(-0.7, 0.7)
			p += Vector2(cos(direction), sin(direction)) * _rng.randf_range(8.0, 24.0)
			points.append(p)
		draw_polyline(points, Color(0.18, 0.09, 0.07, 0.35), 1.5, true)
	# Perimeter cliffs.
	var edge := Color(0.22, 0.11, 0.08)
	draw_rect(Rect2(origin.x - 26, origin.y - 26, size.x + 52, 26), edge)
	draw_rect(Rect2(origin.x - 26, origin.y + size.y, size.x + 52, 26), edge)
	draw_rect(Rect2(origin.x - 26, origin.y - 26, 26, size.y + 52), edge)
	draw_rect(Rect2(origin.x + size.x, origin.y - 26, 26, size.y + 52), edge)
	for i in 40:
		var side := _rng.randi_range(0, 3)
		var pos := Vector2.ZERO
		if side == 0:
			pos = Vector2(_rng.randf_range(origin.x, origin.x + size.x), origin.y - _rng.randf_range(8, 24))
		elif side == 1:
			pos = Vector2(_rng.randf_range(origin.x, origin.x + size.x), origin.y + size.y + _rng.randf_range(8, 24))
		elif side == 2:
			pos = Vector2(origin.x - _rng.randf_range(8, 24), _rng.randf_range(origin.y, origin.y + size.y))
		else:
			pos = Vector2(origin.x + size.x + _rng.randf_range(8, 24), _rng.randf_range(origin.y, origin.y + size.y))
		draw_circle(pos, _rng.randf_range(4.0, 11.0), edge.lightened(0.08))
	# Props exactly on blocked cells.
	for cell in data.blocked_cells:
		var world := GameConfig.MAP_ORIGIN + Vector2(int(cell.x) * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5,
			int(cell.y) * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5)
		_draw_prop(world, Vector2i(int(cell.x), int(cell.y)))
	# Launch scar / dust run near the base side.
	draw_line(origin + Vector2(size.x - 210, 30), origin + Vector2(size.x - 110, size.y - 30),
		Color(0.1, 0.08, 0.075, 0.3), 40.0, true)


func _draw_prop(world: Vector2, cell: Vector2i) -> void:
	var choice := (cell.x * 7 + cell.y * 13 + data.prop_seed) % 7
	var theme := data.environment_theme
	match theme:
		"solar":
			if choice < 5:
				_draw_solar(world, choice)
			else:
				_draw_rock(world, choice)
		"pipeline":
			if choice < 4:
				_draw_pipe(world)
			elif choice < 6:
				_draw_crate(world, false)
			else:
				_draw_rock(world, choice)
		"supply", "relay":
			if choice < 4:
				_draw_crate(world, choice % 2 == 0)
			elif choice < 6:
				_draw_antenna(world)
			else:
				_draw_rock(world, choice)
		"landing", "bastion", "ridge":
			if choice < 3:
				_draw_crate(world, choice == 0)
			elif choice < 5:
				_draw_barricade(world)
			else:
				_draw_rock(world, choice)
		"ore", "excavation":
			if choice < 5:
				_draw_rock(world, choice, true)
			else:
				_draw_crate(world, false)
		"crater", "black":
			if choice < 4:
				_draw_rock(world, choice, true)
			elif choice < 6:
				_draw_crater(world)
			else:
				_draw_barricade(world)
		_:
			if choice < 3:
				_draw_rock(world, choice)
			elif choice < 5:
				_draw_crate(world, choice == 3)
			elif choice < 6:
				_draw_pipe(world)
			else:
				_draw_crater(world)


func _draw_rock(world: Vector2, variant: int, ore_hint: bool = false) -> void:
	var radius := 15.0 + float(variant % 3) * 4.0
	var points := PackedVector2Array()
	for i in 7:
		var a := TAU * float(i) / 7.0
		var r := radius * _rng.randf_range(0.68, 1.15)
		points.append(world + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, Color(0.28, 0.16, 0.12))
	var inner := PackedVector2Array()
	for p in points:
		inner.append(world + (p - world) * 0.7 + Vector2(-2, -3))
	draw_colored_polygon(inner, Color(0.38, 0.23, 0.16))
	if ore_hint:
		draw_circle(world + Vector2(4, -2), 3.5, Color(0.85, 0.5, 0.2))
		draw_circle(world + Vector2(-5, 5), 2.5, Color(0.7, 0.38, 0.18))


func _draw_crate(world: Vector2, large: bool) -> void:
	var size := 28.0 if large else 22.0
	var rect := Rect2(world - Vector2(size * 0.5, size * 0.5), Vector2(size, size))
	draw_rect(rect, Color(0.23, 0.24, 0.23))
	draw_rect(rect, Color(0.38, 0.34, 0.25), false, 2.0)
	draw_line(rect.position, rect.position + rect.size, Color(0.45, 0.4, 0.3, 0.7), 1.5)
	draw_line(rect.position + Vector2(size, 0), rect.position + Vector2(0, size), Color(0.45, 0.4, 0.3, 0.7), 1.5)
	draw_rect(Rect2(world.x - 5, world.y - 2, 10, 4), Color(0.9, 0.58, 0.2, 0.7))


func _draw_solar(world: Vector2, variant: int) -> void:
	var angle := -0.12 + float(variant) * 0.09
	draw_set_transform(world, angle, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -14), Vector2(22, -14), Vector2(18, 14), Vector2(-18, 14)]),
		Color(0.12, 0.17, 0.24))
	for i in 3:
		draw_line(Vector2(-18 + i * 12, -12), Vector2(-15 + i * 12, 12), Color(0.28, 0.45, 0.65, 0.65), 1.2)
	for i in 2:
		draw_line(Vector2(-21, -5 + i * 10), Vector2(21, -5 + i * 10), Color(0.28, 0.45, 0.65, 0.55), 1.0)
	draw_line(Vector2(0, 14), Vector2(0, 22), Color(0.35, 0.35, 0.34), 3.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_pipe(world: Vector2) -> void:
	draw_line(world + Vector2(-28, 8), world + Vector2(28, -8), Color(0.24, 0.25, 0.24), 13.0, true)
	draw_line(world + Vector2(-28, 8), world + Vector2(28, -8), Color(0.38, 0.36, 0.31), 7.0, true)
	draw_circle(world + Vector2(-18, 5), 6.0, Color(0.3, 0.3, 0.28))
	draw_circle(world + Vector2(17, -5), 6.0, Color(0.3, 0.3, 0.28))
	draw_line(world + Vector2(-7, 1), world + Vector2(1, 8), Color(0.72, 0.48, 0.2, 0.75), 2.0, true)


func _draw_antenna(world: Vector2) -> void:
	draw_circle(world + Vector2(0, 9), 8.0, Color(0.25, 0.25, 0.23))
	draw_line(world + Vector2(0, 8), world + Vector2(0, -24), Color(0.5, 0.52, 0.5), 2.5, true)
	draw_line(world + Vector2(-7, -10), world + Vector2(7, -10), Color(0.5, 0.52, 0.5), 2.0, true)
	draw_line(world + Vector2(-9, -16), world + Vector2(9, -16), Color(0.5, 0.52, 0.5), 2.0, true)
	draw_circle(world + Vector2(0, -26), 3.0, Color(1.0, 0.35, 0.2, 0.9))


func _draw_barricade(world: Vector2) -> void:
	draw_rect(Rect2(world.x - 26, world.y - 8, 52, 16), Color(0.28, 0.25, 0.21))
	for i in 4:
		draw_rect(Rect2(world.x - 24 + i * 13, world.y - 6, 7, 12), Color(0.78, 0.52, 0.12, 0.75))
	draw_circle(world + Vector2(-24, 12), 3.0, Color(0.2, 0.2, 0.18))
	draw_circle(world + Vector2(24, 12), 3.0, Color(0.2, 0.2, 0.18))


func _draw_crater(world: Vector2) -> void:
	draw_circle(world, 24.0, Color(0.2, 0.1, 0.08, 0.55))
	draw_circle(world, 17.0, Color(0.27, 0.13, 0.1, 0.6))
	draw_arc(world, 24.0, 0, TAU, 24, Color(0.38, 0.2, 0.14, 0.55), 3.0, true)
