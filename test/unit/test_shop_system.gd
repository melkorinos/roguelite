extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func test_buy_deducts_gold() -> void:
	var s := ShopSystem.buy_item(_make_state(), "water", 0)
	assert_eq(s["gold"], 5)


func test_buy_places_element_in_slot_0() -> void:
	var s := ShopSystem.buy_item(_make_state(), "water", 0)
	var slot: Variant = s["inventory"][0]
	assert_not_null(slot)
	assert_eq((slot as Dictionary)["element_id"], "water")
	assert_eq((slot as Dictionary)["level"], 1)


func test_buy_fails_when_gold_insufficient() -> void:
	var state := _make_state()
	state["gold"] = 0
	var s := ShopSystem.buy_item(state, "water", 0)
	assert_eq(s["gold"], 0)
	assert_null(s["inventory"][0])


func test_buy_fails_when_inventory_full() -> void:
	var state := _make_state()
	var dummy: Dictionary = ElementData.find("water").duplicate()
	dummy["element_id"] = "water"
	dummy["level"] = 1
	for i: int in state["inventory"].size():
		state["inventory"][i] = dummy.duplicate()
	var s := ShopSystem.buy_item(state, "water", 0)
	assert_eq(s["gold"], 10)


func test_buy_nulls_out_shop_slot() -> void:
	var state := _make_state()
	state["shop_items"][1] = ElementData.find("water").duplicate()
	var s := ShopSystem.buy_item(state, "water", 1)
	assert_null(s["shop_items"][1])


func test_sell_refunds_half_price_rounded_down() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water", 0)  # 10 - 5 = 5g remaining
	var s := ShopSystem.sell_item(state, 0)          # refund floor(5/2) = 2
	assert_eq(s["gold"], 7)


func test_sell_clears_slot() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water", 0)
	var s := ShopSystem.sell_item(state, 0)
	assert_null(s["inventory"][0])


func test_sell_does_not_mutate_original() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water", 0)
	var before: Variant = state["inventory"][0]
	ShopSystem.sell_item(state, 0)
	assert_not_null(before)


func test_sell_grid_item_refunds_and_clears() -> void:
	var state := _make_state()
	var elem: Dictionary = ElementData.find("fire").duplicate()
	elem["element_id"] = "fire"
	elem["level"] = 1
	state["battle_grid"][1] = elem
	var s := ShopSystem.sell_grid_item(state, 1)
	assert_null(s["battle_grid"][1])
	assert_gt(s["gold"] as int, state["gold"] as int)


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
	# When reroll fails, shop_items stays as-is (all null — no items yet).
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
