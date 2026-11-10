extends Label
## Floating combat number.

var _rise: float = 42.0


func setup(text_value: String, text_color: Color) -> void:
	text = text_value
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.03, 0.95))
	add_theme_constant_override("outline_size", 4)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 60
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - _rise, 0.85).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.85).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
