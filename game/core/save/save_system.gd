class_name SaveSystem
extends RefCounted
## Speichert den Spielstand als JSON. Fehlender Stand → {}, beschädigter → {"error": "beschaedigt"}.

const VERSION := 1
const DEFAULT_PATH := "user://save1.json"


static func save(state: Dictionary, path := DEFAULT_PATH) -> bool:
	var d := state.duplicate(true)
	d["version"] = VERSION
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.close()
	return true


static func load_save(path := DEFAULT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"error": "beschaedigt"}
	var parsed = json.data
	if not parsed is Dictionary or not parsed.has("version"):
		return {"error": "beschaedigt"}
	return parsed


static func exists(path := DEFAULT_PATH) -> bool:
	var d := load_save(path)
	return not d.is_empty() and not d.has("error")
