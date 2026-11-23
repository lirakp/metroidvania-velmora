extends TestCase


func _state(heroes: Array, enemies: Array, opening := "neutral") -> BattleState:
	var s := BattleState.new()
	for h in heroes:
		s.heroes.append(h)
	for e in enemies:
		s.enemies.append(e)
	s.start(opening)
	return s


func test_tribute_no_death_on_victory() -> void:
	var h := Combatant.from_hero("warschick")
	h.equipment.append({"id": "x", "slot": "ring", "bonus": {}, "tribute": {"type": "blut", "amount": 50, "when": "use"}})
	h.hp = 3
	var e := Combatant.from_enemy("goblin")
	e.hp = 1
	var s := _state([h], [e], "erstschlag")
	assert_eq(s.current_actor(), h)
	s.submit({"action": "attack", "target": e})
	assert_eq(s.outcome(), "sieg")
	assert_eq(h.hp, 1)


func test_victory_rewards() -> void:
	var h := Combatant.from_hero("warschick")
	var a := Combatant.from_enemy("goblin")
	var b := Combatant.from_enemy("gruenschleim")
	a.hp = 0
	b.hp = 0
	var s := _state([h], [a, b])
	assert_eq(s.outcome(), "sieg")
	var r := s.result()
	assert_eq(r.xp, 7)
	assert_eq(r.silver, 10)


func test_defeat() -> void:
	var h := Combatant.from_hero("lira")
	h.hp = 1
	var e := Combatant.from_enemy("ghul")
	var s := _state([h], [e], "ueberfall")
	assert_eq(s.current_actor(), e)
	s.step()
	assert_eq(s.outcome(), "niederlage")


func test_ai_targets_lowest_hp() -> void:
	var w := Combatant.from_hero("warschick")
	var l := Combatant.from_hero("lira")
	l.hp = 10
	var e := Combatant.from_enemy("goblin")
	var s := _state([w, l], [e])
	assert_eq(EnemyAI.choose(s, e).target, l)


func test_boss_gains_attack_per_hit() -> void:
	var w := Combatant.from_hero("warschick")
	var b := Combatant.from_enemy("blutwolf_alpha")
	var s := _state([w], [b], "ueberfall")
	s.step()
	assert_eq(b.atk, 15)


func test_round_advances_and_stun_wears_off() -> void:
	var w := Combatant.from_hero("warschick")
	var e := Combatant.from_enemy("ghul")
	var s := _state([w], [e], "erstschlag")
	s.submit({"action": "defend"})
	assert_eq(s.round, 2)
	assert_eq(int(e.statuses.get("betaeubt", 0)), 0)
	assert_true(e in s.turn_order())


func test_hero_action_on_enemy_turn_ignored() -> void:
	var w := Combatant.from_hero("warschick")
	var e := Combatant.from_enemy("ghul")
	var s := _state([w], [e], "ueberfall")
	assert_eq(s.submit({"action": "attack", "target": e}), [])
	assert_eq(e.hp, 48)
