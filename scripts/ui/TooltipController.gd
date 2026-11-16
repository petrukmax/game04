extends Panel
## Floating tooltip used by shop cards and the tower panel.
##
## A plain Panel is used instead of a PanelContainer so the tooltip's size never
## depends on a wrapped Label's cached minimum height. The original first hover
## in a session inherited a stale 1970 px minimum because the invisible Label
## had not wrapped yet. Size is now measured from font metrics and applied
## directly, and the font/window are roughly twice the old dimensions.

const TIP_WIDTH := 660.0
const TIP_FONT_SIZE := 16
const PAD_LEFT := 12.0
const PAD_TOP := 10.0
const PAD_BOTTOM := 10.0
const CONTENT_WIDTH := TIP_WIDTH - PAD_LEFT * 2.0

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	custom_minimum_size = Vector2(TIP_WIDTH, 0)
	add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.04, 0.04, 0.05, 0.97), Color(0.55, 0.4, 0.2), 1, 3))
	_label = UIStyle.make_label("", TIP_FONT_SIZE, UIStyle.OFFWHITE)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.position = Vector2(PAD_LEFT, PAD_TOP)
	_label.size = Vector2(CONTENT_WIDTH, 0)
	add_child(_label)


func show_text(text: String, global_pos: Vector2) -> void:
	if _label == null:
		return
	_label.text = text
	var font := _label.get_theme_font("font")
	var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, CONTENT_WIDTH, TIP_FONT_SIZE)
	var height := maxf(measured.y, TIP_FONT_SIZE) + PAD_TOP + PAD_BOTTOM
	_label.size = Vector2(CONTENT_WIDTH, height - PAD_TOP - PAD_BOTTOM)
	size = Vector2(TIP_WIDTH, height)
	visible = true
	var view := get_viewport_rect().size
	var desired := global_pos + Vector2(0, -8)
	desired.x = clampf(desired.x, 8.0, maxf(8.0, view.x - size.x - 8.0))
	desired.y = clampf(desired.y - size.y, 8.0, maxf(8.0, view.y - size.y - 8.0))
	position = desired


func hide_tip() -> void:
	visible = false
