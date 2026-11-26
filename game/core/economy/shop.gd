class_name Shop
extends RefCounted
## Kaufen, Verkaufen und Brot backen lassen. Läden in res://data/shops.json.

## Kaufpreis von Ausrüstung nach Rang (D, C, B, A); Ankauf zum halben Preis.
const EQUIP_PRICE := {1: 40, 2: 90, 3: 160, 4: 300}
const BAKE_WHEAT := 3
const BAKE_SILVER := 2
const CORES := ["monsterkern_D", "monsterkern_C"]

static var _data: Dictionary = {}


static func data(shop_id: String) -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/shops.json"))
	return _data[shop_id]


static func _name(item: String) -> String:
	return DB.item(item).name if DB.items.has(item) else DB.equipment(item).name


static func price_buy(item: String) -> int:
	if DB.items.has(item):
		return int(DB.item(item).buy)
	if DB.equip.has(item):
		return int(EQUIP_PRICE.get(int(DB.equipment(item).rank), 0))
	return 0


static func price_sell(shop_id: String, item: String) -> int:
	if DB.equip.has(item):
		return price_buy(item) / 2
	return maxi(1, int(floor(int(DB.item(item).sell) * float(data(shop_id).rate))))


static func sells(shop_id: String, item: String) -> bool:
	return item in data(shop_id).sells


static func buys(shop_id: String, item: String) -> bool:
	var d := data(shop_id)
	if DB.equip.has(item):
		return d.get("buys_equipment", false)
	if not DB.items.has(item):
		return false
	if d.buys is String and d.buys == "sammelbar":
		return String(DB.item(item).icon).begins_with("sammeln:") or item in CORES
	return item in d.buys


static func is_equipped(item: String) -> bool:
	for hid in GameState.equipped:
		if item in GameState.equipped[hid]:
			return true
	return false


static func owned(item: String) -> int:
	return GameState.inventory.count(item) if DB.equip.has(item) else GameState.item_count(item)


static func buy(shop_id: String, item: String) -> String:
	if not sells(shop_id, item):
		return "Das gibt es hier nicht."
	var price := price_buy(item)
	if GameState.gold < price:
		return "Zu wenig Silber."
	GameState.gold -= price
	if DB.equip.has(item):
		GameState.inventory.append(item)
	else:
		GameState.add_item(item)
	return "Gekauft: %s für %d Silber." % [_name(item), price]


static func sell(shop_id: String, item: String) -> String:
	if not buys(shop_id, item):
		return "Das kauft hier keiner."
	if owned(item) <= 0:
		return "Davon habt ihr nichts mehr."
	if DB.equip.has(item):
		if is_equipped(item):
			return "Angelegte Ausrüstung kann nicht verkauft werden."
		GameState.inventory.erase(item)
	else:
		GameState.remove_item(item)
	var price := price_sell(shop_id, item)
	GameState.gold += price
	return "Verkauft: %s für %d Silber." % [_name(item), price]


## Bäcker Jonte backt aus 3 Weizen und 2 Silber ein Brot.
static func bake() -> String:
	if GameState.item_count("weizen") < BAKE_WHEAT:
		return "Dafür braucht Jonte %d Weizen." % BAKE_WHEAT
	if GameState.gold < BAKE_SILVER:
		return "Zu wenig Silber."
	GameState.remove_item("weizen", BAKE_WHEAT)
	GameState.gold -= BAKE_SILVER
	GameState.add_item("brot")
	return "Jonte backt euch ein Brot."
