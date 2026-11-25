extends TestCase


func test_place_requires_spare() -> void:
	var p := Plaketten.new()
	p.spare = 1
	assert_true(p.place("a", Vector2i(1, 1)))
	assert_eq(p.spare, 0)
	assert_false(p.place("b", Vector2i(1, 1)))
	assert_true(p.place("a", Vector2i(1, 1)), "Ort hat schon eine")
	assert_eq(p.placed.size(), 1)


func test_max_five_replaces_oldest() -> void:
	var p := Plaketten.new()
	p.spare = 5
	for r in ["a", "b", "c", "d", "e"]:
		p.place(r, Vector2i(0, 0))
	assert_false(p.add_spare(), "maximal 5 insgesamt")
	assert_true(p.place("f", Vector2i(0, 0)))
	var rooms := p.placed.map(func(x): return x.room)
	assert_false("a" in rooms)
	assert_true("f" in rooms)
	assert_eq(p.placed.size(), 5)


func test_respawn_last_used() -> void:
	var p := Plaketten.new()
	p.spare = 2
	p.place("a", Vector2i(2, 3))
	p.place("b", Vector2i(4, 5))
	p.use("a")
	assert_eq(p.respawn_point(), {"room": "a", "cell": Vector2i(2, 3)})


func test_roundtrip() -> void:
	var p := Plaketten.new()
	p.spare = 1
	p.place("a", Vector2i(2, 3))
	var q := Plaketten.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_eq(q.respawn_point(), {"room": "a", "cell": Vector2i(2, 3)})
	assert_eq(q.spare, 0)


func test_death_tax_floor() -> void:
	GameState.reset()
	GameState.gold = 95
	GameState.on_death()
	assert_eq(GameState.gold, 86)


func test_respawn_fallback_guild() -> void:
	GameState.reset()
	assert_eq(GameState.on_death(), {"room": "kornburg_gilde", "cell": Vector2i(-1, -1)})


func test_respawn_fallback_cleared_dungeon() -> void:
	GameState.reset()
	RoomManager.room_dir = "res://tests/rooms"
	GameState.plaketten.place("t_b", Vector2i(3, 14))
	GameState.clear_dungeon("td")
	assert_eq(GameState.on_death().room, "kornburg_gilde")
	RoomManager.room_dir = "res://data/rooms"
