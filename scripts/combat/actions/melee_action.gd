extends ActionBase
class_name MeleeAction
## Basic melee attack action - hits adjacent tile in facing direction.


func _init() -> void:
	id = "melee_attack"
	display_name = "Melee Attack"
	cooldown_ms = 2000
	mana_cost = 0
	exhaust_type = "aggressive"


func _do_action() -> void:
	var player := _get_player()
	if not player:
		return
	if player.has_method("perform_melee"):
		player.perform_melee()


func _get_player() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	return tree.get_first_node_in_group("player")
