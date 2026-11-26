class_name SuppliesMenu
extends RefCounted
## „Vorräte“ im Pausenmenü: Gegenstand wählen, dann Held oder Geschwister.


## Einträge für alle Vorräte mit Wirkung, z. B. „Brot ×3“; Mana-Vorräte mit „(nur im Kampf)“.
static func entries() -> Array:
	var out := []
	for id in _ids():
		var it: Dictionary = DB.item(id)
		out.append("%s ×%d%s" % [it.name, GameState.item_count(id), " (nur im Kampf)" if it.battle_only else ""])
	return out


static func _ids() -> Array[String]:
	return Consumables.usable(true)


static func open(parent: Node) -> void:
	var ids := _ids()
	if ids.is_empty():
		ChoiceMenu.toast(parent, "Keine Vorräte.")
		return
	var m := ChoiceMenu.open(parent, "Vorräte", entries() + ["Zurück"], ids.size())
	var i: int = await m.chosen
	if i >= ids.size():
		return
	var id: String = ids[i]
	if DB.item(id).battle_only:
		ChoiceMenu.toast(parent, "Das wirkt nur im Kampf.")
		return
	var party := GameState.party()
	var names := []
	for h in party:
		var mx := Consumables.max_hp_of(h)
		names.append("%s %d/%d LP" % [DB.hero(h).name, int(GameState.hp.get(h, mx)), mx])
	var t := ChoiceMenu.open(parent, DB.item(id).name, names + ["Zurück"], party.size())
	var j: int = await t.chosen
	if j >= party.size():
		return
	var healed := Consumables.apply_field(id, party[j])
	if healed > 0:
		ChoiceMenu.toast(parent, "%s: +%d LP" % [DB.hero(party[j]).name, healed])
	else:
		ChoiceMenu.toast(parent, "%s ist unverletzt." % DB.hero(party[j]).name)
