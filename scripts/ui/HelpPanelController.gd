extends CanvasLayer
## In-game and main-menu help: controls, towers, enemies, abilities and tips.

var _text: RichTextLabel


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.01, 0.015, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_box(UIStyle.BG_PANEL, Color(0.55, 0.4, 0.2), 1, 4))
	panel.custom_minimum_size = Vector2(980, 676)
	panel.position = Vector2(310, 110)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := UIStyle.make_label("FIELD MANUAL", 22, UIStyle.AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := UIStyle.make_button("CLOSE", true, true)
	close.custom_minimum_size = Vector2(100, 34)
	close.pressed.connect(close_panel)
	header.add_child(close)
	box.add_child(UIStyle.separator(true))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(920, 0)
	_text.add_theme_font_size_override("normal_font_size", 12)
	_text.add_theme_font_size_override("bold_font_size", 13)
	_text.add_theme_color_override("default_color", UIStyle.OFFWHITE)
	scroll.add_child(_text)
	_text.text = _build_manual()


func open() -> void:
	visible = true
	if _text:
		_text.text = _build_manual()
	AudioManager.play_ui("ui_click")


func close_panel() -> void:
	visible = false
	AudioManager.play_ui("ui_cancel")


func _build_manual() -> String:
	var lines: Array[String] = []
	lines.append("[color=#f9a633][b]MISSION[/b][/color]")
	lines.append("Two hostile roads run left to right and cross somewhere on the map. Arachnids follow those roads toward the First Bastion on the right. Build towers on the visible square grid beside the roads and stop every wave. You lose integrity when a creature reaches the base; at zero the outpost falls.")
	lines.append("")
	lines.append("[color=#f9a633][b]CONTROLS[/b][/color]")
	lines.append("[b]Left click[/b] build / select · [b]Right click[/b] cancel · [b]1–0[/b] choose tower · [b]Space[/b] send next wave early · [b]Q W E R T[/b] abilities")
	lines.append("[b]U[/b] upgrade selected tower · [b]X[/b] or [b]Delete[/b] sell · [b]Tab[/b] cycle towers · [b]F1/F2/F3[/b] or top-bar buttons set 1x/2x/3x speed · [b]Esc[/b] pause / cancel · [b]M[/b] mute")
	lines.append("Abilities that target an area are aimed with the mouse and confirmed with a left click. The Emergency Repair ability is self-targeted.")
	lines.append("")
	lines.append("[color=#f9a633][b]TOWERS[/b][/color]")
	lines.append("[table=2]")
	for id in ["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"]:
		var path := "res://resources/towers/tower_%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: TowerData = load(path)
		lines.append("[cell][b]%s[/b] — $%d[/cell][cell]%s[/cell]" % [data.display_name, data.cost, data.role])
	lines.append("[/table]")
	lines.append("Every tower can be upgraded three times (Mk 1 to Mk 4). Selling returns 70% of the credits invested. Some towers cannot hit flying enemies until an upgrade unlocks it — check the inspector panel.")
	lines.append("")
	lines.append("[color=#f9a633][b]HOSTILES[/b][/color]")
	lines.append("[table=2]")
	for id in ["scout", "worker", "warrior", "spitter", "healer", "burrower", "shieldbearer", "flyer", "elite", "boss"]:
		var path := "res://resources/enemies/enemy_%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: EnemyData = load(path)
		lines.append("[cell][b]%s[/b][/cell][cell]%s[/cell]" % [data.display_name, data.tip])
	lines.append("[/table]")
	lines.append("Shields absorb damage and regenerate if you stop firing. Burrowers become untargetable while underground. Healers restore nearby arachnids. Spitters disable towers. Flying enemies ignore road-blocking tactics and require anti-air coverage. Elites frenzy below half health; the Brood Tyrant has three escalating phases.")
	lines.append("")
	lines.append("[color=#f9a633][b]ABILITIES[/b][/color]")
	for id in ["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"]:
		var path := "res://resources/abilities/ability_%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: AbilityData = load(path)
		var uses := "unlimited" if data.uses_per_level < 0 else "%d per level" % data.uses_per_level
		lines.append("[b]%s[/b] (%s, %.0fs cooldown, %s) — %s" % [data.display_name, data.shortcut, data.cooldown, uses, data.description])
	lines.append("")
	lines.append("[color=#f9a633][b]TACTICS[/b][/color]")
	lines.append("Build where two roads cross or run close together so one tower covers both. Command Relays buff nearby tower damage and rate — place them beside your kill zone, not on the front line. Send waves early for bonus credits when you are confident. Use EMP on shield packs, Orbital Strike on dense clusters, and save Emergency Repair for the final bosses.")
	lines.append("")
	lines.append("[color=#8d8d87]The campaign runs 15 sectors: five easy, five medium and five very hard. Stars depend on remaining base integrity (80%+ = 3 stars, 45%+ = 2 stars). Progress, best stars and settings are stored locally.[/color]")
	return "\n".join(lines)
