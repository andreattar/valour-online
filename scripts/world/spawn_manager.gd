extends Node2D
## Minimal overspawn loop: one spawn point, cap 1, respawn after delay.

@export var enemy_scene: PackedScene
@export var spawn_cell: Vector2i = Vector2i(3, -2)
@export var respawn_seconds: float = 6.0

var _world: Node
var _alive: bool = false


func _ready() -> void:
	_world = get_tree().get_first_node_in_group("iso_world")
	call_deferred("_spawn")


func _spawn() -> void:
	if _alive or enemy_scene == null or _world == null:
		return
	var e: Node2D = enemy_scene.instantiate() as Node2D
	e.global_position = _world.grid_to_world_pos(spawn_cell)
	add_child(e)
	_alive = true
	if e.has_signal("died"):
		e.died.connect(_on_enemy_died)


func _on_enemy_died() -> void:
	_alive = false
	get_tree().create_timer(respawn_seconds).timeout.connect(_spawn)
