extends VBoxContainer
## Five ability buttons with charge and cooldown feedback.

var hud: CanvasLayer
var level: LevelBase
var buttons: Dictionary = {}


func setup(owner_hud: CanvasLayer, owner_level: LevelBase) -> void:
	hud = owner_hud
	level = owner_level
	add_theme_constant_override("separation", 4)
	for child in get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	add_child(header)
	header.add_child(UIStyle.make_label("ABILITIES", 10, UIStyle.AMBER))
	var hint := UIStyle.make_label("Q W E R T", 9, UIStyle.MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	var button_scene: PackedScene = load("res://scenes/ui/AbilityButton.tscn")
	for id in level.abilities.get_display_order():
		var button = button_scene.instantiate()
		row.add_child(button)
		button.call("setup", hud, level, id)
		buttons[id] = button


func refresh() -> void:
	for button in buttons.values():
		if is_instance_valid(button):
			button.call("refresh")
