class_name ShopSystem

# Moves an item from one location to another.
# from_loc / to_loc: {"zone": "shop"|"inventory"|"grid", "slot": int}
# slot = -1 in to_loc means "first empty slot" in that zone.
static func transfer(state: Dictionary, from_loc: Dictionary, to_loc: Dictionary) -> Dictionary:
	var from_zone: String = from_loc["zone"] as String
	var from_slot: int = from_loc["slot"] as int
	var to_zone: String = to_loc["zone"] as String
	var to_slot: int = to_loc["slot"] as int

	if to_slot == -1:
		var target_arr: Array = state["inventory"] if to_zone == "inventory" else state["battle_grid"]
		to_slot = _first_empty_slot(target_arr)
		if to_slot == -1:
			return state

	if from_zone == "shop" and to_zone == "inventory":
		return _buy(state, from_slot, to_slot)
	if from_zone == "inventory" and to_zone == "grid":
		return _swap_arrays(state, "inventory", from_slot, "battle_grid", to_slot)
	if from_zone == "grid" and to_zone == "inventory":
		return _swap_arrays(state, "battle_grid", from_slot, "inventory", to_slot)
	if from_zone == "grid" and to_zone == "grid":
		return _swap_arrays(state, "battle_grid", from_slot, "battle_grid", to_slot)
	return state


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


static func _buy(state: Dictionary, shop_slot: int, inv_slot: int) -> Dictionary:
	var shop_items: Array = state["shop_items"]
	if shop_slot < 0 or shop_slot >= shop_items.size():
		return state
	var item: Variant = shop_items[shop_slot]
	if item == null:
		return state
	var elem_def: Dictionary = item as Dictionary
	var price: int = elem_def["price"] as int
	var gold: int = state["gold"] as int
	if gold < price:
		return state
	var inv: Array = state["inventory"]
	if inv_slot < 0 or inv_slot >= inv.size():
		return state
	var existing: Variant = inv[inv_slot]
	if existing == null:
		var s: Dictionary = state.duplicate(true)
		var instance: Dictionary = elem_def.duplicate()
		instance["element_id"] = elem_def["id"] as String
		instance["level"] = 1
		s["inventory"][inv_slot] = instance
		s["gold"] = gold - price
		s["shop_items"][shop_slot] = null
		return s
	else:
		var target: Dictionary = existing as Dictionary
		if (target["element_id"] as String) != (elem_def["id"] as String):
			return state
		if (target["level"] as int) != 1:
			return state
		var s: Dictionary = state.duplicate(true)
		var upgraded: Dictionary = (s["inventory"][inv_slot] as Dictionary).duplicate()
		upgraded["level"] = 2
		s["inventory"][inv_slot] = upgraded
		s["gold"] = gold - price
		s["shop_items"][shop_slot] = null
		return s


static func _swap_arrays(state: Dictionary, from_key: String, from_slot: int, to_key: String, to_slot: int) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	var temp: Variant = s[from_key][from_slot]
	s[from_key][from_slot] = s[to_key][to_slot]
	s[to_key][to_slot] = temp
	return s


static func _first_empty_slot(arr: Array) -> int:
	for i: int in arr.size():
		if arr[i] == null:
			return i
	return -1
