extends Node2D
## Floating health/shield bars and status markers for every arachnid.

var data: EnemyData
var _bar_width: float = 42.0


func configure(enemy_data: EnemyData) -> void:
	data = enemy_data
	if enemy_data.is_boss:
		_bar_width = 96.0
	elif enemy_data.is_elite:
		_bar_width = 64.0
	else:
		_bar_width = 42.0
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var enemy = get_parent()
	if enemy == null:
		return
	if enemy.dead or enemy.removed:
		return
	var scale_factor: float = maxf(0.7, enemy.enemy_data.body_scale)
	var y := -38.0 * scale_factor
	var width := _bar_width
	var height := 6.0 if not enemy.enemy_data.is_boss else 9.0
	var ratio := clampf(enemy.health / maxf(1.0, enemy.max_health), 0.0, 1.0)
	var bg := Rect2(-width * 0.5, y, width, height)
	draw_rect(bg, Color(0.06, 0.06, 0.07, 0.85))
	draw_rect(Rect2(bg.position, Vector2(width * ratio, height)), _health_color(ratio))
	if enemy.max_shield > 0.0 and enemy.shield_current > 0.0:
		var sr := clampf(enemy.shield_current / maxf(1.0, enemy.max_shield), 0.0, 1.0)
		draw_rect(Rect2(-width * 0.5, y - 4.0, width, 2.5), Color(0.1, 0.16, 0.22, 0.9))
		draw_rect(Rect2(-width * 0.5, y - 4.0, width * sr, 2.5), Color(0.4, 0.82, 1.0))
	draw_rect(bg, Color(0.35, 0.33, 0.3, 0.9), false, 1.0)

	var status_y := y + height + 5.0
	var x := -width * 0.5
	if enemy.burn_timer > 0.0:
		draw_circle(Vector2(x, status_y), 2.6, Color(1.0, 0.5, 0.12))
		x += 8.0
	if enemy.slow_timer > 0.0:
		draw_circle(Vector2(x, status_y), 2.6, Color(0.5, 0.85, 1.0))
		x += 8.0
	if enemy.stun_timer > 0.0:
		draw_circle(Vector2(x, status_y), 2.6, Color(1.0, 0.95, 0.3))
		x += 8.0
	if enemy.corrode_timer > 0.0:
		draw_circle(Vector2(x, status_y), 2.6, Color(0.55, 1.0, 0.3))
		x += 8.0
	if enemy.burrow_active:
		draw_circle(Vector2(x, status_y), 2.6, Color(0.75, 0.55, 0.35))
		x += 8.0

	if enemy.enemy_data.is_boss:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(-width * 0.5, y - 9.0), "BROOD TYRANT",
			HORIZONTAL_ALIGNMENT_CENTER, width, 11, Color(1.0, 0.4, 0.3))


func _health_color(ratio: float) -> Color:
	if ratio > 0.6:
		return Color(0.55, 0.85, 0.38)
	if ratio > 0.3:
		return Color(0.98, 0.72, 0.22)
	return Color(0.92, 0.25, 0.18)
