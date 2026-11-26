extends TestCase


func _room(id: String, area: String, exits: String, row14: String) -> RoomDef:
	var t := "id: %s\nbiome: kornfeld\narea: %s\nexits: %s\n---\n" % [id, area, exits]
	for y in 17:
		t += (row14 if y == 14 else ("#" if y >= 15 else ".").repeat(30)) + "\n"
	return RoomDef.parse(t)


func test_layout_positions() -> void:
	var lay := WorldMap.layout("td", "res://tests/rooms")
	assert_eq(lay["t_b"], Rect2i(0, 0, 1, 1))
	assert_eq(lay["t_c"], Rect2i(1, 0, 1, 1))
	assert_false(lay.has("t_a"))


func test_validate_catches_missing_counter_exit() -> void:
	var a := _room("a", "x", "R1=b:L1", ".............................1")
	var b := _room("b", "x", "L1=c:R1", "1.............................")
	var errs := WorldMap.validate_defs({"a": a, "b": b})
	assert_eq(errs.size(), 2)


func test_validate_ok() -> void:
	var a := _room("a", "x", "R1=b:L1", ".............................1")
	var b := _room("b", "x", "L1=a:R1", "1.............................")
	assert_eq(WorldMap.validate_defs({"a": a, "b": b}), [])


func test_validate_all_real_rooms() -> void:
	assert_eq(WorldMap.validate_all("res://data/rooms"), [])
	assert_eq(WorldMap.validate_all("res://tests/rooms"), [])


func test_buy_map_requires_gold() -> void:
	GameState.reset()
	GameState.gold = 30
	assert_false(GameState.buy_map("kornburg", 40))
	assert_eq(GameState.gold, 30)
	GameState.gold = 45
	assert_true(GameState.buy_map("kornburg", 40))
	assert_eq(GameState.gold, 5)
	assert_true(GameState.owned_maps.has("kornburg"))


func test_validate_catches_missing_counter_door() -> void:
	var a := _room("a", "x", "", "..............................")
	a.entities.append({"type": "door", "id": "haus", "pos": Vector2i(3, 14), "props": {"to": "b:aussen"}})
	var b := _room("b", "x", "", "..............................")
	b.entities.append({"type": "door", "id": "aussen", "pos": Vector2i(3, 14), "props": {"to": "a:falsch"}})
	assert_eq(WorldMap.validate_defs({"a": a, "b": b}).size(), 2)
	b.entities[0].props.to = "a:haus"
	assert_eq(WorldMap.validate_defs({"a": a, "b": b}), [])


func test_layout_ignores_interiors() -> void:
	var lay := WorldMap.layout("ta", "res://tests/rooms")
	assert_true(lay.has("t_a"))
	assert_false(lay.has("t_i"))


func test_layout_real_kornburg_starts_outside() -> void:
	var lay := WorldMap.layout("kornburg")
	assert_true(lay.has("stadt_01") and lay.has("kornfeld_08"), "Außenräume auf der Karte")
	assert_false(lay.has("kornburg_gilde") or lay.has("kartograf_haus") or lay.has("muehle_innen"), "keine Innenräume")



func test_birds_eye_layout_of_dungeon() -> void:
	var lay := WorldMap.layout("blutdungeon")
	var at := func(id): return lay[id].position
	assert_eq(at.call("blutdungeon_ketten") - at.call("blutdungeon_eingang"), Vector2i(1, 0), "Osten = rechts")
	assert_eq(at.call("blutdungeon_kreuzgang") - at.call("blutdungeon_ketten"), Vector2i(0, -1), "hinten = oben")
	assert_eq(at.call("blutdungeon_rast") - at.call("blutdungeon_kreuzgang"), Vector2i(0, -1))
	assert_eq(at.call("blutdungeon_boss") - at.call("blutdungeon_vorkammer"), Vector2i(1, 0))
	assert_eq(lay.size(), 15, "alle Dungeon-Räume auf der Karte")


func test_validate_door_directions_must_be_opposite() -> void:
	var a := _room("a", "x", "", "..............................")
	a.entities.append({"type": "door", "id": "h", "pos": Vector2i(3, 14), "props": {"to": "b:v", "richtung": "hinten"}})
	var b := _room("b", "x", "", "..............................")
	b.entities.append({"type": "door", "id": "v", "pos": Vector2i(3, 14), "props": {"to": "a:h", "richtung": "hinten"}})
	assert_eq(WorldMap.validate_defs({"a": a, "b": b}).size(), 2)
	b.entities[0].props.richtung = "vorne"
	assert_eq(WorldMap.validate_defs({"a": a, "b": b}), [])
