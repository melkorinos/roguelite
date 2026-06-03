extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func _state_with_shop_item(shop_slot: int, id: String) -> Dictionary:
	var state := _make_state()
	state["shop_items"][shop_slot] = ElementData.find(id).duplicate()
	return state


func _state_with_inv_item(inv_slot: int, id: String) -> Dictionary:
	var state := _make_state()
	var elem: Dictionary = ElementData.find(id).duplicate()
	elem["element_id"] = id
	elem["level"] = 1
	state["inventory"][inv_slot] = elem
	return state


# ── transfer: shop → inventory (first empty slot) ─────────────────────────────

func test_transfer_buy_deducts_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_eq(s["gold"], 5)


func test_transfer_buy_places_element_in_first_empty_slot() -> void:
	var state := _state_with_shop_item(0, "water")
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	var slot: Variant = s["inventory"][0]
	assert_not_null(slot)
	assert_eq((slot as Dictionary)["element_id"], "water")
	assert_eq((slot as Dictionary)["level"], 1)


func test_transfer_buy_fails_when_gold_insufficient() -> void:
	var state := _state_with_shop_item(0, "water")
	state["gold"] = 0
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_null(s["inventory"][0])


func test_transfer_buy_fails_when_inventory_full() -> void:
	var state := _state_with_shop_item(0, "water")
	var dummy: Dictionary = ElementData.find("fire").duplicate()
	dummy["element_id"] = "fire"
	dummy["level"] = 1
	for i: int in state["inventory"].size():
		state["inventory"][i] = dummy.duplicate()
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_eq(s["gold"] as int, state["gold"] as int)


func test_transfer_buy_nulls_shop_slot() -> void:
	var state := _state_with_shop_item(1, "water")
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": -1})
	assert_null(s["shop_items"][1])


func test_transfer_buy_does_not_mutate_original() -> void:
	var state := _state_with_shop_item(0, "water")
	ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_null(state["inventory"][0])


# ── transfer: shop → inventory (explicit slot) ────────────────────────────────

func test_transfer_buy_to_explicit_slot() -> void:
	var state := _state_with_shop_item(0, "water")
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 3})
	assert_not_null(s["inventory"][3])
	assert_null(s["inventory"][0])


func test_transfer_buy_to_explicit_slot_rejects_occupied_by_different_element() -> void:
	var state := _state_with_shop_item(1, "fire")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][0] = water
	var before_gold: int = state["gold"] as int
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq(s["gold"] as int, before_gold)
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "water")


# ── transfer: shop → inventory (level-up) ────────────────────────────────────

func test_transfer_buy_levels_up_matching_element() -> void:
	var state := _state_with_shop_item(1, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][0] = water
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq((s["inventory"][0] as Dictionary)["level"], 2)


func test_transfer_buy_level_up_deducts_gold() -> void:
	var state := _state_with_shop_item(1, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][0] = water
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq(s["gold"] as int, 5)


func test_transfer_buy_level_up_nulls_shop_slot() -> void:
	var state := _state_with_shop_item(1, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][0] = water
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_null(s["shop_items"][1])


func test_transfer_buy_level_up_rejects_mismatched_element() -> void:
	var state := _state_with_shop_item(1, "water")
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"
	fire["level"] = 1
	state["inventory"][0] = fire
	var before_gold: int = state["gold"] as int
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq(s["gold"] as int, before_gold)
	assert_eq((s["inventory"][0] as Dictionary)["level"], 1)


func test_transfer_buy_level_up_rejects_target_above_level_1() -> void:
	var state := _state_with_shop_item(1, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 2
	state["inventory"][0] = water
	var before_gold: int = state["gold"] as int
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq(s["gold"] as int, before_gold)


func test_transfer_buy_level_up_does_not_mutate_original() -> void:
	var state := _state_with_shop_item(1, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][0] = water
	ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq((state["inventory"][0] as Dictionary)["level"], 1)


# ── transfer: inventory → grid ────────────────────────────────────────────────

func test_transfer_inv_to_grid_places_item() -> void:
	var state := _state_with_inv_item(0, "water")
	var s := ShopSystem.transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "grid", "slot": 2})
	assert_null(s["inventory"][0])
	assert_not_null(s["battle_grid"][2])
	assert_eq((s["battle_grid"][2] as Dictionary)["element_id"], "water")


func test_transfer_inv_to_grid_returns_grid_item_to_inventory() -> void:
	var state := _state_with_inv_item(1, "fire")
	var earth: Dictionary = ElementData.find("earth").duplicate()
	earth["element_id"] = "earth"
	earth["level"] = 1
	state["battle_grid"][0] = earth
	var s := ShopSystem.transfer(state, {"zone": "inventory", "slot": 1}, {"zone": "grid", "slot": 0})
	assert_eq((s["inventory"][1] as Dictionary)["element_id"], "earth")
	assert_eq((s["battle_grid"][0] as Dictionary)["element_id"], "fire")


