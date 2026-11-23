class_name EntityFactory
extends RefCounted
## Erzeugt die Entitäten eines Raums aus seiner RoomDef.


static func populate(room: Node2D, def: RoomDef) -> void:
	for i in def.entities.size():
		var ent: Dictionary = def.entities[i]
		var pos := RoomBuilder.cell_to_pos(ent.pos)
		match ent.type:
			"enemy", "boss":
				if GameState.get_flag("defeated:%s:%d" % [def.id, i]):
					continue
				var e := FieldEnemy.create(ent.id.split("+"), int(ent.props.get("patrol", "0")), def.id, i, ent.type == "boss")
				e.position = pos
				room.add_child(e)
