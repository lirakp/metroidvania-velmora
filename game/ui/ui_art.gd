class_name UiArt
extends RefCounted
## Oberflächen-Grafik aus dem Grafik-Repo: Rahmen (9-Slice), Porträts, Schadenszahlen, Banner.

const DIGITS := "0123456789+-!"
const DIGIT_SIZE := Vector2(5, 7)


static func frame(style: String, size: Vector2) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = load(CosyArt.BASE + "ui/rahmen_%s.png" % style)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		n.set_patch_margin(side, 8)
	n.size = size
	return n


static func portrait_frames(sheet: String) -> SpriteFrames:
	var m := CosyArt.meta("portraits/portraits.json")
	var tex: Texture2D = load(CosyArt.BASE + "portraits/%s.png" % sheet)
	var g := int(m.groesse)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var row: int = m.zeilen_ausdruecke.find("neutral")
	for anim_def in [["still", [0]], ["spricht", [0, 1]], ["blinzeln", [2, 0]]]:
		var anim: String = anim_def[0]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, 8.0)
		sf.set_animation_loop(anim, anim == "spricht")
		for col in anim_def[1]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * g, row * g, g, g)
			sf.add_frame(anim, at)
	return sf


static func digit_rect(ch: String) -> Rect2:
	return Rect2(DIGITS.find(ch) * DIGIT_SIZE.x, 0, DIGIT_SIZE.x, DIGIT_SIZE.y)


## Zahl aus Pixel-Ziffern (Stil: normal, kritisch, heilung, mana).
static func number_node(text: String, style := "normal") -> Node2D:
	var root := Node2D.new()
	var tex: Texture2D = load(CosyArt.BASE + "ui/zahlen_%s.png" % style)
	var x := 0.0
	for ch in text:
		if DIGITS.find(ch) < 0:
			continue
		var sp := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = digit_rect(ch)
		sp.texture = at
		sp.centered = false
		sp.position = Vector2(x, 0)
		root.add_child(sp)
		x += DIGIT_SIZE.x + 1
	return root


## Banner (10 Bilder, 112x36): besiegt, dungeon_geloest, auftrag_erledigt.
static func banner(kind: String) -> AnimatedSprite2D:
	var tex: Texture2D = load(CosyArt.BASE + "ui/banner_%s.png" % kind)
	var n := 10
	var w := tex.get_width() / n
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", 12.0)
	sf.set_animation_loop("default", false)
	for i in n:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, tex.get_height())
		sf.add_frame("default", at)
	var sp := AnimatedSprite2D.new()
	sp.name = "Banner"
	sp.sprite_frames = sf
	sp.play("default")
	return sp
