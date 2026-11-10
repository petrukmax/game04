extends Control
## Sector select: campaign cards, locks, stars and briefing text.

const COLUMNS := 5
const CARD_SIZE := Vector2(286, 146)

var _detail_title: Label
var _detail_body: Label
var _settings: CanvasLayer
var _help: CanvasLayer
var _cards: Array[Button] = []


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
	shade.color = Color(0.012, 0.012, 0.018, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var header := HBoxContainer.new()
	header.position = Vector2(56, 28)
	header.custom_minimum_size = Vector2(1488, 0)
	header.add_theme_constant_override("separation", 12)
	add_child(header)
	var back := UIStyle.make_button("‹ MAIN MENU", false, true)
	back.custom_minimum_size = Vector2(140, 42)
	back.pressed.connect(func():
		AudioManager.play_ui("ui_cancel")
		GameState.goto_main_menu()
	)
	header.add_child(back)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	header.add_child(title_box)
	title_box.add_child(UIStyle.make_label("SECTOR SELECT", 26, UIStyle.AMBER))
	title_box.add_child(UIStyle.make_label("Choose a battlefield. Sectors unlock in order as the campaign advances.",
		11, UIStyle.MUTED))
	var stars := 0
	for key in GameState.best_stars.keys():
		stars += int(GameState.best_stars[key])
	header.add_child(UIStyle.make_label("STARS %d / 45" % stars, 15, UIStyle.OFFWHITE))
	var settings := UIStyle.make_button("SETTINGS", false, true)
	settings.custom_minimum_size = Vector2(110, 42)
	settings.pressed.connect(_on_settings)
	header.add_child(settings)
	var help := UIStyle.make_button("MANUAL", false, true)
	help.custom_minimum_size = Vector2(100, 42)
	help.pressed.connect(_on_help)
	header.add_child(help)

	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.position = Vector2(56, 120)
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	for index in 15:
		var card := _make_card(index)
		grid.add_child(card)
		_cards.append(card)

	var detail := PanelContainer.new()
	detail.add_theme_stylebox_override("panel", UIStyle.panel_box(Color(0.04, 0.04, 0.05, 0.86), Color(0.45, 0.33, 0.18), 1, 3))
	detail.position = Vector2(56, 604)
	detail.custom_minimum_size = Vector2(1488, 116)
	add_child(detail)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	detail.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)
	_detail_title = UIStyle.make_label("SELECT A SECTOR", 16, UIStyle.AMBER)
	box.add_child(_detail_title)
	_detail_body = UIStyle.make_label("Hover a sector for its briefing. Completed sectors show their best star rating.",
		11, UIStyle.OFFWHITE)
	_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_body)

	var footer := UIStyle.make_label("Progress and best stars are saved locally after every battle.",
		9, Color(0.5, 0.5, 0.46))
	footer.position = Vector2(56, 744)
	add_child(footer)

	_settings = load("res://scenes/ui/SettingsPanel.tscn").instantiate()
	add_child(_settings)
	_help = load("res://scenes/ui/HelpPanel.tscn").instantiate()
	add_child(_help)


func _make_card(index: int) -> Button:
	var data: LevelData = load(GameState.LEVEL_DATA_PATHS[index])
	var unlocked := GameState.is_level_unlocked(index)
	var stars := GameState.level_stars(index)
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.disabled = not unlocked
	UIStyle.style_button(card, false, true)
	var tint := Color(0.1, 0.12, 0.1) if data.difficulty == "Easy" else (
		Color(0.13, 0.11, 0.075) if data.difficulty == "Medium" else Color(0.15, 0.075, 0.07))
	var border := UIStyle.GREEN if data.difficulty == "Easy" else (
		UIStyle.AMBER if data.difficulty == "Medium" else UIStyle.RED)
	if not unlocked:
		card.modulate = Color(0.55, 0.55, 0.52)
		border = Color(0.28, 0.28, 0.26)
	card.add_theme_stylebox_override("normal", UIStyle.panel_box(tint, border, 1, 3))
	card.add_theme_stylebox_override("hover", UIStyle.panel_box(tint.lightened(0.05), UIStyle.AMBER, 2, 3))
	card.add_theme_stylebox_override("pressed", UIStyle.panel_box(tint.darkened(0.2), UIStyle.AMBER, 2, 3))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var number := UIStyle.make_label("%02d" % data.level_number, 24, UIStyle.AMBER)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(number)
	var name_label := UIStyle.make_label(data.display_name, 14, UIStyle.OFFWHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(name_label)
	var difficulty := UIStyle.make_label(data.difficulty.to_upper(), 9, border)
	difficulty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(difficulty)
	var star_text := "★ ★ ★" if stars >= 3 else ("★ ★ ☆" if stars == 2 else ("★ ☆ ☆" if stars == 1 else "☆ ☆ ☆"))
	var star_label := UIStyle.make_label(star_text, 16, UIStyle.AMBER if stars > 0 else UIStyle.MUTED)
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(star_label)
	var status := UIStyle.make_label("LOCKED" if not unlocked else ("CLEARED" if stars > 0 else "AVAILABLE"),
		9, UIStyle.RED if not unlocked else (UIStyle.GREEN if stars > 0 else UIStyle.MUTED))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status)

	if unlocked:
		card.pressed.connect(_on_card_pressed.bind(index))
		card.mouse_entered.connect(_on_card_hover.bind(index, data))
	return card


func _on_card_pressed(index: int) -> void:
	AudioManager.play_ui("ui_confirm")
	GameState.start_level(index)


func _on_card_hover(index: int, data: LevelData) -> void:
	if _detail_title == null:
		return
	var stars := GameState.level_stars(index)
	_detail_title.text = "%s  ·  SECTOR %02d  ·  %s  ·  %s" % [
		data.display_name.to_upper(), data.level_number, data.difficulty.to_upper(),
		("BEST %d / 3 STARS" % stars) if stars > 0 else "NOT YET CLEARED"]
	_detail_body.text = "%s\nStart: $%d · Base integrity %d · %d waves · Towers available: %d" % [
		data.description, data.starting_credits, data.base_health, data.wave_data_list.size(),
		data.available_towers.size()]
	AudioManager.play_ui("ui_hover")


func _on_settings() -> void:
	if _settings:
		_settings.call("open")


func _on_help() -> void:
	if _help:
		_help.call("open")
