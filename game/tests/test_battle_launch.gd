extends TestCase

var tree: SceneTree = Engine.get_main_loop()


func _world(enemy_x: float) -> Array:
	BattleLauncher.reset_for_test()
	var world := Node2D.new()
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 20)
	shape.shape = rect
	floor.position = Vector2(0, 210)
	floor.add_child(shape)
	world.add_child(floor)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	p.position = Vector2(100, 199)
	world.add_child(p)
	var e := FieldEnemy.create(["goblin"], 0, "testraum", 0)
	e.position = Vector2(enemy_x, 199)
	world.add_child(e)
	tree.root.add_child(world)
	for i in 6:
		await tree.physics_frame
	return [world, p, e]


func test_strike_starts_erstschlag() -> void:
	var w = await _world(122)
	assert_eq(BattleLauncher.last_opening, "")
	w[1].strike()
	for i in 4:
		await tree.physics_frame
	assert_eq(BattleLauncher.last_opening, "erstschlag")
	assert_eq(BattleLauncher.last_enemy_ids, ["goblin"])
	w[0].queue_free()


func test_touch_starts_ueberfall() -> void:
	var w = await _world(104)
	assert_eq(BattleLauncher.last_opening, "ueberfall")
	w[0].queue_free()


func test_defeated_enemy_not_respawned() -> void:
	BattleLauncher.reset_for_test()
	GameState.flags.clear()
	var text := "id: testraum\nbiome: kornfeld\narea: k\n---\n"
	for y in 17:
		text += ("#" if y >= 15 else ".").repeat(30) + "\n"
	text += "---\nenemy goblin+goblin 10,14 patrol=3\n"
	var def := RoomDef.parse(text)
	var room := RoomBuilder.build(def)
	EntityFactory.populate(room, def)
	var enemies := room.get_children().filter(func(n): return n is FieldEnemy)
	assert_eq(enemies.size(), 1)
	assert_eq(enemies[0].enemy_ids, ["goblin", "goblin"])
	assert_true(BattleLauncher.start(enemies[0], "neutral"))
	var r := BattleResult.new()
	r.silver = 12
	var gold_before: int = GameState.gold
	BattleLauncher.finish("sieg", r)
	assert_eq(GameState.gold, gold_before + 12)
	room.free()
	var room2 := RoomBuilder.build(def)
	EntityFactory.populate(room2, def)
	assert_eq(room2.get_children().filter(func(n): return n is FieldEnemy).size(), 0)
	room2.free()


func test_grace_after_battle() -> void:
	var w = await _world(300)
	assert_true(BattleLauncher.start(w[2], "neutral"))
	BattleLauncher.finish("flucht", BattleResult.new())
	assert_false(BattleLauncher.start(w[2], "neutral"), "1 s unverwundbar")
	w[0].queue_free()
