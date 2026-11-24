class_name RoomBuilder
extends RefCounted
## Baut aus einer RoomDef einen Raum-Knoten:
## - „Tiles“: unsichtbare Kollision für alle Kacheln (inkl. Einweg-Plattformen)
## - „Terrain“: Boden/Wände aus den Terrain-Kacheln des Grafik-Repos, auf dem um eine halbe Kachel
##   versetzten Raster (Wang-Ecken: NW*1 + NE*2 + SW*4 + SE*8), damit Bild und Kollision deckungsgleich sind
## - „Visual“: alle übrigen Kacheln (Plattformen, Stacheln, Platten, Tore, Innenraum-Kacheln …)

const TILE := 16
const ONE_WAY := 3
const HAZARD := 7

const SRC_OWN := 0
const SRC_PLATFORM := 1
const SRC_SPIKES := 2
## Terrain-Quellen ab 10: Biom → Terrain-Datei im Grafik-Repo
const TERRAINS := {"wiese": 10, "fels": 11, "dungeon_blut": 12}
const BIOME_TERRAIN := {"kornfeld": "wiese", "stadt": "fels", "dungeon_blut": "dungeon_blut", "innen_kammer": "dungeon_blut"}
## Welche eigenen Kachel-IDs pro Terrain als „fest“ gezeichnet werden
const TERRAIN_TILES := {"wiese": [1, 2], "fels": [1, 2, 4], "dungeon_blut": [4, 5]}

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
	ts.add_source(src, SRC_OWN)
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
	_add_atlas(ts, SRC_PLATFORM, CosyArt.BASE + "level/plattformen.png", Vector2i(8, 1))
	_add_atlas(ts, SRC_SPIKES, CosyArt.BASE + "level/stacheln.png", Vector2i(4, 1))
	for t in TERRAINS:
		_add_atlas(ts, TERRAINS[t], CosyArt.BASE + "level/terrain_%s.png" % t, Vector2i(4, 4))
	_tileset = ts
	return ts


static func _add_atlas(ts: TileSet, id: int, path: String, grid: Vector2i) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = load(path)
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, id)
	for y in grid.y:
		for x in grid.x:
			src.create_tile(Vector2i(x, y))


static func terrain_tiles(biome: String) -> Array:
	if not BIOME_TERRAIN.has(biome):
		return []
	return TERRAIN_TILES[BIOME_TERRAIN[biome]]


## Wang-Index an einer Ecke (vertex = obere linke Ecke der Zelle mit diesen Koordinaten).
## Zellen außerhalb des Raums zählen wie die nächste Randzelle (keine Mauer an Ausgängen).
static func wang_index(def: RoomDef, vertex: Vector2i, solid: Array) -> int:
	var idx := 0
	var bits := [[Vector2i(-1, -1), 1], [Vector2i(0, -1), 2], [Vector2i(-1, 0), 4], [Vector2i(0, 0), 8]]
	for b in bits:
		var c: Vector2i = (vertex + b[0]).clamp(Vector2i.ZERO, def.size - Vector2i.ONE)
		if def.tile_at(c) in solid:
			idx += b[1]
	return idx


static func build(def: RoomDef) -> Node2D:
	var root := Node2D.new()
	root.name = "Room_" + def.id
	Backdrop.add_parallax(root, def.biome)
	var collision := TileMapLayer.new()
	collision.name = "Tiles"
	collision.tile_set = tileset()
	collision.visible = false
	var visual := TileMapLayer.new()
	visual.name = "Visual"
	visual.tile_set = tileset()
	var solid := terrain_tiles(def.biome)
	for y in def.size.y:
		for x in def.size.x:
			var c := Vector2i(x, y)
			var t := def.tile_at(c)
			if t == 0:
				continue
			collision.set_cell(c, SRC_OWN, Vector2i(t, 0))
			if t in solid:
				continue
			if t == ONE_WAY:
				var left := def.tile_at(c - Vector2i(1, 0)) == ONE_WAY
				var right := def.tile_at(c + Vector2i(1, 0)) == ONE_WAY
				visual.set_cell(c, SRC_PLATFORM, Vector2i(1 if left and right else (2 if left else 0), 0))
			elif t == HAZARD:
				visual.set_cell(c, SRC_SPIKES, Vector2i(1 if def.biome.begins_with("dungeon") else 0, 0))
			else:
				visual.set_cell(c, SRC_OWN, Vector2i(t, 0))
	root.add_child(collision)
	if not solid.is_empty():
		var terrain := TileMapLayer.new()
		terrain.name = "Terrain"
		terrain.tile_set = tileset()
		terrain.position = Vector2(-TILE / 2.0, -TILE / 2.0)
		var src: int = TERRAINS[BIOME_TERRAIN[def.biome]]
		for y in def.size.y + 1:
			for x in def.size.x + 1:
				var idx := wang_index(def, Vector2i(x, y), solid)
				if idx != 0:
					terrain.set_cell(Vector2i(x, y), src, Vector2i(idx % 4, idx / 4))
		root.add_child(terrain)
	root.add_child(visual)
	root.set_meta("room_def", def)
	return root


static func cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE)
