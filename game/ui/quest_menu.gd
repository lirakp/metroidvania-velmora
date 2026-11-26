class_name QuestMenu
extends RefCounted
## Auftragsbrett-Menü: Angebote annehmen, aktive Aufträge abgeben.


static func lines() -> Array:
	var out := []
	for o in GameState.quests.offers:
		out.append("Neu: %s – %d Silber" % [o.kurz, Quests.payout(o)])
	for a in GameState.quests.active:
		out.append("%s %d/%d – %d Silber" % [a.kurz, Quests.progress(a), a.need, Quests.payout(a)])
	out.append("Zurück")
	return out


static func open(parent: Node) -> void:
	Quests.ensure_offers()
	while is_instance_valid(parent):
		var offers: int = GameState.quests.offers.size()
		var opts := lines()
		var m := ChoiceMenu.open(parent, "Auftragsbrett", opts, opts.size() - 1)
		var i: int = await m.chosen
		if i >= opts.size() - 1:
			return
		if i < offers:
			var text: String = GameState.quests.offers[i].text
			if Quests.accept(i):
				var box := DialogBox.show_lines(parent, [{"speaker": "Auftrag", "text": text}])
				await box.finished
			else:
				ChoiceMenu.toast(parent, "Mehr als drei Aufträge gleichzeitig nimmt die Gilde nicht an.")
				return
		else:
			var a: Dictionary = GameState.quests.active[i - offers]
			var pay := Quests.turn_in(i - offers)
			if pay > 0:
				_banner(parent)
				ChoiceMenu.toast(parent, "Auftrag erledigt: +%d Silber" % pay)
			else:
				ChoiceMenu.toast(parent, "Noch nicht erfüllt (%d/%d)." % [Quests.progress(a), a.need])
			return


static func _banner(parent: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var b := UiArt.banner("auftrag_erledigt")
	b.position = Vector2(240, 80)
	layer.add_child(b)
	parent.get_tree().root.add_child(layer)
	parent.get_tree().create_timer(1.6, true).timeout.connect(layer.queue_free)
