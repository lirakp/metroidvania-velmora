extends TestCase


func test_battle_scene_autoplay() -> void:
	var tree: SceneTree = Engine.get_main_loop()
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["warschick", "lira"], ["goblin"], "erstschlag", "kornfeld")
	scene.auto_play_for_test()
	var got := []
	scene.battle_finished.connect(func(o, r): got.append(o))
	for i in 600:
		await tree.process_frame
		if not got.is_empty():
			break
	assert_eq(got, ["sieg"])
	scene.queue_free()


func test_spell_menu_greys_unaffordable() -> void:
	var tree: SceneTree = Engine.get_main_loop()
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["lira"], ["goblin"], "erstschlag", "kornfeld")
	scene.state.heroes[0].mana_c = 2
	var entries := scene.spell_entries(scene.state.heroes[0])
	var funke = entries.filter(func(e): return e.id == "funke")[0]
	assert_false(funke.enabled)
	scene.queue_free()


func test_flee_blocked_for_boss() -> void:
	var tree: SceneTree = Engine.get_main_loop()
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["lira"], ["blutwolf_alpha"], "neutral", "dungeon_blut")
	assert_false(scene.can_flee())
	scene.queue_free()
