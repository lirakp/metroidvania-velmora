class_name Building
extends Node2D
## Gebäude aus dem Grafik-Repo (Nachtversion), doppelt so groß dargestellt, damit die Türen
## höher sind als die Figuren. Die Bilddatei bleibt unverändert.
## Der Knoten-Ursprung ist die Unterkante der Türmitte – so liegt die Tür genau auf der Tür-Entität.

const SCALE := 2

var kind := ""
var sprite: Sprite2D
var door: Dictionary
var door_anim: AnimatedSprite2D

const DOOR_FPS := 14.0


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
	b._add_door_anim()
	var light := Stimmung.light("gebaeude")
	light.position = b.sprite.position + b.sprite.texture.get_size() * Vector2(0.5, 0.6)
	b.add_child(light)
	return b


## Türflügel als Overlay (5 Bilder: zu → offen) genau über der gemalten Tür.
func _add_door_anim() -> void:
	var tex: Texture2D = load(CosyArt.BASE + "buildings/doors/%s_nacht_tuer_overlay.png" % kind)
	var w := int(door.w)
	var h := int(door.h)
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "auf")
	sf.set_animation_speed("auf", DOOR_FPS)
	sf.set_animation_loop("auf", false)
	for i in int(door.bilder):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		sf.add_frame("auf", at)
	door_anim = AnimatedSprite2D.new()
	door_anim.sprite_frames = sf
	door_anim.centered = false
	door_anim.position = sprite.position + Vector2(door.x, door.y)
	door_anim.animation = "auf"
	door_anim.frame = 0
	add_child(door_anim)


func open_door() -> void:
	door_anim.play("auf")


## Dauer der Öffnungsanimation in Sekunden.
func door_open_time() -> float:
	return float(door.bilder) / DOOR_FPS


func door_height_px() -> int:
	return int(door.h) * SCALE
