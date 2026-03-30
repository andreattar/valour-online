extends Node2D
## Manages multiple spawn points with different creature types.

@export var spawn_points: Array[SpawnPoint] = []
@export var default_enemy_scene: PackedScene
@export var respawn_seconds: float = 6.0
@export var max_creatures: int = 5

var _world: Node
var _spawn_timers: Dictionary = {}
var _alive_count: int = 0


func _ready() -> void:
	_world = get_tree().get_first_node_in_group("world_grid")
	
	if spawn_points.is_empty() and default_enemy_scene:
		var sp := SpawnPoint.new()
		sp.cell = Vector2i(3, -2)
		sp.scene = default_enemy_scene
		spawn_points.append(sp)
	
	for i in spawn_points.size():
		call_deferred("_spawn_at", i)


func _spawn_at(spawn_index: int) -> void:
	if spawn_index >= spawn_points.size():
		return
	if _alive_count >= max_creatures:
		_schedule_spawn(spawn_index, 2.0)
		return
	
	var sp := spawn_points[spawn_index]
	if sp.scene == null or _world == null:
		return
	
	if _spawn_timers.get(spawn_index, false):
		return
	
	var e: Node2D = sp.scene.instantiate() as Node2D
	e.global_position = _world.grid_to_world_pos(sp.cell)
	add_child(e)
	_alive_count += 1
	
	if e.has_signal("died"):
		e.died.connect(_on_enemy_died.bind(spawn_index))


func _on_enemy_died(spawn_index: int) -> void:
	_alive_count = maxi(0, _alive_count - 1)
	_schedule_spawn(spawn_index, respawn_seconds)


func _schedule_spawn(spawn_index: int, delay: float) -> void:
	if _spawn_timers.get(spawn_index, false):
		return
	_spawn_timers[spawn_index] = true
	get_tree().create_timer(delay).timeout.connect(func():
		_spawn_timers[spawn_index] = false
		_spawn_at(spawn_index)
	)
