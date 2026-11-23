class_name FieldEnemy
extends CharacterBody2D
## Gegner, der sichtbar durch den Raum läuft. Schlag → Erstschlag, Berührung → Überfall.

const SPEED := 30.0
const GRAVITY := 600.0

var enemy_ids: Array = []
var patrol := 0
var room_id := ""
var index := 0
var is_boss := false
var _origin_x := 0.0
var _dir := 1.0
var _sprite: Sprite2D


static func create(ids: Array, p_patrol: int, p_room: String, p_index: int, boss := false) -> FieldEnemy:
	var e: FieldEnemy = load("res://world/field_enemy.tscn").instantiate()
	e.enemy_ids = ids
	e.patrol = p_patrol
	e.room_id = p_room
	e.index = p_index
	e.is_boss = boss
	return e


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_origin_x = position.x
	var size := 64 if is_boss else 32
	var body := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 14) if not is_boss else Vector2(40, 30)
	body.shape = r
	body.position = Vector2(0, -r.size.y / 2)
	add_child(body)
	var hurt := Area2D.new()
	hurt.name = "Hurtbox"
	hurt.collision_layer = 4
	hurt.collision_mask = 0
	var hs := CollisionShape2D.new()
	hs.shape = r
	hs.position = body.position
	hurt.add_child(hs)
	add_child(hurt)
	var touch := Area2D.new()
	touch.name = "Touch"
	touch.collision_layer = 0
	touch.collision_mask = 2
	var ts := CollisionShape2D.new()
	ts.shape = r
	ts.position = body.position
	touch.add_child(ts)
	add_child(touch)
	touch.body_entered.connect(_on_touch)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://art/enemies/%s.png" % DB.enemy(enemy_ids[0]).art)
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, size, size)
	_sprite.position = Vector2(0, -size / 2.0)
	add_child(_sprite)


func _on_touch(body: Node2D) -> void:
	if body is Player:
		BattleLauncher.start(self, "ueberfall")


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	if patrol > 0:
		velocity.x = SPEED * _dir
		var limit := patrol * 16.0
		if (position.x > _origin_x + limit and _dir > 0) or (position.x < _origin_x - limit and _dir < 0) or is_on_wall():
			_dir = -_dir
	else:
		velocity.x = 0.0
	move_and_slide()
	if _sprite:
		_sprite.flip_h = _dir > 0
