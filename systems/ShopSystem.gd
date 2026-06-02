class_name ShopSystem


static func buy_item(state: Dictionary, element_id: String) -> Dictionary:
	var elem: Dictionary = ElementData.find(element_id)
	if elem.is_empty():
		return state
	var gold: int = state["gold"]
	if gold < (elem["price"] as int):
		return state
	var slot: int = _first_empty_slot(state["inventory"])
	if slot == -1:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - (elem["price"] as int)
	var instance: Dictionary = elem.duplicate()
	instance["element_id"] = element_id
	instance["level"] = 1
	s["inventory"][slot] = instance
	var remaining: Array = []
	for item: Variant in s["shop_items"]:
		var it: Dictionary = item as Dictionary
		if it["id"] != element_id:
			remaining.append(it)
	s["shop_items"] = remaining
	return s


static func sell_item(state: Dictionary, slot_index: int) -> Dictionary:
	var inv: Array = state["inventory"]
	if slot_index < 0 or slot_index >= inv.size():
		return state
	var item: Variant = inv[slot_index]
	if item == null:
		return state
	var s: Dictionary = state.duplicate(true)
	var elem: Dictionary = item as Dictionary
	@warning_ignore("integer_division")
	var refund: int = (elem["price"] as int) / 2
	s["gold"] = (s["gold"] as int) + refund
	s["inventory"][slot_index] = null
	return s


static func reroll_shop(state: Dictionary, is_free: bool = false) -> Dictionary:
	if not is_free and (state["gold"] as int) < 2:
		return state
	var s: Dictionary = state.duplicate(true)
	if not is_free:
		s["gold"] = (s["gold"] as int) - 2
	var tier: int = s["shop_tier"]
	var pool: Array[Dictionary] = []
	for elem: Dictionary in ElementData.all_elements():
		if (elem["tier"] as int) <= tier and (elem["price"] as int) > 0:
			pool.append(elem)
	pool.shuffle()
	s["shop_items"] = pool.slice(0, 4)
	return s


static func _first_empty_slot(inventory: Array) -> int:
	for i: int in inventory.size():
		if inventory[i] == null:
			return i
	return -1
