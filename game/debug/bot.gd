extends Node
## Rauchtest: läuft ab einem Raum nach rechts, schlägt, springt, lässt Kämpfe automatisch laufen.
## godot --headless --path game res://debug/bot.tscn -- <startraum> <sekunden>

var _t := 0.0
var _limit := 30.0
var _rooms: Array = []
var _battles := 0


func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var start: String = args[0] if args.size() > 0 else "kornfeld_01"
	_limit = float(args[1]) if args.size() > 1 else 30.0
	GameState.reset()
	GameState.choose_hero("warschick")
	for k in DialogBox.all_dialogs():
		GameState.set_flag("seen:" + k)
	GameState.abilities["federfall"] = true
	var w := World.new()
	add_child(w)
	w.start(false)
	RoomManager.go_to(start, "L1")
	RoomManager.room_changed.connect(func(d): _rooms.append(d.id))
	BattleLauncher.battle_ended.connect(func(o): _battles += 1; print("Kampf: ", o))
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	for n in get_tree().root.get_children():
		if n is CanvasLayer:
			for c in n.get_children():
				if c is BattleScene and not c.auto:
					c.auto_play_for_test()
			if n is DialogBox:
				n._close()
			if n is ChoiceMenu:
				n.close(0)
	if not get_tree().paused:
		Input.action_press("rechts")
		var p: Player = RoomManager.player
		if p.is_on_wall() and not p.is_on_floor() and p.velocity.y > -40.0 and Input.is_action_pressed("springen"):
			Input.action_release("springen")
		elif p.is_on_wall() or (p.is_on_floor() and int(_t * 2) % 5 == 0):
			Input.action_press("springen")
		else:
			Input.action_release("springen")
		if int(_t * 5) % 2 == 0:
			Input.action_press("schlagen")
		else:
			Input.action_release("schlagen")
	if _t > _limit:
		print("BOT: Räume ", _rooms, " Kämpfe ", _battles, " Silber ", GameState.gold)
		get_tree().quit()
