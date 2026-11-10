class_name UpgradeData
extends Resource
## One purchasable tower upgrade step. Authored as a .tres resource.

@export var level: int = 2
@export var cost: int = 120
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""

@export_group("Stat modifiers")
@export var damage_add: float = 0.0
@export var range_add: float = 0.0
@export var rate_add: float = 0.0
@export var splash_add: float = 0.0
@export var projectile_speed_add: float = 0.0
@export var armor_pen_add: float = 0.0
@export var slow_add: float = 0.0
@export var slow_duration_add: float = 0.0
@export var chain_add: int = 0
@export var burn_add: float = 0.0
@export var income_add: int = 0
@export var buff_add: float = 0.0
@export var deploy_interval_add: float = 0.0
@export var missiles_add: int = 0
@export var mine_damage_add: float = 0.0
@export var freeze_chance_add: float = 0.0
@export var freeze_duration_add: float = 0.0
@export var corrode_duration_add: float = 0.0

@export_group("Behaviour")
@export var unlock_air: bool = false
@export var unlock_armor_break: bool = false
@export var special_note: String = ""
