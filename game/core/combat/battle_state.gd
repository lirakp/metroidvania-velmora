class_name BattleState
extends RefCounted
## Zustand eines Rundenkampfs: Zugfolge, Angriffe, Zauber.

var heroes: Array[Combatant] = []
var enemies: Array[Combatant] = []
var round := 0
var opening := "neutral"


func start(p_opening: String) -> void:
	opening = p_opening
	round = 1
	if opening == "erstschlag":
		for e in enemies:
			e.statuses["betaeubt"] = 1


func turn_order() -> Array[Combatant]:
	var all: Array[Combatant] = []
	for c in heroes + enemies:
		if c.is_alive() and int(c.statuses.get("betaeubt", 0)) == 0:
			all.append(c)
	var idx := {}
	for i in (heroes + enemies).size():
		idx[(heroes + enemies)[i]] = i
	var ambush := opening == "ueberfall" and round == 1
	all.sort_custom(func(a: Combatant, b: Combatant) -> bool:
		if ambush and a.is_hero != b.is_hero:
			return not a.is_hero
		if a.effective_tempo() != b.effective_tempo():
			return a.effective_tempo() > b.effective_tempo()
		if a.is_hero != b.is_hero:
			return a.is_hero
		return idx[a] < idx[b])
	return all


static func allowed_tier(rank: int) -> int:
	return clampi(rank - 1, 1, 4)


static func split_cost(cost: int) -> int:
	return int(ceil(cost / 2.0))


func _flow_rank(c: Combatant, flow: String) -> int:
	match flow:
		"C":
			return c.rank_c
		"S":
			return c.rank_s
		_:
			return mini(c.rank_c, c.rank_s)


func can_cast(c: Combatant, spell_id: String) -> bool:
	var sp: Dictionary = DB.spell(spell_id)
	var rank := _flow_rank(c, sp.flow)
	var needed_tier: int = sp.tier if sp.flow != "beide" else maxi(1, sp.tier / 2)
	if needed_tier > allowed_tier(rank) and spell_id != "heilung":
		return false
	match sp.flow:
		"C":
			return c.mana_c >= sp.cost
		"S":
			return c.mana_s >= sp.cost
		_:
			return c.mana_c >= split_cost(sp.cost) and c.mana_s >= split_cost(sp.cost)


func cast(c: Combatant, spell_id: String, target: Combatant) -> int:
	if not can_cast(c, spell_id):
		return 0
	var sp: Dictionary = DB.spell(spell_id)
	match sp.flow:
		"C":
			c.mana_c -= sp.cost
		"S":
			c.mana_s -= sp.cost
		_:
			c.mana_c -= split_cost(sp.cost)
			c.mana_s -= split_cost(sp.cost)
	var rank := _flow_rank(c, sp.flow)
	if sp.target == "ally":
		var amount: int = mini(sp.power + c.mag + rank * 2, target.max_hp - target.hp)
		target.hp += amount
		return amount
	var dmg := Damage.compute(c, target, sp.power, sp.elements, c.mag + rank * 2)
	target.hp = maxi(0, target.hp - dmg)
	return dmg


func attack(c: Combatant, target: Combatant, power := 0) -> int:
	var dmg := Damage.compute(c, target, power, [c.dmg_type])
	target.hp = maxi(0, target.hp - dmg)
	return dmg


func defend(c: Combatant) -> void:
	c.defending = true
