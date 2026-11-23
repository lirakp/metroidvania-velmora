class_name Tribute
extends RefCounted
## Tribut der Ausrüstung (Bibel: Blut, Körperwärme, Ausdauer, Mana, Haut, Fleisch, Sinne, Gift).


static func distinct_types(c: Combatant) -> int:
	var seen := {}
	for q in c.equipment:
		if q.has("tribute"):
			seen[q.tribute.type] = true
	return seen.size()


static func apply(c: Combatant, when: String) -> Array[String]:
	var log: Array[String] = []
	var mult := 2 if distinct_types(c) >= 3 else 1
	for q in c.equipment:
		if not q.has("tribute") or q.tribute.when != when:
			continue
		var amount: int = int(q.tribute.amount) * mult
		match q.tribute.type:
			"blut":
				c.hp = maxi(0, c.hp - amount)
				log.append("%s zahlt %d Blut an %s." % [c.name, amount, q.get("name", "die Ausrüstung")])
			"waerme":
				c.statuses["unterkuehlt"] = int(c.statuses.get("unterkuehlt", 0)) + amount
				log.append("%s friert (Wärme-Tribut)." % c.name)
			"ausdauer":
				c.atk = maxi(0, c.atk - amount)
				log.append("%s verliert Kraft (Ausdauer-Tribut)." % c.name)
			"mana":
				c.mana_s = maxi(0, c.mana_s - amount)
				log.append("%s verliert %d Mana." % [c.name, amount])
			"haut", "fleisch":
				c.max_hp_penalty += amount
				c.max_hp = maxi(1, c.max_hp - amount)
				c.hp = mini(c.hp, c.max_hp)
				log.append("Die Rüstung nimmt sich %s von %s." % ["Haut" if q.tribute.type == "haut" else "Fleisch", c.name])
			"sinne":
				c.statuses["getruebt"] = 1
				log.append("%s sieht nur noch verschwommen." % c.name)
			"gift":
				c.statuses["vergiftet"] = 1
				c.hp = maxi(0, c.hp - amount)
				log.append("%s vergiftet sich selbst (%d)." % [c.name, amount])
	return log
