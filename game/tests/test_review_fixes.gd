extends TestCase
## Regressionstests für die Funde der Abschlussprüfung.

var tree: SceneTree = Engine.get_main_loop()


func _overlays(cls) -> Array:
	return tree.root.get_children().filter(func(n): return is_instance_of(n, cls) and not n.is_queued_for_deletion())


func _cleanup() -> void:
	for n in tree.root.get_children():
		if n is CanvasLayer:
			n.queue_free()
	GameState.pause_reset()
	await tree.process_frame


func test_equip_offer_survives_freed_pickup() -> void:
	GameState.reset()
	var host := Node2D.new()
	tree.root.add_child(host)
	Pickup.collect("item:rostiger_kriegshammer", host)
	host.queue_free()
	await tree.process_frame
	var boxes := _overlays(DialogBox)
	assert_eq(boxes.size(), 1, "Hammer-Dialog")
	if boxes.size() == 1:
		boxes[0]._close()
	for i in 3:
		await tree.process_frame
	var menus := _overlays(ChoiceMenu)
	assert_eq(menus.size(), 1, "Anlege-Menü")
	if menus.size() == 1:
		menus[0].close(0)
	await tree.process_frame
	assert_true("rostiger_kriegshammer" in GameState.equipped.get(GameState.hero_id, []))
	await _cleanup()


func test_pause_menu_cancel_continues() -> void:
	var m := ChoiceMenu.open(tree.root, "Pause", ["Weiter", "Zum Titel", "Spiel beenden"], 0)
	var got := []
	m.chosen.connect(func(i): got.append(i))
	await tree.process_frame
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	m._unhandled_input(ev)
	assert_eq(got, [0])
	await _cleanup()


func test_dialog_does_not_advance_on_interact() -> void:
	GameState.reset()
	var box := DialogBox.show_dialog(tree.root, "tut_schlag")
	await tree.process_frame
	var ev := InputEventAction.new()
	ev.action = "interagieren"
	ev.pressed = true
	box._unhandled_input(ev)
	assert_eq(box._i, 0)
	await _cleanup()


func test_npc_has_cooldown_after_dialog() -> void:
	GameState.reset()
	var npc := Npc.new()
	npc.npc_id = "gildenmeisterin"
	npc.props = {"dialog": "gilde_rat"}
	tree.root.add_child(npc)
	npc.interact()
	await tree.process_frame
	var boxes := _overlays(DialogBox)
	assert_eq(boxes.size(), 1)
	boxes[0]._close()
	assert_false(npc.can_interact(), "gleich nach dem Schließen gesperrt")
	await tree.create_timer(0.4).timeout
	assert_true(npc.can_interact())
	npc.queue_free()
	await _cleanup()


func test_pause_counter() -> void:
	GameState.pause_reset()
	GameState.pause_push()
	GameState.pause_push()
	GameState.pause_pop()
	assert_true(tree.paused, "noch ein Overlay offen")
	GameState.pause_pop()
	assert_false(tree.paused)
	GameState.pause_pop()
	assert_false(tree.paused, "nie negativ")
	GameState.pause_push()
	assert_true(tree.paused)
	GameState.pause_reset()


func test_no_battle_while_paused() -> void:
	BattleLauncher.reset_for_test()
	var e := FieldEnemy.create(["goblin"], 0, "x", 0)
	tree.root.add_child(e)
	GameState.pause_push()
	assert_false(BattleLauncher.start(e, "neutral"))
	GameState.pause_reset()
	assert_true(BattleLauncher.start(e, "neutral"))
	BattleLauncher.busy = false
	e.queue_free()


func test_resolve_respawn_missing_room() -> void:
	GameState.reset()
	GameState.plaketten.place("gibt_es_nicht", Vector2i(3, 3))
	assert_eq(GameState.resolve_respawn().room, "kornburg_gilde")


func test_resolve_respawn_valid() -> void:
	GameState.reset()
	GameState.plaketten.place("blutdungeon_rast", Vector2i(17, 14))
	assert_eq(GameState.resolve_respawn(), {"room": "blutdungeon_rast", "cell": Vector2i(17, 14)})
	GameState.clear_dungeon("blutdungeon")
	assert_eq(GameState.resolve_respawn().room, "kornburg_gilde")


func test_title_offers_continue_for_corrupt_save() -> void:
	var path := "user://test_corrupt.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{kaputt")
	f.close()
	var t := TitleMenu.new()
	t.save_path = path
	tree.root.add_child(t)
	assert_true(t._enabled(1), "Fortsetzen aktiv, damit der Fehler gemeldet wird")
	t.queue_free()
