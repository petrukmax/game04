class_name GridManager
extends Node
## Owns cell states, buildability and placement validation.

enum CellState { EMPTY, BUILDABLE, ROAD, BLOCKED, OCCUPIED, DECORATION_ONLY }

var level_data: LevelData
var cells: Dictionary = {}
var occupied: Dictionary = {}
var width: int = GameConfig.GRID_WIDTH
var height: int = GameConfig.GRID_HEIGHT
var build_margin: int = 2


func setup(data: LevelData, road_cells: Dictionary) -> void:
	level_data = data
	width = data.grid_width
	height = data.grid_height
	build_margin = data.build_margin
	cells.clear()
	occupied.clear()
	var blocked: Dictionary = {}
	for cell in data.blocked_cells:
		blocked[Vector2i(int(cell.x), int(cell.y))] = true

	var near_road: Dictionary = {}
	for road_cell in road_cells.keys():
		for dx in range(-build_margin, build_margin + 1):
			for dy in range(-build_margin, build_margin + 1):
				var candidate := Vector2i(road_cell.x + dx, road_cell.y + dy)
				if candidate.x >= 0 and candidate.x < width and candidate.y >= 0 and candidate.y < height:
					near_road[candidate] = true

	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if road_cells.has(cell):
				cells[cell] = CellState.ROAD
			elif blocked.has(cell):
				cells[cell] = CellState.BLOCKED
			elif near_road.has(cell):
				cells[cell] = CellState.BUILDABLE
			else:
				cells[cell] = CellState.DECORATION_ONLY


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


func get_state(cell: Vector2i) -> int:
	return int(cells.get(cell, CellState.BLOCKED))


func world_to_cell(world_position: Vector2) -> Vector2i:
	var local := (world_position - GameConfig.MAP_ORIGIN) / float(GameConfig.CELL_SIZE)
	return Vector2i(floori(local.x), floori(local.y))


func cell_to_world(cell: Vector2i) -> Vector2:
	return GameConfig.MAP_ORIGIN + Vector2(cell.x * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5,
		cell.y * GameConfig.CELL_SIZE + GameConfig.CELL_SIZE * 0.5)


func snap_to_cell(world_position: Vector2) -> Vector2:
	return cell_to_world(world_to_cell(world_position))


func is_occupied(cell: Vector2i) -> bool:
	return occupied.has(cell)


func mark_occupied(cell: Vector2i, tower: Node) -> void:
	occupied[cell] = tower
	if is_inside(cell):
		cells[cell] = CellState.OCCUPIED


func clear_occupied(cell: Vector2i) -> void:
	occupied.erase(cell)
	if is_inside(cell) and get_state(cell) == CellState.OCCUPIED:
		cells[cell] = CellState.BUILDABLE


func can_build(cell: Vector2i, tower_cost: int, credits: int, available: bool = true) -> Dictionary:
	if not is_inside(cell):
		return {"ok": false, "reason": "Outside grid"}
	var state := get_state(cell)
	match state:
		CellState.ROAD:
			return {"ok": false, "reason": "Road"}
		CellState.BLOCKED:
			return {"ok": false, "reason": "Blocked"}
		CellState.OCCUPIED:
			return {"ok": false, "reason": "Occupied"}
		CellState.DECORATION_ONLY, CellState.EMPTY:
			return {"ok": false, "reason": "Too far from road"}
	if not available:
		return {"ok": false, "reason": "Unavailable"}
	if credits < tower_cost:
		return {"ok": false, "reason": "Not enough credits"}
	return {"ok": true, "reason": ""}


func state_name(state: int) -> String:
	match state:
		CellState.BUILDABLE:
			return "Buildable"
		CellState.ROAD:
			return "Road"
		CellState.BLOCKED:
			return "Blocked"
		CellState.OCCUPIED:
			return "Occupied"
		CellState.DECORATION_ONLY:
			return "Decoration"
		_:
			return "Empty"


func buildable_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in cells.keys():
		if int(cells[cell]) == CellState.BUILDABLE:
			out.append(cell)
	return out


func find_nearest_buildable(origin: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 99999.0
	for cell in buildable_cells():
		var d := Vector2(cell).distance_squared_to(Vector2(origin))
		if d < best_distance:
			best_distance = d
			best = cell
	return best
