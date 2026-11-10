class_name LevelData
extends Resource
## Everything a level needs to build itself, editable in the Godot inspector.

@export var id: String = ""
@export var display_name: String = "Sector"
@export var level_number: int = 1
@export var difficulty: String = "Easy"
@export_multiline var description: String = ""

@export_group("Economy")
@export var starting_credits: int = 600
@export var base_health: int = 100
@export var completion_reward: int = 120
@export var interest_rate: float = 0.0

@export_group("Grid and roads")
@export var grid_width: int = 22
@export var grid_height: int = 11
@export var build_margin: int = 2
@export var path_a: Array = []
@export var path_b: Array = []
@export var blocked_cells: Array = []

@export_group("Content")
@export var available_towers: Array = []
@export var unlocked_abilities: Array = []
@export var wave_data_list: Array = []

@export_group("Presentation")
@export var environment_theme: String = "landing"
@export var ground_color: Color = Color(0.48, 0.2, 0.13)
@export var dust_color: Color = Color(0.85, 0.48, 0.28)
@export var prop_seed: int = 1
@export_multiline var briefing: String = ""
