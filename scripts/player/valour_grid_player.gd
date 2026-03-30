extends CharacterBody2D
## Tibia-style: square tile grid + smooth steps (oblique / top-down presentation, not diamond isometric).
## WASD = screen cardinal on the grid (plus). Click = BFS. Space = melee.

const PlaceholderSpriteFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")
const MeleeAction := preload("res://scripts/combat/actions/melee_action.gd")
const HealAction := preload("res://scripts/combat/actions/heal_action.gd")

signal target_changed(target: Node)

enum State { IDLE, WALKING, DEAD }

const ARRIVE_EPS := 2.0

@export_group("Grid")
@export var cell_size: Vector2 = Vector2(32, 32)
@export var move_speed: float = 220.0

@export_group("Combat")
@export var base_melee_damage: int = 4

var state: State = State.IDLE
var current_target: Node = null
var _grid_pos: Vector2i = Vector2i.ZERO
var _walking: bool = false
var _dest_tile: Vector2i = Vector2i.ZERO
var _target_world: Vector2 = Vector2.ZERO
var _path: Array[Vector2i] = []
var _keyboard_dir: Vector2i = Vector2i.ZERO
## Grid steps: (0,-1) north, (0,1) south, (-1,0) west, (1,0) east — screen-aligned.
var _facing: Vector2i = Vector2i(0, 1)

var _world: Node
var _exhaust := ExhaustTimers.new()

@onready var _visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("player")
	_visual.sprite_frames = PlaceholderSpriteFrames.make_character_frames()
	_visual.play("idle_south")
	_world = get_tree().get_first_node_in_group("world_grid")
	if _world:
		_grid_pos = _world.world_to_grid_pos(global_position)
		global_position = _world.grid_to_world_pos(_grid_pos)
	else:
		_grid_pos = world_to_grid_fallback(global_position)
		global_position = grid_to_world_fallback(_grid_pos)
	_target_world = global_position
	
	PlayerStats.died.connect(_on_died)
	ActionSystem.set_player(self)
	_setup_default_actions()


func get_grid_pos() -> Vector2i:
	return _grid_pos


func get_melee_damage() -> int:
	var weapon_dmg := Equipment.get_total_attack_damage()
	return base_melee_damage + weapon_dmg + PlayerStats.total_strength() / 5


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	PlayerStats.take_damage(amount)


func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_path.clear()
	_visual.modulate = Color(0.5, 0.5, 0.5, 0.7)
	set_physics_process(false)
	set_process_input(false)
	await get_tree().create_timer(2.0).timeout
	_respawn()


func _respawn() -> void:
	PlayerStats.reset()
	state = State.IDLE
	_visual.modulate = Color.WHITE
	_grid_pos = Vector2i(5, 5)
	global_position = _grid_to_world(_grid_pos)
	_target_world = global_position
	set_physics_process(true)
	set_process_input(true)


func get_aggressive_cooldown_remaining() -> float:
	return _exhaust.aggressive_cooldown_remaining()


func grid_to_world_fallback(g: Vector2i) -> Vector2:
	return Vector2(
		(float(g.x) + 0.5) * cell_size.x,
		(float(g.y) + 0.5) * cell_size.y,
	)


func world_to_grid_fallback(p: Vector2) -> Vector2i:
	return Vector2i(
		floori(p.x / cell_size.x),
		floori(p.y / cell_size.y),
	)


func _grid_to_world(g: Vector2i) -> Vector2:
	if _world and _world.has_method("grid_to_world_pos"):
		return _world.grid_to_world_pos(g)
	return grid_to_world_fallback(g)


func _world_to_grid(p: Vector2) -> Vector2i:
	if _world and _world.has_method("world_to_grid_pos"):
		return _world.world_to_grid_pos(p)
	return world_to_grid_fallback(p)


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return
	
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
	var dx := 0
	var dy := 0
	if Input.is_action_pressed("move_right"):
		dx += 1
	if Input.is_action_pressed("move_left"):
		dx -= 1
	if Input.is_action_pressed("move_back"):
		dy += 1
	if Input.is_action_pressed("move_forward"):
		dy -= 1
	if dx == 0 and dy == 0:
		return Vector2i.ZERO
	if abs(dx) >= abs(dy):
		return Vector2i(_sign_int(dx), 0)
	return Vector2i(0, _sign_int(dy))


