extends VBoxContainer
## Ten-card tower shop, animated affordability and build-mode highlighting.

var hud: CanvasLayer
var level: LevelBase
var cards: Dictionary = {}
var selected_id: String = ""


func setup(owner_hud: CanvasLayer, owner_level: LevelBase) -> void:
	hud = owner_hud
	level = owner_level
	add_theme_constant_override("separation", 4)
	for child in get_children():
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var title := UIStyle.make_label("DEFENCE GRID / TOWER SHOP", 12, UIStyle.AMBER)
	header.add_child(title)
	var hint := UIStyle.make_label("1–0 select · click a buildable cell · right-click cancel", 10, UIStyle.MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hint)
	add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	var card_scene: PackedScene = load("res://scenes/ui/TowerCard.tscn")
	for data in level.get_all_tower_data():
		var card = card_scene.instantiate()
		row.add_child(card)
		card.call("setup", data, hud, level)
		cards[data.id] = card
	EventBus.build_mode_changed.connect(_on_build_mode_changed)
	EventBus.credits_changed.connect(_on_credits_changed)
	_on_credits_changed(level.economy.credits)


func refresh(credits: int) -> void:
	_on_credits_changed(credits)


func _on_credits_changed(credits: int) -> void:
	for card in cards.values():
		if is_instance_valid(card):
			card.call("refresh", credits)


func _on_build_mode_changed(tower_id: String) -> void:
	selected_id = tower_id
	for id in cards.keys():
		var card = cards[id]
		if is_instance_valid(card):
			card.call("set_selected", id == tower_id)
