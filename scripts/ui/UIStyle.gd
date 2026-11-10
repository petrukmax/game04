class_name UIStyle
extends RefCounted
## Shared dark graphite / amber military console styling.

const BG_DEEP := Color(0.047, 0.05, 0.06, 0.96)
const BG_PANEL := Color(0.075, 0.08, 0.09, 0.96)
const BG_RAISED := Color(0.115, 0.12, 0.135, 0.98)
const AMBER := Color(0.98, 0.65, 0.2)
const AMBER_DARK := Color(0.56, 0.34, 0.08)
const OFFWHITE := Color(0.9, 0.89, 0.83)
const MUTED := Color(0.6, 0.6, 0.56)
const RED := Color(0.86, 0.19, 0.14)
const GREEN := Color(0.5, 0.85, 0.45)
const BLUE := Color(0.45, 0.78, 1.0)


static func panel_box(bg: Color = BG_PANEL, border: Color = Color(0.3, 0.27, 0.21, 0.9),
		width: int = 1, radius: int = 3) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 4
	return box


static func make_panel(bg: Color = BG_PANEL, border: Color = Color(0.3, 0.27, 0.21, 0.9)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_box(bg, border))
	return panel


static func style_button(button: Button, accent: bool = false, compact: bool = false) -> void:
	var normal := panel_box(Color(0.72, 0.4, 0.08) if accent else BG_RAISED,
		Color(0.98, 0.65, 0.2) if accent else Color(0.35, 0.31, 0.24), 1, 3)
	var hover := panel_box(Color(0.86, 0.5, 0.12) if accent else Color(0.18, 0.18, 0.19),
		AMBER, 1, 3)
	var pressed := panel_box(Color(0.5, 0.29, 0.06) if accent else Color(0.09, 0.1, 0.11),
		AMBER, 1, 3)
	var disabled := panel_box(Color(0.07, 0.075, 0.08), Color(0.19, 0.19, 0.18), 1, 3)
	var top := 5 if compact else 8
	var side := 8 if compact else 12
	for box in [normal, hover, pressed]:
		box.content_margin_left = side
		box.content_margin_right = side
		box.content_margin_top = top
		box.content_margin_bottom = top
	disabled.content_margin_left = side
	disabled.content_margin_right = side
	disabled.content_margin_top = top
	disabled.content_margin_bottom = top
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0.15, 0.1, 0.04) if accent else OFFWHITE)
	button.add_theme_color_override("font_hover_color", Color(0.08, 0.05, 0.02) if accent else Color(1.0, 0.92, 0.78))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.02) if accent else AMBER)
	button.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.38))
	button.add_theme_font_size_override("font_size", 13 if compact else 14)


static func make_button(text: String, accent: bool = false, compact: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	style_button(button, accent, compact)
	return button


static func make_label(text: String, size: int = 14, color: Color = OFFWHITE,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


static func separator(horizontal: bool = false) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.36, 0.33, 0.27, 0.7)
	if horizontal:
		rect.custom_minimum_size = Vector2(40, 1)
	else:
		rect.custom_minimum_size = Vector2(1, 40)
	return rect


static func stat_block(caption: String, value: String, value_color: Color = OFFWHITE) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var cap := make_label(caption, 10, MUTED)
	var val := make_label(value, 18, value_color)
	box.add_child(cap)
	box.add_child(val)
	return box
