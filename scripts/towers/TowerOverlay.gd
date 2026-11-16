extends Node2D
## Selection ring, upgrade pips and the disabled marker for one tower.
##
## It lives in a canvas item of its own so the baked tower art (body, deco and
## turret quads) never has to re-record just because the tower got selected,
## upgraded or hit by corrosive acid.

var selected: bool = false
var disabled: bool = false
var level: int = 1
var max_level: int = 1
var color: Color = Color(0.95, 0.64, 0.24)
var time: float = 0.0


func set_state(is_selected: bool, is_disabled: bool, tower_level: int, tower_max_level: int, tower_color: Color) -> void:
	var changed := selected != is_selected or disabled != is_disabled \
		or level != tower_level or max_level != tower_max_level or color != tower_color
	selected = is_selected
	disabled = is_disabled
	level = tower_level
	max_level = tower_max_level
	color = tower_color
	if changed:
		queue_redraw()


func set_time(value: float) -> void:
	time = value
	if disabled:
		queue_redraw()


func _draw() -> void:
	if selected:
		draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color(0.98, 0.65, 0.2, 0.85), 2.0, true)
	if disabled:
		var flicker := 0.35 + 0.35 * sin(time * 26.0)
		draw_circle(Vector2.ZERO, 30, Color(0.25, 0.85, 0.4, flicker * 0.35))
		draw_line(Vector2(-22, -22), Vector2(22, 22), Color(0.4, 1.0, 0.5, flicker), 2.0)
	# Upgrade pips.
	if max_level > 1:
		for i in range(1, 4):
			var pip_color := color if i < level else Color(0.22, 0.23, 0.25)
			draw_circle(Vector2(-10 + i * 10, 24), 3.0, pip_color)
