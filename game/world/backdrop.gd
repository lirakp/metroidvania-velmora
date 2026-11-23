class_name Backdrop
extends RefCounted
## Hintergrund-Ebenen eines Bioms (res://art/bg/<biom>/layer_0..2.png).

const SCROLL := [0.1, 0.3, 0.6]


static func layer_path(biome: String, i: int) -> String:
	return "res://art/bg/%s/layer_%d.png" % [biome, i]


## Statische Ebenen übereinander (für Kampfplatz und Menüs).
static func make(biome: String) -> Node2D:
	var root := Node2D.new()
	root.name = "Backdrop"
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
