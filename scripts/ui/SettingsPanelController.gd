extends CanvasLayer
## Settings overlay shared by the main menu, level select and pause menu.

var _master: HSlider
var _sfx: HSlider
var _music: HSlider
var _muted: CheckButton
var _shake: CheckButton
var _colorblind: CheckButton
var _master_value: Label
var _sfx_value: Label
var _music_value: Label
var _syncing: bool = false
var _confirm_reset: ConfirmationDialog


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.015, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(UIStyle.BG_PANEL, Color(0.55, 0.4, 0.2), 1, 4))
	panel.custom_minimum_size = Vector2(520, 0)
	panel.position = Vector2(540, 176)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(UIStyle.make_label("SETTINGS", 24, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER))
	var note := UIStyle.make_label("Audio is generated locally. Volumes apply immediately and are saved on change.",
		10, UIStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)
	box.add_child(UIStyle.separator(true))

	_master = _add_slider(box, "Master volume", "master_volume", "_master_value")
	_sfx = _add_slider(box, "Effects volume", "sfx_volume", "_sfx_value")
	_music = _add_slider(box, "Ambience volume", "music_volume", "_music_value")

	_muted = _add_check(box, "Mute all audio", "muted")
	_shake = _add_check(box, "Screen shake", "screen_shake")
	_colorblind = _add_check(box, "High-contrast status markers", "colorblind")

	box.add_child(UIStyle.separator(true))
	var reset := UIStyle.make_button("RESET CAMPAIGN PROGRESS", false, true)
	reset.pressed.connect(_on_reset_pressed)
	box.add_child(reset)

	var close := UIStyle.make_button("CLOSE", true)
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(close_panel)
	box.add_child(close)

	_confirm_reset = ConfirmationDialog.new()
	_confirm_reset.title = "Reset campaign"
	_confirm_reset.dialog_text = "Reset all unlocks, stars and campaign totals?\nThis cannot be undone."
	_confirm_reset.ok_button_text = "RESET"
	_confirm_reset.cancel_button_text = "CANCEL"
	_confirm_reset.confirmed.connect(_on_reset_confirmed)
	add_child(_confirm_reset)

	_load_values()


func _add_slider(parent: VBoxContainer, caption: String, key: String, value_label_name: String) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := UIStyle.make_label(caption, 12, UIStyle.OFFWHITE)
	label.custom_minimum_size = Vector2(180, 0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 26)
	slider.value_changed.connect(_on_slider_changed.bind(key))
	row.add_child(slider)
	var value := UIStyle.make_label("100%", 12, UIStyle.AMBER)
	value.custom_minimum_size = Vector2(48, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	set(value_label_name, value)
	return slider


func _add_check(parent: VBoxContainer, caption: String, key: String) -> CheckButton:
	var check := CheckButton.new()
	check.text = caption
	check.add_theme_font_size_override("font_size", 12)
	check.add_theme_color_override("font_color", UIStyle.OFFWHITE)
	check.add_theme_color_override("font_pressed_color", UIStyle.AMBER)
	check.toggled.connect(_on_check_toggled.bind(key))
	parent.add_child(check)
	return check


func open() -> void:
	visible = true
	_load_values()
	AudioManager.play_ui("ui_click")


func close() -> void:
	visible = false


func close_panel() -> void:
	visible = false
	AudioManager.play_ui("ui_cancel")


func _load_values() -> void:
	if _master == null:
		return
	_syncing = true
	_master.value = float(GameState.settings.get("master_volume", 0.8)) * 100.0
	_sfx.value = float(GameState.settings.get("sfx_volume", 0.85)) * 100.0
	_music.value = float(GameState.settings.get("music_volume", 0.5)) * 100.0
	_muted.button_pressed = GameConfig.as_bool(GameState.settings.get("muted", false))
	_shake.button_pressed = GameConfig.as_bool(GameState.settings.get("screen_shake", true))
	_colorblind.button_pressed = GameConfig.as_bool(GameState.settings.get("colorblind", false))
	_syncing = false
	_update_value_labels()


func _on_slider_changed(value: float, key: String) -> void:
	if _syncing:
		return
	GameState.update_setting(key, value / 100.0)
	_update_value_labels()


func _on_check_toggled(pressed: bool, key: String) -> void:
	if _syncing:
		return
	GameState.update_setting(key, pressed)
	if key == "muted":
		AudioManager.set_muted(pressed)


func _update_value_labels() -> void:
	if _master_value:
		_master_value.text = "%d%%" % int(roundf(_master.value))
	if _sfx_value:
		_sfx_value.text = "%d%%" % int(roundf(_sfx.value))
	if _music_value:
		_music_value.text = "%d%%" % int(roundf(_music.value))


func _on_reset_pressed() -> void:
	AudioManager.play_ui("ui_click")
	if _confirm_reset:
		_confirm_reset.popup_centered()


func _on_reset_confirmed() -> void:
	GameState.reset_campaign()
	EventBus.notification.emit("Campaign progress reset.", UIStyle.AMBER)
	AudioManager.play_ui("ui_confirm")
