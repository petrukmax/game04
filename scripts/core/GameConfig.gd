class_name GameConfig
extends RefCounted
## Shared constants for the Mars battlefield.

const CELL_SIZE := 64
const MAP_ORIGIN := Vector2(96, 76)
const GRID_WIDTH := 22
const GRID_HEIGHT := 11
const SIM_STEP := 1.0 / 60.0
const MAX_DELTA := 0.05
const SELL_RATIO_DEFAULT := 0.7
const PANEL_DARK := Color(0.058, 0.062, 0.075)
const PANEL_MID := Color(0.095, 0.1, 0.115)
const AMBER := Color(0.98, 0.65, 0.2)
const OFFWHITE := Color(0.9, 0.89, 0.83)
const WARNING_RED := Color(0.86, 0.19, 0.14)
const ROAD_COLOR := Color(0.16, 0.14, 0.14)
const GRID_COLOR := Color(0.74, 0.48, 0.28, 0.2)


static func as_bool(value: Variant) -> bool:
	## Godot 4.7 has no built-in bool conversion, so coerce Variants explicitly.
	if value == null:
		return false
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(value))
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value).strip_edges().to_lower()
			return text != "" and text != "false" and text != "0" and text != "no"
		TYPE_ARRAY, TYPE_DICTIONARY:
			return not value.is_empty()
		TYPE_OBJECT:
			return is_instance_valid(value)
		_:
			return true
