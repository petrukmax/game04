extends PanelContainer
## Floating tooltip used by shop cards, tower panel and ability buttons.

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	custom_minimum_size = Vector2(330, 0)
	add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.04, 0.04, 0.05, 0.97), Color(0.55, 0.4, 0.2), 1, 3))
	_label = UIStyle.make_label("", 11, UIStyle.OFFWHITE)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func show_text(text: String, global_pos: Vector2) -> void:
	if _label == null:
		return
	_label.text = text
	visible = true
	reset_size()
	var view := get_viewport_rect().size
	var desired := global_pos + Vector2(0, -8)
	desired.x = clampf(desired.x, 8.0, maxf(8.0, view.x - size.x - 8.0))
	desired.y = clampf(desired.y - size.y, 8.0, maxf(8.0, view.y - size.y - 8.0))
	position = desired


func hide_tip() -> void:
	visible = false
