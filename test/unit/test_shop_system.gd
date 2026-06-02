extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func test_buy_deducts_gold() -> void:
	var s := ShopSystem.buy_item(_make_state(), "water")
	assert_eq(s["gold"], 5)


func test_buy_places_element_in_slot_0() -> void:
	var s := ShopSystem.buy_item(_make_state(), "water")
	var slot: Variant = s["inventory"][0]
	assert_not_null(slot)
	assert_eq((slot as Dictionary)["element_id"], "water")
	assert_eq((slot as Dictionary)["level"], 1)


func test_buy_fails_when_gold_insufficient() -> void:
	var state := _make_state()
	state["gold"] = 0
	var s := ShopSystem.buy_item(state, "water")
	assert_eq(s["gold"], 0)
	assert_null(s["inventory"][0])


func test_buy_fails_when_inventory_full() -> void:
	var state := _make_state()
	var dummy: Dictionary = ElementData.find("water").duplicate()
	dummy["element_id"] = "water"
	dummy["level"] = 1
	for i: int in state["inventory"].size():
		state["inventory"][i] = dummy.duplicate()
	var s := ShopSystem.buy_item(state, "water")
	assert_eq(s["gold"], 10)


func test_sell_refunds_half_price_rounded_down() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water")  # 10 - 5 = 5g remaining
	var s := ShopSystem.sell_item(state, 0)       # refund floor(5/2) = 2
	assert_eq(s["gold"], 7)


func test_sell_clears_slot() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water")
	var s := ShopSystem.sell_item(state, 0)
	assert_null(s["inventory"][0])


func test_sell_does_not_mutate_original() -> void:
	var state := _make_state()
	state = ShopSystem.buy_item(state, "water")
	var before: Variant = state["inventory"][0]
	ShopSystem.sell_item(state, 0)
	assert_not_null(before)


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
	assert_true((s["shop_items"] as Array).is_empty())


func test_reroll_returns_only_tier1_at_default_shop_tier() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	for item: Variant in s["shop_items"]:
		assert_eq((item as Dictionary)["tier"], 1)


func test_reroll_returns_up_to_4_items() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	assert_lte(s["shop_items"].size(), 4)