func test_transfer_inv_to_grid_does_not_mutate_original() -> void:
	var state := _state_with_inv_item(0, "water")
	ShopSystem.transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "grid", "slot": 2})
	assert_not_null(state["inventory"][0])


# ── transfer: grid → inventory ────────────────────────────────────────────────

func test_transfer_grid_to_inv_moves_item() -> void:
	var state := _make_state()
	var elem: Dictionary = ElementData.find("air").duplicate()
	elem["element_id"] = "air"
	elem["level"] = 1
	state["battle_grid"][1] = elem
	var s := ShopSystem.transfer(state, {"zone": "grid", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_null(s["battle_grid"][1])
	assert_eq((s["inventory"][0] as Dictionary)["element_id"], "air")


func test_transfer_grid_to_inv_returns_inv_item_to_grid() -> void:
	var state := _state_with_inv_item(2, "earth")
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"
	fire["level"] = 1
	state["battle_grid"][0] = fire
	var s := ShopSystem.transfer(state, {"zone": "grid", "slot": 0}, {"zone": "inventory", "slot": 2})
	assert_eq((s["battle_grid"][0] as Dictionary)["element_id"], "earth")
	assert_eq((s["inventory"][2] as Dictionary)["element_id"], "fire")


# ── transfer: grid → grid ─────────────────────────────────────────────────────

func test_transfer_grid_grid_exchanges_slots() -> void:
	var state := _make_state()
	var ea: Dictionary = ElementData.find("water").duplicate()
	ea["element_id"] = "water"; ea["level"] = 1
	var eb: Dictionary = ElementData.find("fire").duplicate()
	eb["element_id"] = "fire"; eb["level"] = 1
	state["battle_grid"][0] = ea
	state["battle_grid"][3] = eb
	var s := ShopSystem.transfer(state, {"zone": "grid", "slot": 0}, {"zone": "grid", "slot": 3})
	assert_eq((s["battle_grid"][0] as Dictionary)["element_id"], "fire")
	assert_eq((s["battle_grid"][3] as Dictionary)["element_id"], "water")


func test_transfer_grid_grid_does_not_mutate_original() -> void:
	var state := _make_state()
	var ea: Dictionary = ElementData.find("air").duplicate()
	ea["element_id"] = "air"; ea["level"] = 1
	state["battle_grid"][0] = ea
	ShopSystem.transfer(state, {"zone": "grid", "slot": 0}, {"zone": "grid", "slot": 1})
	assert_not_null(state["battle_grid"][0])


# ── sell ──────────────────────────────────────────────────────────────────────

func test_sell_refunds_half_price_rounded_down() -> void:
	var state := _state_with_inv_item(0, "water")
	state["gold"] = 5
	var s := ShopSystem.sell_item(state, 0)
	assert_eq(s["gold"], 7)


func test_sell_clears_slot() -> void:
	var state := _state_with_inv_item(0, "water")
	var s := ShopSystem.sell_item(state, 0)
	assert_null(s["inventory"][0])


func test_sell_does_not_mutate_original() -> void:
	var state := _state_with_inv_item(0, "water")
	ShopSystem.sell_item(state, 0)
	assert_not_null(state["inventory"][0])


func test_sell_grid_item_refunds_and_clears() -> void:
	var state := _make_state()
	var elem: Dictionary = ElementData.find("fire").duplicate()
	elem["element_id"] = "fire"
	elem["level"] = 1
	state["battle_grid"][1] = elem
	var s := ShopSystem.sell_grid_item(state, 1)
	assert_null(s["battle_grid"][1])
	assert_gt(s["gold"] as int, state["gold"] as int)


# ── reroll ────────────────────────────────────────────────────────────────────

func test_reroll_free_does_not_cost_gold() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	assert_eq(s["gold"], 10)


func test_reroll_costs_2_gold() -> void:
	var s := ShopSystem.reroll_shop(_make_state())
	assert_eq(s["gold"], 8)


func test_reroll_fails_without_enough_gold() -> void:
	var state := _make_state()
	state["gold"] = 1
	var s := ShopSystem.reroll_shop(state)
	var all_null: bool = (s["shop_items"] as Array).all(func(x: Variant) -> bool: return x == null)
	assert_true(all_null)


func test_reroll_returns_only_tier1_at_default_shop_tier() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	for item: Variant in s["shop_items"]:
		if item == null:
			continue
		assert_eq((item as Dictionary)["tier"], 1)


func test_reroll_fills_exactly_5_slots() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	assert_eq(s["shop_items"].size(), 5)
	for item: Variant in s["shop_items"]:
		assert_not_null(item)


func test_reroll_t1_shop_never_returns_tier2() -> void:
	# At shop_tier 1, every item must be tier 1 — run 20 rerolls to be sure.
	var state := _make_state()
	state["shop_tier"] = 1
	for _i: int in 20:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			assert_eq((item as Dictionary)["tier"], 1)


func test_reroll_t2_shop_can_return_tier2_items() -> void:
	# At shop_tier 2, at least one tier-2 item must appear across 40 rerolls.
	var state := _make_state()
	state["shop_tier"] = 2
	var found_t2: bool = false
	for _i: int in 40:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if (item as Dictionary)["tier"] == 2:
				found_t2 = true
	assert_true(found_t2)


func test_reroll_t3_shop_can_return_tier3_items() -> void:
	var state := _make_state()
	state["shop_tier"] = 3
	var found_t3: bool = false
	for _i: int in 40:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if (item as Dictionary)["tier"] == 3:
				found_t3 = true
	assert_true(found_t3)


# ── can_transfer: shop → inventory ───────────────────────────────────────────

func test_can_transfer_shop_to_inv_allowed_with_enough_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	assert_true(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_shop_to_inv_rejected_insufficient_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	state["gold"] = 0
	assert_false(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_shop_to_inv_allowed_level_up_same_element_lv1() -> void:
	var state := _state_with_shop_item(0, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"; water["level"] = 1
	state["inventory"][0] = water
	assert_true(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_shop_to_inv_rejected_different_element_in_slot() -> void:
	var state := _state_with_shop_item(0, "water")
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"; fire["level"] = 1
	state["inventory"][0] = fire
	assert_false(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_shop_to_inv_rejected_target_lv2() -> void:
	var state := _state_with_shop_item(0, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"; water["level"] = 2
	state["inventory"][0] = water
	assert_false(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0}))


# ── can_transfer: shop → grid ─────────────────────────────────────────────────

func test_can_transfer_shop_to_grid_allowed_with_enough_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	assert_true(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "grid", "slot": 0}))


func test_can_transfer_shop_to_grid_rejected_insufficient_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	state["gold"] = 0
	assert_false(ShopSystem.can_transfer(state, {"zone": "shop", "slot": 0}, {"zone": "grid", "slot": 0}))


# ── can_transfer: inventory → inventory ──────────────────────────────────────

func test_can_transfer_inv_to_inv_allowed_same_element_same_level() -> void:
	var state := _state_with_inv_item(0, "water")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"; water["level"] = 1
	state["inventory"][1] = water
	assert_true(ShopSystem.can_transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "inventory", "slot": 1}))


func test_can_transfer_inv_to_inv_rejected_different_element() -> void:
	var state := _state_with_inv_item(0, "water")
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"; fire["level"] = 1
	state["inventory"][1] = fire
	assert_false(ShopSystem.can_transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "inventory", "slot": 1}))


