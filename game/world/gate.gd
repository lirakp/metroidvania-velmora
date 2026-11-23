class_name Gate
extends StaticBody2D
## Tor: offen, wenn alle Platten, die es öffnen, gleichzeitig aktiv sind.

var gate_name := ""
var is_open := false
var _shape: CollisionShape2D
var _sprite: Sprite2D


func _ready() -> void:
	add_to_group("gates")
	collision_layer = 1
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 48)
	_shape.shape = r
	_shape.position = Vector2(0, -24)
	add_child(_shape)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://art/tiles.png")
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(9 * 16, 0, 16, 16)
	_sprite.scale = Vector2(1, 3)
	_sprite.position = Vector2(0, -24)
	add_child(_sprite)
	refresh()


func refresh() -> void:
	var plates := get_tree().get_nodes_in_group("plates").filter(func(p): return p.opens == gate_name)
	var open := not plates.is_empty() and plates.all(func(p): return p.active)
	if open == is_open:
		return
	is_open = open
	_shape.set_deferred("disabled", open)
	_sprite.visible = not open
