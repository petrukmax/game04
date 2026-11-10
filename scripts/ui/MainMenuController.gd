extends Control
## Main menu: campaign entry, level select, settings, help and quit.

var _settings: CanvasLayer
var _help: CanvasLayer
var _new_campaign_dialog: ConfirmationDialog
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := Control.new()
	backdrop.set_script(load("res://scripts/ui/MenuBackdrop.gd"))
	add_child(backdrop)
	move_child(backdrop, 0)
	_build()
	AudioManager.start_ambience()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.015, 0.02, 0.35)
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.custom_minimum_size = Vector2(760, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var header := VBoxContainer.new()
	header.position = Vector2(96, 104)
	header.custom_minimum_size = Vector2(620, 0)
	header.add_theme_constant_override("separation", 0)
	add_child(header)
	header.add_child(UIStyle.make_label("FIRST BASTION COMMAND", 13, UIStyle.AMBER))
	var title := UIStyle.make_label("MARS\nARACHNID\nDEFENSE", 52, UIStyle.OFFWHITE)
	title.add_theme_color_override("font_shadow_color", Color(0.25, 0.06, 0.02, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_constant_override("line_spacing", -8)
	header.add_child(title)
	var subtitle := UIStyle.make_label("Hold the first human outpost against the Martian brood.", 14, UIStyle.MUTED)
	header.add_child(subtitle)

	var menu := VBoxContainer.new()
	menu.position = Vector2(96, 424)
	menu.custom_minimum_size = Vector2(380, 0)
	menu.add_theme_constant_override("separation", 6)
	add_child(menu)

	var continue_text := "START CAMPAIGN"
	if GameState.campaign_started:
		continue_text = "CONTINUE — SECTOR %02d" % GameState.unlocked_level
	menu.add_child(_menu_button(continue_text, true, _on_continue))
	menu.add_child(_menu_button("NEW CAMPAIGN", false, _on_new_campaign))
	menu.add_child(_menu_button("SECTOR SELECT", false, _on_level_select))
	menu.add_child(_menu_button("SETTINGS", false, _on_settings))
	menu.add_child(_menu_button("FIELD MANUAL", false, _on_help))
	if OS.has_feature("web"):
		menu.add_child(_menu_button("RELOAD GAME", false, _on_reload_game))
	else:
		menu.add_child(_menu_button("QUIT TO DESKTOP", false, _on_quit))

	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.04, 0.04, 0.05, 0.8), Color(0.4, 0.3, 0.17), 1, 3))
	info.position = Vector2(1118, 300)
	info.custom_minimum_size = Vector2(384, 0)
	add_child(info)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	info.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)
	box.add_child(UIStyle.make_label("CAMPAIGN RECORD", 11, UIStyle.AMBER))
	box.add_child(UIStyle.separator(true))
	var stars := 0
	for key in GameState.best_stars.keys():
		stars += int(GameState.best_stars[key])
	box.add_child(_stat_line("Sectors unlocked", "%d / 15" % GameState.unlocked_level))
	box.add_child(_stat_line("Sectors completed", "%d / 15" % GameState.total_levels))
	box.add_child(_stat_line("Stars earned", "%d / 45" % stars))
	box.add_child(_stat_line("Arachnids killed", str(GameState.total_kills)))
	box.add_child(_stat_line("Credits earned", "$%d" % GameState.total_credits))
	box.add_child(UIStyle.separator(true))
	_status_label = UIStyle.make_label("", 10, UIStyle.MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)
	_refresh_status()

	var footer := UIStyle.make_label("GODOT 4 · LOCAL SAVE · PROCEDURAL ART AND AUDIO · NO ONLINE SERVICES",
		9, Color(0.5, 0.5, 0.46))
	footer.position = Vector2(96, 848)
	add_child(footer)

	_settings = load("res://scenes/ui/SettingsPanel.tscn").instantiate()
	add_child(_settings)
	_help = load("res://scenes/ui/HelpPanel.tscn").instantiate()
	add_child(_help)

	_new_campaign_dialog = ConfirmationDialog.new()
	_new_campaign_dialog.title = "New campaign"
	_new_campaign_dialog.dialog_text = "Start a new campaign and reset all unlocks, stars and totals?"
	_new_campaign_dialog.ok_button_text = "START NEW"
	_new_campaign_dialog.cancel_button_text = "CANCEL"
	_new_campaign_dialog.confirmed.connect(_on_new_campaign_confirmed)
	add_child(_new_campaign_dialog)


func _menu_button(text: String, accent: bool, handler: Callable) -> Button:
	var button := UIStyle.make_button(text, accent)
	button.custom_minimum_size = Vector2(380, 46)
	button.add_theme_font_size_override("font_size", 15)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func():
		AudioManager.play_ui("ui_confirm")
		handler.call()
	)
	button.mouse_entered.connect(func(): AudioManager.play_ui("ui_hover"))
	return button


func _stat_line(caption: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var left := UIStyle.make_label(caption, 12, UIStyle.MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UIStyle.make_label(value, 13, UIStyle.OFFWHITE))
	return row


func _refresh_status() -> void:
	if _status_label == null:
		return
	if GameState.campaign_started:
		_status_label.text = "Highest unlocked sector: %02d — %s" % [
			GameState.unlocked_level, GameState.level_title(GameState.unlocked_level - 1)]
	else:
		_status_label.text = "No campaign started. The brood is waiting."


func _on_continue() -> void:
	if GameState.campaign_started:
		GameState.start_level(GameState.unlocked_level - 1)
	else:
		GameState.start_level(0)


func _on_new_campaign() -> void:
	if GameState.campaign_started or GameState.total_levels > 0:
		_new_campaign_dialog.popup_centered()
	else:
		_on_new_campaign_confirmed()


func _on_new_campaign_confirmed() -> void:
	GameState.reset_campaign()
	GameState.start_level(0)


func _on_level_select() -> void:
	GameState.goto_level_select()


func _on_settings() -> void:
	if _settings:
		_settings.call("open")


func _on_help() -> void:
	if _help:
		_help.call("open")


func _on_quit() -> void:
	get_tree().quit()


func _on_reload_game() -> void:
	# A browser tab cannot quit itself; reloading the page returns to a clean menu.
	var js := Engine.get_singleton("JavaScriptBridge")
	if js != null:
		js.eval("window.location.reload()")
	else:
		GameState.goto_main_menu()
