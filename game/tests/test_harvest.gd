extends TestCase
## Sammelstellen: [W] erntet, die Stelle bleibt leer, nach dem Rasten wächst sie nach.

var tree: SceneTree = Engine.get_main_loop()


func _spot(kind := "beeren_rot", amount := 2) -> HarvestSpot:
	var h := HarvestSpot.new()
	h.kind = kind
	h.amount = amount
	h.flag = "geerntet:test_raum:3"
	tree.root.add_child(h)
	return h


func test_harvest_frames_from_metadata() -> void:
	var sf := CosyArt.harvest_frames("weizen")
	assert_eq(sf.get_frame_count("idle"), 6)
	assert_eq(sf.get_frame_count("ernten"), 6)
	assert_eq(sf.get_frame_count("leer"), 1)
	assert_eq(sf.get_frame_count("nachwachsen"), 5)
	assert_true(sf.get_animation_loop("idle"))
	assert_false(sf.get_animation_loop("ernten"))
	assert_eq(sf.get_frame_texture("idle", 0).get_size(), Vector2(20, 32))


func test_harvest_adds_items_once() -> void:
	GameState.reset()
	var h := _spot()
	assert_true(h.harvest())
	assert_eq(GameState.item_count("beeren_rot"), 2)
	assert_true(GameState.get_flag("geerntet:test_raum:3"))
	assert_false(h.harvest())
	assert_eq(GameState.item_count("beeren_rot"), 2)
	assert_eq(h.sprite.animation, &"ernten")
	h.free()


func test_harvested_spot_spawns_empty() -> void:
	GameState.reset()
	GameState.set_flag("geerntet:test_raum:3")
	var h := _spot()
	assert_eq(h.sprite.animation, &"leer")
	assert_true(GameState.get_flag("gesehen_leer:test_raum:3"))
	h.free()


func test_regrow_after_flag_cleared() -> void:
	GameState.reset()
	GameState.set_flag("gesehen_leer:test_raum:3")
	var h := _spot()
	assert_eq(h.sprite.animation, &"nachwachsen")
	assert_false(GameState.get_flag("gesehen_leer:test_raum:3"))
	h.free()


func test_fresh_spot_idles() -> void:
	GameState.reset()
	var h := _spot()
	assert_eq(h.sprite.animation, &"idle")
	assert_eq(h.sprite.scale, Vector2(2, 2), "doppelt groß wie Gebäude und Requisiten")
	assert_true(h.sprite.is_playing())
	h.free()


func test_no_harvest_while_paused() -> void:
	GameState.reset()
	var h := _spot()
	h._inside = true
	GameState.pause_push()
	assert_false(h.can_interact())
	GameState.pause_reset()
	assert_true(h.can_interact())
	h.free()


func test_glowing_kinds_get_light() -> void:
	GameState.reset()
	var h := _spot("leuchtpilz", 1)
	assert_true(h.get_children().any(func(c): return c is PointLight2D))
	h.free()
	var b := _spot("beeren_rot", 1)
	assert_false(b.get_children().any(func(c): return c is PointLight2D))
	b.free()
