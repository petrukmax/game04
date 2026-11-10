class_name EconomyManager
extends Node
## Credits, expenditures and rewards. All credit changes flow through here.

var credits: int = 0
var starting_credits: int = 0
var total_earned: int = 0
var total_spent: int = 0


func setup(data: LevelData) -> void:
	starting_credits = data.starting_credits
	credits = starting_credits
	total_earned = starting_credits
	total_spent = 0
	_emit()


func add_credits(amount: int, _reason: String = "") -> void:
	if amount <= 0:
		return
	credits += amount
	total_earned += amount
	_emit()


func can_afford(amount: int) -> bool:
	return credits >= amount


func spend(amount: int) -> bool:
	if amount < 0 or credits < amount:
		return false
	credits -= amount
	total_spent += amount
	_emit()
	return true


func refund(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	# Refunds are returned investment, not new income.
	_emit()


func wave_bonus(amount: int) -> void:
	add_credits(amount, "wave")


func _emit() -> void:
	EventBus.credits_changed.emit(credits)
