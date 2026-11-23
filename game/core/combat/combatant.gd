class_name Combatant
extends RefCounted
## Ein Kämpfer auf dem Kampfplatz (Held oder Gegner).

var id := ""
var name := ""
var art := ""
var is_hero := false
var is_boss := false
var hp := 1
var max_hp := 1
var atk := 0
var def := 0
var tempo := 1
var mag := 0
var mana_c := 0
var max_mana_c := 0
var mana_s := 0
var max_mana_s := 0
var rank_c := 0
var rank_s := 0
var weak: Array = []
var resist: Array = []
var dmg_type := "schnitt"
var statuses: Dictionary = {}
var equipment: Array[Dictionary] = []
var spells: Array = []
var defending := false
var xp := 0
var silver := 0


static func from_hero(hid: String, equipment_ids: Array = []) -> Combatant:
	var d: Dictionary = DB.hero(hid)
	var c := Combatant.new()
	c.id = hid
	c.name = d.name
	c.art = d.art
	c.is_hero = true
	c.max_hp = d.hp
	c.atk = d.atk
	c.def = d.def
	c.tempo = d.tempo
	c.max_mana_c = d.mana_c
	c.max_mana_s = d.mana_s
	c.rank_c = d.rank_c
	c.rank_s = d.rank_s
	c.spells = d.spells.duplicate()
	var ids: Array = equipment_ids if not equipment_ids.is_empty() else [d.weapon, d.armor]
	for eid in ids:
		var q: Dictionary = DB.equipment(eid)
		c.equipment.append(q)
		for k in q.get("bonus", {}):
			c.set(k, c.get(k) + q.bonus[k])
		if q.slot == "waffe":
			c.dmg_type = q.get("dmg_type", "schnitt")
	c.hp = c.max_hp
	c.mana_c = c.max_mana_c
	c.mana_s = c.max_mana_s
	return c


static func from_enemy(eid: String) -> Combatant:
	var d: Dictionary = DB.enemy(eid)
	var c := Combatant.new()
	c.id = eid
	c.name = d.name
	c.art = d.art
	c.is_boss = d.get("boss", false)
	c.max_hp = d.hp
	c.hp = d.hp
	c.atk = d.atk
	c.def = d.def
	c.tempo = d.tempo
	c.mag = d.atk
	c.weak = d.weak.duplicate()
	c.resist = d.resist.duplicate()
	c.dmg_type = d.dmg_type
	c.xp = d.xp
	c.silver = d.silver
	c.rank_c = d.rank
	c.rank_s = d.rank
	return c


func is_alive() -> bool:
	return hp > 0


func effective_tempo() -> int:
	return maxi(1, tempo - 2 * int(statuses.get("unterkuehlt", 0)))
