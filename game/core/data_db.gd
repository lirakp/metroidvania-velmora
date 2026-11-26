class_name DataDB
extends Node
## Lädt die Spieldaten aus res://data/*.json. Als Autoload „DB“ registriert.

const ELEMENTS := ["feuer", "eis", "wasser", "erde", "dendro", "wind", "elektro", "schatten", "licht"]
const PHYSICAL := ["schnitt", "stumpf", "stich"]
const TRIBUTES := ["blut", "waerme", "ausdauer", "mana", "haut", "fleisch", "sinne", "gift"]

var enemies: Dictionary = {}
var heroes: Dictionary = {}
var spells: Dictionary = {}
var equip: Dictionary = {}
var items: Dictionary = {}


func _init() -> void:
	load_all()


func load_all() -> void:
	enemies = _load("res://data/enemies.json", true)
	heroes = _load("res://data/heroes.json", false)
	spells = _load("res://data/spells.json", false)
	equip = _load("res://data/equipment.json", true)
	items = _load("res://data/items.json", false)
	for it in items.values():
		for k in it.effect.keys():
			it.effect[k] = int(it.effect[k])


func _load(path: String, has_rank: bool) -> Dictionary:
	var out := {}
	var arr = JSON.parse_string(FileAccess.get_file_as_string(path))
	for e in arr:
		var d: Dictionary = e
		if has_rank:
			d.rank = Ranks.from_letter(d.rank)
		for k in d.keys():
			if d[k] is float and d[k] == floorf(d[k]):
				d[k] = int(d[k])
		if d.has("tribute"):
			d.tribute.amount = int(d.tribute.amount)
		if d.has("bonus"):
			for k in d.bonus.keys():
				d.bonus[k] = int(d.bonus[k])
		out[d.id] = d
	return out


func enemy(id: String) -> Dictionary:
	return enemies[id]


func hero(id: String) -> Dictionary:
	return heroes[id]


func spell(id: String) -> Dictionary:
	return spells[id]


func equipment(id: String) -> Dictionary:
	return equip[id]


func validate() -> Array[String]:
	var errs: Array[String] = []
	var types := ELEMENTS + PHYSICAL
	for s in spells.values():
		for el in s.elements:
			if not el in ELEMENTS:
				errs.append("Zauber %s: unbekanntes Element %s" % [s.id, el])
	for e in enemies.values():
		if e.rank < 1 or e.rank > 6:
			errs.append("Gegner %s: Rang ungültig" % e.id)
		for t in e.weak + e.resist + [e.dmg_type]:
			if not t in types:
				errs.append("Gegner %s: unbekannter Typ %s" % [e.id, t])
	for q in equip.values():
		if q.rank < 1 or q.rank > 6:
			errs.append("Ausrüstung %s: Rang ungültig" % q.id)
		if q.has("tribute") and not q.tribute.type in TRIBUTES:
			errs.append("Ausrüstung %s: unbekannter Tribut %s" % [q.id, q.tribute.type])
	for h in heroes.values():
		for sid in h.spells:
			if not spells.has(sid):
				errs.append("Held %s: unbekannter Zauber %s" % [h.id, sid])
		for slot in ["weapon", "armor"]:
			if not equip.has(h[slot]):
				errs.append("Held %s: unbekannte Ausrüstung %s" % [h.id, h[slot]])
	return errs


## Stapelbarer Gegenstand (Vorrat, Ware, Beute) aus res://data/items.json.
func item(id: String) -> Dictionary:
	return items[id]
