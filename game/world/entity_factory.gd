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
			"save":
				var sp := SaveSpot.new()
				sp.room_id = def.id
				sp.cell = ent.pos
				sp.kind = ent.props.get("kind", "rastort")
				sp.position = pos
				room.add_child(sp)
			"sibling_point":
				var sp := SiblingPoint.new()
				sp.point_name = ent.id
				sp.position = pos
				room.add_child(sp)
			"plate":
				var pl := PressurePlate.new()
				pl.plate_name = ent.id
				pl.opens = ent.props.get("opens", "")
				pl.position = pos
				room.add_child(pl)
			"gate":
				var g := Gate.new()
				g.gate_name = ent.id
				g.position = pos
				room.add_child(g)
			"npc":
				var n := Npc.new()
				n.npc_id = ent.id
				n.props = ent.props
				n.position = pos
				room.add_child(n)
