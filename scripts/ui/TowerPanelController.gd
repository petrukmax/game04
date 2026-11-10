extends PanelContainer
## Selected-tower inspection: stats, upgrade preview, sell and targeting.

var level: LevelBase
var tower: Node

var _name_label: Label
var _level_label: Label
var _role_label: Label
var _stats_label: Label
var _next_label: Label
var _upgrade_button: Button
var _sell_button: Button
var _targeting: OptionButton
var _range_label: Label
var _priority_ids: Array[String] = ["first", "last", "strongest", "weakest", "closest", "highest_health", "flying_first"]


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(326, 380)
	add_theme_stylebox_override("panel", UIStyle.panel_box(UIStyle.BG_DEEP, Color(0.44, 0.34, 0.18), 1, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var top := HBoxContainer.new()
	vbox.add_child(top)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_box)
	_name_label = UIStyle.make_label("Tower", 17, UIStyle.AMBER)
	title_box.add_child(_name_label)
	_level_label = UIStyle.make_label("Mk 1 / 4", 11, UIStyle.MUTED)
	title_box.add_child(_level_label)
	var close := UIStyle.make_button("X", false, true)
	close.custom_minimum_size = Vector2(30, 28)
	close.pressed.connect(_on_close)
	top.add_child(close)

	_role_label = UIStyle.make_label("Role", 11, UIStyle.OFFWHITE)
	vbox.add_child(_role_label)
	vbox.add_child(UIStyle.separator(true))
	_stats_label = UIStyle.make_label("", 12, UIStyle.OFFWHITE)
	_stats_label.add_theme_constant_override("line_spacing", 1)
	vbox.add_child(_stats_label)
	vbox.add_child(UIStyle.separator(true))
	_next_label = UIStyle.make_label("", 11, UIStyle.MUTED)
	_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_next_label)

	var upgrade_row := HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation", 6)
	vbox.add_child(upgrade_row)
	_upgrade_button = UIStyle.make_button("UPGRADE", true, true)
	_upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_button.custom_minimum_size = Vector2(0, 36)
	_upgrade_button.pressed.connect(_on_upgrade)
	upgrade_row.add_child(_upgrade_button)
	_sell_button = UIStyle.make_button("SELL", false, true)
	_sell_button.custom_minimum_size = Vector2(92, 36)
	_sell_button.pressed.connect(_on_sell)
	upgrade_row.add_child(_sell_button)

	var target_row := HBoxContainer.new()
	target_row.add_theme_constant_override("separation", 6)
	vbox.add_child(target_row)
	target_row.add_child(UIStyle.make_label("TARGET", 10, UIStyle.MUTED))
	_targeting = OptionButton.new()
	_targeting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_targeting.add_theme_font_size_override("font_size", 11)
	_targeting.add_theme_color_override("font_color", UIStyle.OFFWHITE)
	_targeting.add_theme_stylebox_override("normal", UIStyle.panel_box(UIStyle.BG_RAISED, Color(0.35, 0.31, 0.24), 1, 2))
	_targeting.add_theme_stylebox_override("hover", UIStyle.panel_box(Color(0.18, 0.18, 0.19), UIStyle.AMBER, 1, 2))
	_targeting.add_item("First", 0)
	_targeting.add_item("Last", 1)
	_targeting.add_item("Strongest", 2)
	_targeting.add_item("Weakest", 3)
	_targeting.add_item("Closest", 4)
	_targeting.add_item("Highest HP", 5)
	_targeting.add_item("Flying first", 6)
	_targeting.item_selected.connect(_on_targeting_changed)
	target_row.add_child(_targeting)
	_range_label = UIStyle.make_label("Range ring is shown while this tower is selected.", 10, UIStyle.MUTED)
	vbox.add_child(_range_label)


func setup(owner_level: LevelBase) -> void:
	level = owner_level


func show_tower(tower_node: Node) -> void:
	tower = tower_node
	visible = true
	refresh()


func clear() -> void:
	tower = null
	visible = false


