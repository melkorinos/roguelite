class_name ShopSystem


static func buy_item(state: Dictionary, item_id: String) -> Dictionary:
	var item: Dictionary = _find_item(item_id)
	if item.is_empty():
		return state
	var gold: int = state["gold"]
	if gold < (item["price"] as int):
		return state
	var slot: int = _first_empty_slot(state["inventory"])
	if slot == -1:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - (item["price"] as int)
	s["inventory"][slot] = item.duplicate()
	return s


static func sell_item(state: Dictionary, slot_index: int) -> Dictionary:
	var inv: Array = state["inventory"]
	if slot_index < 0 or slot_index >= inv.size():
		return state
	var item: Variant = inv[slot_index]
	if item == null:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = (s["gold"] as int) + ((item as Dictionary)["price"] as int) / 2
	s["inventory"][slot_index] = null
	return s


static func reroll_shop(state: Dictionary, is_free: bool = false) -> Dictionary:
	if not is_free and (state["gold"] as int) < 2:
		return state
	var s: Dictionary = state.duplicate(true)
	if not is_free:
		s["gold"] = (s["gold"] as int) - 2
	var all: Array[Dictionary] = ItemData.all_items()
	all.shuffle()
	s["shop_items"] = all.slice(0, 5)
	return s


static func _find_item(item_id: String) -> Dictionary:
	for item: Dictionary in ItemData.all_items():
		if item["id"] == item_id:
			return item
	return {}


static func _first_empty_slot(inventory: Array) -> int:
	for i: int in inventory.size():
		if inventory[i] == null:
			return i
	return -1
