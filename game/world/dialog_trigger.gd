class_name DialogTrigger
extends Area2D
## Zeigt einen Dialog einmalig, wenn der Spieler die Spalte betritt.

var dialog_id := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 400)
	s.shape = r
	s.position = Vector2(0, -200)
	add_child(s)
	body_entered.connect(func(b):
		if b is Player and not GameState.get_flag("seen:" + dialog_id):
			GameState.set_flag("seen:" + dialog_id)
			DialogBox.show_dialog.call_deferred(self, dialog_id)
			queue_free())
