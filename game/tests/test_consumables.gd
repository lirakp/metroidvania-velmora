extends TestCase
## Vorräte benutzen: im Kampf (Menüpunkt „Gegenstand“) und im Pausenmenü („Vorräte“).

var tree: SceneTree = Engine.get_main_loop()


func test_battle_item_heals_and_consumes() -> void:
	GameState.reset()
	GameState.add_item("brot", 2)
	var c := Combatant.from_hero("lira")
	c.hp = 10
	assert_eq(Consumables.apply_battle("brot", c), 30)
	assert_eq(c.hp, 40 if c.max_hp >= 40 else c.max_hp)
	assert_eq(GameState.item_count("brot"), 1)


func test_battle_item_caps_at_max_hp() -> void:
	GameState.reset()
	GameState.add_item("heil_klein")
	var c := Combatant.from_hero("lira")
	c.hp = c.max_hp - 5
	assert_eq(Consumables.apply_battle("heil_klein", c), 5)
	assert_eq(c.hp, c.max_hp)


func test_mana_item_fills_both_flows() -> void:
	GameState.reset()
	GameState.add_item("pilz")
	var c := Combatant.from_hero("lira")
	c.mana_c = 0
	c.mana_s = 0
	Consumables.apply_battle("pilz", c)
	assert_eq(c.mana_c, mini(5, c.max_mana_c))
	assert_eq(c.mana_s, mini(5, c.max_mana_s))


func test_mana_item_only_in_battle() -> void:
	GameState.reset()
	GameState.add_item("pilz")
	GameState.add_item("beeren_rot")
	GameState.add_item("weizen")
	assert_eq(Consumables.usable(true), ["beeren_rot", "pilz"] as Array[String])
	assert_eq(Consumables.usable(false), ["beeren_rot"] as Array[String])


func test_field_item_full_hp_not_consumed() -> void:
	GameState.reset()
	GameState.add_item("brot")
	assert_eq(Consumables.apply_field("brot", "lira"), 0)
	assert_eq(GameState.item_count("brot"), 1)


func test_field_item_heals_stored_hp() -> void:
	GameState.reset()
	GameState.add_item("beeren_rot")
	GameState.hp["lira"] = 5
	assert_eq(Consumables.apply_field("beeren_rot", "lira"), 8)
	assert_eq(GameState.hp["lira"], 13)
	assert_eq(GameState.item_count("beeren_rot"), 0)


func test_submit_item_action_logs_and_ends_turn() -> void:
	GameState.reset()
	GameState.add_item("brot")
	var s := BattleState.new()
	s.heroes.append(Combatant.from_hero("lira"))
	s.enemies.append(Combatant.from_enemy("goblin"))
	s.start("erstschlag")
	while not s.current_actor().is_hero:
		s.step()
	var h := s.current_actor()
	h.hp = 5
	var log := s.submit({"action": "item", "item": "brot", "target": h})
	assert_true(log.has("%s isst Brot: +30 LP." % h.name), str(log))
	assert_eq(h.hp, mini(35, h.max_hp))


func test_menu_item_enabled_only_with_supplies() -> void:
	GameState.reset()
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["lira"], ["goblin"], "erstschlag", "kornfeld")
	var gi := BattleScene.MENU.find("Gegenstand")
	assert_false(scene._menu_enabled(gi))
	GameState.add_item("apfel")
	assert_true(scene._menu_enabled(gi))
	scene.queue_free()


func test_pause_supply_options() -> void:
	GameState.reset()
	GameState.add_item("brot", 3)
	GameState.add_item("pilz")
	assert_eq(SuppliesMenu.entries(), ["Brot ×3", "Waldpilz ×1 (nur im Kampf)"])
