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


# ---------------------------------------------------------------- Ablauf
const TECHNIK_POWER := 6

var rng := RandomNumberGenerator.new()
var _queue: Array[Combatant] = []
var _turn_started := false


func _ensure_queue() -> void:
	while _queue.is_empty() or not _queue[0].is_alive():
		if not _queue.is_empty():
			_queue.pop_front()
			continue
		if outcome() != "laeuft":
			return
		_queue = turn_order()
		if _queue.is_empty():
			_end_round()


## Der Kämpfer, der jetzt am Zug ist. Beim ersten Aufruf pro Zug wird der Zug-Tribut fällig.
func current_actor() -> Combatant:
	if rng.seed == 0:
		rng.seed = 1
	_ensure_queue()
	if _queue.is_empty():
		return null
	var c: Combatant = _queue[0]
	if not _turn_started:
		_turn_started = true
		c.defending = false
		last_log = Tribute.apply(c, "turn")
		if not c.is_alive():
			_finish_turn()
			return current_actor()
	return c


var last_log: Array[String] = []


## Führt den Zug eines Gegners aus (Helden brauchen submit).
func step() -> Array[String]:
	var c := current_actor()
	if c == null or c.is_hero:
		return []
	var log: Array[String] = last_log.duplicate()
	var act := EnemyAI.choose(self, c)
	if act.target != null:
		var dmg := attack(c, act.target)
		log.append("%s greift %s an: %d Schaden." % [c.name, act.target.name, dmg])
		if c.is_boss and c.id == "blutwolf_alpha":
			c.atk += 1
			log.append("%s wird mit jedem Biss stärker." % c.name)
	_finish_turn()
	return log


## Führt die Aktion des Helden aus, der am Zug ist.
## action: {action: "attack"|"technik"|"cast"|"defend", target?: Combatant, spell?: String}
func submit(action: Dictionary) -> Array[String]:
	var c := current_actor()
	if c == null or not c.is_hero:
		return []
	var log: Array[String] = last_log.duplicate()
	match action.action:
		"attack", "technik":
			var t: Combatant = action.target
			if c.statuses.has("getruebt") and rng.randf() < 0.25:
				log.append("%s verfehlt." % c.name)
			else:
				var dmg := attack(c, t, TECHNIK_POWER if action.action == "technik" else 0)
				log.append("%s trifft %s: %d Schaden." % [c.name, t.name, dmg])
			log.append_array(Tribute.apply(c, "use"))
		"cast":
			var t: Combatant = action.target
			var sp: Dictionary = DB.spell(action.spell)
			var amount := cast(c, action.spell, t)
			if sp.target == "ally":
				log.append("%s wirkt %s: %s heilt %d." % [c.name, sp.name, t.name, amount])
			else:
				log.append("%s wirkt %s auf %s: %d Schaden." % [c.name, sp.name, t.name, amount])
		"defend":
			defend(c)
			log.append("%s verteidigt." % c.name)
	# Review Focus 3: Tribut tötet den Helden nicht im Siegeszug
	if outcome() == "sieg" and c.hp <= 0:
		c.hp = 1
	_finish_turn()
	return log


func _finish_turn() -> void:
	_turn_started = false
	if not _queue.is_empty():
		_queue.pop_front()
	if _queue.is_empty() and outcome() == "laeuft":
		_end_round()


func _end_round() -> void:
	round += 1
	for c in heroes + enemies:
		if c.statuses.has("betaeubt"):
			c.statuses.erase("betaeubt")
	_queue = turn_order()


func outcome() -> String:
	var enemies_alive := enemies.any(func(e): return e.is_alive())
	var heroes_alive := heroes.any(func(h): return h.is_alive())
	if not enemies_alive:
		return "sieg"
	if not heroes_alive:
		return "niederlage"
	return "laeuft"


func result() -> BattleResult:
	var r := BattleResult.new()
	for e in enemies:
		r.xp += e.xp
		r.silver += e.silver
	return r
