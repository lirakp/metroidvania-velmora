extends TestCase


func test_ranks_roundtrip() -> void:
	var letters := ["D", "C", "B", "A", "S", "SS"]
	for i in letters.size():
		assert_eq(Ranks.from_letter(letters[i]), i + 1, letters[i])
		assert_eq(Ranks.to_letter(i + 1), letters[i])


func test_enemy_values() -> void:
	var g: Dictionary = DB.enemy("ghul")
	assert_eq(g.hp, 48)
	assert_eq(g.rank, 2)
	assert_eq(g.weak, ["licht"])
	assert_eq(DB.enemy("blutwolf_alpha").hp, 140)


func test_hero_and_spell_values() -> void:
	assert_eq(DB.hero("lira").mana_s, 60)
	assert_eq(DB.spell("dampfstoss").cost, 8)
	assert_eq(DB.equipment("rostiger_kriegshammer").tribute.type, "blut")


func test_validate_clean() -> void:
	assert_eq(DB.validate(), [])


func test_validate_catches_unknown_element() -> void:
	var db := DataDB.new()
	db.load_all()
	db.spells["funke"]["elements"] = ["lava"]
	assert_eq(db.validate().size(), 1)
