class_name Consumables
extends RefCounted
## Vorräte benutzen: Wirkung aus items.json („effect“: hp oder mana). Mana gibt es nur im Kampf.


## IDs im Vorrat mit Wirkung, alphabetisch; außerhalb des Kampfes ohne „battle_only“.
static func usable(in_battle: bool) -> Array[String]:
	var out: Array[String] = []
	for id in GameState.items:
		if not DB.items.has(id) or GameState.item_count(id) <= 0:
			continue
		var it: Dictionary = DB.item(id)
		if it.effect.is_empty() or (it.battle_only and not in_battle):
			continue
		out.append(id)
	out.sort()
	return out


## Wirkt im Kampf auf target, verbraucht ein Stück. Gibt die tatsächlich geheilte/aufgefüllte Menge zurück.
static func apply_battle(item_id: String, target: Combatant) -> int:
	if not GameState.remove_item(item_id):
		return 0
	var eff: Dictionary = DB.item(item_id).effect
	if eff.has("hp"):
		var before := target.hp
		target.hp = mini(target.max_hp, target.hp + int(eff.hp))
		return target.hp - before
	if eff.has("mana"):
		var before := maxi(target.mana_c, target.mana_s)
		target.mana_c = mini(target.max_mana_c, target.mana_c + int(eff.mana))
		target.mana_s = mini(target.max_mana_s, target.mana_s + int(eff.mana))
		return maxi(target.mana_c, target.mana_s) - before
	return 0


## Außerhalb des Kampfes: heilt GameState.hp[hero_id]. Volle LP (oder kein Eintrag) → 0, nichts verbraucht.
static func apply_field(item_id: String, hero_id: String) -> int:
	var eff: Dictionary = DB.item(item_id).effect
	if not eff.has("hp") or GameState.item_count(item_id) <= 0:
		return 0
	var max_hp := max_hp_of(hero_id)
	var cur := int(GameState.hp.get(hero_id, max_hp))
	if cur >= max_hp:
		return 0
	GameState.remove_item(item_id)
	var now := mini(max_hp, cur + int(eff.hp))
	GameState.hp[hero_id] = now
	return now - cur


static func max_hp_of(hero_id: String) -> int:
	return Combatant.from_hero(hero_id, GameState.party_equipment().get(hero_id, [])).max_hp
