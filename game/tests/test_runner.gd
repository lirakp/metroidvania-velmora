extends Node
## Lädt alle res://tests/test_*.gd, ruft jede Methode test_* auf einer neuen Instanz auf.
## Aufruf: godot --headless --path game res://tests/test_runner.tscn -- [filter]


func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var filter: String = args[0] if args.size() > 0 else ""
	var passed := 0
	var failed := 0
	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_runner.gd" and f != "test_case.gd":
			if filter == "" or f.contains(filter):
				files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAIL %s: Skript lädt nicht (Parse-Fehler)" % f)
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var inst = script.new()
			if inst is Node:
				add_child(inst)
			await inst.call(name)
			if inst.failures.is_empty():
				passed += 1
				print("PASS %s::%s" % [f, name])
			else:
				failed += 1
				print("FAIL %s::%s: %s" % [f, name, "; ".join(inst.failures)])
			if inst is Node:
				inst.queue_free()
				await get_tree().process_frame
	print("ERGEBNIS: %d bestanden, %d fehlgeschlagen" % [passed, failed])
	get_tree().quit(1 if failed > 0 or passed == 0 else 0)
