extends TestCase
## Dungeon-Eingang als Portal: davorstellen, [W] drücken. Einweg-Schwelle gilt weiter.

var tree: SceneTree = Engine.get_main_loop()


func _setup(room: String) -> Node2D:
	GameState.reset()
	RoomManager.room_dir = "res://data/rooms"
	BattleLauncher.reset_for_test()
	var world := Node2D.new()
	tree.root.add_child(world)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	RoomManager.attach(world, p)
	RoomManager.go_to(room, "L1")
	RoomManager.block_doors(0.0)
	return world


func _portal() -> Door:
	return RoomManager.current.get_children().filter(func(n): return n is Door and n.is_portal())[0]


func test_portal_has_animations() -> void:
	var w := _setup("kornfeld_08")
	var p := _portal()
	for anim in ["oeffnen", "offen", "durchgang", "schliessen"]:
		assert_true(p.portal_sprite.sprite_frames.has_animation(anim), anim)
	assert_eq(p.portal_sprite.sprite_frames.get_frame_count("offen"), 12)
	w.queue_free()


func test_kornfeld_has_no_side_exit_into_dungeon() -> void:
	var d := RoomDef.load_room("kornfeld_08")
	assert_false(d.exits.any(func(e): return e.target_room.begins_with("blutdungeon")), "Dungeon nur übers Portal")
	assert_false(d.entities.any(func(e): return e.type == "deco" and e.id == "kristall"), "kein sichtbarer Dungeon-Block")
	var inner := RoomDef.load_room("blutdungeon_eingang")
	assert_false(inner.exits.any(func(e): return not e.target_room.begins_with("blutdungeon")))


func test_portal_enters_dungeon_after_animation() -> void:
	var w := _setup("kornfeld_08")
	var p := _portal()
	assert_true(p.try_enter())
	assert_eq(p.portal_sprite.animation, "durchgang")
	await tree.process_frame
	assert_eq(RoomManager.current_def.id, "kornfeld_08", "erst nach der Durchgangs-Animation")
	await tree.create_timer(0.7).timeout
	assert_eq(RoomManager.current_def.id, "blutdungeon_eingang")
	assert_true(GameState.get_flag("dungeon_locked:blutdungeon"))
	w.queue_free()


func test_portal_back_sealed_until_boss_defeated() -> void:
	var w := _setup("kornfeld_08")
	RoomManager.enter_door("blutdungeon_eingang", "portal")
	RoomManager.block_doors(0.0)
	var back := _portal()
	assert_false(back.try_enter(), "versiegelt, solange der Dungeon nicht gelöst ist")
	GameState.clear_dungeon("blutdungeon")
	back.refresh_state()
	assert_true(back.try_enter(), "nach dem Boss offen")
	w.queue_free()
	await tree.create_timer(0.7).timeout  # verzögerter Wechsel darf ins Leere laufen


func test_cleared_dungeon_portal_closed() -> void:
	var w := _setup("kornfeld_08")
	GameState.clear_dungeon("blutdungeon")
	RoomManager.go_to("kornfeld_08", "L1")
	RoomManager.block_doors(0.0)
	assert_false(_portal().try_enter(), "gelöster Dungeon: Portal geschlossen")
	GameState.abilities["zeitsplitter"] = true
	_portal().refresh_state()
	assert_true(_portal().try_enter(), "mit Zeitsplitter wieder offen")
	w.queue_free()
	await tree.create_timer(0.7).timeout  # verzögerter Wechsel darf ins Leere laufen
