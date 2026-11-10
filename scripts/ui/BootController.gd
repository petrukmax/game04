extends Node
## Entry point: hands control to the main menu on the first idle frame.


func _ready() -> void:
	call_deferred("_boot")


func _boot() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
