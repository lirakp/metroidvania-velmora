class_name EnemyAI
extends RefCounted
## Einfache Gegner-KI: greift den Helden mit den wenigsten LP an.


static func choose(state: BattleState, enemy: Combatant) -> Dictionary:
	var target: Combatant = null
	for h in state.heroes:
		if h.is_alive() and (target == null or h.hp < target.hp):
			target = h
	return {"action": "attack", "target": target}
