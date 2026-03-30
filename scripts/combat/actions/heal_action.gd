extends ActionBase
class_name HealAction
## Simple healing spell - restores HP using mana.

@export var heal_amount: int = 20


func _init() -> void:
	id = "heal"
	display_name = "Heal"
	cooldown_ms = 4000
	mana_cost = 15
	exhaust_type = "utility"


func _do_action() -> void:
	PlayerStats.heal(heal_amount)