func test_can_transfer_inv_to_inv_rejected_same_slot() -> void:
	var state := _state_with_inv_item(0, "water")
	assert_false(ShopSystem.can_transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_inv_to_inv_rejected_target_empty() -> void:
	var state := _state_with_inv_item(0, "water")
	assert_false(ShopSystem.can_transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "inventory", "slot": 1}))


# ── can_transfer: across zones ────────────────────────────────────────────────

func test_can_transfer_inv_to_grid_always_allowed() -> void:
	var state := _state_with_inv_item(0, "water")
	assert_true(ShopSystem.can_transfer(state, {"zone": "inventory", "slot": 0}, {"zone": "grid", "slot": 2}))


func test_can_transfer_grid_to_inv_always_allowed() -> void:
	var state := _make_state()
	var elem: Dictionary = ElementData.find("fire").duplicate()
	elem["element_id"] = "fire"; elem["level"] = 1
	state["battle_grid"][0] = elem
	assert_true(ShopSystem.can_transfer(state, {"zone": "grid", "slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_transfer_grid_to_grid_different_slots_allowed() -> void:
	var state := _make_state()
	assert_true(ShopSystem.can_transfer(state, {"zone": "grid", "slot": 0}, {"zone": "grid", "slot": 1}))


func test_can_transfer_grid_to_grid_same_slot_rejected() -> void:
	var state := _make_state()
	assert_false(ShopSystem.can_transfer(state, {"zone": "grid", "slot": 2}, {"zone": "grid", "slot": 2}))
