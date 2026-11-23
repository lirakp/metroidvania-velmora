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
