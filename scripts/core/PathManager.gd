class_name PathManager
extends Node
## Rasterises both authored roads, owns waypoints, length and leak detection.

var level_data: LevelData
var road_cells: Dictionary = {}
var path_points: Array = []
var path_lengths: Array = []
var path_cell_points: Array = []


func setup(data: LevelData) -> void:
	level_data = data
	road_cells.clear()
	path_points.clear()
	path_lengths.clear()
	path_cell_points.clear()
	path_cell_points.append(_expand(data.path_a))
	path_cell_points.append(_expand(data.path_b))
	for cells in path_cell_points:
		for cell in cells:
			road_cells[cell] = true
		var points: Array[Vector2] = []
		for cell in cells:
			points.append(GameConfig.MAP_ORIGIN + Vector2(cell.x * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5,
				cell.y * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5))
		path_points.append(points)
		var total := 0.0
		for i in range(1, points.size()):
			total += points[i - 1].distance_to(points[i])
		path_lengths.append(total)


func _expand(turns: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if turns.size() < 2:
		return out
	for i in range(turns.size() - 1):
		var a: Vector2 = turns[i]
		var b: Vector2 = turns[i + 1]
		var p := Vector2i(int(a.x), int(a.y))
		var target := Vector2i(int(b.x), int(b.y))
		var dx: int = abs(target.x - p.x)
		var dy: int = abs(target.y - p.y)
		var sx: int = 1 if target.x > p.x else -1
		var sy: int = 1 if target.y > p.y else -1
		var err: int = dx - dy
		while true:
			if out.is_empty() or out[out.size() - 1] != p:
				out.append(p)
			if p == target:
				break
			var e2: int = 2 * err
			if e2 > -dy:
				err -= dy
				p.x += sx
			if e2 < dx:
				err += dx
				p.y += sy
	return out


func get_points(path_id: int) -> Array[Vector2]:
	if path_id < 0 or path_id >= path_points.size():
		return []
	return path_points[path_id]


func get_start(path_id: int) -> Vector2:
	var points := get_points(path_id)
	if points.is_empty():
		return GameConfig.MAP_ORIGIN
	return points[0]


func get_end(path_id: int) -> Vector2:
	var points := get_points(path_id)
	if points.is_empty():
		return GameConfig.MAP_ORIGIN
	return points[points.size() - 1]


func total_length(path_id: int) -> float:
	if path_id < 0 or path_id >= path_lengths.size():
		return 1.0
	return path_lengths[path_id]


func point_at_distance(path_id: int, distance: float) -> Vector2:
	var points := get_points(path_id)
	if points.is_empty():
		return GameConfig.MAP_ORIGIN
	var remaining := maxf(0.0, distance)
	for i in range(1, points.size()):
		var segment := points[i - 1].distance_to(points[i])
		if remaining <= segment and segment > 0.0:
			return points[i - 1].lerp(points[i], remaining / segment)
		remaining -= segment
	return points[points.size() - 1]


func road_cell_count() -> int:
	return road_cells.size()


func is_road_cell(cell: Vector2i) -> bool:
	return road_cells.has(cell)
