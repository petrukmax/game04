extends Node2D
## Build placement preview: footprint, range, cost and invalid reason.

var level: Node
var data: TowerData
var valid: bool = false
var reason: String = ""
var error_timer: float = 0.0


func setup(owner_level: Node) -> void:
	level = owner_level


func update_preview(tower_data: TowerData, is_valid: bool, invalid_reason: String = "") -> void:
	data = tower_data
	valid = is_valid
	reason = invalid_reason
	visible = true
	queue_redraw()


func flash_error() -> void:
	error_timer = 0.28
	queue_redraw()


func _process(delta: float) -> void:
	if error_timer > 0.0:
		error_timer = maxf(0.0, error_timer - delta)
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var col := Color(0.45, 0.95, 0.5, 0.85) if valid else Color(0.95, 0.25, 0.2, 0.9)
	var range_radius: float = data.attack_range
	if data.id == "relay":
		range_radius = data.support_radius
	if range_radius > 0.0:
		draw_circle(Vector2.ZERO, range_radius, Color(col.r, col.g, col.b, 0.055))
		for i in 48:
			if i % 2 == 0:
				continue
			var a0 := TAU * float(i) / 48.0
			var a1 := TAU * float(i + 1) / 48.0
			draw_line(Vector2(cos(a0), sin(a0)) * range_radius, Vector2(cos(a1), sin(a1)) * range_radius,
				Color(col.r, col.g, col.b, 0.55), 1.5, true)
	var cell_size := float(GameConfig.CELL_SIZE) - 4.0
	var rect := Rect2(-cell_size * 0.5, -cell_size * 0.5, cell_size, cell_size)
	draw_rect(rect, Color(col.r, col.g, col.b, 0.13))
	draw_rect(rect, col, false, 2.0)
	# Ghost turret silhouette.
	draw_circle(Vector2.ZERO, 19.0, Color(0.16, 0.17, 0.19, 0.7))
	draw_circle(Vector2.ZERO, 12.0, Color(col.r, col.g, col.b, 0.35))
	draw_line(Vector2.ZERO, Vector2(24, 0), Color(col.r, col.g, col.b, 0.65), 6.0, true)
	draw_circle(Vector2.ZERO, 5.0, Color(col.r, col.g, col.b, 0.9))
	var font := ThemeDB.fallback_font
	var label := "$%d" % data.cost if valid else "%s · $%d" % [reason, data.cost]
	var draw_color := Color(0.9, 0.92, 0.85) if valid else Color(1.0, 0.55, 0.45)
	draw_string(font, Vector2(-42, 43), label, HORIZONTAL_ALIGNMENT_CENTER, 84, 13, draw_color)
	if error_timer > 0.0:
		draw_rect(rect, Color(1.0, 0.2, 0.15, error_timer * 0.8), false, 3.0)
