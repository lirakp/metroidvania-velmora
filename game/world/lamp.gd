class_name Lamp
extends Node2D
## Animierte Lichtquelle aus dem Grafik-Repo (Laterne, Fackel, Lagerfeuer …) mit additivem Lichtkreis.
## Füße unten mittig am Knoten-Ursprung.

var kind := "strassenlaterne"
var body: AnimatedSprite2D
var glow: AnimatedSprite2D


static func create(p_kind: String) -> Lamp:
	var l := Lamp.new()
	l.kind = p_kind
	l._build()
	return l


func _build() -> void:
	var m: Dictionary = CosyArt.meta("objects/licht/licht.json")[kind]
	var w := int(m.bild[0])
	var h := int(m.bild[1])
	var fps := 1000.0 / float(m.ms_pro_bild)
	body = AnimatedSprite2D.new()
	body.sprite_frames = _strip("objects/licht/%s_anim.png" % kind, w, h, int(m.bilder), fps)
	body.centered = false
	body.position = Vector2(-w / 2.0, -h)
	body.play("an")
	add_child(body)
	var gw := int(m.lichtkreis_groesse[0])
	var gh := int(m.lichtkreis_groesse[1])
	glow = AnimatedSprite2D.new()
	glow.sprite_frames = _strip("objects/licht/%s_lichtkreis.png" % kind, gw, gh, int(m.bilder), fps)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.position = body.position + Vector2(m.lichtpunkt[0], m.lichtpunkt[1])
	glow.z_index = 3
	glow.play("an")
	add_child(glow)
	var light := Stimmung.light("lampe")
	light.position = glow.position
	add_child(light)


static func _strip(rel: String, w: int, h: int, n: int, fps: float) -> SpriteFrames:
	var tex: Texture2D = load(CosyArt.BASE + rel)
	var sf := SpriteFrames.new()
	sf.rename_animation("default", "an")
	sf.set_animation_speed("an", fps)
	sf.set_animation_loop("an", true)
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		sf.add_frame("an", at)
	return sf
