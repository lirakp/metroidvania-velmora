extends TestCase
## Vorrat (stapelbare Gegenstände) und ihre Daten.

const IDS := ["weizen", "beeren_rot", "blaubeeren", "pilz", "leuchtpilz", "manablume", "heilkraut", "apfel",
	"brot", "heil_klein", "mana_klein", "monsterkern_D", "monsterkern_C"]


func test_items_from_spec() -> void:
	for id in IDS:
		assert_true(DB.items.has(id), "fehlt: " + id)
	assert_eq(DB.item("monsterkern_D").sell, 15)
	assert_eq(DB.item("monsterkern_C").sell, 35)
	assert_eq(DB.item("brot").buy, 12)
	assert_eq(DB.item("brot").effect, {"hp": 30})
	assert_eq(DB.item("weizen").effect, {})
	assert_eq(DB.item("weizen").buy, 0)
	assert_true(DB.item("pilz").battle_only)
	assert_false(DB.item("beeren_rot").battle_only)
	assert_eq(DB.item("heil_klein").effect, {"hp": 50})
	assert_eq(DB.item("mana_klein").effect, {"mana": 25})
	assert_false(DB.items.has("gegengift_klein"))


func test_add_remove_count() -> void:
	GameState.reset()
	GameState.add_item("weizen", 2)
	assert_eq(GameState.item_count("weizen"), 2)
	assert_false(GameState.remove_item("weizen", 3))
	assert_eq(GameState.item_count("weizen"), 2)
	assert_true(GameState.remove_item("weizen", 2))
	assert_eq(GameState.item_count("weizen"), 0)
	assert_false(GameState.items.has("weizen"))


func test_items_saved_and_old_save_loads() -> void:
	GameState.reset()
	GameState.add_item("brot", 3)
	var d := GameState.to_dict()
	GameState.reset()
	assert_eq(GameState.item_count("brot"), 0)
	GameState.from_dict(d)
	assert_eq(GameState.item_count("brot"), 3)
	GameState.from_dict({})
	assert_eq(GameState.items, {})


func test_every_item_and_equipment_has_icon() -> void:
	for id in DB.items.keys() + DB.equip.keys():
		var t := CosyArt.item_icon(id)
		assert_true(t != null, "Icon fehlt: " + id)
		if t:
			assert_eq(t.get_size(), Vector2(16, 16), id)


func test_icon_regions_follow_metadata() -> void:
	# brot ist das 1. Icon in essen_kraeuter, weizen hat icon_index 3 im Sammel-Streifen
	var brot: AtlasTexture = CosyArt.item_icon("brot")
	assert_eq(brot.region, Rect2(0, 0, 16, 16))
	var weizen: AtlasTexture = CosyArt.item_icon("weizen")
	assert_eq(weizen.region, Rect2(48, 0, 16, 16))
	var schwert: AtlasTexture = CosyArt.item_icon("kurzschwert")
	assert_eq(schwert.region, Rect2(0, 0, 16, 16))
