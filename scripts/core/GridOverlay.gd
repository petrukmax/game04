extends Node2D
## Visible square grid over the entire battlefield. Purely presentational.

var level: LevelBase


func setup(owner_level: LevelBase) -> void:
	level = owner_level
	z_index = 2
	queue_redraw()


func _draw() -> void:
	if level == null or level.grid == null:
		return
	var origin := GameConfig.MAP_ORIGIN
	var cell := float(GameConfig.CELL_SIZE)
	var w := float(level.grid.width)
	var h := float(level.grid.height)
	# Faint buildable tint so valid squares read without dominating the field.
	for y in level.grid.height:
		for x in level.grid.width:
			var state := level.grid.get_state(Vector2i(x, y))
			if state == GridManager.CellState.BUILDABLE:
				draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)),
					Color(0.98, 0.65, 0.2, 0.022))
	# Grid lines.
	for x in range(int(w) + 1):
		var strong := x % 5 == 0
		draw_line(origin + Vector2(x * cell, 0), origin + Vector2(x * cell, h * cell),
			Color(0.9, 0.65, 0.4, 0.17 if strong else 0.085), 1.0, true)
	for y in range(int(h) + 1):
		var strong := y % 5 == 0
		draw_line(origin + Vector2(0, y * cell), origin + Vector2(w * cell, y * cell),
			Color(0.9, 0.65, 0.4, 0.17 if strong else 0.085), 1.0, true)
	draw_rect(Rect2(origin, Vector2(w * cell, h * cell)), Color(0.95, 0.62, 0.22, 0.35), false, 2.0)
