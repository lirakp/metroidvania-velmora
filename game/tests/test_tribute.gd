extends TestCase


func _hero(equip: Array) -> Combatant:
	var c := Combatant.from_hero("warschick")
	c.equipment.clear()
	for q in equip:
		c.equipment.append(q)
	return c


func _q(type: String, amount: int, when := "turn") -> Dictionary:
	return {"id": type, "slot": "ring", "bonus": {}, "tribute": {"type": type, "amount": amount, "when": when}}


func test_blood_tribute_per_turn() -> void:
	var c := Combatant.from_hero("warschick", ["rostiger_kriegshammer", "lederharnisch"])
	var hp := c.hp
	Tribute.apply(c, "turn")
	assert_eq(c.hp, hp - 4)


func test_use_tribute_not_on_turn() -> void:
	var c := _hero([_q("blut", 4, "use")])
	var hp := c.hp
	Tribute.apply(c, "turn")
	assert_eq(c.hp, hp)
	Tribute.apply(c, "use")
	assert_eq(c.hp, hp - 4)


func test_warmth_stacks_reduce_tempo() -> void:
	var c := Combatant.from_hero("warschick", ["kurzschwert", "frostkettenhemd"])
	Tribute.apply(c, "turn")
	Tribute.apply(c, "turn")
	assert_eq(c.statuses.unterkuehlt, 2)
	assert_eq(c.effective_tempo(), 8 - 4)


func test_mana_and_flesh() -> void:
	var c := _hero([_q("mana", 5), _q("fleisch", 6)])
	Tribute.apply(c, "turn")
	assert_eq(c.mana_s, 35)
	assert_eq(c.max_hp, 54)
	assert_eq(c.max_hp_penalty, 6)


func test_three_types_double_cost() -> void:
	var c := _hero([DB.equipment("rostiger_kriegshammer"), DB.equipment("frostkettenhemd"), _q("ausdauer", 1)])
	assert_eq(Tribute.distinct_types(c), 3)
	var hp := c.hp
	Tribute.apply(c, "turn")
	assert_eq(c.hp, hp - 8)
	assert_eq(c.statuses.unterkuehlt, 2)
