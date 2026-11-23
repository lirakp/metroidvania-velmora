extends Node
## Globaler Spielzustand (Autoload „GameState“). Wird in Task 10/11 erweitert.

var hero_id := "warschick"
var companion_id := "lira"
var gold := 25
var xp := 0
var abilities: Dictionary = {}
var flags: Dictionary = {}
var equipped: Dictionary = {}


func _init() -> void:
	InputSetup.ensure()


func has_ability(n: String) -> bool:
	return abilities.get(n, false)


func set_flag(k: String, v: Variant = true) -> void:
	flags[k] = v


func get_flag(k: String) -> Variant:
	return flags.get(k, null)


func party() -> Array:
	if get_flag("solo_mode"):
		return [hero_id]
	return [hero_id, companion_id]


func party_equipment() -> Dictionary:
	return equipped
