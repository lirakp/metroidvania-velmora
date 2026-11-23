class_name Player
extends CharacterBody2D
## Spielfigur: Laufen, Springen (Coyote-Zeit, Sprungpuffer), Federfall-Doppelsprung, Feldschlag.

signal field_strike(area: Area2D)

const SPEED := 90.0
const JUMP_VELOCITY := -230.0
const GRAVITY := 600.0
const DOUBLE_JUMP_VELOCITY := -200.0
const COYOTE := 0.1
const JUMP_BUFFER := 0.1
const STRIKE_TIME := 0.25
const STRIKE_COOLDOWN := 0.4
const MAX_FALL := 400.0

## Für Tests: Eingaben kommen aus in_* statt aus Input.
var test_control := false
var in_left := false
var in_right := false
var in_jump := false
var in_jump_held := false
var control_enabled := true

var hero_id := "warschick"
var facing := 1
var strike_box: Area2D
var _coyote := 0.0
var _buffer := 0.0
var _air_jump_used := false
var _strike_timer := 0.0
var _cooldown := 0.0
var _sprite: AnimatedSprite2D
var _striking := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 26)
	shape.shape = rect
	shape.position = Vector2(0, -13)
	add_child(shape)
	strike_box = Area2D.new()
	strike_box.collision_layer = 0
	strike_box.collision_mask = 4
	strike_box.monitoring = false
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(18, 14)
	ss.shape = sr
	strike_box.add_child(ss)
	add_child(strike_box)
	_place_strike_box()
	strike_box.area_entered.connect(func(a: Area2D) -> void: field_strike.emit(a))
	set_hero(hero_id)


func set_hero(id: String) -> void:
	hero_id = id
	if _sprite:
		_sprite.queue_free()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = make_frames("res://art/chars/%s.png" % id)
	_sprite.position = Vector2(0, -16)
	_sprite.play("idle")
	add_child(_sprite)


static func make_frames(path: String) -> SpriteFrames:
	var tex: Texture2D = load(path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var rows := [["idle", 2, 3.0], ["lauf", 4, 10.0], ["sprung", 1, 1.0], ["schlag", 3, 12.0]]
	for r in rows.size():
		var anim: String = rows[r][0]
		sf.add_animation(anim)
		sf.set_animation_speed(anim, rows[r][2])
		sf.set_animation_loop(anim, anim != "schlag")
		for f in int(rows[r][1]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(f * 16, r * 32, 16, 32)
			sf.add_frame(anim, at)
	return sf


func _place_strike_box() -> void:
	strike_box.position = Vector2(14 * facing, -14)


func _read_input() -> Dictionary:
	if test_control:
		return {"x": float(in_right) - float(in_left), "jump": in_jump, "held": in_jump or in_jump_held}
	if not control_enabled:
		return {"x": 0.0, "jump": false, "held": false}
	return {
		"x": Input.get_axis("links", "rechts"),
		"jump": Input.is_action_just_pressed("springen"),
		"held": Input.is_action_pressed("springen"),
	}


func _physics_process(delta: float) -> void:
	var inp := _read_input()
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if is_on_floor():
		_coyote = COYOTE
		_air_jump_used = false
	else:
		_coyote -= delta
	if inp.jump:
		_buffer = JUMP_BUFFER
	else:
		_buffer -= delta
	if _buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			_buffer = 0.0
			_coyote = 0.0
		elif inp.jump and not _air_jump_used and GameState.has_ability("federfall"):
			velocity.y = DOUBLE_JUMP_VELOCITY
			_air_jump_used = true
			_buffer = 0.0
	if not inp.held and velocity.y < -80.0:
		velocity.y = -80.0  # variable Sprunghöhe
	velocity.x = inp.x * SPEED
	if inp.x != 0.0:
		facing = 1 if inp.x > 0 else -1
		_place_strike_box()
	move_and_slide()
	_tick_strike(delta)
	if not test_control and control_enabled and Input.is_action_just_pressed("schlagen"):
		strike()
	_animate(inp.x)


func _tick_strike(delta: float) -> void:
	_cooldown -= delta
	if _strike_timer > 0.0:
		_strike_timer -= delta
		if _strike_timer <= 0.0:
			strike_box.set_deferred("monitoring", false)
			_striking = false


## Startet den Feldschlag. false während der Abklingzeit.
func strike() -> bool:
	if _cooldown > 0.0:
		return false
	_cooldown = STRIKE_COOLDOWN
	_strike_timer = STRIKE_TIME
	strike_box.monitoring = true
	_striking = true
	if _sprite:
		_sprite.play("schlag")
	return true


func _animate(x: float) -> void:
	if _sprite == null:
		return
	_sprite.flip_h = facing < 0
	if _striking:
		return
	var anim := "idle"
	if not is_on_floor():
		anim = "sprung"
	elif x != 0.0:
		anim = "lauf"
	if _sprite.animation != anim:
		_sprite.play(anim)
