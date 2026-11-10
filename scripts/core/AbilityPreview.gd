extends Node2D
## Ability area targeting preview.

var level: Node
var ability: AbilityData


func setup(owner_level: Node) -> void:
	level = owner_level


func set_ability(ability_data: AbilityData) -> void:
	ability = ability_data
	visible = true
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	if ability == null:
		return
	var col := ability.color
	var radius := ability.radius
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, 0.1))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(col.r, col.g, col.b, 0.9), 3.0, true)
	for i in 16:
		var a := TAU * float(i) / 16.0
		draw_line(Vector2(cos(a), sin(a)) * (radius - 8), Vector2(cos(a), sin(a)) * radius,
			Color(col.r, col.g, col.b, 0.8), 2.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(col.r, col.g, col.b, 0.65))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-radius, -radius - 12), ability.display_name,
		HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 16, Color(col.r, col.g, col.b, 0.95))
