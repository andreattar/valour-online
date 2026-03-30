extends "res://scripts/creatures/grid_enemy.gd"
## Skeleton - medium difficulty enemy with better loot.

const PlaceholderFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")


func _ready() -> void:
	display_name = "Skeleton"
	super._ready()
	_anim.sprite_frames = PlaceholderFrames.make_skeleton_frames()
	_anim.play(&"idle")
