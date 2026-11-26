extends TestCase
## Rasten: heilt, Pflanzen wachsen nach, normale Gegner außerhalb der Dungeons kehren zurück.


func _index_of(room: String, type: String) -> int:
	var d := RoomDef.load_room(room)
	for i in d.entities.size():
		if d.entities[i].type == type:
			return i
	return -1


func test_rest_revives_field_enemies() -> void:
	GameState.reset()
	var i := _index_of("kornfeld_01", "enemy")
	GameState.set_flag("defeated:kornfeld_01:%d" % i)
	GameState.rest()
	assert_eq(GameState.get_flag("defeated:kornfeld_01:%d" % i), null)


func test_rest_keeps_dungeon_and_boss() -> void:
	GameState.reset()
	var e := _index_of("blutdungeon_ketten", "enemy")
	var b := _index_of("blutdungeon_boss", "boss")
	assert_true(e >= 0 and b >= 0, "Testdaten")
	GameState.set_flag("defeated:blutdungeon_ketten:%d" % e)
	GameState.set_flag("defeated:blutdungeon_boss:%d" % b)
	GameState.rest()
	assert_true(GameState.get_flag("defeated:blutdungeon_ketten:%d" % e))
	assert_true(GameState.get_flag("defeated:blutdungeon_boss:%d" % b))


func test_rest_keeps_unknown_rooms() -> void:
	GameState.reset()
	GameState.set_flag("defeated:gibt_es_nicht:0")
	GameState.rest()
	assert_true(GameState.get_flag("defeated:gibt_es_nicht:0"))


func test_rest_regrows() -> void:
	GameState.reset()
	GameState.set_flag("geerntet:kornfeld_01:5")
	GameState.set_flag("gesehen_leer:kornfeld_01:5")
	GameState.rest()
	assert_eq(GameState.get_flag("geerntet:kornfeld_01:5"), null)
	assert_true(GameState.get_flag("gesehen_leer:kornfeld_01:5"))


func test_rest_heals_and_signals() -> void:
	GameState.reset()
	GameState.hp["lira"] = 3
	var got := [false]
	var cb := func(): got[0] = true
	GameState.rested.connect(cb)
	GameState.rest()
	GameState.rested.disconnect(cb)
	assert_true(GameState.hp.is_empty())
	assert_true(got[0])


func test_save_spot_rest_uses_game_state() -> void:
	GameState.reset()
	var i := _index_of("kornfeld_01", "enemy")
	GameState.set_flag("defeated:kornfeld_01:%d" % i)
	var s := SaveSpot.new()
	s.choose("rasten")
	assert_eq(GameState.get_flag("defeated:kornfeld_01:%d" % i), null)
	s.free()
