extends CharacterBody2D
## Grid-based isometric movement (Tibia-style logical tiles) + facing + melee + exhaust.
## WASD: Input.get_vector. Left-click: BFS path. Space: melee (adjacent tile).

const PlaceholderSpriteFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")

enum State { IDLE, WALKING }

const ARRIVE_EPS := 2.0

@export_group("Grid")
@export var cell_size: Vector2 = Vector2(64, 32)
@export var move_speed: float = 220.0
@export var melee_damage: int = 4

var state: State = State.IDLE
var _grid_pos: Vector2i = Vector2i.ZERO
var _walking: bool = false
var _dest_tile: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO
var _path: Array[Vector2i] = []
var _keyboard_dir: Vector2i = Vector2i.ZERO
## Screen-down on isometric diamond (matches grid +gy step).
var _facing: Vector2i = Vector2i(0, 1)

var _world: Node
var _exhaust := ExhaustTimers.new()

@onready var _visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	_visual.sprite_frames = PlaceholderSpriteFrames.make_character_frames()
	_visual.play("idle_south")
	_world = get_tree().get_first_node_in_group("iso_world")
	if _world:
		_grid_pos = _world.world_to_grid_pos(global_position)
		global_position = _world.grid_to_world_pos(_grid_pos)
	else:
		_grid_pos = world_to_grid_fallback(global_position)
		global_position = grid_to_world_fallback(_grid_pos)
	_target_world = global_position


func get_aggressive_cooldown_remaining() -> float:
	return _exhaust.aggressive_cooldown_remaining()


func grid_to_world_fallback(g: Vector2i) -> Vector2:
	var hw := cell_size.x * 0.5
	var hh := cell_size.y * 0.5
	return Vector2((g.x - g.y) * hw, (g.x + g.y) * hh)


func world_to_grid_fallback(p: Vector2) -> Vector2i:
	var hw := cell_size.x * 0.5
	var hh := cell_size.y * 0.5
	if hw == 0.0 or hh == 0.0:
		return Vector2i.ZERO
	var gx := (p.x / hw + p.y / hh) * 0.5
	var gy := (p.y / hh - p.x / hw) * 0.5
	return Vector2i(round(gx), round(gy))


func _grid_to_world(g: Vector2i) -> Vector2:
	if _world and _world.has_method("grid_to_world_pos"):
		return _world.grid_to_world_pos(g)
	return grid_to_world_fallback(g)


func _world_to_grid(p: Vector2) -> Vector2i:
	if _world and _world.has_method("world_to_grid_pos"):
		return _world.world_to_grid_pos(p)
	return world_to_grid_fallback(p)


func _physics_process(_delta: float) -> void:
	_keyboard_dir = _read_grid_direction_from_input()
	if _keyboard_dir != Vector2i.ZERO:
		_facing = _keyboard_dir
		_path.clear()

	if global_position.distance_to(_target_world) > ARRIVE_EPS:
		state = State.WALKING
		var to := _target_world - global_position
		velocity = to.normalized() * move_speed
		move_and_slide()
		_update_facing_from_velocity(velocity)
		_play_anim_walking()
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
	if state == State.IDLE:
		_play_anim_idle()


func _begin_walk_to(t: Vector2i) -> void:
	var from_c := _grid_pos
	_dest_tile = t
	_walking = true
	_target_world = _grid_to_world(t)
	var na := get_node_or_null("/root/NetworkAuthority")
	if na:
		na.validate_walk(from_c, t)


func _is_neighbor(a: Vector2i, b: Vector2i) -> bool:
	var d := a - b
	return abs(d.x) + abs(d.y) == 1


func _read_grid_direction_from_input() -> Vector2i:
	# Explicit WASD (not only Input.get_vector) so keyboard is never eaten by deadzone.
	var gx := 0
	var gy := 0
	if Input.is_action_pressed("move_right"):
		gx += 1
	if Input.is_action_pressed("move_left"):
		gx -= 1
	if Input.is_action_pressed("move_back"):
		gy += 1
	if Input.is_action_pressed("move_forward"):
		gy -= 1
	if gx == 0 and gy == 0:
		return Vector2i.ZERO
	if abs(gx) >= abs(gy):
		return Vector2i(_sign_int(gx), 0)
	return Vector2i(0, _sign_int(gy))


func _sign_int(x: int) -> int:
	if x > 0:
		return 1
	if x < 0:
		return -1
	return 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("melee_attack"):
		_try_melee()


func _try_melee() -> void:
	if _walking:
		return
	if not _exhaust.can_aggressive():
		return
	var tgt: Vector2i = _grid_pos + _facing
	if not _can_enter_cell(tgt):
		return
	for n in get_tree().get_nodes_in_group("grid_enemies"):
		if n.has_method("get_grid_pos") and n.get_grid_pos() == tgt:
			var attacker_id := get_instance_id()
			var na := get_node_or_null("/root/NetworkAuthority")
			if na == null or na.validate_melee(attacker_id, tgt):
				n.take_damage(melee_damage)
			_exhaust.consume_aggressive()
			return


func _unhandled_input(event: InputEvent) -> void:
	if _walking:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var target := _world_to_grid(get_global_mouse_position())
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


func _can_enter_cell(g: Vector2i) -> bool:
	if _world and _world.has_method("is_walkable"):
		return _world.is_walkable(g)
	return true


func _dir_name(f: Vector2i) -> String:
	if f.y > 0:
		return "south"
	if f.y < 0:
		return "north"
	if f.x > 0:
		return "east"
	return "west"


func _play_anim_walking() -> void:
	var d := _dir_name(_facing)
	_visual.play("walk_%s" % d)


func _play_anim_idle() -> void:
	var d := _dir_name(_facing)
	_visual.play("idle_%s" % d)


func _update_facing_from_velocity(v: Vector2) -> void:
	if v.length_squared() < 0.01:
		return
	if absf(v.x) >= absf(v.y):
		_facing = Vector2i(1 if v.x > 0.0 else -1, 0)
	else:
		_facing = Vector2i(0, 1 if v.y > 0.0 else -1)
