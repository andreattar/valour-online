extends Resource
class_name ActionBase
## Base class for all actions (skills, spells, item uses).

@export var id: String = ""
@export var display_name: String = "Action"
@export var icon: Texture2D
@export var mana_cost: int = 0
@export var cooldown_ms: int = 0
@export var exhaust_type: String = "aggressive"

var _next_use_ms: int = 0


func can_use() -> bool:
	if Time.get_ticks_msec() < _next_use_ms:
		return false
	if mana_cost > 0 and PlayerStats.mana < mana_cost:
		return false
	return true


func cooldown_remaining() -> float:
	var now := Time.get_ticks_msec()
	return maxf(0.0, (_next_use_ms - now) / 1000.0)


func cooldown_total() -> float:
	return cooldown_ms / 1000.0


func execute() -> bool:
	if not can_use():
		return false
	if mana_cost > 0:
		if not PlayerStats.use_mana(mana_cost):
			return false
	_next_use_ms = Time.get_ticks_msec() + cooldown_ms
	_do_action()
	return true


func _do_action() -> void:
	pass
