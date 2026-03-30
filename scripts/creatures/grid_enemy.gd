extends CharacterBody2D
## Grid-based enemy with chase AI, attacks, and loot drops.

const PlaceholderSpriteFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")

signal died

enum State { IDLE, CHASING, ATTACKING, DEAD }

@export_group("Stats")
@export var max_hp: int = 12
@export var attack_damage: int = 3
@export var xp_reward: int = 5

@export_group("Behavior")
@export var aggro_range: int = 6
@export var attack_range: int = 1
@export var move_speed: float = 100.0
@export var attack_cooldown_ms: int = 2500
@export var move_cooldown_ms: int = 800

@export_group("Loot")
@export var loot_table: Resource = null
@export var gold_min: int = 1
@export var gold_max: int = 5

var grid_pos: Vector2i = Vector2i.ZERO
var hp: int
var state: State = State.IDLE
var display_name: String = "Enemy"

var _world: Node
var _target: Node = null
var _next_move_ms: int = 0
var _next_attack_ms: int = 0
var _dest_world: Vector2 = Vector2.ZERO
var _walking: bool = false

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("grid_enemies")
	hp = max_hp
	_anim.sprite_frames = PlaceholderSpriteFrames.make_slime_frames()
	_anim.play(&"idle")
	_world = get_tree().get_first_node_in_group("world_grid")
	if _world and _world.has_method("world_to_grid_pos"):
		grid_pos = _world.world_to_grid_pos(global_position)
		global_position = _world.grid_to_world_pos(grid_pos)
	_dest_world = global_position


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	_update_target()
	
	if _walking:
		var dist := global_position.distance_to(_dest_world)
		if dist < 2.0:
			global_position = _dest_world
			_walking = false
			if _world:
				grid_pos = _world.world_to_grid_pos(global_position)
		else:
			var dir := (_dest_world - global_position).normalized()
			velocity = dir * move_speed
			move_and_slide()
		return
	
	if not _target:
		state = State.IDLE
		return
	
	var player_pos := _get_target_grid_pos()
	var dist_to_player := _grid_distance(grid_pos, player_pos)
	
	if dist_to_player <= attack_range:
		state = State.ATTACKING
		_try_attack()
	elif dist_to_player <= aggro_range:
		state = State.CHASING
		_try_move_toward(player_pos)
	else:
		state = State.IDLE


func _update_target() -> void:
	if _target and is_instance_valid(_target):
		return
	_target = get_tree().get_first_node_in_group("player")


func _get_target_grid_pos() -> Vector2i:
	if _target and _target.has_method("get_grid_pos"):
		return _target.get_grid_pos()
	return Vector2i.ZERO


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


func _try_move_toward(target_pos: Vector2i) -> void:
	var now := Time.get_ticks_msec()
	if now < _next_move_ms:
		return
	
	var best_step: Vector2i = grid_pos
	var best_dist := _grid_distance(grid_pos, target_pos)
	
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]
	
	for d in dirs:
		var next_pos := grid_pos + d
		if _can_enter(next_pos):
			var dist := _grid_distance(next_pos, target_pos)
			if dist < best_dist:
				best_dist = dist
				best_step = next_pos
	
	if best_step != grid_pos:
		_begin_move_to(best_step)
		_next_move_ms = now + move_cooldown_ms


func _begin_move_to(target: Vector2i) -> void:
	if not _world:
		return
	_dest_world = _world.grid_to_world_pos(target)
	_walking = true


func _can_enter(pos: Vector2i) -> bool:
	if _world and _world.has_method("is_walkable"):
		if not _world.is_walkable(pos):
			return false
	for enemy in get_tree().get_nodes_in_group("grid_enemies"):
		if enemy != self and enemy.has_method("get_grid_pos"):
			if enemy.get_grid_pos() == pos:
				return false
	if _target and _target.has_method("get_grid_pos"):
		if _target.get_grid_pos() == pos:
			return false
	return true


func _try_attack() -> void:
	var now := Time.get_ticks_msec()
	if now < _next_attack_ms:
		return
	
	if _target and _target.has_method("take_damage"):
		_target.take_damage(attack_damage)
		_next_attack_ms = now + attack_cooldown_ms
		_anim.play(&"attack") if _anim.sprite_frames.has_animation(&"attack") else null


func get_grid_pos() -> Vector2i:
	return grid_pos


func get_display_name() -> String:
	return display_name


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	_flash_damage()
	if hp <= 0:
		_die()


func _flash_damage() -> void:
	_anim.modulate = Color(1.0, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		_anim.modulate = Color.WHITE


func _die() -> void:
	state = State.DEAD
	_drop_loot()
	PlayerStats.gain_xp(xp_reward)
	died.emit()
	queue_free()


func _drop_loot() -> void:
	var gold_drop := randi_range(gold_min, gold_max)
	if gold_drop > 0:
		Inventory.gold += gold_drop
	
	if loot_table and loot_table.has_method("roll"):
		var drops: Array = loot_table.roll()
		for drop in drops:
			if drop is ItemResource:
				Inventory.add_item(drop)
			elif drop is Dictionary and "item" in drop:
				Inventory.add_item(drop.item, drop.get("quantity", 1))
