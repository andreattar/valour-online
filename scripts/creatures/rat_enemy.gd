extends "res://scripts/creatures/grid_enemy.gd"
## Rat - weak and fast enemy.

const PlaceholderFrames := preload("res://scripts/rendering/placeholder_sprite_frames.gd")


func _ready() -> void:
	display_name = "Rat"
	super._ready()
	_anim.sprite_frames = PlaceholderFrames.make_rat_frames()
	_anim.play(&"idle")
