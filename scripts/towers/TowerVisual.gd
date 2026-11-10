extends Node2D
## Procedural top-down tower art. One script, ten unmistakable silhouettes.

var data: TowerData
var style: String = "pulse"
var aim: float = 0.0
var kick_timer: float = 0.0
var selected: bool = false
var disabled: bool = false
var _time: float = 0.0
var _anim_accum: float = 0.0

## Only styles whose art actually changes over time need a continuous redraw.
const ANIM_INTERVAL := 1.0 / 24.0
const ANIMATED_STYLES := {
	"tesla": true, "cryo": true, "relay": true, "mine": true, "orbital": true,
}


func configure(tower_data: TowerData) -> void:
	data = tower_data
	style = tower_data.visual_style
	queue_redraw()


func set_aim(value: float) -> void:
	aim = value
	queue_redraw()


func kick() -> void:
	kick_timer = 0.12
	queue_redraw()


func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()


func set_disabled(value: bool) -> void:
	disabled = value
	queue_redraw()


func on_upgrade() -> void:
	kick_timer = 0.3
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var was_kicking := kick_timer > 0.0
	if kick_timer > 0.0:
		kick_timer = maxf(0.0, kick_timer - delta)
	if disabled or ANIMATED_STYLES.has(style):
		_anim_accum += delta
		if _anim_accum >= ANIM_INTERVAL:
			_anim_accum = 0.0
			queue_redraw()
	elif kick_timer > 0.0 or was_kicking:
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var col := data.primary_color
	var metal := Color(0.19, 0.2, 0.23)
	var dark := Color(0.1, 0.11, 0.13)
	var light := Color(0.5, 0.52, 0.55)
	var kick_offset := Vector2(-4.0 * (kick_timer / 0.12), 0.0).rotated(aim) if kick_timer > 0.0 else Vector2.ZERO

	# Shadow and hexagonal pad.
	draw_circle(Vector2(3, 7), 27, Color(0.0, 0.0, 0.0, 0.34))
	var pad := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		pad.append(Vector2(cos(a), sin(a)) * 28.0)
	draw_colored_polygon(pad, metal)
	var pad_line := pad.duplicate()
	pad_line.append(pad[0])
	draw_polyline(pad_line, Color(0.4, 0.34, 0.28), 2.0, true)
	draw_circle(Vector2.ZERO, 22, dark)

	if style == "relay":
		_draw_relay(col, metal, light)
	elif style == "mine":
		_draw_mine(col, metal)
	elif style == "orbital":
		_draw_orbital(col, metal, light, kick_offset)
	else:
		_draw_turret(col, metal, light, kick_offset)

	if selected:
		draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color(0.98, 0.65, 0.2, 0.85), 2.0, true)
	if disabled:
		var flicker := 0.35 + 0.35 * sin(_time * 26.0)
		draw_circle(Vector2.ZERO, 30, Color(0.25, 0.85, 0.4, flicker * 0.35))
		draw_line(Vector2(-22, -22), Vector2(22, 22), Color(0.4, 1.0, 0.5, flicker), 2.0)
	# Upgrade pips.
	if data != null and data.max_level > 1:
		var parent_tower = get_parent()
		var level: int = int(parent_tower.current_level) if parent_tower and "current_level" in parent_tower else 1
		for i in range(1, 4):
			var pip_col := col if i < level else Color(0.22, 0.23, 0.25)
			draw_circle(Vector2(-10 + i * 10, 24), 3.0, pip_col)


