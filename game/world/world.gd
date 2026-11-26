class_name World
extends Node2D
## Spielwelt: Spieler, Geschwister, aktueller Raum, HUD.

signal to_title

var player: Player
var sibling: Sibling


func start(new_game: bool) -> void:
	player = load("res://world/player.tscn").instantiate()
	player.hero_id = GameState.hero_id
	RoomManager.room_dir = "res://data/rooms"
	BattleLauncher.test_mode = false
	BattleLauncher.busy = false
	RoomManager.attach(self, player)
	sibling = Sibling.new()
	sibling.player = player
	add_child(sibling)
	add_child(Hud.new())
	RoomManager.room_changed.connect(_on_room_changed)
	BattleLauncher.boss_defeated.connect(func(_a): DialogBox.show_dialog(self, "boss_sieg"))
	if new_game:
		RoomManager.go_to("kornburg_gilde", "")
		DialogBox.show_dialog.call_deferred(self, "intro")
	else:
		var rp := GameState.resolve_respawn()
		RoomManager.go_to(rp.room, "", "start", rp.cell)


func _on_room_changed(_def: RoomDef) -> void:
	if sibling and player:
		sibling.position = player.position + Vector2(-Sibling.FOLLOW_GAP * player.facing, 0)
		sibling.velocity = Vector2.ZERO
		if sibling.mode != "follow":
			sibling.mode = "follow"


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("karte"):
		MapView.toggle(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		var m := ChoiceMenu.open(self, "Pause", ["Weiter", "Vorräte", "Zum Titel", "Spiel beenden"], 0)
		var i: int = await m.chosen
		if i == 1:
			SuppliesMenu.open(self)
		elif i == 2:
			to_title.emit()
		elif i == 3:
			get_tree().quit()
