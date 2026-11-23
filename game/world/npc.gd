class_name Npc
extends Area2D
## Figur in der Welt: Kartograf (verkauft Gebietskarten) oder Gesprächspartner (Dialog).

var npc_id := ""
var props: Dictionary = {}
var _inside := false
var _hint: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 28)
	s.shape = r
	s.position = Vector2(0, -14)
	add_child(s)
	var art := "res://art/chars/%s.png" % props.get("art", npc_id)
	if ResourceLoader.exists(art):
		var sp := AnimatedSprite2D.new()
		sp.sprite_frames = Player.make_frames(art)
		sp.position = Vector2(0, -16)
		sp.flip_h = true
		sp.play("idle")
		add_child(sp)
	_hint = Label.new()
	_hint.text = "[W]"
	_hint.position = Vector2(-8, -44)
	_hint.visible = false
	BattleScene._style_label(_hint, Color("d9a441"))
	add_child(_hint)
	body_entered.connect(func(b): if b is Player: _inside = true; _hint.visible = true)
	body_exited.connect(func(b): if b is Player: _inside = false; _hint.visible = false)


func _process(_d: float) -> void:
	if _inside and not get_tree().paused and Input.is_action_just_pressed("interagieren"):
		interact()


func interact() -> void:
	if npc_id == "kartograf":
		var area: String = props.get("area", "")
		var price := int(props.get("price", "40"))
		if GameState.owned_maps.has(area):
			ChoiceMenu.toast(self, "„Ihr habt die Karte schon. Ich verkaufe nichts zweimal.“")
			return
		var m := ChoiceMenu.open(self, "Karte von %s – %d Silber kaufen?" % [MapView.AREA_NAMES.get(area, area), price], ["Kaufen", "Nein"])
		m.chosen.connect(func(i):
			if i == 0:
				if GameState.buy_map(area, price):
					ChoiceMenu.toast(self, "Karte gekauft. [M] öffnet sie.")
				else:
					ChoiceMenu.toast(self, "„Kein Silber, keine Karte.“"))
	elif props.has("dialog"):
		DialogBox.show_dialog(self, props.dialog)
