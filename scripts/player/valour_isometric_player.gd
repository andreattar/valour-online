extends CharacterBody2D
## Grid-based isometric movement with smooth interpolation (Tibia-style logical tiles).
## WASD: Input.get_vector(move_left, move_right, move_forward, move_back).
## Left-click: BFS path on the virtual grid (_unhandled_input).

enum State { IDLE, WALKING }

const ARRIVE_EPS := 2.0

@export_group("Grid")
@export var cell_size: Vector2 = Vector2(64, 32)
@export var move_speed: float = 220.0

var state: State = State.IDLE
var _grid_pos: Vector2i = Vector2i.ZERO
var _walking: bool = false
var _dest_tile: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO
var _path: Array[Vector2i] = []
var _keyboard_dir: Vector2i = Vector2i.ZERO

@onready var _visual: CanvasItem = $Visual


func _ready() -> void:
	_grid_pos = world_to_grid(global_position)
	global_position = grid_to_world(_grid_pos)
	_target_world = global_position


func grid_to_world(g: Vector2i) -> Vector2:
	var hw := cell_size.x * 0.5
	var hh := cell_size.y * 0.5
	return Vector2((g.x - g.y) * hw, (g.x + g.y) * hh)


func world_to_grid(p: Vector2) -> Vector2i:
	var hw := cell_size.x * 0.5
	var hh := cell_size.y * 0.5
	if hw == 0.0 or hh == 0.0:
		return Vector2i.ZERO
	var gx := (p.x / hw + p.y / hh) * 0.5
	var gy := (p.y / hh - p.x / hw) * 0.5
	return Vector2i(round(gx), round(gy))


func _physics_process(_delta: float) -> void:
	_keyboard_dir = _read_grid_direction_from_input()
	if _keyboard_dir != Vector2i.ZERO:
		_path.clear()

	if global_position.distance_to(_target_world) > ARRIVE_EPS:
		state = State.WALKING
		var to := _target_world - global_position
		velocity = to.normalized() * move_speed
		move_and_slide()
		_update_facing_from_velocity(velocity)
		return

	global_position = _target_world
	velocity = Vector2.ZERO
	if _walking:
		_grid_pos = _dest_tile
		_walking = false

	if not _path.is_empty():
		var nxt: Vector2i = _path.pop_front()
		if nxt != _grid_pos and _is_neighbor(_grid_pos, nxt) and _can_enter_cell(nxt):
			_begin_walk_to(nxt)
	elif _keyboard_dir != Vector2i.ZERO:
		var step: Vector2i = _grid_pos + _keyboard_dir
		if _can_enter_cell(step):
			_begin_walk_to(step)

	state = State.IDLE if not _walking and _path.is_empty() and _keyboard_dir == Vector2i.ZERO else State.WALKING


func _begin_walk_to(t: Vector2i) -> void:
	_dest_tile = t
	_walking = true
	_target_world = grid_to_world(t)


func _is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var d := a - b
	return abs(d.x) + abs(d.y) == 1


func _read_grid_direction_from_input() -> Vector2i:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if v.length_squared() < 0.01:
		return Vector2i.ZERO
	if absf(v.x) >= absf(v.y):
		return Vector2i(1 if v.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if v.y > 0.0 else -1)


func _unhandled_input(event: InputEvent) -> void:
	if _walking:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var target := world_to_grid(get_global_mouse_position())
			if target == _grid_pos:
				return
			var full := _find_path(_grid_pos, target)
			if full.size() < 2:
				return
			_path.clear()
			for i in range(1, full.size()):
				_path.append(full[i])


func _find_path(from_g: Vector2i, to_g: Vector2i) -> Array[Vector2i]:
	if from_g == to_g:
		return [from_g]
	var frontier: Array[Vector2i] = [from_g]
	var came_from: Dictionary = {}
	var head := 0
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	]
	while head < frontier.size():
		var cur: Vector2i = frontier[head]
		head += 1
		if cur == to_g:
			return _reconstruct_path(came_from, from_g, to_g)
		for d in dirs:
			var nxt: Vector2i = cur + d
			if nxt in came_from:
				continue
			if not _can_enter_cell(nxt):
				continue
			came_from[nxt] = cur
			frontier.append(nxt)
	return [from_g]


func _reconstruct_path(came_from: Dictionary, from_g: Vector2i, to_g: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cur: Vector2i = to_g
	while cur != from_g:
		out.push_front(cur)
		cur = came_from[cur]
	out.push_front(from_g)
	return out


func _can_enter_cell(_g: Vector2i) -> bool:
	return true


func _update_facing_from_velocity(v: Vector2) -> void:
	if v.length_squared() < 0.01:
		return
	if _visual:
		_visual.scale.x = 1.0 if v.x >= 0.0 else -1.0
