extends TestCase


func _c(atk: int, def: int, tempo := 5, hero := true) -> Combatant:
	var c := Combatant.new()
	c.atk = atk
	c.def = def
	c.tempo = tempo
	c.hp = 50
	c.max_hp = 50
	c.is_hero = hero
	c.dmg_type = "schnitt"
	return c


func test_hero_stats_include_equipment() -> void:
	var w := Combatant.from_hero("warschick")
	assert_eq(w.atk, 12)
	assert_eq(w.def, 7)
	assert_eq(Combatant.from_hero("lira").mag, 3)


func test_damage_basic() -> void:
	assert_eq(Damage.compute(_c(9, 0), _c(0, 4), 0, ["schnitt"]), 7)


func test_damage_weakness() -> void:
	var s := BattleState.new()
	s.heroes = [Combatant.from_hero("lira")]
	s.enemies = [Combatant.from_enemy("gruenschleim")]
	s.start("neutral")
	assert_eq(s.cast(s.heroes[0], "funke", s.enemies[0]), 22)


func test_damage_min_one() -> void:
	assert_eq(Damage.compute(_c(1, 0), _c(0, 40), 0, ["schnitt"]), 1)


func test_defend_halves() -> void:
	var t := _c(0, 0)
	t.defending = true
	assert_eq(Damage.compute(_c(10, 0), t, 0, ["schnitt"]), 5)


func test_resist_and_weak_cancel() -> void:
	var t := _c(0, 0)
	t.weak = ["feuer"]
	t.resist = ["schnitt"]
	assert_eq(Damage.compute(_c(10, 0), t, 0, ["feuer", "schnitt"]), 10)


func test_turn_order_tempo_and_ties() -> void:
	var s := BattleState.new()
	var h1 := _c(1, 1, 5)
	var h2 := _c(1, 1, 9)
	var e1 := _c(1, 1, 9, false)
	var e2 := _c(1, 1, 7, false)
	s.heroes = [h1, h2]
	s.enemies = [e1, e2]
	s.start("neutral")
	assert_eq(s.turn_order(), [h2, e1, e2, h1])


func test_erstschlag_enemies_skip_round1() -> void:
	var s := BattleState.new()
	s.heroes = [_c(1, 1, 5)]
	s.enemies = [_c(1, 1, 9, false), _c(1, 1, 9, false)]
	s.start("erstschlag")
	assert_eq(s.turn_order(), [s.heroes[0]])
	assert_eq(s.enemies[0].statuses.get("betaeubt", 0), 1)


func test_ueberfall_enemies_first_round1() -> void:
	var s := BattleState.new()
	var h := _c(1, 1, 20)
	var e := _c(1, 1, 2, false)
	s.heroes = [h]
	s.enemies = [e]
	s.start("ueberfall")
	assert_eq(s.turn_order(), [e, h])


func test_beide_cost_split() -> void:
	var s := BattleState.new()
	var l := Combatant.from_hero("lira")
	s.heroes = [l]
	s.enemies = [Combatant.from_enemy("ghul")]
	s.start("neutral")
	s.cast(l, "dampfstoss", s.enemies[0])
	assert_eq(l.mana_c, 16)
	assert_eq(l.mana_s, 56)
	assert_eq(BattleState.split_cost(5), 3)


func test_cannot_cast_without_mana() -> void:
	var s := BattleState.new()
	var l := Combatant.from_hero("lira")
	l.mana_c = 2
	s.heroes = [l]
	s.enemies = [Combatant.from_enemy("goblin")]
	s.start("neutral")
	assert_false(s.can_cast(l, "funke"))
	assert_eq(s.cast(l, "funke", s.enemies[0]), 0)
	assert_eq(l.mana_c, 2)


func test_combined_rank_is_min() -> void:
	# Dampfstoß (beide): 16 + mag 3 + min(2,5)*2 = 23 - floor(5/2)=2 → 21 gegen Ghul (keine Schwäche)
	var s := BattleState.new()
	var l := Combatant.from_hero("lira")
	s.heroes = [l]
	s.enemies = [Combatant.from_enemy("ghul")]
	s.start("neutral")
	assert_true(s.can_cast(l, "dampfstoss"))
	assert_eq(s.cast(l, "dampfstoss", s.enemies[0]), 21)


func test_heal_capped() -> void:
	var s := BattleState.new()
	var l := Combatant.from_hero("lira")
	l.hp = 40
	s.heroes = [l]
	s.enemies = [Combatant.from_enemy("goblin")]
	s.start("neutral")
	assert_eq(s.cast(l, "heilung", l), 8)
	assert_eq(l.hp, 48)
