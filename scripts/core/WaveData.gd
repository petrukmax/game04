class_name WaveData
extends Resource
## A hand-authored wave. Spawn entries are resolved by WaveManager.

@export var wave_index: int = 1
@export var display_name: String = "Wave"
@export var entries: Array = []
@export var completion_bonus: int = 40
@export var boss_wave: bool = false
@export_multiline var preview: String = ""
