extends TestCase
## Läden: kaufen, verkaufen, Brot backen lassen.

var tree: SceneTree = Engine.get_main_loop()


func test_buy_reduces_silver_adds_item() -> void:
	GameState.reset()
	GameState.gold = 30
	assert_eq(Shop.buy("baeckerei", "brot"), "Gekauft: Brot für 12 Silber.")
	assert_eq(GameState.gold, 18)
	assert_eq(GameState.item_count("brot"), 1)


func test_buy_equipment_goes_to_inventory() -> void:
	GameState.reset()
	GameState.gold = 100
	assert_eq(Shop.price_buy("kurzschwert"), 40)
	assert_eq(Shop.price_buy("streitkolben"), 90)
	Shop.buy("waffen", "kurzschwert")
	assert_eq(GameState.gold, 60)
	assert_true(GameState.inventory.has("kurzschwert"))


func test_buy_without_silver_refused() -> void:
	GameState.reset()
	GameState.gold = 11
	assert_eq(Shop.buy("baeckerei", "brot"), "Zu wenig Silber.")
	assert_eq(GameState.gold, 11)
	assert_eq(GameState.item_count("brot"), 0)


func test_buy_only_shop_goods() -> void:
	GameState.reset()
	GameState.gold = 100
	assert_eq(Shop.buy("baeckerei", "heil_klein"), "Das gibt es hier nicht.")
	assert_eq(GameState.gold, 100)


func test_sell_only_shop_goods() -> void:
	GameState.reset()
	GameState.add_item("heilkraut", 2)
	var before := GameState.gold
	assert_eq(Shop.sell("baeckerei", "heilkraut"), "Das kauft hier keiner.")
	assert_eq(GameState.item_count("heilkraut"), 2)
	assert_eq(Shop.sell("alchemie", "heilkraut"), "Verkauft: Heilkraut für 4 Silber.")
	assert_eq(GameState.gold, before + 4)
	assert_eq(GameState.item_count("heilkraut"), 1)


func test_sell_last_unit_and_none_left() -> void:
	GameState.reset()
	GameState.add_item("weizen", 1)
	Shop.sell("baeckerei", "weizen")
	assert_eq(GameState.item_count("weizen"), 0)
	var before := GameState.gold
	assert_eq(Shop.sell("baeckerei", "weizen"), "Davon habt ihr nichts mehr.")
	assert_eq(GameState.gold, before)


func test_market_pays_70_percent() -> void:
	assert_eq(Shop.price_sell("markt", "monsterkern_C"), 24)  # 35 × 0.7 = 24,5 → 24
	assert_eq(Shop.price_sell("markt", "weizen"), 1)  # mindestens 1
	assert_true(Shop.buys("markt", "leuchtpilz"))
	assert_true(Shop.buys("markt", "monsterkern_D"))
	assert_false(Shop.buys("markt", "brot"))


func test_cannot_sell_equipped() -> void:
	GameState.reset()
	# Streitkolben ist keine Start-Ausrüstung: das einzige Stück im Inventar wird getragen
	GameState.inventory.append("streitkolben")
	GameState.equip(GameState.hero_id, "streitkolben")
	var before := GameState.gold
	assert_eq(Shop.sell("waffen", "streitkolben"), "Angelegte Ausrüstung kann nicht verkauft werden.")
	assert_eq(GameState.gold, before)
	assert_true(GameState.inventory.has("streitkolben"))


func test_sell_spare_equipment_half_price() -> void:
	GameState.reset()
	GameState.inventory.append("streitkolben")
	var before := GameState.gold
	assert_eq(Shop.sell("waffen", "streitkolben"), "Verkauft: Streitkolben für 45 Silber.")
	assert_eq(GameState.gold, before + 45)
	assert_false(GameState.inventory.has("streitkolben"))


func test_bake_bread() -> void:
	GameState.reset()
	GameState.gold = 5
	GameState.add_item("weizen", 2)
	assert_eq(Shop.bake(), "Dafür braucht Jonte 3 Weizen.")
	GameState.add_item("weizen", 1)
	assert_eq(Shop.bake(), "Jonte backt euch ein Brot.")
	assert_eq(GameState.item_count("weizen"), 0)
	assert_eq(GameState.item_count("brot"), 1)
	assert_eq(GameState.gold, 3)
	GameState.add_item("weizen", 3)
	GameState.gold = 1
	assert_eq(Shop.bake(), "Zu wenig Silber.")
	assert_eq(GameState.item_count("weizen"), 3)


func test_guild_buys_cores_full_price() -> void:
	assert_eq(Shop.price_sell("gilde", "monsterkern_D"), 15)
	assert_eq(Shop.price_sell("gilde", "monsterkern_C"), 35)
	assert_false(Shop.buys("gilde", "weizen"))


