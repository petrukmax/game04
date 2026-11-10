class_name AbilityData
extends Resource
## Player ability definition (orbital strike, EMP, drones, repair, supply).

@export var id: String = ""
@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export var cooldown: float = 40.0
@export var uses_per_level: int = -1
@export var target_mode: String = "area"
@export var radius: float = 120.0
@export var delay: float = 1.0
@export var damage: float = 0.0
@export var damage_type: String = "explosive"
@export var duration: float = 0.0
@export var stun_duration: float = 0.0
@export var slow_amount: float = 0.0
@export var credits: int = 0
@export var heal_amount: int = 0
@export var shortcut: String = "Q"
@export var color: Color = Color(1.0, 0.55, 0.15)
