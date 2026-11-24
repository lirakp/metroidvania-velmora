class_name EntityFactory
extends RefCounted
## Erzeugt die Entitäten eines Raums aus seiner RoomDef.


static func populate(room: Node2D, def: RoomDef) -> void:
	for i in def.entities.size():
		var ent: Dictionary = def.entities[i]
		var pos := RoomBuilder.cell_to_pos(ent.pos)
		var flag := "picked:%s:%d" % [def.id, i]
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
			"pickup":
				if GameState.get_flag(flag):
					continue
				var pk := Pickup.new()
				pk.kind = ent.id
				pk.flag = flag
				pk.position = pos
				room.add_child(pk)
			"dialog":
				if GameState.get_flag("seen:" + ent.id):
					continue
				var tr := DialogTrigger.new()
				tr.dialog_id = ent.id
				tr.position = pos
				room.add_child(tr)
			"deco":
				var tex_path := "res://art/deco/%s.png" % ent.id
				if not ResourceLoader.exists(tex_path):
					push_warning("Deko fehlt: " + tex_path)
					continue
				var sp := Sprite2D.new()
				sp.texture = load(tex_path)
				sp.centered = false
				sp.set_meta("deco", ent.id)
				sp.position = pos - Vector2(sp.texture.get_width() / 2.0, sp.texture.get_height())
				sp.flip_h = ent.props.get("flip", "false") == "true"
				# Hinter den Figuren, aber vor den Hintergrundebenen; front=true vor den Figuren
				sp.z_index = 2 if ent.props.get("front", "false") == "true" else 0
				room.add_child(sp)
			"light":
				var l := LightGlow.create(ent.id == "warm", int(ent.props.get("radius", "32")))
				l.position = pos - Vector2(0, RoomBuilder.TILE)
				room.add_child(l)
			"door":
				var door := Door.new()
				door.door_id = ent.id
				door.target = ent.props.get("to", "")
				door.position = pos
				room.add_child(door)
			"lampe":
				var lamp := Lamp.create(ent.id)
				lamp.position = pos
				room.add_child(lamp)
			"gebaeude":
				var bld := Building.create(ent.id)
				bld.position = pos
				room.add_child(bld)
