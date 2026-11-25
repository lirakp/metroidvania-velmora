class_name Damage
extends RefCounted
## Schadensformel des Rundenkampfs.


static func compute(attacker: Combatant, target: Combatant, power: int, types: Array, offense := -1) -> int:
	var off: int = attacker.atk if offense < 0 else offense
	var dmg := float(maxi(1, power + off - target.def / 2))
	var is_weak := false
	var is_resist := false
	for t in types:
		if t in target.weak:
			is_weak = true
		if t in target.resist:
			is_resist = true
	if is_weak and not is_resist:
		dmg *= 1.5
	elif is_resist and not is_weak:
		dmg *= 0.5
	if target.defending:
		dmg *= 0.5
	return maxi(1, int(floor(dmg)))
