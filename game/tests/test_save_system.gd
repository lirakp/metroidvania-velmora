extends TestCase

const PATH := "user://test_save.json"


func test_save_load_roundtrip() -> void:
	GameState.reset()
	GameState.gold = 140
	GameState.plaketten.place("kornburg_gilde", Vector2i(5, 14))
	assert_true(SaveSystem.save(GameState.to_dict(), PATH))
	var d := SaveSystem.load_save(PATH)
	assert_eq(int(d.version), 1)
	GameState.reset()
	GameState.from_dict(d)
	assert_eq(GameState.gold, 140)
	assert_eq(GameState.plaketten.respawn_point().room, "kornburg_gilde")


func test_missing_save_empty() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://nope.json"))
	assert_eq(SaveSystem.load_save("user://nope.json"), {})


func test_corrupt_save_reported() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{kaputt")
	f.close()
	assert_eq(SaveSystem.load_save(PATH), {"error": "beschaedigt"})
	f = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{\"gold\": 3}")
	f.close()
	assert_eq(SaveSystem.load_save(PATH), {"error": "beschaedigt"})


func test_save_spot_actions() -> void:
	GameState.reset()
	var spot := SaveSpot.new()
	spot.room_id = "kornburg_gilde"
	spot.cell = Vector2i(5, 14)
	assert_eq(spot.options()[0], "Plakette ablegen (1 übrig)")
	spot.choose("plakette")
	assert_eq(GameState.plaketten.respawn_point(), {"room": "kornburg_gilde", "cell": Vector2i(5, 14)})
	assert_eq(spot.options()[0], "Plakette liegt hier")
	GameState.hp["warschick"] = 3
	spot.choose("rasten")
	assert_true(GameState.hp.is_empty())
	spot.free()



func test_silver_chest_pickup() -> void:
	GameState.reset()
	var before := GameState.gold
	Pickup.collect("silber:40")
	assert_eq(GameState.gold, before + 40)
