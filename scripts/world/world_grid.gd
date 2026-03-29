extends TileMapLayer
## Square logical grid for oblique / top-down ~45° presentation (Tibia-style), not 2:1 diamond isometric.
## TileSet is orthogonal; sprites can later be drawn with oblique perspective.
## Group "world_grid": is_walkable, grid_to_world_pos, world_to_grid_pos.

const CELL := Vector2i(32, 32)
const ATLAS_FLOOR := Vector2i(0, 0)
const ATLAS_WALL := Vector2i(1, 0)

@export var map_radius: int = 12


func _ready() -> void:
	add_to_group("world_grid")
	tile_set = _build_tileset()
	_paint_arena()


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = CELL
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.22, 0.16, 1))
	for x in range(32, 64):
		for y in range(32):
			img.set_pixel(x, y, Color(0.35, 0.28, 0.22, 1))
	var tex := ImageTexture.create_from_image(img)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = CELL
	atlas.create_tile(ATLAS_FLOOR)
	atlas.create_tile(ATLAS_WALL)
	ts.add_source(atlas, 0)
	return ts


func _paint_arena() -> void:
	for x in range(-map_radius, map_radius + 1):
		for y in range(-map_radius, map_radius + 1):
			var c := Vector2i(x, y)
			var is_border: bool = (
				x == -map_radius or x == map_radius or y == -map_radius or y == map_radius
			)
			if is_border:
				set_cell(c, 0, ATLAS_WALL)
			else:
				set_cell(c, 0, ATLAS_FLOOR)


func is_walkable(grid: Vector2i) -> bool:
	if get_cell_source_id(grid) < 0:
		return false
	return get_cell_atlas_coords(grid) != ATLAS_WALL


func grid_to_world_pos(grid: Vector2i) -> Vector2:
	return to_global(map_to_local(grid))


func world_to_grid_pos(global_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(global_pos))