func _sign_int(x: int) -> int:
	if x > 0:
		return 1
	if x < 0:
		return -1
	return 0


func _keyboard_screen_dir() -> Vector2:
	var dx := 0.0
	var dy := 0.0
	if Input.is_action_pressed("move_forward"):
		dy -= 1.0
	if Input.is_action_pressed("move_back"):
		dy += 1.0
	if Input.is_action_pressed("move_left"):
		dx -= 1.0
	if Input.is_action_pressed("move_right"):
		dx += 1.0
	if dx == 0.0 and dy == 0.0:
		return Vector2.ZERO
	return Vector2(dx, dy).normalized()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("melee_attack"):
		_try_melee()


func _melee_facing_grid() -> Vector2i:
	var k := _read_grid_direction_from_input()
	if k != Vector2i.ZERO:
		return k
	return _facing


func _setup_default_actions() -> void:
	var melee := MeleeAction.new()
	ActionSystem.register_action(melee)
	ActionSystem.assign_to_slot(0, "melee_attack")
	
	var heal := HealAction.new()
	ActionSystem.register_action(heal)
	ActionSystem.assign_to_slot(1, "heal")


func _try_melee() -> void:
	perform_melee()


func perform_melee() -> void:
	if state == State.DEAD:
		return
	if _walking:
		return
	if not _exhaust.can_aggressive():
		return
	var step := _melee_facing_grid()
	if step == Vector2i.ZERO:
		return
	var tgt: Vector2i = _grid_pos + step
	for n in get_tree().get_nodes_in_group("grid_enemies"):
		if n.has_method("get_grid_pos") and n.get_grid_pos() == tgt:
			var attacker_id := get_instance_id()
			var na := get_node_or_null("/root/NetworkAuthority")
			if na == null or na.validate_melee(attacker_id, tgt):
				n.take_damage(get_melee_damage())
				_set_target(n)
				PlayerStats.gain_xp(1)
			_exhaust.consume_aggressive()
			return


func _set_target(node: Node) -> void:
	if current_target == node:
		return
	current_target = node
	target_changed.emit(node)
	if node and node.has_signal("died"):
		node.died.connect(_on_target_died, CONNECT_ONE_SHOT)


func _on_target_died() -> void:
	current_target = null
	target_changed.emit(null)


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


func _dir_name_from_screen(screen_dir: Vector2) -> String:
	if screen_dir.length_squared() < 1e-8:
		return "south"
	var a := atan2(screen_dir.y, screen_dir.x)
	if a >= -PI * 0.25 and a < PI * 0.25:
		return "east"
	if a >= PI * 0.25 and a < PI * 0.75:
		return "south"
	if a >= PI * 0.75 or a < -PI * 0.75:
		return "west"
	return "north"


func _dir_name_from_grid_facing(f: Vector2i) -> String:
	match f:
		Vector2i(0, -1):
			return "north"
		Vector2i(0, 1):
			return "south"
		Vector2i(-1, 0):
			return "west"
		Vector2i(1, 0):
			return "east"
		_:
			return "south"


func _anim_label() -> String:
	var ks := _keyboard_screen_dir()
	if ks.length_squared() > 1e-8:
		return _dir_name_from_screen(ks)
	if velocity.length_squared() > 10.0:
		return _dir_name_from_screen(velocity)
	var to_n := _target_world - global_position
	if to_n.length_squared() > 1e-8:
		return _dir_name_from_screen(to_n)
	return _dir_name_from_grid_facing(_facing)


func _play_anim_walking() -> void:
	_visual.play("walk_%s" % _anim_label())


func _play_anim_idle() -> void:
	_visual.play("idle_%s" % _anim_label())


func _update_facing_from_velocity(v: Vector2) -> void:
	if v.length_squared() < 0.01:
		return
	if absf(v.x) >= absf(v.y):
		_facing = Vector2i(1 if v.x > 0.0 else -1, 0)
	else:
		_facing = Vector2i(0, 1 if v.y > 0.0 else -1)
