extends Node
## Einstiegspunkt: Titel → Figurenwahl → Welt.

var _current: Node


func _ready() -> void:
	_show_title()


func _swap(n: Node) -> void:
	if _current:
		_current.queue_free()
	for c in get_tree().root.get_children():
		if c is CanvasLayer and c != self:
			c.queue_free()
	GameState.pause_reset()
	_current = n
	add_child(n)


func _show_title() -> void:
	var t := TitleMenu.new()
	t.new_game.connect(_on_new_game)
	t.continue_game.connect(_on_continue)
	_swap(t)


func _on_new_game() -> void:
	var cs := CharacterSelect.new()
	cs.chosen.connect(func(id):
		GameState.reset()
		GameState.choose_hero(id)
		_start_world(true))
	_swap(cs)


func _on_continue() -> void:
	var d := SaveSystem.load_save()
	if d.is_empty() or d.has("error"):
		ChoiceMenu.toast(self, "Der Spielstand ist beschädigt und kann nicht geladen werden.")
		return
	GameState.from_dict(d)
	_start_world(false)


func _start_world(new_game: bool) -> void:
	var w := World.new()
	w.to_title.connect(_show_title.call_deferred)
	_swap(w)
	w.start(new_game)
