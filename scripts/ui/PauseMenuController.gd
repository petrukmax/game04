extends CanvasLayer
## Pause overlay with resume, restart, settings, help and navigation.

var level: LevelBase
var settings_panel: CanvasLayer
var help_panel: CanvasLayer


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.015, 0.02, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(UIStyle.BG_PANEL, Color(0.55, 0.4, 0.2), 1, 4))
	panel.custom_minimum_size = Vector2(420, 0)
	panel.position = Vector2(590, 220)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)
	box.add_child(UIStyle.make_label("SIMULATION PAUSED", 24, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	var hint := UIStyle.make_label("The battle waits for you. Esc or Resume continues.", 11, UIStyle.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(hint)
	box.add_child(UIStyle.separator(true))

	_add_button(box, "RESUME", true, _on_resume)
	_add_button(box, "RESTART SECTOR", false, _on_restart)
	_add_button(box, "SETTINGS", false, _on_settings)
	_add_button(box, "HELP / CONTROLS", false, _on_help)
	_add_button(box, "SECTOR SELECT", false, _on_level_select)
	_add_button(box, "MAIN MENU", false, _on_menu)

	settings_panel = load("res://scenes/ui/SettingsPanel.tscn").instantiate()
	add_child(settings_panel)
	help_panel = load("res://scenes/ui/HelpPanel.tscn").instantiate()
	add_child(help_panel)


func _add_button(parent: VBoxContainer, text: String, accent: bool, handler: Callable) -> void:
	var button := UIStyle.make_button(text, accent)
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(func():
		AudioManager.play_ui("ui_confirm")
		handler.call()
	)
	parent.add_child(button)


func setup(owner_level: LevelBase) -> void:
	level = owner_level


func set_visible_state(state: bool) -> void:
	visible = state
	if state:
		if settings_panel:
			settings_panel.call("close")
		if help_panel:
			help_panel.call("close_panel")
		AudioManager.play_ui("ui_click")


func _on_resume() -> void:
	if level:
		level.set_paused(false)


func _on_restart() -> void:
	get_tree().paused = false
	if level:
		level.restart_level()


func _on_settings() -> void:
	if settings_panel:
		settings_panel.call("open")


func _on_help() -> void:
	if help_panel:
		help_panel.call("open")


func _on_level_select() -> void:
	get_tree().paused = false
	if level:
		level.go_to_level_select()
	else:
		GameState.goto_level_select()


func _on_menu() -> void:
	get_tree().paused = false
	if level:
		level.go_to_menu()
	else:
		GameState.goto_main_menu()
