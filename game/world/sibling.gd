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
	r.size = Vector2(12, 36)
	shape.shape = r
	shape.position = Vector2(0, -18)
	add_child(shape)
	_sprite = CosyArt.character_sprite(DB.hero(GameState.companion_id).cosy)
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
	if mode == "follow":
		target_x = _safe_x(target_x)
	if _in_hazard():
		_rescue()
		return
	var dx := target_x - position.x
	if absf(dx) > 2.0:
		velocity.x = signf(dx) * SPEED
	else:
		velocity.x = 0.0
		if mode == "go":
			mode = "stay"
	if is_on_floor() and mode == "follow" and (is_on_wall() or player.position.y < position.y - 24 or _hazard_ahead(signf(velocity.x), target_x)):
		velocity.y = Player.JUMP_VELOCITY
	move_and_slide()
	if not player.test_control and Input.is_action_just_pressed("befehl"):
		command()
	_animate()


# ---------------------------------------------------------------- Stacheln meiden
func _def() -> RoomDef:
	return RoomManager.current_def


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / RoomBuilder.TILE), floori((p.y - 1) / RoomBuilder.TILE))


func _is_hazard(c: Vector2i) -> bool:
	return _def() != null and _def().tile_at(c) == RoomBuilder.HAZARD


func _in_hazard() -> bool:
	return _is_hazard(_cell(position))


## Liegt direkt vor dem Geschwister eine Stachelgrube und das Ziel dahinter? Dann springen.
func _hazard_ahead(dir: float, target_x: float) -> bool:
	if dir == 0.0:
		return false
	var c := _cell(position)
	var target_cell := floori(target_x / RoomBuilder.TILE)
	for step in [1, 2]:
		var x: int = c.x + int(dir) * step
		var beyond := (target_cell - x) * int(dir) > 0
		if beyond and (_is_hazard(Vector2i(x, c.y + 1)) or _is_hazard(Vector2i(x, c.y))):
			return true
	return false


## Zielpunkt nie über Stacheln: zur nächsten sicheren Spalte auf der Seite des Geschwisters schieben.
func _safe_x(x: float) -> float:
	if _def() == null:
		return x
	var c := _cell(Vector2(x, position.y))
	if not (_is_hazard(Vector2i(c.x, c.y + 1)) or _is_hazard(c)):
		return x
	var dir := -1 if position.x < x else 1
	if absf(position.x - x) < 1.0:
		dir = -int(player.facing)
	for i in range(1, 8):
		var cx := c.x + dir * i
		if not (_is_hazard(Vector2i(cx, c.y + 1)) or _is_hazard(Vector2i(cx, c.y))):
			return cx * RoomBuilder.TILE + RoomBuilder.TILE / 2.0
	return x


## Steht das Geschwister doch in Stacheln, holt es sich sofort neben den Spieler.
func _rescue() -> void:
	position = player.position + Vector2(-FOLLOW_GAP * player.facing, 0)
	if _in_hazard():
		position = player.position
	velocity = Vector2.ZERO


func _animate() -> void:
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0
	var anim := "rennen" if absf(velocity.x) > 0.0 and is_on_floor() else ("fallen" if not is_on_floor() else "stehen")
	if _sprite.animation != anim:
		_sprite.play(anim)
