extends CharacterBody2D
## Simple grid-tied enemy: no movement AI in MVP; receives melee damage.

const PlaceholderSpriteFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")

signal died

@export var max_hp: int = 12

var grid_pos: Vector2i = Vector2i.ZERO
var hp: int

var _world: Node

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


func get_grid_pos() -> Vector2i:
	return grid_pos


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		died.emit()
		queue_free()
