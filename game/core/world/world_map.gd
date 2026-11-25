class_name WorldMap
extends RefCounted
## Karten-Layout aus den Ausgängen der Räume und Prüfung, dass alle Ausgänge zusammenpassen.

const UNIT := Vector2i(30, 17)


static func load_defs(dir: String) -> Dictionary:
	var out := {}
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".room"):
			var d := RoomDef.load_file(dir + "/" + f)
			out[f.get_basename()] = d
	return out


static func units(d: RoomDef) -> Vector2i:
	return Vector2i(ceili(float(d.size.x) / UNIT.x), ceili(float(d.size.y) / UNIT.y))


## Raum-ID → Rechteck in Karteneinheiten (Breitensuche ab dem alphabetisch ersten Außenraum des Gebiets).
static func layout(area: String, dir := "res://data/rooms") -> Dictionary:
	var defs := load_defs(dir)
	# Innenräume (ohne Ausgänge) erscheinen nicht auf der Karte; Start ist der erste Außenraum.
	var ids: Array = defs.keys().filter(func(k): return defs[k].area == area and not defs[k].exits.is_empty())
	ids.sort()
	var out := {}
	if ids.is_empty():
		return out
	out[ids[0]] = Rect2i(Vector2i.ZERO, units(defs[ids[0]]))
	var queue: Array = [ids[0]]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		var d: RoomDef = defs[id]
		var r: Rect2i = out[id]
		for e in d.exits:
			if out.has(e.target_room) or not defs.has(e.target_room) or defs[e.target_room].area != area:
				continue
			var t: RoomDef = defs[e.target_room]
			var te := t.exit_by_id(e.target_exit_id)
			if te.is_empty():
				continue
			var tu := units(t)
			var my_cell := Vector2i(e.pos.x / UNIT.x, e.pos.y / UNIT.y)
			var t_cell := Vector2i(te.pos.x / UNIT.x, te.pos.y / UNIT.y)
			var origin := r.position + my_cell - t_cell
			match e.edge:
				"R":
					origin.x = r.position.x + r.size.x
				"L":
					origin.x = r.position.x - tu.x
				"B":
					origin.y = r.position.y + r.size.y
				"T":
					origin.y = r.position.y - tu.y
			out[e.target_room] = Rect2i(origin, tu)
			queue.append(e.target_room)
	return out


static func validate_defs(defs: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for id in defs:
		var d: RoomDef = defs[id]
		if d.error != "":
			errs.append(d.error)
			continue
		if d.id != id:
			errs.append("%s: id '%s' passt nicht zum Dateinamen" % [id, d.id])
		for e in d.exits:
			if not defs.has(e.target_room):
				errs.append("%s:%s → Raum %s fehlt" % [id, e.id, e.target_room])
				continue
			var te: Dictionary = defs[e.target_room].exit_by_id(e.target_exit_id)
			if te.is_empty() or te.target_room != id or te.target_exit_id != e.id:
				errs.append("%s:%s → %s:%s zeigt nicht zurück" % [id, e.id, e.target_room, e.target_exit_id])
		for e in d.entities:
			if e.type != "door":
				continue
			var to: PackedStringArray = String(e.props.get("to", "")).split(":")
			if to.size() != 2 or not defs.has(to[0]):
				errs.append("%s: Tür %s → Ziel fehlt (%s)" % [id, e.id, e.props.get("to", "")])
				continue
			var td: Dictionary = defs[to[0]].door_by_id(to[1])
			if td.is_empty() or td.props.get("to", "") != "%s:%s" % [id, e.id]:
				errs.append("%s: Tür %s → %s zeigt nicht zurück" % [id, e.id, e.props.to])
	return errs


static func validate_all(dir := "res://data/rooms") -> Array[String]:
	return validate_defs(load_defs(dir))
