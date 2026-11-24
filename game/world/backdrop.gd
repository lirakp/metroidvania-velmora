class_name Backdrop
extends RefCounted
## Hintergrund-Ebenen eines Bioms (res://art/bg/<biom>/layer_0..2.png).

const SCROLL := [0.1, 0.3, 0.6]
## Biome mit Hintergründen aus dem Grafik-Repo (320x180, waagrecht kachelbar, Unterkante auf Bodenhöhe)
const COSY := {"kornfeld": "dorf_nacht", "stadt": "dorf_nacht", "dungeon_blut": "dungeon_blut"}
const COSY_SCROLL := [0.0, 0.2, 0.4, 0.65]
const COSY_SIZE := Vector2(320, 180)
const GROUND_Y := 240.0


static var _moon_cache := {}


## Mitte des gelben Mondes im Himmel einer Ebenen-Gruppe (Vector2.ZERO = kein Mond). Wird im Bild gesucht,
## damit der Blutmond auch nach Änderungen im Grafik-Repo richtig sitzt.
static func moon_center(group: String) -> Vector2:
	if _moon_cache.has(group):
		return _moon_cache[group]
	var path := CosyArt.BASE + "level/parallax/%s_0_himmel.png" % group
	var center := Vector2.ZERO
	if ResourceLoader.exists(path):
		var img := (load(path) as Texture2D).get_image()
		var lo := Vector2i(9999, 9999)
		var hi := Vector2i(-1, -1)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.r8 > 200 and c.g8 > 190 and c.b8 < 200:
					lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
					hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
		if hi.x >= 0:
			center = Vector2(lo + hi) / 2.0
	_moon_cache[group] = center
	return center


static func _blood_moon(group: String) -> Sprite2D:
	var c := moon_center(group)
	if c == Vector2.ZERO:
		return null
	var sp := Sprite2D.new()
	sp.name = "Blutmond"
	sp.texture = load("res://art/bg/blutmond.png")
	sp.position = c + Vector2(0, GROUND_Y - COSY_SIZE.y)
	return sp


static func cosy_layers(biome: String) -> Array[String]:
	var out: Array[String] = []
	if not COSY.has(biome):
		return out
	for n in CosyArt.meta("level/level.json").parallax[COSY[biome]]:
		out.append(CosyArt.BASE + "level/parallax/%s_%s.png" % [COSY[biome], n])
	return out


static func _sky_fill(first_layer: String) -> ColorRect:
	var img := (load(first_layer) as Texture2D).get_image()
	var r := ColorRect.new()
	r.color = img.get_pixel(0, 0)
	r.size = Vector2(480, 270)
	return r


static func layer_path(biome: String, i: int) -> String:
	return "res://art/bg/%s/layer_%d.png" % [biome, i]


## Statische Ebenen übereinander (für Kampfplatz und Menüs).
static func make(biome: String) -> Node2D:
	var root := Node2D.new()
	root.name = "Backdrop"
	var cl := cosy_layers(biome)
	if not cl.is_empty():
		root.add_child(_sky_fill(cl[0]))
		for p in cl:
			var sp := Sprite2D.new()
			sp.texture = load(p)
			sp.centered = false
			sp.region_enabled = true
			sp.region_rect = Rect2(0, 0, 480, COSY_SIZE.y)
			sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sp.position = Vector2(0, GROUND_Y - COSY_SIZE.y)
			root.add_child(sp)
			if p == cl[0]:
				var moon := _blood_moon(COSY[biome])
				if moon:
					root.add_child(moon)
		return root
	for i in 3:
		var p := layer_path(biome, i)
		if ResourceLoader.exists(p):
			var sp := Sprite2D.new()
			sp.texture = load(p)
			sp.centered = false
			root.add_child(sp)
	return root


## Ebenen als Parallax für Räume.
static func add_parallax(parent: Node, biome: String) -> void:
	var cl := cosy_layers(biome)
	if not cl.is_empty():
		var sky := Parallax2D.new()
		sky.name = "ParallaxHimmel"
		sky.scroll_scale = Vector2.ZERO
		sky.add_child(_sky_fill(cl[0]))
		parent.add_child(sky)
		for i in cl.size():
			var para := Parallax2D.new()
			para.name = "Parallax%d" % i
			para.scroll_scale = Vector2(COSY_SCROLL[i], 0)
			para.repeat_size = Vector2(COSY_SIZE.x, 0)
			para.repeat_times = 3
			var sp := Sprite2D.new()
			sp.texture = load(cl[i])
			sp.centered = false
			sp.position = Vector2(0, GROUND_Y - COSY_SIZE.y)
			para.add_child(sp)
			if i == 0:
				var moon := _blood_moon(COSY[biome])
				if moon:
					para.add_child(moon)
			parent.add_child(para)
		return
	for i in 3:
		var p := layer_path(biome, i)
		if not ResourceLoader.exists(p):
			continue
		var para := Parallax2D.new()
		para.name = "Parallax%d" % i
		para.scroll_scale = Vector2(SCROLL[i], SCROLL[i])
		para.repeat_size = Vector2(480, 0)
		var sp := Sprite2D.new()
		sp.texture = load(p)
		sp.centered = false
		para.add_child(sp)
		parent.add_child(para)
