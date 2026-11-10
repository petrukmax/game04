extends CanvasLayer
## Victory overlay with stars, battle statistics and campaign navigation.

var _level: LevelBase
var _result: Dictionary = {}


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(result: Dictionary, owner_level: LevelBase) -> void:
	_result = result
	_level = owner_level
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.014, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.05, 0.055, 0.06, 0.98),
		Color(0.55, 0.42, 0.18), 2, 4))
	panel.custom_minimum_size = Vector2(660, 0)
	panel.position = Vector2(470, 138)
	add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var stats: Dictionary = _result.get("stats", {})
	var campaign_complete := GameConfig.as_bool(_result.get("campaign_complete", false))
	box.add_child(UIStyle.make_label("SECTOR SECURED", 13, UIStyle.GREEN, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.make_label("CAMPAIGN COMPLETE" if campaign_complete else "VICTORY",
		38, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.make_label("%s  ·  SECTOR %02d" % [
		String(stats.get("level_name", "Sector")), int(stats.get("level_number", 1))],
		12, UIStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER))

	var stars := int(_result.get("stars", 1))
	var star_text := ""
	for i in 3:
		star_text += "★ " if i < stars else "☆ "
	var star_label := UIStyle.make_label(star_text.strip_edges(), 38, UIStyle.AMBER if stars > 1 else UIStyle.MUTED,
		HORIZONTAL_ALIGNMENT_CENTER)
	star_label.add_theme_color_override("font_shadow_color", Color(0.4, 0.2, 0.02, 0.8))
	star_label.add_theme_constant_override("shadow_offset_x", 2)
	star_label.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(star_label)
	box.add_child(UIStyle.separator(true))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	_add_stat(grid, "Base integrity", "%d / %d" % [int(stats.get("base_health", 0)), int(stats.get("base_max", 1))])
	_add_stat(grid, "Arachnids killed", str(int(stats.get("kills", 0))))
	_add_stat(grid, "Leaks", str(int(stats.get("leaks", 0))))
	_add_stat(grid, "Waves cleared", str(int(stats.get("waves_cleared", 0))))
	_add_stat(grid, "Towers built", str(int(stats.get("towers_built", 0))))
	_add_stat(grid, "Credits earned", "$%d" % int(stats.get("credits_earned", 0)))
	_add_stat(grid, "Battle time", _format_time(float(stats.get("time", 0.0))))
	_add_stat(grid, "Next sector", "UNLOCKED" if GameConfig.as_bool(_result.get("unlocked_next", false)) else "—")
	box.add_child(UIStyle.separator(true))

	if campaign_complete:
		box.add_child(UIStyle.make_label("The First Bastion stands. The brood is broken — for now.",
			12, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER))
	elif GameConfig.as_bool(_result.get("unlocked_next", false)):
		box.add_child(UIStyle.make_label("Sector %02d is now available." % (int(_result.get("level_number", 1)) + 1),
			12, UIStyle.GREEN, HORIZONTAL_ALIGNMENT_CENTER))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	if GameConfig.as_bool(_result.get("unlocked_next", false)) and not campaign_complete:
		_add_button(row, "NEXT SECTOR", true, _on_next)
	_add_button(row, "REPLAY", false, _on_replay)
	_add_button(row, "SECTOR SELECT", false, _on_level_select)
	_add_button(row, "MAIN MENU", false, _on_menu)
	AudioManager.play_sound("victory", 0.8, 1.0)


func _add_stat(grid: GridContainer, caption: String, value: String) -> void:
	var left := UIStyle.make_label(caption, 12, UIStyle.MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(left)
	var right := UIStyle.make_label(value, 13, UIStyle.OFFWHITE)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(right)


func _add_button(parent: HBoxContainer, text: String, accent: bool, handler: Callable) -> void:
	var button := UIStyle.make_button(text, accent, true)
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func():
		AudioManager.play_ui("ui_confirm")
		handler.call()
	)
	parent.add_child(button)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]


func _on_next() -> void:
	if _level:
		_level.next_level()
	else:
		GameState.next_level()


func _on_replay() -> void:
	GameState.restart_level()


func _on_level_select() -> void:
	GameState.goto_level_select()


func _on_menu() -> void:
	GameState.goto_main_menu()
