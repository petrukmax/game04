extends CanvasLayer
## Battle HUD: tactical bar, shop, tower inspector, abilities, banners and tooltips.

var level: LevelBase
var tower_shop: Control
var tower_panel: Control
var ability_bar: Control
var wave_banner: Control
var tooltip: Control

var _root: Control
var _credits_label: Label
var _wave_label: Label
var _preview_label: Label
var _speed_buttons: Array[Button] = []
var _notification_box: VBoxContainer
var _refresh_timer: float = 0.0
var _last_preview: String = ""


func _ready() -> void:
	layer = 1


func setup(owner_level: LevelBase) -> void:
	level = owner_level
	_build()


func _build() -> void:
	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_top_bar()
	_build_notifications()
	_build_wave_banner()
	_build_bottom_bar()
	_build_tower_panel()
	_build_tooltip()
	_connect_signals()
	_refresh_header()
	_refresh_shop(level.economy.credits)


func _build_top_bar() -> void:
	var top := PanelContainer.new()
	top.name = "TopBar"
	var top_style := UIStyle.panel_box(UIStyle.BG_DEEP, Color(0.42, 0.32, 0.17), 1, 2)
	top_style.content_margin_left = 4
	top_style.content_margin_right = 4
	top_style.content_margin_top = 2
	top_style.content_margin_bottom = 2
	top.add_theme_stylebox_override("panel", top_style)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 6
	top.offset_bottom = 74
	_root.add_child(top)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_bottom", 1)
	top.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	var identity := VBoxContainer.new()
	identity.add_theme_constant_override("separation", 0)
	identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(identity)
	identity.add_child(UIStyle.make_label(Loc.t("MARS ARACHNID DEFENSE"), 8, UIStyle.MUTED))
	identity.add_child(UIStyle.make_label(_sector_title(), 17, UIStyle.AMBER))

	row.add_child(UIStyle.separator(false))

	var credits_box := VBoxContainer.new()
	credits_box.add_theme_constant_override("separation", 0)
	credits_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(credits_box)
	credits_box.add_child(UIStyle.make_label(Loc.t("CREDITS"), 8, UIStyle.MUTED))
	_credits_label = UIStyle.make_label("0", 18, UIStyle.AMBER)
	credits_box.add_child(_credits_label)

	var wave_box := VBoxContainer.new()
	wave_box.add_theme_constant_override("separation", 0)
	wave_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(wave_box)
	wave_box.add_child(UIStyle.make_label(Loc.t("WAVE"), 8, UIStyle.MUTED))
	_wave_label = UIStyle.make_label("0 / 0", 16, UIStyle.OFFWHITE)
	wave_box.add_child(_wave_label)

	row.add_child(UIStyle.separator(false))

	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 0)
	preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(preview_box)
	preview_box.add_child(UIStyle.make_label(Loc.t("NEXT WAVE — SPACE TO CALL EARLY"), 8, UIStyle.MUTED))
	_preview_label = UIStyle.make_label(Loc.t("Preparing first contact"), 17, UIStyle.OFFWHITE)
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_label.max_lines_visible = 2
	preview_box.add_child(_preview_label)

	var send := UIStyle.make_button(Loc.t("SEND WAVE"), true, true)
	send.name = "SendWaveButton"
	send.custom_minimum_size = Vector2(112, 34)
	send.tooltip_text = Loc.t("Call the next wave early for a credit bonus (Space).")
	send.pressed.connect(_on_send_pressed)
	row.add_child(send)

	for speed in [1, 2, 3]:
		var button := UIStyle.make_button("%dx" % speed, false, true)
		button.custom_minimum_size = Vector2(34, 34)
		button.tooltip_text = Loc.tf("Set simulation speed to %dx (F%d).", [speed, speed])
		button.pressed.connect(_on_speed_pressed.bind(speed))
		row.add_child(button)
		_speed_buttons.append(button)

	var pause := UIStyle.make_button("II", false, true)
	pause.custom_minimum_size = Vector2(36, 34)
	pause.tooltip_text = Loc.t("Pause simulation (Esc).")
	pause.pressed.connect(_on_pause_pressed)
	row.add_child(pause)


func _build_notifications() -> void:
	_notification_box = VBoxContainer.new()
	_notification_box.name = "Notifications"
	_notification_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_notification_box.offset_left = 330
	_notification_box.offset_right = -330
	_notification_box.offset_top = 88
	_notification_box.offset_bottom = 286
	_notification_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_notification_box.add_theme_constant_override("separation", 3)
	_notification_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_notification_box)


func _build_wave_banner() -> void:
	var scene: PackedScene = load("res://scenes/ui/WaveBanner.tscn")
	wave_banner = scene.instantiate()
	_root.add_child(wave_banner)


func _build_bottom_bar() -> void:
	var bottom := PanelContainer.new()
	bottom.name = "BottomBar"
	var bottom_style := UIStyle.panel_box(UIStyle.BG_DEEP, Color(0.42, 0.32, 0.17), 1, 2)
	bottom_style.content_margin_left = 4
	bottom_style.content_margin_right = 4
	bottom_style.content_margin_top = 2
	bottom_style.content_margin_bottom = 2
	bottom.add_theme_stylebox_override("panel", bottom_style)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 8
	bottom.offset_right = -8
	bottom.offset_top = -114
	bottom.offset_bottom = -8
	_root.add_child(bottom)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_bottom", 1)
	bottom.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)

	# Abilities are temporarily disabled by user request. The manager, data and
	# scene are kept intact, so the bar can be restored by reinstating this block
	# and the Q/W/E/R/T bindings in LevelBase.
	# ability_bar = load("res://scenes/ui/AbilityBar.tscn").instantiate()
	# ability_bar.custom_minimum_size = Vector2(430, 0)
	# row.add_child(ability_bar)
	# ability_bar.call("setup", self, level)
	# row.add_child(UIStyle.separator(false))

	tower_shop = load("res://scenes/ui/TowerShop.tscn").instantiate()
	tower_shop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tower_shop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(tower_shop)
	tower_shop.call("setup", self, level)


