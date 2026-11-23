class_name Sibling
extends CharacterBody2D
## Das Geschwister: folgt dem Spieler und lässt sich zu Befehlspunkten schicken.

const SPEED := 95.0
const FOLLOW_GAP := 24.0
const TELEPORT_DIST := 160.0
const COMMAND_RANGE := 48.0
const GRAVITY := 600.0

var player: Player
var mode := "follow"  # follow | go | stay
var stay_x := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 26)
	shape.shape = r
	shape.position = Vector2(0, -13)
	add_child(shape)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Player.make_frames("res://art/chars/%s.png" % GameState.companion_id)
	_sprite.position = Vector2(0, -16)
	_sprite.modulate = Color(0.85, 0.85, 0.9)
	_sprite.play("idle")
	add_child(_sprite)


func _solo() -> bool:
	return GameState.get_flag("solo_mode") == true


## Schickt das Geschwister zum nächsten Befehlspunkt (≤ 48 px vom Spieler) oder ruft es zurück.
func command() -> bool:
	if _solo() or player == null:
		return false
	if mode != "follow":
		mode = "follow"
		return true
	var best: SiblingPoint = null
	for n in get_tree().get_nodes_in_group("sibling_points"):
		var pt: SiblingPoint = n
		if pt.global_position.distance_to(player.global_position) <= COMMAND_RANGE:
			if best == null or pt.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
				best = pt
	if best == null:
		return false
	mode = "go"
	stay_x = best.global_position.x
	return true


func _physics_process(delta: float) -> void:
	visible = not _solo()
	if _solo() or player == null:
		set_collision_layer_value(5, false)
		return
	set_collision_layer_value(5, true)
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	var target_x := stay_x
	if mode == "follow":
		target_x = player.position.x - FOLLOW_GAP * player.facing
		if position.distance_to(player.position) > TELEPORT_DIST:
			position = player.position + Vector2(-FOLLOW_GAP * player.facing, 0)
			velocity = Vector2.ZERO
	var dx := target_x - position.x
	if absf(dx) > 2.0:
		velocity.x = signf(dx) * SPEED
	else:
		velocity.x = 0.0
		if mode == "go":
			mode = "stay"
	if is_on_floor() and mode == "follow" and (is_on_wall() or player.position.y < position.y - 24):
		velocity.y = Player.JUMP_VELOCITY
	move_and_slide()
	if not player.test_control and Input.is_action_just_pressed("befehl"):
		command()
	_animate()


func _animate() -> void:
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0
	var anim := "lauf" if absf(velocity.x) > 0.0 and is_on_floor() else ("sprung" if not is_on_floor() else "idle")
	if _sprite.animation != anim:
		_sprite.play(anim)
