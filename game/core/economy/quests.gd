class_name Quests
extends RefCounted
## Auftragsbrett der Gilde. Zustand in GameState.quests = {offers, active, roll}.
## Angebote werden beim Rasten neu gewürfelt (Seed = roll); angenommene Aufträge bleiben.

const OFFERS := 3
const MAX_ACTIVE := 3
const BLOOD_TAX := 0.10
const GUILD := "Gilde"
const CORES := ["monsterkern_D", "monsterkern_C"]

static var _templates: Array = []


static func templates() -> Array:
	if _templates.is_empty():
		_templates = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
		for t in _templates:
			t.need = int(t.need)
	return _templates


## Neuer Auftrag aus einer Vorlage, mit Lohn: liefern 3 × Verkaufswert × Menge, jagen 10 je Gegner, Kerne 20 je Kern.
static func from_template(id: String) -> Dictionary:
	var t: Dictionary = templates().filter(func(x): return x.id == id)[0].duplicate()
	match t.kind:
		"liefern":
			t.reward = 3 * int(DB.item(t.item).sell) * t.need
		"jagen":
			t.reward = 10 * t.need
		"kerne":
			t.reward = 20 * t.need
	t.progress = 0
	return t


static func reroll() -> void:
	var q: Dictionary = GameState.quests
	var rng := RandomNumberGenerator.new()
	rng.seed = int(q.roll) + 1
	q.roll = int(q.roll) + 1
	var taken: Array = q.active.map(func(a): return a.id)
	var pool: Array = templates().map(func(t): return t.id).filter(func(id): return not id in taken)
	q.offers = []
	while q.offers.size() < OFFERS and not pool.is_empty():
		var id: String = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		q.offers.append(from_template(id))


## Alter Spielstand oder neues Spiel: Brett hat noch nie gewürfelt.
static func ensure_offers() -> void:
	if GameState.quests.offers.is_empty() and int(GameState.quests.roll) == 0:
		reroll()


static func accept(index: int) -> bool:
	var q: Dictionary = GameState.quests
	if index < 0 or index >= q.offers.size() or q.active.size() >= MAX_ACTIVE:
		return false
	var a: Dictionary = q.offers.pop_at(index)
	a.progress = 0
	q.active.append(a)
	return true


## Fortschritt zur Anzeige: Liefern/Kerne = Vorrat (gedeckelt), Jagen = Siege seit Annahme.
static func progress(a: Dictionary) -> int:
	match a.kind:
		"liefern":
			return mini(GameState.item_count(a.item), a.need)
		"kerne":
			return mini(_cores(), a.need)
	return mini(int(a.progress), a.need)


static func _cores() -> int:
	var n := 0
	for c in CORES:
		n += GameState.item_count(c)
	return n


static func can_turn_in(a: Dictionary) -> bool:
	return progress(a) >= int(a.need)


## Silber nach Blutsteuer (nur Gilden-Aufträge, 10 % abgerundet zugunsten der Gilde).
static func payout(a: Dictionary) -> int:
	var r := int(a.reward)
	return int(floor(r * (1.0 - BLOOD_TAX))) if a.giver == GUILD else r


## Gibt den aktiven Auftrag ab; 0, wenn er noch nicht erfüllt ist.
static func turn_in(index: int) -> int:
	var q: Dictionary = GameState.quests
	if index < 0 or index >= q.active.size():
		return 0
	var a: Dictionary = q.active[index]
	if not can_turn_in(a):
		return 0
	match a.kind:
		"liefern":
			GameState.remove_item(a.item, a.need)
		"kerne":
			var left := int(a.need)
			for c in CORES:
				var take := mini(left, GameState.item_count(c))
				if take > 0:
					GameState.remove_item(c, take)
					left -= take
	var pay := payout(a)
	GameState.gold += pay
	q.active.remove_at(index)
	return pay


static func on_defeated(ids: Array) -> void:
	for a in GameState.quests.active:
		if a.kind == "jagen":
			a.progress = mini(int(a.need), int(a.progress) + ids.count(a.enemy))
