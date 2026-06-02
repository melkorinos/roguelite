class_name ShopSystem


static func buy_item(state: Dictionary, element_id: String, shop_slot: int) -> Dictionary:
	var elem: Dictionary = ElementData.find(element_id)
	if elem.is_empty():
		return state
	var gold: int = state["gold"]
	if gold < (elem["price"] as int):
		return state
	var inv_slot: int = _first_empty_slot(state["inventory"])
	if inv_slot == -1:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - (elem["price"] as int)
	var instance: Dictionary = elem.duplicate()
	instance["element_id"] = element_id
	instance["level"] = 1
	s["inventory"][inv_slot] = instance
	s["shop_items"][shop_slot] = null
	return s


# Buy a shop item and place it directly in a specific inventory slot.
static func buy_item_to_slot(state: Dictionary, element_id: String, target_inv_slot: int, shop_slot: int) -> Dictionary:
	var elem: Dictionary = ElementData.find(element_id)
	if elem.is_empty():
		return state
	var gold: int = state["gold"] as int
	if gold < (elem["price"] as int):
		return state
	var inv: Array = state["inventory"]
	if inv[target_inv_slot] != null:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - (elem["price"] as int)
	var instance: Dictionary = elem.duplicate()
	instance["element_id"] = element_id
	instance["level"] = 1
	s["inventory"][target_inv_slot] = instance
	s["shop_items"][shop_slot] = null
	return s


# Buy a shop item and immediately level-up the inventory item at to_inv_index.
# The bought item is always level 1; to_inv_index must also be level 1.
static func buy_and_level_up(state: Dictionary, element_id: String, to_inv_index: int, shop_slot: int) -> Dictionary:
	var elem_def: Dictionary = ElementData.find(element_id)
	if elem_def.is_empty():
		return state
	var gold: int = state["gold"] as int
	if gold < (elem_def["price"] as int):
		return state
	var inv: Array = state["inventory"]
	var target: Variant = inv[to_inv_index]
	if target == null:
		return state
	var target_elem: Dictionary = target as Dictionary
	if target_elem["element_id"] != element_id:
		return state
	if (target_elem["level"] as int) != 1:
		return state
	var s: Dictionary = state.duplicate(true)
	s["gold"] = gold - (elem_def["price"] as int)
	s["shop_items"][shop_slot] = null
	var upgraded: Dictionary = (s["inventory"][to_inv_index] as Dictionary).duplicate()
	upgraded["level"] = 2
	s["inventory"][to_inv_index] = upgraded
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


static func sell_grid_item(state: Dictionary, grid_slot: int) -> Dictionary:
	var grid: Array = state["battle_grid"]
	if grid_slot < 0 or grid_slot >= grid.size():
		return state
	var item: Variant = grid[grid_slot]
	if item == null:
		return state
	var s: Dictionary = state.duplicate(true)
	var elem: Dictionary = item as Dictionary
	@warning_ignore("integer_division")
	var refund: int = (elem["price"] as int) / 2
	s["gold"] = (s["gold"] as int) + refund
	s["battle_grid"][grid_slot] = null
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
	var slots: Array = [null, null, null, null, null]
	if not pool.is_empty():
		for i: int in 5:
			slots[i] = pool[randi() % pool.size()].duplicate()
	s["shop_items"] = slots
	return s


static func _first_empty_slot(inventory: Array) -> int:
	for i: int in inventory.size():
		if inventory[i] == null:
			return i
	return -1
