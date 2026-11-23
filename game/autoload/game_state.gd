extends Node
## Globaler Spielzustand (Autoload „GameState“). Wird in Task 10/11 erweitert.

var abilities: Dictionary = {}


func _init() -> void:
	InputSetup.ensure()


func has_ability(n: String) -> bool:
	return abilities.get(n, false)
