extends Node2D
## Draws both compacted regolith roads, their junction and direction chevrons.

var level: LevelBase


func setup(owner_level: LevelBase) -> void:
	level = owner_level
	z_index = -5
	queue_redraw()


func _draw() -> void:
	if level == null or level.path == null:
		return
	for path_id in 2:
		var points: Array[Vector2] = level.path.get_points(path_id)
		if points.size() < 2:
			continue
		draw_polyline(points, Color(0.11, 0.09, 0.09, 0.75), 56.0, true)
		draw_polyline(points, Color(0.2, 0.16, 0.14), 48.0, true)
		draw_polyline(points, Color(0.27, 0.21, 0.17), 36.0, true)
		draw_polyline(points, Color(0.36, 0.28, 0.21, 0.65), 2.0, true)
		for i in points.size():
			draw_circle(points[i], 24.0, Color(0.23, 0.18, 0.15))
			if i > 0 and i < points.size() - 1:
				draw_circle(points[i], 16.0, Color(0.29, 0.22, 0.17))
		_draw_chevrons(points, path_id)
	# Junction marker.
	var intersection := _find_intersection()
	if intersection != Vector2.ZERO:
		draw_circle(intersection, 31.0, Color(0.35, 0.25, 0.16, 0.5))
		draw_arc(intersection, 27.0, 0, TAU, 32, Color(0.95, 0.6, 0.18, 0.4), 2.0, true)
		draw_arc(intersection, 18.0, 0, TAU, 24, Color(0.95, 0.6, 0.18, 0.25), 1.5, true)


func _draw_chevrons(points: Array[Vector2], path_id: int) -> void:
	var travelled := 0.0
	var next_marker := 90.0
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var seg := a.distance_to(b)
		while travelled + seg >= next_marker:
			var t := (next_marker - travelled) / maxf(seg, 0.001)
			var p := a.lerp(b, t)
			var dir := (b - a).normalized()
			var normal := dir.orthogonal()
			var tip := p + dir * 9.0
			var left := p - dir * 4.0 + normal * 6.0
			var right := p - dir * 4.0 - normal * 6.0
			var col := Color(0.85, 0.55, 0.2, 0.35) if path_id == 0 else Color(0.6, 0.75, 0.95, 0.28)
			draw_colored_polygon(PackedVector2Array([tip, left, right]), col)
			next_marker += 120.0
		travelled += seg


func _find_intersection() -> Vector2:
	if level == null or level.path == null or level.path.path_cell_points.size() < 2:
		return Vector2.ZERO
	var first: Array = level.path.path_cell_points[0]
	var second: Array = level.path.path_cell_points[1]
	for cell in first:
		if second.has(cell):
			return level.grid.cell_to_world(cell)
	return Vector2.ZERO
