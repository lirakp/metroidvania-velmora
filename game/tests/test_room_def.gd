extends TestCase

const ROW_EMPTY := "..............................\n"
const ROW_FLOOR := "##############################\n"


func _room(header: String, grid_rows: Array, entities := "") -> String:
	return header + "\n---\n" + "".join(grid_rows) + "---\n" + entities


func _grid(special := {}) -> Array:
	var rows := []
	for y in 17:
		var r: String = ROW_FLOOR if y >= 15 else ROW_EMPTY
		if special.has(y):
			r = special[y] + "\n"
		rows.append(r)
	return rows


func test_parse_header_and_grid() -> void:
	var d := RoomDef.parse(_room("id: kornfeld_01\nbiome: kornfeld\narea: kornburg", _grid({14: "@............................."})))
	assert_eq(d.error, "")
	assert_eq(d.id, "kornfeld_01")
	assert_eq(d.biome, "kornfeld")
	assert_eq(d.area, "kornburg")
	assert_eq(d.size, Vector2i(30, 17))
	assert_eq(d.tile_at(Vector2i(0, 15)), 1)
	assert_eq(d.tile_at(Vector2i(0, 0)), 0)
	assert_eq(d.spawns["start"], Vector2i(0, 14))
	assert_false(d.one_way_dungeon)


func test_parse_exits() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: kornfeld\narea: k\nexits: L1=stadt_03:R2, R2=kornfeld_02:L1",
		_grid({14: "1............................2"})))
	assert_eq(d.error, "")
	assert_eq(d.exits.size(), 2)
	assert_eq(d.exits[0], {"id": "L1", "edge": "L", "target_room": "stadt_03", "target_exit_id": "R2", "pos": Vector2i(0, 14)})
	assert_eq(d.exit_by_id("R2").pos, Vector2i(29, 14))


func test_parse_entities_props() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: kornfeld\narea: k\ndungeon: true", _grid(),
		"enemy goblin 12,8 patrol=4\npickup item:rostiger_kriegshammer 7,9\nnpc kartograf 20,9 area=kornburg price=40\n"))
	assert_eq(d.error, "")
	assert_true(d.one_way_dungeon)
	assert_eq(d.entities.size(), 3)
	assert_eq(d.entities[0], {"type": "enemy", "id": "goblin", "pos": Vector2i(12, 8), "props": {"patrol": "4"}})
	assert_eq(d.entities[1].id, "item:rostiger_kriegshammer")
	assert_eq(d.entities[2].props, {"area": "kornburg", "price": "40"})


func test_minimum_size_rejected() -> void:
	var d := RoomDef.parse("id: a\nbiome: k\narea: k\n---\n..........\n..........\n---\n")
	assert_true(d.error != "")


func test_exit_without_marker_rejected() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: k\narea: k\nexits: L3=b:R1", _grid()))
	assert_true(d.error.contains("L3"))


func test_builder_creates_collision_tiles() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: kornfeld\narea: k", _grid()))
	var node := RoomBuilder.build(d)
	var tiles: TileMapLayer = node.get_node("Tiles")
	assert_eq(tiles.get_cell_atlas_coords(Vector2i(3, 16)), Vector2i(1, 0))
	assert_eq(tiles.get_cell_source_id(Vector2i(3, 3)), -1)
	node.free()


func test_builder_has_three_background_layers() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: dungeon_blut\narea: k", _grid()))
	var node := RoomBuilder.build(d)
	var layers := node.get_children().filter(func(n): return n is Parallax2D)
	assert_eq(layers.size(), 3)
	assert_true(layers[0].scroll_scale.x < layers[2].scroll_scale.x, "ferne Ebene bewegt sich langsamer")
	node.free()


func test_new_tiles_parse() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: innen_gilde\narea: k", _grid({14: "hw............................"})))
	assert_eq(d.tile_at(Vector2i(0, 14)), 13)
	assert_eq(d.tile_at(Vector2i(1, 14)), 14)
	assert_true(14 in RoomDef.SOLID and 13 in RoomDef.SOLID)


func test_backdrop_for_battle() -> void:
	var b := Backdrop.make("innen_gilde")
	assert_eq(b.get_child_count(), 3)
	b.free()


func test_deco_and_light_entities_build() -> void:
	var d := RoomDef.parse(_room("id: a\nbiome: stadt\narea: k", _grid(), "deco gildenhaus 14,14\nlight warm 10,10 radius=32\nlight kalt 20,10 radius=24\n"))
	var node := RoomBuilder.build(d)
	EntityFactory.populate(node, d)
	var decos := node.get_children().filter(func(n): return n is Sprite2D and n.has_meta("deco"))
	assert_eq(decos.size(), 1)
	assert_true(decos[0].texture != null)
	var lights := node.get_children().filter(func(n): return n is LightGlow)
	assert_eq(lights.size(), 2)
	assert_eq(lights[0].texture.get_width(), 64)
	node.free()
