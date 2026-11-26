extends TestCase
## Monsterkerne als Beute nach einem Sieg.


func _state(ids: Array) -> BattleState:
	var s := BattleState.new()
	for id in ids:
		var e := Combatant.from_enemy(id)
		e.hp = 0
		s.enemies.append(e)
	return s


func test_boss_always_drops_core() -> void:
	for seed in [1, 2, 3, 4]:
		var s := _state(["blutwolf_alpha"])
		s.rng.seed = seed
		assert_eq(s.result().drops, ["monsterkern_C"] as Array[String])


func test_drop_rate_seeded() -> void:
	var s := _state(["goblin", "riesenspinne", "goblin"])
	s.rng.seed = 77
	var ref := RandomNumberGenerator.new()
	ref.seed = 77
	var expected: Array[String] = []
	for k in ["monsterkern_D", "monsterkern_C", "monsterkern_D"]:
		if ref.randf() < 0.5:
			expected.append(k)
	assert_eq(s.result().drops, expected)


func test_some_seed_drops_and_some_does_not() -> void:
	var counts := {}
	for seed in range(1, 30):
		var s := _state(["goblin"])
		s.rng.seed = seed
		counts[s.result().drops.size()] = true
	assert_true(counts.has(0) and counts.has(1))


func test_launcher_adds_drops_and_reports_defeated() -> void:
	GameState.reset()
	BattleLauncher.reset_for_test()
	BattleLauncher.test_mode = true
	BattleLauncher.last_enemy_ids = ["goblin", "goblin"]
	var got := []
	var cb := func(ids): got.append_array(ids)
	BattleLauncher.enemies_defeated.connect(cb)
	var r := BattleResult.new()
	r.drops = ["monsterkern_D", "monsterkern_D"] as Array[String]
	BattleLauncher.finish("sieg", r)
	BattleLauncher.enemies_defeated.disconnect(cb)
	assert_eq(GameState.item_count("monsterkern_D"), 2)
	assert_eq(got, ["goblin", "goblin"])


func test_victory_text_names_cores() -> void:
	var r := BattleResult.new()
	r.silver = 12
	r.drops = ["monsterkern_D"] as Array[String]
	assert_eq(BattleScene.victory_text(r), "Sieg! 12 Silber erbeutet. Monsterkern (D) ×1.")
	r.drops = [] as Array[String]
	assert_eq(BattleScene.victory_text(r), "Sieg! 12 Silber erbeutet.")