func _build_tower_panel() -> void:
	tower_panel = load("res://scenes/ui/TowerPanel.tscn").instantiate()
	tower_panel.name = "TowerPanel"
	_root.add_child(tower_panel)
	tower_panel.position = Vector2(1206, 300)
	tower_panel.call("setup", level)


func _build_tooltip() -> void:
	tooltip = load("res://scenes/ui/Tooltip.tscn").instantiate()
	_root.add_child(tooltip)


func _connect_signals() -> void:
	EventBus.credits_changed.connect(_on_credits_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.speed_changed.connect(_on_speed_changed)
	EventBus.tower_selected.connect(_on_tower_selected)
	EventBus.selection_cleared.connect(_on_selection_cleared)
	EventBus.tower_upgraded.connect(_on_tower_changed)
	EventBus.tower_sold.connect(_on_tower_sold)
	EventBus.notification.connect(_on_notification)
	EventBus.boss_phase.connect(_on_boss_phase)
	EventBus.tower_disabled.connect(_on_tower_disabled)


func _process(delta: float) -> void:
	if level == null or not is_instance_valid(level):
		return
	_refresh_timer -= delta
	if _refresh_timer > 0.0:
		return
	_refresh_timer = 0.2
	_refresh_header()
	if tower_panel.visible:
		tower_panel.call("refresh")


## Sector number leads the name, e.g. "С12-ШТОРМОВАЯ ЛИНИЯ", so the top bar does
## not need a second "SECTOR 12 · VERY HARD" line any more. The "С" prefix marks
## the number as a sector id (С1, С2, С3 ...).
func _sector_title() -> String:
	var data := level.level_data
	return Loc.tf("С%d-%s", [data.level_number, Loc.t(data.display_name).to_upper()])


func _refresh_header() -> void:
	if level == null or level.economy == null:
		return
	_credits_label.text = "$%d" % level.economy.credits
	if level.waves != null:
		_wave_label.text = "%d / %d" % [level.waves.current_number(), level.waves.total_waves]
		var preview := level.waves.next_preview()
		if preview != _last_preview:
			_last_preview = preview
			_preview_label.text = preview
	for index in _speed_buttons.size():
		var active := level.game_speed == index + 1
		_speed_buttons[index].add_theme_color_override("font_color", UIStyle.AMBER if active else UIStyle.OFFWHITE)


func _refresh_shop(credits: int) -> void:
	if tower_shop != null and is_instance_valid(tower_shop) and tower_shop.has_method("refresh"):
		tower_shop.call("refresh", credits)


func show_tooltip(text: String, global_pos: Vector2) -> void:
	if tooltip != null and is_instance_valid(tooltip):
		tooltip.call("show_text", text, global_pos)


func hide_tooltip() -> void:
	if tooltip != null and is_instance_valid(tooltip):
		tooltip.call("hide_tip")


func _on_credits_changed(credits: int) -> void:
	if _credits_label:
		_credits_label.text = "$%d" % credits
	_refresh_shop(credits)


func _on_wave_started(index: int, total: int, preview: String) -> void:
	_wave_label.text = "%d / %d" % [index, total]
	_preview_label.text = preview
	if wave_banner:
		wave_banner.call("show_wave", index, total, preview)


func _on_wave_completed(_index: int, bonus: int) -> void:
	if wave_banner:
		wave_banner.call("show_message", Loc.t("WAVE CLEARED"), Loc.tf("+%d CREDITS", [bonus]), UIStyle.GREEN)


func _on_speed_changed(_speed: int) -> void:
	_refresh_header()


func _on_tower_selected(tower: Node) -> void:
	if tower_panel and tower != null:
		tower_panel.call("show_tower", tower)
		AudioManager.play_ui("ui_click")


func _on_selection_cleared() -> void:
	if tower_panel:
		tower_panel.call("clear")


func _on_tower_changed(tower: Node) -> void:
	if tower_panel and tower_panel.visible:
		tower_panel.call("refresh")


func _on_tower_sold(_tower: Node) -> void:
	if tower_panel:
		tower_panel.call("clear")


func _on_notification(text: String, color: Color) -> void:
	if _notification_box == null or not is_instance_valid(_notification_box):
		return
	while _notification_box.get_child_count() >= 6:
		var oldest := _notification_box.get_child(0)
		_notification_box.remove_child(oldest)
		oldest.queue_free()
	var label := UIStyle.make_label(text, 12, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	_notification_box.add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.16)
	tween.tween_interval(2.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)


func _on_boss_phase(text: String) -> void:
	if wave_banner:
		wave_banner.call("show_message", Loc.t("BROOD TYRANT"), Loc.t(text), UIStyle.RED)


func _on_tower_disabled(tower: Node, _duration: float) -> void:
	if tower != null and is_instance_valid(tower):
		EventBus.notification.emit(Loc.t("Tower disabled by corrosive acid!"), Color(0.55, 1.0, 0.3))


func _on_send_pressed() -> void:
	if level:
		level.request_next_wave()


func _on_speed_pressed(speed: int) -> void:
	if level:
		level.set_game_speed(speed)
		AudioManager.play_ui("ui_click")


func _on_pause_pressed() -> void:
	if level:
		level.toggle_pause()
		AudioManager.play_ui("ui_click")
