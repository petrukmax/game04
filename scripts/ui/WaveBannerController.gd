extends Control
## Animated wave and boss banner shown under the top tactical bar.

var _title: Label
var _subtitle: Label
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 300
	offset_right = -300
	offset_top = 92
	offset_bottom = 206
	modulate.a = 0.0
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.05, 0.05, 0.06, 0.82), UIStyle.AMBER_DARK, 1, 3))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	_title = UIStyle.make_label("", 25, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_title)
	_subtitle = UIStyle.make_label("", 12, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_subtitle)


func show_wave(index: int, total: int, preview: String) -> void:
	var boss := preview.to_lower().contains("boss") or preview.to_lower().contains("tyrant")
	show_message("WAVE %d / %d" % [index, total], preview.to_upper(),
		UIStyle.RED if boss else UIStyle.AMBER)


func show_message(title: String, subtitle: String, color: Color = UIStyle.AMBER) -> void:
	if _title == null:
		return
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_subtitle.text = subtitle
	visible = true
	modulate.a = 0.0
	position.y = 82.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_property(self, "position:y", 92.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.set_parallel(false)
	_tween.tween_interval(2.1)
	_tween.tween_property(self, "modulate:a", 0.0, 0.45)
