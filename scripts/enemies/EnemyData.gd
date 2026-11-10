class_name EnemyData
extends Resource
## Data-driven definition of a hostile arachnid.

@export var id: String = ""
@export var display_name: String = "Arachnid"
@export var role: String = "Ground"
@export_multiline var description: String = ""
@export var max_health: float = 100.0
@export var speed: float = 70.0
@export var armor: float = 0.0
@export var bounty: int = 8
@export var leak_damage: int = 1
@export var spawn_weight: float = 1.0

@export_group("Traits")
@export var flying: bool = false
@export var burrowed: bool = false
@export var shield: float = 0.0
@export var shield_regen: float = 0.0
@export var shield_delay: float = 5.0
@export var heal_radius: float = 0.0
@export var heal_amount: float = 0.0
@export var heal_interval: float = 2.0
@export var ranged_range: float = 0.0
@export var ranged_interval: float = 4.0
@export var is_elite: bool = false
@export var is_boss: bool = false

@export_group("Damage profile")
@export var resistances: Dictionary = {}
@export var immune_to: Array = []

@export_group("Presentation")
@export var scene_path: String = ""
@export var visual_style: String = "scout"
@export var body_color: Color = Color(0.72, 0.26, 0.16)
@export var accent_color: Color = Color(1.0, 0.63, 0.2)
@export var body_scale: float = 1.0
@export_multiline var tip: String = ""
