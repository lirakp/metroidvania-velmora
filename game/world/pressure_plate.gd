class_name PressurePlate
extends Area2D
## Druckplatte: aktiv, solange Spieler oder Geschwister darauf steht.

signal changed

var plate_name := ""
var opens := ""
var active := false
var _bodies := 0


func _ready() -> void:
	add_to_group("plates")
	collision_layer = 0
	collision_mask = 2 | 16
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 8)
	s.shape = r
	s.position = Vector2(0, -6)
	add_child(s)
	body_entered.connect(func(_b): _set_count(_bodies + 1))
	body_exited.connect(func(_b): _set_count(_bodies - 1))


func _set_count(n: int) -> void:
	_bodies = maxi(0, n)
	var now := _bodies > 0
	if now != active:
		active = now
		changed.emit()
		for g in get_tree().get_nodes_in_group("gates"):
			g.refresh()
