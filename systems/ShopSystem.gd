class_name ShopSystem

# ── Tier weight table (cumulative thresholds, T1-T5) ─────────────────────────
# Curve shifts toward T3/T4 at higher shop tiers (less T1, more T2-4).
static func _tier_thresholds(shop_tier: int) -> Array[float]:
	match shop_tier:
		1: return [1.00, 1.00, 1.00, 1.00, 1.00]
		2: return [0.65, 1.00, 1.00, 1.00, 1.00]
		3: return [0.45, 0.80, 1.00, 1.00, 1.00]
		4: return [0.25, 0.55, 0.85, 1.00, 1.00]
		5: return [0.15, 0.35, 0.60, 0.85, 1.00]
	return [1.00, 1.00, 1.00, 1.00, 1.00]


static func _pick_tier(shop_tier: int) -> int:
	var thresholds: Array[float] = _tier_thresholds(shop_tier)
	var roll: float = randf()
	for i: int in thresholds.size():
		if roll < thresholds[i]:
			return i + 1
	return shop_tier


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
	if from_zone == "shop" and to_zone == "grid":
		return _buy_to_grid(state, from_slot, to_slot)
	if from_zone == "inventory" and to_zone == "grid":
		return _swap_arrays(state, "inventory", from_slot, "battle_grid", to_slot)
	if from_zone == "grid" and to_zone == "inventory":
		return _swap_arrays(state, "battle_grid", from_slot, "inventory", to_slot)
	if from_zone == "grid" and to_zone == "grid":
		return _swap_arrays(state, "battle_grid", from_slot, "battle_grid", to_slot)
	return state


static func can_transfer(state: Dictionary, from_loc: Dictionary, to_loc: Dictionary) -> bool:
	var from_zone: String = from_loc["zone"] as String
	var from_slot: int = from_loc["slot"] as int
	var to_zone: String = to_loc["zone"] as String
	var to_slot: int = to_loc["slot"] as int

	if from_zone == "shop":
		var shop_items: Array = state["shop_items"] as Array
		if from_slot < 0 or from_slot >= shop_items.size():
			return false
		var item: Variant = shop_items[from_slot]
		if item == null:
			return false
		var elem: Dictionary = item as Dictionary
		if (state["gold"] as int) < (elem["price"] as int):
			return false
		if to_zone == "inventory":
			var inv: Array = state["inventory"] as Array
			if to_slot >= 0 and to_slot < inv.size():
				var existing: Variant = inv[to_slot]
				if existing != null:
					var target: Dictionary = existing as Dictionary
					if (target["element_id"] as String) != (elem["id"] as String):
						return false
					if (target["level"] as int) != 1:
						return false
		elif to_zone == "grid":
			var grid: Array = state["battle_grid"] as Array
			if to_slot >= 0 and to_slot < grid.size():
				var existing: Variant = grid[to_slot]
				if existing != null:
					var target: Dictionary = existing as Dictionary
					if (target.get("element_id", "") as String) != (elem["id"] as String):
						return false
					if (target["level"] as int) != 1:
						return false
		return true

	if from_zone == "inventory" and to_zone == "inventory":
		if from_slot == to_slot:
			return false
		var inv: Array = state["inventory"] as Array
		if from_slot < 0 or from_slot >= inv.size() or to_slot < 0 or to_slot >= inv.size():
			return false
		var from_item: Variant = inv[from_slot]
		var to_item: Variant = inv[to_slot]
		if from_item == null or to_item == null:
			return false
		var fa: Dictionary = from_item as Dictionary
		var ta: Dictionary = to_item as Dictionary
		if (fa["element_id"] as String) != (ta["element_id"] as String):
			return false
		return (fa["level"] as int) == (ta["level"] as int)

	if from_zone == "grid" and to_zone == "grid" and from_slot == to_slot:
		return false

	return true


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

	var shop_tier: int = s["shop_tier"] as int

	# Build per-tier pools
	var pools: Array = [[], [], [], [], []]
	for elem: Dictionary in ElementData.all_elements():
		var t: int = (elem["tier"] as int) - 1
		if t >= 0 and t < 5:
			(pools[t] as Array).append(elem)

	var slots: Array = [null, null, null, null, null]
	for i: int in 5:
		var chosen: int = _pick_tier(shop_tier)
		var pool: Array = pools[chosen - 1] as Array
		if pool.is_empty():
			pool = pools[0] as Array  # fallback to T1 if tier not yet populated
		if not pool.is_empty():
			slots[i] = (pool[randi() % pool.size()] as Dictionary).duplicate()
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


static func _buy_to_grid(state: Dictionary, shop_slot: int, grid_slot: int) -> Dictionary:
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
	var grid: Array = state["battle_grid"]
	if grid_slot < 0 or grid_slot >= grid.size():
		return state
	var existing: Variant = grid[grid_slot]
	if existing == null:
		var s: Dictionary = state.duplicate(true)
		var instance: Dictionary = elem_def.duplicate()
		instance["element_id"] = elem_def["id"] as String
		instance["level"] = 1
		s["battle_grid"][grid_slot] = instance
		s["gold"] = gold - price
		s["shop_items"][shop_slot] = null
		return s
	else:
		var target: Dictionary = existing as Dictionary
		if (target.get("element_id", "") as String) != (elem_def["id"] as String):
			return state
		if (target["level"] as int) != 1:
			return state
		var s: Dictionary = state.duplicate(true)
		var upgraded: Dictionary = (s["battle_grid"][grid_slot] as Dictionary).duplicate()
		upgraded["level"] = 2
		s["battle_grid"][grid_slot] = upgraded
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
