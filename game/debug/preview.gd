extends Node
## Vorschau für Screenshots: godot ... res://debug/preview.tscn -- <modus> [raum]
## modus: title | select | room <id> | map <id>


func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "title"
	match mode:
		"title":
			add_child(TitleMenu.new())
		"select":
			add_child(CharacterSelect.new())
		_:
			GameState.reset()
			GameState.choose_hero("lira")
			GameState.set_flag("seen:intro")
			for k in DialogBox.all_dialogs():
				GameState.set_flag("seen:" + k)
			var w := World.new()
			add_child(w)
			w.start(false)
			var room: String = args[1] if args.size() > 1 else "kornburg_gilde"
			RoomManager.go_to(room, "L1" if RoomManager.def_of(room).exit_by_id("L1") else "")
			if mode == "dialog":
				GameState.flags.clear()
				DialogBox.show_dialog(w, "intro")
			if mode == "battle":
				var e := FieldEnemy.create(["ghul", "riesenspinne"], 0, room, 99)
				RoomManager.current.add_child(e)
				BattleLauncher.start(e, "ueberfall")
			if mode == "map":
				GameState.owned_maps[RoomManager.current_def.area] = true
				for id in WorldMap.layout(RoomManager.current_def.area):
					if randf() < 0.6:
						GameState.discovered_rooms[id] = true
				MapView.toggle(w)
