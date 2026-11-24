class_name Building
extends Node2D
## Gebäude aus dem Grafik-Repo (Nachtversion), doppelt so groß dargestellt, damit die Türen
## höher sind als die Figuren. Die Bilddatei bleibt unverändert.
## Der Knoten-Ursprung ist die Unterkante der Türmitte – so liegt die Tür genau auf der Tür-Entität.

const SCALE := 2

var kind := ""
var sprite: Sprite2D
var door: Dictionary


static func create(p_kind: String) -> Building:
	var b := Building.new()
	b.kind = p_kind
	b.scale = Vector2(SCALE, SCALE)
	b.door = CosyArt.meta("buildings/doors/tueren.json")[p_kind]
	b.sprite = Sprite2D.new()
	b.sprite.texture = load(CosyArt.BASE + "buildings/%s_nacht.png" % p_kind)
	b.sprite.centered = false
	b.sprite.position = -Vector2(b.door.x + b.door.w / 2.0, b.door.y + b.door.h)
	b.add_child(b.sprite)
	return b


func door_height_px() -> int:
	return int(door.h) * SCALE
