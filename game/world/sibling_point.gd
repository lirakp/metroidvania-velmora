class_name SiblingPoint
extends Node2D
## Befehlspunkt: Hierhin kann das Geschwister geschickt werden.

var point_name := ""


func _ready() -> void:
	add_to_group("sibling_points")
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(0, -7)])
	mark.color = Color("d9a441")
	add_child(mark)
