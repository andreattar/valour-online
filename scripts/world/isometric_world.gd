extends TileMap
## Builds isometric TileSet at runtime and paints a small arena with walkable floor + wall border.
## Group "iso_world": exposes is_walkable(grid: Vector2i).

const CELL := Vector2i(64, 32)
const ATLAS_FLOOR := Vector2i(0, 0)
const ATLAS_WALL := Vector2i(1, 0)

@export var map_radius: int = 8


func _ready() -> void:
	add_to_group("iso_world")
	if get_layer_count() == 0:
		add_layer(-1)
	tile_set = _build_tileset()
	var layer := get_layer(0) as TileMapLayer
	_paint_arena(layer)


func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = CELL

	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.18, 0.22, 0.16, 1))
	for x in range(64, 128):
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


func _paint_arena(layer: TileMapLayer) -> void:
	for x in range(-map_radius, map_radius + 1):
		for y in range(-map_radius, map_radius + 1):
			var c := Vector2i(x, y)
			var is_border: bool = (
				x == -map_radius or x == map_radius or y == -map_radius or y == map_radius
			)
			if is_border:
				layer.set_cell(c, 0, ATLAS_WALL)
			else:
				layer.set_cell(c, 0, ATLAS_FLOOR)


func is_walkable(grid: Vector2i) -> bool:
	var layer := get_layer(0) as TileMapLayer
	if layer.get_cell_source_id(grid) < 0:
		return false
	return layer.get_cell_atlas_coords(grid) != ATLAS_WALL


func grid_to_world_pos(grid: Vector2i) -> Vector2:
	var layer := get_layer(0) as TileMapLayer
	return layer.to_global(layer.map_to_local(grid))


func world_to_grid_pos(global_pos: Vector2) -> Vector2i:
	var layer := get_layer(0) as TileMapLayer
	return layer.local_to_map(layer.to_local(global_pos))
