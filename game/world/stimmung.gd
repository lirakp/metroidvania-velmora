class_name Stimmung
extends RefCounted
## Stimmung pro Gebiet aus res://data/stimmung.json: Farbtönung und warme 2D-Lichter.

static var _data: Dictionary = {}
static var _light_tex: Texture2D


static func data() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/stimmung.json"))
	return _data


static func has_tint(biome: String) -> bool:
	return data().toenung.has(biome)


static func tint(biome: String) -> Color:
	return Color(data().toenung.get(biome, "#ffffff"))


static func tint_node(biome: String) -> CanvasModulate:
	if not has_tint(biome):
		return null
	var cm := CanvasModulate.new()
	cm.name = "Toenung"
	cm.color = tint(biome)
	return cm


## Weiches, warmes 2D-Licht (hellt die getönte Umgebung wieder auf).
static func light(kind: String) -> PointLight2D:
	var p: Dictionary = data().licht[kind]
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_light_tex = t
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.color = Color(p.farbe)
	l.energy = float(p.energie)
	l.texture_scale = float(p.groesse)
	return l