func refresh() -> void:
	if tower == null or not is_instance_valid(tower):
		clear()
		return
	var stats: Dictionary = tower.stats
	_name_label.text = tower.tower_data.display_name
	_level_label.text = "Mk %d / %d · %s" % [tower.current_level, tower.tower_data.max_level, tower.tower_data.role]
	_role_label.text = "Damage type: %s" % tower.tower_data.damage_type.to_upper()
	var lines := PackedStringArray()
	if float(stats.get("damage", 0.0)) > 0.0:
		lines.append("Damage        %s" % _num(stats.damage))
	if float(stats.get("attack_rate", 0.0)) > 0.0:
		var dps := float(stats.damage) * float(stats.attack_rate)
		lines.append("Fire rate     %.2f /s   (%.0f DPS)" % [float(stats.attack_rate), dps])
	if float(stats.get("attack_range", 0.0)) > 0.0:
		lines.append("Range         %d" % int(stats.attack_range))
	if float(stats.get("splash_radius", 0.0)) > 0.0:
		lines.append("Splash        %d" % int(stats.splash_radius))
	if float(stats.get("slow_amount", 0.0)) > 0.0:
		lines.append("Slow          %d%% for %.1fs" % [int(float(stats.slow_amount) * 100.0), float(stats.slow_duration)])
	if float(stats.get("armor_penetration", 0.0)) > 0.0:
		lines.append("Armour pen.   %d%%" % int(float(stats.armor_penetration) * 100.0))
	if int(stats.get("chain_count", 0)) > 0:
		lines.append("Chain targets %d" % (int(stats.chain_count) + 1))
	if float(stats.get("burn_dps", 0.0)) > 0.0:
		lines.append("Burn          %.0f /s for %.1fs" % [float(stats.burn_dps), float(stats.burn_duration) + float(tower._flame_bonus_duration())])
	if int(stats.get("missiles", 1)) > 1:
		lines.append("Missiles      %d per salvo" % int(stats.missiles))
	if float(stats.get("support_radius", 0.0)) > 0.0:
		lines.append("Command aura  %d radius" % int(stats.support_radius))
		lines.append("Tower buff    +%d%%" % int(float(stats.support_buff) * 100.0))
	if int(stats.get("income_per_wave", 0)) > 0:
		lines.append("Stipend       +%d / wave" % int(stats.income_per_wave))
	if float(stats.get("deploy_interval", 0.0)) > 0.0:
		lines.append("Mine reload   %.1fs · %d blast" % [float(stats.deploy_interval), int(stats.mine_damage)])
	lines.append("Targets air   %s" % ("YES" if GameConfig.as_bool(stats.get("anti_air", false)) else "NO"))
	_stats_label.text = "\n".join(lines)

	var next: UpgradeData = tower.next_upgrade()
	if next == null:
		_next_label.text = "Maximum upgrade level reached. This tower is fully upgraded."
		_upgrade_button.text = "MAX LEVEL"
		_upgrade_button.disabled = true
	else:
		_next_label.text = "NEXT — %s ($%d)\n%s" % [next.display_name, next.cost, next.description]
		_upgrade_button.text = "UPGRADE  $%d" % next.cost
		_upgrade_button.disabled = not tower.can_upgrade()
		_upgrade_button.tooltip_text = "Not enough credits." if not tower.can_upgrade() else next.description
	_sell_button.text = "SELL  +$%d" % tower.sell_value()
	_sell_button.tooltip_text = "Refund %d%% of invested credits." % int(tower.tower_data.sell_ratio * 100.0)
	var index := _priority_ids.find(tower.targeting_priority)
	_targeting.selected = maxi(0, index)
	_range_label.text = "Range %d · invested $%d · select target priority for this tower." % [int(stats.get("attack_range", 0.0)), int(tower.invested)]


func _on_upgrade() -> void:
	if tower != null and is_instance_valid(tower):
		level.upgrade_selected()


func _on_sell() -> void:
	if tower != null and is_instance_valid(tower):
		level.sell_selected()


func _on_close() -> void:
	if level:
		level.clear_selection()


func _on_targeting_changed(index: int) -> void:
	if tower == null or not is_instance_valid(tower) or index < 0 or index >= _priority_ids.size():
		return
	level.set_targeting_priority(_priority_ids[index], tower)
	AudioManager.play_ui("ui_click")


func _num(value: float) -> String:
	if absf(value - roundf(value)) < 0.01:
		return str(int(roundf(value)))
	return "%.1f" % value