func test_shop_rows() -> void:
	GameState.reset()
	GameState.add_item("brot", 2)
	var rows := ShopMenu.rows("baeckerei", "kaufen")
	assert_eq(rows.map(func(r): return r.id), ["brot", "apfel"])
	assert_eq(rows[0].price, 12)
	assert_eq(rows[0].count, 2)
	GameState.add_item("weizen", 4)
	GameState.add_item("heilkraut", 1)
	var sell := ShopMenu.rows("baeckerei", "verkaufen")
	assert_eq(sell.map(func(r): return r.id), ["weizen"])
	assert_eq(sell[0].count, 4)


func test_shop_menu_opens_and_closes() -> void:
	GameState.reset()
	GameState.pause_reset()
	var parent := Node.new()
	tree.root.add_child(parent)
	var m := ShopMenu.open(parent, "baeckerei")
	assert_true(tree.paused)
	assert_eq(m.heads(), ["Kaufen", "Verkaufen", "Backen lassen", "Zurück"])
	m.close()
	assert_false(tree.paused)
	parent.free()


func _shop_menus() -> Array:
	return tree.root.get_children().filter(func(c): return c is ShopMenu and not c.is_queued_for_deletion())


func test_npc_with_shop_opens_window() -> void:
	GameState.reset()
	GameState.pause_reset()
	var n := Npc.new()
	n.npc_id = "veska"
	n.props = {"laden": "alchemie", "art": "keine"}
	tree.root.add_child(n)
	n.interact()
	var menus := _shop_menus()
	assert_eq(menus.size(), 1)
	if menus.size() == 1:
		assert_eq(menus[0].shop_id, "alchemie")
		menus[0].close()
	n.free()


func test_npc_with_shop_and_dialog_asks_first() -> void:
	GameState.reset()
	GameState.pause_reset()
	var n := Npc.new()
	n.npc_id = "haendler"
	n.props = {"laden": "markt", "dialog": "dorf_haendler", "arbeit": "haendler"}
	tree.root.add_child(n)
	n.interact()
	var choice: Array = tree.root.get_children().filter(func(c): return c is ChoiceMenu and not c.is_queued_for_deletion())
	assert_eq(choice.size(), 1)
	if choice.size() == 1:
		assert_eq(choice[0].options, ["Handeln", "Reden", "Zurück"])
		choice[0].close(0)
		await tree.process_frame
		var menus := _shop_menus()
		assert_eq(menus.size(), 1)
		for m in menus:
			m.close()
	n.free()


# ---------------------------------------------------------------- Befunde aus dem Review
func test_buying_equipment_offers_to_equip() -> void:
	GameState.reset()
	GameState.pause_reset()
	GameState.gold = 100
	var parent := Node.new()
	tree.root.add_child(parent)
	var m := ShopMenu.open(parent, "waffen")
	m._level = "kaufen"
	m._index = ShopMenu.rows("waffen", "kaufen").map(func(r): return r.id).find("kurzschwert")
	m._accept()
	await tree.process_frame
	var offers: Array = tree.root.get_children().filter(func(c): return c is ChoiceMenu and not c.is_queued_for_deletion())
	assert_eq(offers.size(), 1, "Anlegen wird nicht angeboten")
	if offers.size() == 1:
		assert_eq(offers[0].title, "Kurzschwert anlegen für:")
		offers[0].close(0)
		await tree.process_frame
		assert_true("kurzschwert" in GameState.equipped.get(GameState.hero_id, []))
	m.close()
	parent.free()
	GameState.pause_reset()


func test_shop_hint_names_working_key() -> void:
	GameState.reset()
	GameState.pause_reset()
	var parent := Node.new()
	tree.root.add_child(parent)
	var m := ShopMenu.open(parent, "baeckerei")
	var texts: Array = m._box.get_children().filter(func(c): return c is Label).map(func(l): return l.text)
	assert_false(texts.any(func(t): return "[W]" in t), "Hinweis nennt [W], das im Laden nicht bestätigt")
	assert_true(texts.any(func(t): return "[Leertaste]" in t))
	m.close()
	parent.free()


func test_spare_copy_of_equipped_item_can_be_sold() -> void:
	GameState.reset()
	# Warschick trägt den Kriegshammer; damit steht seine Start-Rüstung in equipped
	GameState.inventory.append("rostiger_kriegshammer")
	GameState.equip("warschick", "rostiger_kriegshammer")
	var armor: String = DB.hero("warschick").armor
	GameState.inventory.append(armor)
	assert_eq(Shop.sell("waffen", armor), "Verkauft: %s für %d Silber." % [DB.equipment(armor).name, Shop.price_sell("waffen", armor)])
	assert_false(GameState.inventory.has(armor))
	assert_eq(Shop.sell("waffen", "rostiger_kriegshammer"), "Angelegte Ausrüstung kann nicht verkauft werden.")
