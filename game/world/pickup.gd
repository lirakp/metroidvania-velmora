class_name Pickup
extends Area2D
## Aufsammelbares: federfall, plakette, item:<id>, map:<gebiet>.

var kind := ""
var flag := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 16)
	s.shape = r
	s.position = Vector2(0, -8)
	add_child(s)
	var icon := Polygon2D.new()
	if kind == "plakette":
		var sp := Sprite2D.new()
		sp.texture = load("res://art/ui/plakette.png")
		sp.position = Vector2(0, -8)
		add_child(sp)
	elif kind == "federfall":
		icon.polygon = PackedVector2Array([Vector2(0, -16), Vector2(4, -8), Vector2(1, -2), Vector2(-3, -9)])
		icon.color = Color("f0d9a0")
		add_child(icon)
	elif kind.begins_with("map:"):
		icon.polygon = PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(6, -3), Vector2(-6, -3)])
		icon.color = Color("8c6a48")
		add_child(icon)
	else:
		icon.polygon = PackedVector2Array([Vector2(-1, -16), Vector2(1, -16), Vector2(1, -6), Vector2(5, -6), Vector2(5, -2), Vector2(-5, -2), Vector2(-5, -6), Vector2(-1, -6)])
		icon.color = Color("8b93a3")
		add_child(icon)
	var glow := create_tween().set_loops()
	glow.tween_property(self, "modulate", Color(1.4, 1.3, 1.0), 0.6)
	glow.tween_property(self, "modulate", Color(1, 1, 1), 0.6)
	body_entered.connect(_on_body)


func _on_body(b: Node2D) -> void:
	if not b is Player:
		return
	GameState.set_flag(flag)
	collect(kind, self)
	queue_free()


## Wendet die Wirkung an (auch für Tests ohne Szene nutzbar).
static func collect(k: String, ctx: Node = null) -> void:
	var dialog := ""
	if k == "federfall":
		GameState.abilities["federfall"] = true
		dialog = "federfall"
	elif k == "plakette":
		GameState.plaketten.add_spare()
		dialog = "plakette"
	elif k.begins_with("map:"):
		GameState.owned_maps[k.substr(4)] = true
		dialog = "karte_gefunden"
	elif k.begins_with("item:"):
		var item := k.substr(5)
		GameState.inventory.append(item)
		if ctx and ctx.is_inside_tree():
			_offer_equip(ctx, item)
		return
	if ctx and ctx.is_inside_tree() and dialog != "":
		DialogBox.show_dialog(ctx, dialog)


static func _offer_equip(ctx: Node, item: String) -> void:
	var q: Dictionary = DB.equipment(item)
	var box := DialogBox.show_dialog(ctx, "hammer" if item == "rostiger_kriegshammer" else "")
	await box.finished
	var names := [DB.hero(GameState.hero_id).name, DB.hero(GameState.companion_id).name, "Nicht anlegen"]
	var m := ChoiceMenu.open(ctx.get_tree().root, "%s anlegen für:" % q.name, names)
	var i: int = await m.chosen
	if i < 2:
		var hid: String = GameState.hero_id if i == 0 else GameState.companion_id
		GameState.equip(hid, item)
