class_name RoomBuilder
extends RefCounted
## Baut aus einer RoomDef einen Node2D mit TileMapLayer „Tiles“ (Kollision, Einweg-Plattformen).

const TILE := 16
const ONE_WAY := 3
const HAZARD := 7

static var _tileset: TileSet


static func tileset() -> TileSet:
	if _tileset != null:
		return _tileset
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://art/tiles.png")
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for i in range(1, 15):
		src.create_tile(Vector2i(i, 0))
		var data := src.get_tile_data(Vector2i(i, 0), 0)
		if i in RoomDef.SOLID or i == ONE_WAY:
			var h: float = 5.0 if i == ONE_WAY else float(TILE)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-8, -8), Vector2(8, -8), Vector2(8, -8 + h), Vector2(-8, -8 + h)]))
			if i == ONE_WAY:
				data.set_collision_polygon_one_way(0, 0, true)
	_tileset = ts
	return ts


static func build(def: RoomDef) -> Node2D:
	var root := Node2D.new()
	root.name = "Room_" + def.id
	Backdrop.add_parallax(root, def.biome)
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	layer.tile_set = tileset()
	for y in def.size.y:
		for x in def.size.x:
			var t := def.tile_at(Vector2i(x, y))
			if t != 0:
				layer.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	root.add_child(layer)
	root.set_meta("room_def", def)
	return root


static func cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE)
