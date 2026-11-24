extends TestCase
## Abdunkeln pro Gebiet, Blutmond über dem gelben Mond, warme Lichter.

var tree: SceneTree = Engine.get_main_loop()


func _room(biome: String) -> RoomDef:
	var text := "id: a\nbiome: %s\narea: k\n---\n" % biome
	for y in 17:
		text += ("#" if y >= 15 else ".").repeat(30) + "\n"
	return RoomDef.parse(text + "---\nlampe strassenlaterne 10,14\ngebaeude cottage 20,14\n")


func test_tint_per_biome() -> void:
	var node := RoomBuilder.build(_room("dungeon_blut"))
	var tint: CanvasModulate = node.get_node("Toenung")
	assert_eq(tint.color, Color("#8c6870"))
	node.free()
	var inner := RoomBuilder.build(_room("innen_gilde"))
	assert_false(inner.has_node("Toenung"), "sichere Innenräume ohne Tönung")
	inner.free()


func test_blood_moon_over_cosy_moon() -> void:
	assert_eq(Backdrop.moon_center("dorf_nacht"), Vector2(242, 32))
	var node := RoomBuilder.build(_room("kornfeld"))
	var moon: Sprite2D = node.find_child("Blutmond", true, false)
	assert_true(moon != null)
	assert_eq(moon.position, Vector2(242, 32 + Backdrop.GROUND_Y - Backdrop.COSY_SIZE.y))
	assert_true(moon.texture.get_width() >= 25, "deckt den 25 px großen Mond ab")
	node.free()


func test_lamps_and_buildings_cast_light() -> void:
	var d := _room("stadt")
	var node := RoomBuilder.build(d)
	EntityFactory.populate(node, d)
	var lamp: Lamp = node.get_children().filter(func(n): return n is Lamp)[0]
	var bld: Building = node.get_children().filter(func(n): return n is Building)[0]
	assert_true(lamp.find_children("*", "PointLight2D", true, false).size() == 1)
	assert_true(bld.find_children("*", "PointLight2D", true, false).size() == 1)
	node.free()


func test_battle_is_tinted() -> void:
	var scene: BattleScene = load("res://battle/battle_scene.tscn").instantiate()
	tree.root.add_child(scene)
	scene.setup(["warschick"], ["goblin"], "neutral", "dungeon_blut")
	assert_true(scene.find_child("Toenung", true, false) is CanvasModulate)
	scene.queue_free()