func _draw_turret(col: Color, metal: Color, light: Color, kick_offset: Vector2) -> void:
	var dir := Vector2.RIGHT.rotated(aim)
	var side := dir.orthogonal()
	match style:
		"pulse":
			draw_line(kick_offset, dir * 27.0 + kick_offset, Color(0.35, 0.37, 0.4), 8.0, true)
			draw_line(dir * 4 + side * 4.0 + kick_offset, dir * 27 + side * 4.0 + kick_offset, col, 3.0, true)
			draw_line(dir * 4 - side * 4.0 + kick_offset, dir * 27 - side * 4.0 + kick_offset, col, 3.0, true)
			draw_circle(Vector2.ZERO, 13, metal)
			draw_circle(Vector2.ZERO, 8, Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
			draw_circle(Vector2(0, -1), 4, col)
		"cannon":
			draw_line(kick_offset, dir * 31.0 + kick_offset, Color(0.32, 0.33, 0.36), 13.0, true)
			draw_line(kick_offset, dir * 31.0 + kick_offset, Color(0.52, 0.44, 0.32), 8.0, true)
			draw_circle(Vector2.ZERO, 18, metal)
			draw_circle(Vector2.ZERO, 13, Color(0.29, 0.28, 0.26))
			draw_arc(Vector2.ZERO, 13, 0, TAU, 20, col, 2.5, true)
			draw_rect(Rect2(-9, -14, 7, 5), light)
			draw_rect(Rect2(-9, -8, 7, 5), light)
		"flame":
			for i in range(-2, 3):
				var a := aim - 0.32 + float(i) * 0.16
				var d := Vector2.RIGHT.rotated(a)
				draw_line(Vector2.ZERO, d * 26.0, Color(0.35, 0.18, 0.12), 5.0, true)
				draw_line(d * 18.0, d * 29.0, Color(1.0, 0.45, 0.12), 6.0, true)
			draw_circle(Vector2.ZERO, 19, Color(0.25, 0.2, 0.16))
			draw_circle(Vector2(-9, 8), 7, Color(0.38, 0.42, 0.2))
			draw_circle(Vector2(9, 8), 7, Color(0.38, 0.42, 0.2))
			draw_arc(Vector2.ZERO, 14, 0, TAU, 20, Color(1.0, 0.5, 0.13), 2.0, true)
		"tesla":
			draw_circle(Vector2.ZERO, 17, Color(0.16, 0.18, 0.22))
			for i in range(1, 4):
				draw_arc(Vector2.ZERO, 4.0 + i * 4.0, 0, TAU, 24, Color(0.35, 0.7, 1.0, 0.75), 2.0, true)
			for i in 4:
				var a := _time * 1.8 + TAU * float(i) / 4.0
				var p := Vector2(cos(a), sin(a)) * 22.0
				draw_circle(p, 3.0, Color(0.6, 0.9, 1.0))
				draw_line(p, Vector2(cos(a + 0.4), sin(a + 0.4)) * 14.0, Color(0.4, 0.8, 1.0, 0.65), 1.5, true)
			draw_circle(Vector2(0, -22), 4, Color(0.8, 0.95, 1.0))
		"missile":
			draw_rect(Rect2(-17, -16, 34, 30), Color(0.25, 0.26, 0.24))
			for x in range(-13, 14, 9):
				for y in range(-12, 11, 8):
					draw_rect(Rect2(x, y, 6, 6), Color(0.14, 0.15, 0.16))
					draw_circle(Vector2(x + 3, y + 3), 1.5, col)
			var lid := Vector2.RIGHT.rotated(aim)
			draw_line(Vector2.ZERO, lid * 26, Color(0.55, 0.55, 0.5), 3.0, true)
			# Visible missile tips above the cells.
			for i in 3:
				var off := Vector2(-11 + i * 11, -2)
				draw_circle(off, 3.2, Color(0.92, 0.78, 0.45))
				draw_line(off, off + Vector2(0, -7), Color(1.0, 0.55, 0.2), 2.0)
		"cryo":
			draw_circle(Vector2.ZERO, 18, Color(0.3, 0.42, 0.48))
			draw_circle(Vector2.ZERO, 13, Color(0.48, 0.68, 0.75))
			for i in 6:
				var a := TAU * float(i) / 6.0 + _time * 0.35
				draw_line(Vector2(cos(a), sin(a)) * 8, Vector2(cos(a), sin(a)) * 23, Color(0.75, 0.95, 1.0, 0.9), 2.0, true)
			draw_circle(Vector2(0, -19), 5, Color(0.85, 0.98, 1.0))
			var frost_dir := Vector2.RIGHT.rotated(aim)
			draw_line(frost_dir * 12, frost_dir * 25, Color(0.8, 0.97, 1.0), 5.0, true)
		"rail":
			var rail_line := Color(0.65, 0.7, 0.73)
			draw_line(kick_offset, dir * 35.0 + kick_offset, rail_line, 6.0, true)
			draw_line(dir * 31 + side * 6 + kick_offset, dir * 38 + side * 6 + kick_offset, Color(0.35, 0.38, 0.42), 2.0, true)
			draw_line(dir * 31 - side * 6 + kick_offset, dir * 38 - side * 6 + kick_offset, Color(0.35, 0.38, 0.42), 2.0, true)
			draw_circle(Vector2.ZERO, 15, Color(0.22, 0.24, 0.28))
			draw_circle(Vector2.ZERO, 10, col)
			draw_circle(Vector2(-2, -2), 4, Color(0.95, 0.98, 1.0))
			for i in 3:
				draw_circle(Vector2(-10 + i * 10, 18), 2.5, col)
		_:
			draw_circle(Vector2.ZERO, 13, col)


func _draw_relay(col: Color, metal: Color, light: Color) -> void:
	var parent_tower = get_parent()
	var aura: float = float(parent_tower.stats.get("support_radius", 0.0)) if parent_tower else 0.0
	if aura > 0.0:
		draw_circle(Vector2.ZERO, aura, Color(col.r, col.g, col.b, 0.045))
		draw_arc(Vector2.ZERO, aura, 0, TAU, 64, Color(col.r, col.g, col.b, 0.28), 1.5, true)
		draw_arc(Vector2.ZERO, aura * 0.7, _time * 0.3, _time * 0.3 + 4.0, 24, Color(col.r, col.g, col.b, 0.4), 2.0, true)
	draw_circle(Vector2.ZERO, 17, Color(0.18, 0.21, 0.2))
	draw_circle(Vector2.ZERO, 11, Color(0.25, 0.32, 0.28))
	draw_line(Vector2(0, 4), Vector2(0, -22), light, 3.0, true)
	for i in 3:
		var y := -8.0 - i * 6.0
		draw_arc(Vector2(0, y + 5), 7.0 + i * 4.0, PI + 0.5, TAU - 0.5, 12, col, 1.6, true)
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	draw_circle(Vector2(0, -25), 4.5, Color(col.r, col.g, col.b, 0.5 + 0.5 * pulse))
	draw_circle(Vector2(-14, 13), 3, col)
	draw_circle(Vector2(14, 13), 3, col)


func _draw_mine(col: Color, metal: Color) -> void:
	draw_rect(Rect2(-20, -14, 40, 28), metal)
	draw_rect(Rect2(-15, -9, 30, 18), Color(0.22, 0.2, 0.17))
	for i in 3:
		draw_rect(Rect2(-13 + i * 10, -6, 7, 7), Color(0.08, 0.08, 0.09))
		draw_circle(Vector2(-9.5 + i * 10, -2.5), 2.0, col)
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	draw_circle(Vector2(0, 14), 3.0, Color(1.0, 0.35, 0.15, 0.5 + pulse * 0.5))


func _draw_orbital(col: Color, metal: Color, light: Color, kick_offset: Vector2) -> void:
	draw_circle(Vector2.ZERO, 19, Color(0.2, 0.17, 0.23))
	var dir := Vector2.RIGHT.rotated(aim)
	draw_line(Vector2.ZERO, dir * 18.0, light, 4.0, true)
	# Parabolic dish.
	var dish_center := dir * 15.0
	for i in 3:
		draw_arc(dish_center, 9.0 + i * 4.0, aim - 0.9, aim + 0.9, 14, Color(col.r, col.g, col.b, 0.9 - i * 0.22), 2.0, true)
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	draw_circle(dish_center, 10.0, Color(col.r, col.g, col.b, 0.14 + pulse * 0.12))
	draw_circle(dish_center, 4.0, Color(1.0, 0.8, 0.9))
	# Charge ring.
	draw_arc(Vector2.ZERO, 24.0, -_time * 1.5, -_time * 1.5 + 3.5, 28, col, 2.0, true)
