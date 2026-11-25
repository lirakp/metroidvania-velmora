class_name Plaketten
extends RefCounted
## Seelenplaketten als Rückkehrpunkte: höchstens 5 insgesamt (gesetzt + übrig).

const MAX := 5

var placed: Array[Dictionary] = []  # {room, cell: Vector2i, order}
var spare := 1
var last_used := ""
var _order := 0


func _find(room: String) -> int:
	for i in placed.size():
		if placed[i].room == room:
			return i
	return -1


## Legt an diesem Rastort eine Plakette ab (oder nutzt die vorhandene).
func place(room: String, cell: Vector2i) -> bool:
	if _find(room) >= 0:
		last_used = room
		return true
	if spare > 0:
		spare -= 1
	elif placed.size() >= MAX:
		var oldest := 0
		for i in placed.size():
			if placed[i].order < placed[oldest].order:
				oldest = i
		placed.remove_at(oldest)
	else:
		return false
	_order += 1
	placed.append({"room": room, "cell": cell, "order": _order})
	last_used = room
	return true


func use(room: String) -> void:
	if _find(room) >= 0:
		last_used = room


func respawn_point() -> Dictionary:
	var i := _find(last_used)
	if i < 0:
		return {}
	return {"room": placed[i].room, "cell": placed[i].cell}


func add_spare() -> bool:
	if placed.size() + spare >= MAX:
		return false
	spare += 1
	return true


func to_dict() -> Dictionary:
	var arr := []
	for p in placed:
		arr.append({"room": p.room, "x": p.cell.x, "y": p.cell.y, "order": p.order})
	return {"placed": arr, "spare": spare, "last_used": last_used, "order": _order}


static func from_dict(d: Dictionary) -> Plaketten:
	var p := Plaketten.new()
	p.spare = int(d.get("spare", 1))
	p.last_used = d.get("last_used", "")
	p._order = int(d.get("order", 0))
	for e in d.get("placed", []):
		p.placed.append({"room": e.room, "cell": Vector2i(int(e.x), int(e.y)), "order": int(e.order)})
	return p
