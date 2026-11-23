extends TestCase

var tree: SceneTree = Engine.get_main_loop()


func _world() -> Array:
	var world := Node2D.new()
	var floor := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 20)
	shape.shape = rect
	floor.position = Vector2(0, 210)
	floor.add_child(shape)
	world.add_child(floor)
	var p: Player = load("res://world/player.tscn").instantiate()
	p.test_control = true
	p.position = Vector2(100, 199)
	world.add_child(p)
	tree.root.add_child(world)
	for i in 10:
		await tree.physics_frame
	return [world, p]


func _press_jump(p: Player) -> void:
	p.in_jump = true
	await tree.physics_frame
	p.in_jump = false


func _air_jump(p: Player) -> void:
	await _press_jump(p)
	for i in 8:
		await tree.physics_frame
	await _press_jump(p)


func test_single_jump_without_federfall() -> void:
	GameState.abilities.erase("federfall")
	var w = await _world()
	var p: Player = w[1]
	assert_true(p.is_on_floor(), "steht")
	await _air_jump(p)
	assert_true(p.velocity.y > Player.DOUBLE_JUMP_VELOCITY + 10, "kein zweiter Sprung: %s" % p.velocity.y)
	w[0].queue_free()


func test_double_jump_with_federfall() -> void:
	GameState.abilities["federfall"] = true
	var w = await _world()
	var p: Player = w[1]
	await _air_jump(p)
	assert_almost(p.velocity.y, Player.DOUBLE_JUMP_VELOCITY, 1.0)
	GameState.abilities.erase("federfall")
	w[0].queue_free()


func test_strike_hitbox_active_window() -> void:
	var w = await _world()
	var p: Player = w[1]
	assert_true(p.strike())
	assert_true(p.strike_box.monitoring)
	assert_false(p.strike(), "Abklingzeit")
	await tree.create_timer(0.3).timeout
	assert_false(p.strike_box.monitoring)
	await tree.create_timer(0.15).timeout
	assert_true(p.strike())
	w[0].queue_free()
