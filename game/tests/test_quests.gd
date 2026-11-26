extends TestCase
## Auftragsbrett: zufällige Aufträge von Dorfbewohnern und Gilde.

var tree: SceneTree = Engine.get_main_loop()


func _offer(id: String) -> void:
	GameState.quests.offers = [Quests.from_template(id)]


func test_templates_from_spec() -> void:
	var t := Quests.templates()
	assert_eq(t.size(), 9)
	var jonte: Dictionary = t.filter(func(q): return q.id == "weizen_jonte")[0]
	assert_eq(jonte.kind, "liefern")
	assert_eq(jonte.need, 5)
	assert_eq(Quests.from_template("weizen_jonte").reward, 15)  # 3 × 1 × 5
	assert_eq(Quests.from_template("jagd_goblin").reward, 30)  # 10 × 3
	assert_eq(Quests.from_template("kerne").reward, 60)  # 20 × 3


func test_reroll_deterministic_and_keeps_active() -> void:
	GameState.reset()
	Quests.reroll()
	var first: Array = GameState.quests.offers.map(func(q): return q.id)
	assert_eq(first.size(), 3)
	assert_eq(GameState.quests.roll, 1)
	GameState.reset()
	Quests.reroll()
	assert_eq(GameState.quests.offers.map(func(q): return q.id), first)
	assert_true(Quests.accept(0))
	var kept: String = GameState.quests.active[0].id
	Quests.reroll()
	assert_eq(GameState.quests.active[0].id, kept)
	assert_false(GameState.quests.offers.any(func(q): return q.id == kept), "angenommener Auftrag doppelt im Angebot")


func test_accept_max_three() -> void:
	GameState.reset()
	for id in ["weizen_jonte", "jagd_goblin", "kerne", "brot_rufus"]:
		_offer(id)
		var ok := Quests.accept(0)
		assert_eq(ok, id != "brot_rufus", id)
	assert_eq(GameState.quests.active.size(), 3)


func test_deliver_turn_in_removes_items_and_pays() -> void:
	GameState.reset()
	_offer("weizen_jonte")
	Quests.accept(0)
	GameState.add_item("weizen", 4)
	assert_false(Quests.can_turn_in(GameState.quests.active[0]))
	assert_eq(Quests.turn_in(0), 0)
	GameState.add_item("weizen", 2)
	var before := GameState.gold
	assert_eq(Quests.turn_in(0), 15)
	assert_eq(GameState.gold, before + 15)
	assert_eq(GameState.item_count("weizen"), 1)
	assert_true(GameState.quests.active.is_empty())


func test_guild_quest_blood_tax() -> void:
	GameState.reset()
	_offer("jagd_goblin")
	Quests.accept(0)
	Quests.on_defeated(["goblin", "goblin", "goblin"])
	var before := GameState.gold
	assert_eq(Quests.turn_in(0), 27)  # 30 − 10 % Blutsteuer
	assert_eq(GameState.gold, before + 27)


func test_hunt_counts_only_after_accept() -> void:
	GameState.reset()
	_offer("jagd_goblin")
	Quests.on_defeated(["goblin", "goblin", "goblin"])
	Quests.accept(0)
	assert_eq(GameState.quests.active[0].progress, 0)
	Quests.on_defeated(["goblin", "gruenschleim"])
	assert_eq(GameState.quests.active[0].progress, 1)
	Quests.on_defeated(["goblin", "goblin", "goblin"])
	assert_eq(GameState.quests.active[0].progress, 3)


func test_cores_accept_c_for_d() -> void:
	GameState.reset()
	_offer("kerne")
	Quests.accept(0)
	GameState.add_item("monsterkern_D", 1)
	GameState.add_item("monsterkern_C", 3)
	assert_true(Quests.can_turn_in(GameState.quests.active[0]))
	assert_eq(Quests.turn_in(0), 54)
	assert_eq(GameState.item_count("monsterkern_D"), 0)
	assert_eq(GameState.item_count("monsterkern_C"), 1)


func test_victory_counts_for_hunt() -> void:
	GameState.reset()
	BattleLauncher.reset_for_test()
	BattleLauncher.test_mode = true
	_offer("jagd_goblin")
	Quests.accept(0)
	BattleLauncher.last_enemy_ids = ["goblin", "goblin"]
	BattleLauncher.finish("sieg", BattleResult.new())
	assert_eq(GameState.quests.active[0].progress, 2)


func test_rest_rerolls() -> void:
	GameState.reset()
	Quests.reroll()
	var roll: int = GameState.quests.roll
	GameState.rest()
	assert_eq(GameState.quests.roll, roll + 1)


func test_quests_saved_and_old_save_board_rolls_on_open() -> void:
	GameState.reset()
	Quests.reroll()
	Quests.accept(1)
	var d := GameState.to_dict()
	GameState.from_dict(d)
	assert_eq(GameState.quests.active.size(), 1)
	assert_eq(GameState.quests.offers.size(), 2)
	GameState.from_dict({})
	assert_true(GameState.quests.offers.is_empty())
	Quests.ensure_offers()
	assert_eq(GameState.quests.offers.size(), 3)


func test_board_menu_lines() -> void:
	GameState.reset()
	_offer("weizen_jonte")
	assert_eq(QuestMenu.lines(), ["Neu: 5 Weizen für Jonte – 15 Silber", "Zurück"])
	Quests.accept(0)
	GameState.add_item("weizen", 2)
	assert_eq(QuestMenu.lines(), ["5 Weizen für Jonte 2/5 – 15 Silber", "Zurück"])


func test_board_entity_in_guild() -> void:
	var d := RoomDef.load_room("kornburg_gilde")
	assert_true(d.entities.any(func(e): return e.type == "auftragsbrett"))
	var b := QuestBoard.new()
	tree.root.add_child(b)
	assert_true(b.get_children().any(func(c): return c is AnimatedSprite2D))
	b.free()
