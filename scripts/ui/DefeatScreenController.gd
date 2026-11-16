extends CanvasLayer
## Defeat overlay with cause summary, statistics and retry flow.

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
	dim.color = Color(0.02, 0.008, 0.008, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.055, 0.035, 0.035, 0.98),
		Color(0.6, 0.16, 0.12), 2, 4))
	panel.custom_minimum_size = Vector2(640, 0)
	panel.position = Vector2(480, 168)
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
	box.add_child(UIStyle.make_label(Loc.t("BASE INTEGRITY LOST"), 13, UIStyle.RED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.make_label(Loc.t("OUTPOST OVERRUN"), 34, UIStyle.RED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.make_label(Loc.tf("%s  ·  SECTOR %02d", [
		Loc.t(String(stats.get("level_name", Loc.t("Sector")))), int(stats.get("level_number", 1))]),
		12, UIStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.make_label(Loc.t("The base falls the moment a single arachnid gets through. Rebuild and hold every road."),
		12, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIStyle.separator(true))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	_add_stat(grid, Loc.t("Waves cleared"), str(int(stats.get("waves_cleared", 0))))
	_add_stat(grid, Loc.t("Leaks"), str(int(stats.get("leaks", 0))))
	_add_stat(grid, Loc.t("Arachnids killed"), str(int(stats.get("kills", 0))))
	_add_stat(grid, Loc.t("Towers built"), str(int(stats.get("towers_built", 0))))
	_add_stat(grid, Loc.t("Credits earned"), "$%d" % int(stats.get("credits_earned", 0)))
	_add_stat(grid, Loc.t("Battle time"), _format_time(float(stats.get("time", 0.0))))
	box.add_child(UIStyle.separator(true))

	var cleared := _checkpoint_wave()
	if cleared > 0:
		box.add_child(UIStyle.make_label(Loc.tf(
			"Checkpoint: wave %d cleared — all towers and credits will be restored.",
			[cleared]), 11, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER))

	if cleared > 0:
		var wave_row := HBoxContainer.new()
		wave_row.add_theme_constant_override("separation", 8)
		box.add_child(wave_row)
		_add_button(wave_row, Loc.tf("RETRY FROM WAVE %d", [cleared + 1]), true, _on_retry_wave)
		_add_button(wave_row, Loc.t("RETRY SECTOR"), false, _on_retry)

		var nav_row := HBoxContainer.new()
		nav_row.add_theme_constant_override("separation", 8)
		box.add_child(nav_row)
		_add_button(nav_row, Loc.t("SECTOR SELECT"), false, _on_level_select)
		_add_button(nav_row, Loc.t("MAIN MENU"), false, _on_menu)
	else:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)
		_add_button(row, Loc.t("RETRY SECTOR"), true, _on_retry)
		_add_button(row, Loc.t("SECTOR SELECT"), false, _on_level_select)
		_add_button(row, Loc.t("MAIN MENU"), false, _on_menu)
	AudioManager.play_sound("defeat", 0.75, 1.0)


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


func _checkpoint_wave() -> int:
	## Waves already cleared in the stored checkpoint for this sector, or 0 when
	## the player fell before completing a single wave.
	var snapshot: Dictionary = GameState.wave_checkpoint
	if snapshot.is_empty():
		return 0
	if int(snapshot.get("level_index", -1)) != int(GameState.current_level_index):
		return 0
	return maxi(0, int(snapshot.get("waves_cleared", 0)))


func _on_retry_wave() -> void:
	get_tree().paused = false
	if not GameState.resume_wave_checkpoint():
		GameState.restart_level()


func _on_retry() -> void:
	get_tree().paused = false
	GameState.restart_level()


func _on_level_select() -> void:
	GameState.goto_level_select()


func _on_menu() -> void:
	GameState.goto_main_menu()
