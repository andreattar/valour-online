extends Label
## Shows aggressive (melee) exhaust remaining — 7.x-style pacing feedback.

@export var player_path: NodePath = ^"../Entities/Player"


func _process(_delta: float) -> void:
	var p := get_node_or_null(player_path)
	if p == null or not p.has_method("get_aggressive_cooldown_remaining"):
		text = ""
		return
	var r: float = p.get_aggressive_cooldown_remaining()
	if r <= 0.0:
		text = "Melee: ready (Space)"
	else:
		text = "Melee exhaust: %.1fs" % r
