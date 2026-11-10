extends Button
## One ability button with hotkey, charges, cooldown mask and tooltip.

var hud: CanvasLayer
var level: LevelBase
var ability_id: String = ""

var _ability: AbilityData
var _hotkey_label: Label
var _name_label: Label
var _uses_label: Label
var _cooldown_label: Label
var _mask: ColorRect


func _ready() -> void:
	custom_minimum_size = Vector2(80, 96)
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UIStyle.style_button(self, false, true)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	_hotkey_label = UIStyle.make_label("[Q]", 10, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_hotkey_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hotkey_label)
	_name_label = UIStyle.make_label("Ability", 9, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(0, 32)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_name_label)
	_uses_label = UIStyle.make_label("", 10, UIStyle.AMBER, HORIZONTAL_ALIGNMENT_CENTER)
	_uses_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_uses_label)

	_mask = ColorRect.new()
	_mask.color = Color(0.02, 0.02, 0.03, 0.68)
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mask.visible = false
	add_child(_mask)
	_cooldown_label = UIStyle.make_label("", 14, UIStyle.OFFWHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cooldown_label)

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func setup(owner_hud: CanvasLayer, owner_level: LevelBase, id: String) -> void:
	hud = owner_hud
	level = owner_level
	ability_id = id
	_ability = level.abilities.get_ability(id)
	if _ability == null:
		visible = false
		return
	_hotkey_label.text = "[%s]" % _ability.shortcut
	_name_label.text = _ability.display_name.replace(" ", "\n")
	refresh()


func refresh() -> void:
	if level == null or _ability == null:
		return
	var manager := level.abilities
	var usable := manager.is_unlocked(ability_id) and manager.uses_remaining(ability_id) != 0
	disabled = not manager.can_use(ability_id)
	modulate = Color(1.0, 1.0, 1.0) if usable else Color(0.55, 0.55, 0.52)
	var uses := manager.uses_remaining(ability_id)
	if not manager.is_unlocked(ability_id):
		_uses_label.text = "LOCKED"
	elif uses < 0:
		_uses_label.text = "∞"
	else:
		_uses_label.text = "%d LEFT" % uses
	var left := manager.cooldown_left(ability_id)
	if left > 0.05:
		_cooldown_label.text = "%ds" % int(ceilf(left))
		_cooldown_label.visible = true
	else:
		_cooldown_label.visible = false
	var ratio := manager.cooldown_ratio(ability_id)
	_mask.visible = ratio > 0.001
	if _mask.visible:
		_mask.position = Vector2(0, size.y * (1.0 - ratio))
		_mask.size = Vector2(size.x, size.y * ratio)


func _process(_delta: float) -> void:
	if visible and level != null:
		refresh()


func _on_pressed() -> void:
	if level == null:
		return
	hide_tooltip()
	level.begin_ability(ability_id)


func _on_hover() -> void:
	if _ability == null or hud == null or not hud.has_method("show_tooltip"):
		return
	var uses := level.abilities.uses_remaining(ability_id)
	var charges := "Unlimited" if uses < 0 else "%d remaining" % uses
	var text := "%s  [%s]\n%s\nCooldown %.0fs · %s\nRadius %d%s" % [
		_ability.display_name, _ability.shortcut, _ability.description,
		_ability.cooldown, charges, int(_ability.radius),
		"" if _ability.target_mode != "self" else " · self-targeted",
	]
	if not level.abilities.is_unlocked(ability_id):
		text += "\nNot unlocked in this sector."
	hud.call("show_tooltip", text, get_global_rect().position + Vector2(0, -8))


func _on_unhover() -> void:
	hide_tooltip()


func hide_tooltip() -> void:
	if hud != null and hud.has_method("hide_tooltip"):
		hud.call("hide_tooltip")
