extends Button
## One tower shop card. Displays silhouette, name, cost and shortcut.

var data: TowerData
var hud: CanvasLayer
var level: Node
var selected: bool = false
var affordable: bool = true
var available: bool = true

var _icon: Control
var _name_label: Label
var _cost_label: Label
var _shortcut_label: Label
var _status_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(104, 88)
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UIStyle.style_button(self, false, true)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	_icon = Control.new()
	_icon.set_script(load("res://scripts/ui/TowerIcon.gd"))
	_icon.custom_minimum_size = Vector2(0, 35)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_icon)
	_name_label = UIStyle.make_label("Tower", 10, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)
	_cost_label = UIStyle.make_label("100", 12, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_cost_label)
	_shortcut_label = UIStyle.make_label("1", 9, Color(0.62, 0.58, 0.48))
	_shortcut_label.position = Vector2(5, 1)
	_shortcut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shortcut_label)
	_status_label = UIStyle.make_label("", 9, UIStyle.RED, HORIZONTAL_ALIGNMENT_CENTER)
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_top = -14
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_label)
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(tower_data: TowerData, owner_hud: CanvasLayer, owner_level: Node) -> void:
	data = tower_data
	hud = owner_hud
	level = owner_level
	_shortcut_label.text = data.shortcut
	_icon.call("configure", data.visual_style, data.primary_color)
	_name_label.text = data.display_name
	_refresh_state()


func refresh(credits: int) -> void:
	if data == null:
		return
	affordable = credits >= data.cost
	available = level != null and level.get_available_towers().has(data.id)
	_refresh_state()


func set_selected(value: bool) -> void:
	selected = value
	_refresh_state()


func _refresh_state() -> void:
	if data == null:
		return
	var box := UIStyle.panel_box(UIStyle.BG_RAISED,
		UIStyle.AMBER if selected else Color(0.35, 0.31, 0.24), 2 if selected else 1, 3)
	add_theme_stylebox_override("normal", box)
	var hover_box := UIStyle.panel_box(Color(0.18, 0.18, 0.19), UIStyle.AMBER if selected else Color(0.7, 0.5, 0.24), 2, 3)
	add_theme_stylebox_override("hover", hover_box)
	add_theme_stylebox_override("pressed", box)
	_cost_label.text = "LOCKED" if not available else "%d" % data.cost
	_cost_label.add_theme_color_override("font_color",
		UIStyle.MUTED if not available else (UIStyle.AMBER if affordable else UIStyle.RED))
	_name_label.add_theme_color_override("font_color", UIStyle.MUTED if not available else UIStyle.OFFWHITE)
	_status_label.text = "NOT IN SECTOR" if not available else ("INSUFFICIENT" if not affordable else "")
	modulate = Color(0.55, 0.55, 0.53) if not available else (Color(0.72, 0.72, 0.7) if not affordable else Color.WHITE)


func _on_pressed() -> void:
	if data == null or level == null:
		return
	if not available:
		EventBus.notification.emit("%s is not available in this sector." % data.display_name, UIStyle.RED)
		AudioManager.play_ui("ui_error")
		return
	if not affordable:
		EventBus.notification.emit("Not enough credits for %s ($%d)." % [data.display_name, data.cost], UIStyle.RED)
		AudioManager.play_ui("ui_error")
		return
	level.select_build_type(data.id)


func _on_mouse_entered() -> void:
	if hud and hud.has_method("show_tooltip") and data != null:
		var lines := "%s  [%s]\nCost $%d · %s\n%s" % [data.display_name, data.role, data.cost,
			data.damage_type.to_upper(), data.description]
		if not available:
			lines += "\nLocked in this sector."
		hud.call("show_tooltip", lines, get_global_rect().position + Vector2(0, -10))


func _on_mouse_exited() -> void:
	if hud and hud.has_method("hide_tooltip"):
		hud.call("hide_tooltip")
