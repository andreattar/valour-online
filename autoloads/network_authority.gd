extends Node
## Stub for future server-authoritative tile sync. Offline single-player accepts all intents.

signal tile_move_validated(from_cell: Vector2i, to_cell: Vector2i)
signal melee_validated(attacker_id: int, target_cell: Vector2i)


func is_offline_single_player() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer == null


func validate_walk(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	# Future: server checks walkable, exhaust, etc.
	tile_move_validated.emit(from_cell, to_cell)
	return true


func validate_melee(attacker_id: int, target_cell: Vector2i) -> bool:
	melee_validated.emit(attacker_id, target_cell)
	return true
