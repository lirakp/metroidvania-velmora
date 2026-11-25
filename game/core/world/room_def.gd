class_name RoomDef
extends RefCounted
## Ein Raum aus einer .room-Textdatei (Kopf, Gitter, Entitäten). Siehe res://data/rooms/README.md.

const MIN_SIZE := Vector2i(30, 17)
const TILE_CHARS := {".": 0, "#": 1, "=": 2, "-": 3, "S": 4, "B": 5, "x": 6, "^": 7, "p": 8, "T": 9, "A": 11, "G": 12, "h": 13, "w": 14}
const SOLID := [1, 2, 4, 5, 6, 9, 13, 14]

var id := ""
var biome := ""
var area := ""
var size := Vector2i.ZERO
var tiles := PackedInt32Array()
var exits: Array[Dictionary] = []
var spawns: Dictionary = {}
var entities: Array[Dictionary] = []
var one_way_dungeon := false
var error := ""


static func load_file(path: String) -> RoomDef:
	var d := parse(FileAccess.get_file_as_string(path))
	if d.error != "":
		d.error = "%s: %s" % [path, d.error]
	return d


static func load_room(room_id: String) -> RoomDef:
	return load_file("res://data/rooms/%s.room" % room_id)


static func parse(text: String) -> RoomDef:
	var d := RoomDef.new()
	var parts := text.split("---\n")
	if parts.size() < 2:
		d.error = "Kopf oder Gitter fehlt"
		return d
	var header := {}
	for line in parts[0].split("\n"):
		var i := line.find(":")
		if i > 0:
			header[line.substr(0, i).strip_edges()] = line.substr(i + 1).strip_edges()
	d.id = header.get("id", "")
	d.biome = header.get("biome", "")
	d.area = header.get("area", "")
	d.one_way_dungeon = header.get("dungeon", "false") == "true"
	var rows: Array[String] = []
	for r in parts[1].split("\n"):
		if r.length() > 0:
			rows.append(r)
	if rows.is_empty():
		d.error = "Gitter leer"
		return d
	d.size = Vector2i(rows[0].length(), rows.size())
	if d.size.x < MIN_SIZE.x or d.size.y < MIN_SIZE.y:
		d.error = "Raum zu klein (%dx%d, mindestens %dx%d)" % [d.size.x, d.size.y, MIN_SIZE.x, MIN_SIZE.y]
		return d
	var markers := {}
	d.tiles.resize(d.size.x * d.size.y)
	for y in rows.size():
		if rows[y].length() != d.size.x:
			d.error = "Zeile %d hat falsche Länge" % (y + 1)
			return d
		for x in d.size.x:
			var ch: String = rows[y][x]
			var t := 0
			if TILE_CHARS.has(ch):
				t = TILE_CHARS[ch]
			elif ch == "@":
				d.spawns["start"] = Vector2i(x, y)
			elif ch.is_valid_int():
				if not markers.has(ch):
					markers[ch] = Vector2i(x, y)
			else:
				d.error = "Unbekanntes Zeichen '%s' in Zeile %d" % [ch, y + 1]
				return d
			d.tiles[y * d.size.x + x] = t
	if header.has("exits") and header.exits != "":
		for spec in header.exits.split(","):
			var kv: PackedStringArray = spec.strip_edges().split("=")
			var target: PackedStringArray = kv[1].split(":")
			var eid: String = kv[0]
			var digit: String = eid.substr(1)
			if not markers.has(digit):
				d.error = "Ausgang %s hat keine Markierung %s im Gitter" % [eid, digit]
				return d
			d.exits.append({"id": eid, "edge": eid.substr(0, 1), "target_room": target[0], "target_exit_id": target[1], "pos": markers[digit]})
	if parts.size() > 2:
		for line in parts[2].split("\n"):
			var tok: PackedStringArray = line.strip_edges().split(" ", false)
			if tok.size() < 3:
				continue
			var xy: PackedStringArray = tok[2].split(",")
			if xy.size() != 2:
				d.error = "Entität ohne Position: %s" % line
				return d
			var props := {}
			for i in range(3, tok.size()):
				var kv: PackedStringArray = tok[i].split("=")
				if kv.size() > 1:
					props[kv[0]] = kv[1]
				else:
					props[kv[0]] = "true"
			d.entities.append({"type": tok[0], "id": tok[1], "pos": Vector2i(int(xy[0]), int(xy[1])), "props": props})
	return d


func tile_at(p: Vector2i) -> int:
	if p.x < 0 or p.y < 0 or p.x >= size.x or p.y >= size.y:
		return 1
	return tiles[p.y * size.x + p.x]


## Tür-Entität (Durchgang in den Hintergrund) nach ID; {} wenn keine.
func door_by_id(did: String) -> Dictionary:
	for e in entities:
		if e.type == "door" and e.id == did:
			return e
	return {}


func exit_by_id(eid: String) -> Dictionary:
	for e in exits:
		if e.id == eid:
			return e
	return {}


## Kachel, auf die der Spieler beim Betreten durch diesen Ausgang gesetzt wird.
func arrival_cell(eid: String) -> Vector2i:
	var e := exit_by_id(eid)
	match e.edge:
		"L":
			return e.pos + Vector2i(1, 0)
		"R":
			return e.pos - Vector2i(1, 0)
		"T":
			return e.pos + Vector2i(0, 1)
		_:
			return e.pos - Vector2i(0, 2)
