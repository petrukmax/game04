class_name TowerData
extends Resource
## Data-driven definition of a defensive tower.

@export var id: String = ""
@export var display_name: String = "Tower"
@export var role: String = "Damage"
@export var description: String = ""
@export var cost: int = 100
@export var sell_ratio: float = 0.7
@export var max_level: int = 4

@export_group("Combat")
@export_enum("kinetic", "explosive", "fire", "electric", "frost", "energy", "corrosive", "support") var damage_type: String = "kinetic"
@export var damage: float = 12.0
@export var attack_rate: float = 1.5
@export var attack_range: float = 190.0
@export var projectile_speed: float = 750.0
@export var splash_radius: float = 0.0
@export var slow_amount: float = 0.0
@export var slow_duration: float = 0.0
@export var armor_penetration: float = 0.0
@export var chain_count: int = 0
@export var burn_dps: float = 0.0
@export var burn_duration: float = 0.0
@export var missiles: int = 1
@export var anti_air: bool = false
@export var can_target_ground: bool = true
@export var crit_chance: float = 0.0
@export var stun_chance: float = 0.0
@export var stun_duration: float = 0.0
@export var freeze_chance: float = 0.0
@export var freeze_duration: float = 0.0
@export var corrode_duration: float = 0.0

@export_group("Support")
@export var support_radius: float = 0.0
@export var support_buff: float = 0.0
@export var income_per_wave: int = 0
@export var deploy_interval: float = 0.0
@export var mine_damage: float = 0.0

@export_group("Presentation")
@export var projectile_scene_path: String = ""
@export var scene_path: String = ""
@export var visual_style: String = "pulse"
@export var primary_color: Color = Color(0.95, 0.62, 0.22)
@export var shortcut: String = "1"
@export_multiline var tip: String = ""

@export_group("Upgrades")
@export var upgrades: Array = []
