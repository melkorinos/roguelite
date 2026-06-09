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
	var before: int = state["gold"] as int
	var price: int = (state["shop_items"][0] as Dictionary)["price"] as int
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_eq(s["gold"] as int, before - price)


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
	var before: int = state["gold"] as int
	var price: int = (state["shop_items"][1] as Dictionary)["price"] as int
	var s := ShopSystem.transfer(state, {"zone": "shop", "slot": 1}, {"zone": "inventory", "slot": 0})
	assert_eq(s["gold"] as int, before - price)


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
	var state := _make_state()
	var s := ShopSystem.reroll_shop(state, true)
	assert_eq(s["gold"] as int, state["gold"] as int)


func test_reroll_costs_2_gold() -> void:
	var state := _make_state()
	var s := ShopSystem.reroll_shop(state)
	assert_eq(s["gold"] as int, (state["gold"] as int) - 2)


func test_reroll_fails_without_enough_gold() -> void:
	var state := _make_state()
	state["gold"] = 1
	var s := ShopSystem.reroll_shop(state)
	var all_null: bool = (s["shop_items"] as Array).all(func(x: Variant) -> bool: return x == null)
	assert_true(all_null)


# ── escalating reroll cost (resets each round) ────────────────────────────────

func test_reroll_cost_starts_at_base() -> void:
	assert_eq(ShopSystem.reroll_cost(_make_state()), TuningData.REROLL_BASE_COST)


func test_paid_reroll_escalates_cost_by_one() -> void:
	var state := _make_state()
	var after_first := ShopSystem.reroll_shop(state)
	assert_eq(after_first["reroll_count"] as int, 1)
	assert_eq(ShopSystem.reroll_cost(after_first), TuningData.REROLL_BASE_COST + 1)


func test_second_paid_reroll_costs_one_more_gold() -> void:
	var state := _make_state()
	var a := ShopSystem.reroll_shop(state)          # costs base (2)
	var gold_after_first: int = a["gold"] as int
	var b := ShopSystem.reroll_shop(a)              # costs base+1 (3)
	assert_eq(b["gold"] as int, gold_after_first - (TuningData.REROLL_BASE_COST + 1))


func test_free_reroll_does_not_escalate_or_charge() -> void:
	var state := _make_state()
	var s := ShopSystem.reroll_shop(state, true)
	assert_eq(s["gold"] as int, state["gold"] as int)
	assert_eq(s["reroll_count"] as int, 0)


# ── reroll_discount Run Modifier (ADR 0011) ───────────────────────────────────

func test_reroll_discount_reduces_cost() -> void:
	var state := _make_state()
	state["reroll_discount"] = 1
	assert_eq(ShopSystem.reroll_cost(state), TuningData.REROLL_BASE_COST - 1)


func test_reroll_discount_floored_at_zero() -> void:
	var state := _make_state()
	state["reroll_discount"] = TuningData.REROLL_BASE_COST + 100
	assert_eq(ShopSystem.reroll_cost(state), 0)


func test_advance_round_resets_reroll_count() -> void:
	var state := _make_state()
	state = ShopSystem.reroll_shop(state)
	state["opponent_hp"] = 0  # count it as a win so advance_round routes back to shop
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["reroll_count"] as int, 0)


func test_reroll_fills_exactly_5_slots() -> void:
	var s := ShopSystem.reroll_shop(_make_state(), true)
	assert_eq(s["shop_items"].size(), 5)
	for item: Variant in s["shop_items"]:
		assert_not_null(item)


# ── discovery-gated shop pool (ADR 0007) ──────────────────────────────────────

func test_unlocked_tiers_t1_only_when_no_discoveries() -> void:
	assert_eq(ShopSystem.unlocked_tiers([]), [1] as Array[int])


func test_t2_locked_below_three_distinct() -> void:
	assert_false(ShopSystem.unlocked_tiers(["arc", "static"]).has(2))


func test_t2_unlocked_at_three_distinct() -> void:
	assert_true(ShopSystem.unlocked_tiers(["arc", "static", "surge"]).has(2))


func test_t3_unlocked_at_two_distinct() -> void:
	assert_true(ShopSystem.unlocked_tiers(["glacier", "blizzard"]).has(3))


func test_eligible_tier1_is_full_pool() -> void:
	assert_eq(ShopSystem.eligible_for_tier([], 1).size(), 12)


func test_eligible_t2_limited_to_used_families() -> void:
	# Discovered Lightning T2s → families {lightning, fire, air, water}.
	var eligible: Array[Dictionary] = ShopSystem.eligible_for_tier(["arc", "static", "surge"], 2)
	var ids: Dictionary = {}
	for e: Dictionary in eligible:
		ids[e["id"] as String] = true
	assert_true(ids.has("arc"), "a discovered element is in its own family")
	assert_false(ids.has("frostbite"), "blood+frost T2 shares no used family → excluded")


func test_reroll_only_tier1_with_no_discoveries() -> void:
	for _i: int in 20:
		var s := ShopSystem.reroll_shop(_make_state(), true)
		for item: Variant in s["shop_items"]:
			if item != null:
				assert_eq((item as Dictionary)["tier"], 1)


func test_reroll_keeps_tier2_locked_below_threshold() -> void:
	var state := _make_state()
	state["run_discoveries"] = ["arc", "static"]  # only 2 distinct T2
	for _i: int in 30:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if item != null:
				assert_eq((item as Dictionary)["tier"], 1)


func test_reroll_shows_tier2_after_unlock() -> void:
	var state := _make_state()
	state["run_discoveries"] = ["arc", "static", "surge"]
	var found_t2: bool = false
	for _i: int in 40:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if item != null and (item as Dictionary)["tier"] == 2:
				found_t2 = true
	assert_true(found_t2)


func test_reroll_tier2_pool_stays_within_families() -> void:
	var state := _make_state()
	state["run_discoveries"] = ["arc", "static", "surge"]
	var eligible_ids: Dictionary = {}
	for e: Dictionary in ShopSystem.eligible_for_tier(["arc", "static", "surge"], 2):
		eligible_ids[e["id"] as String] = true
	var seen_t2: bool = false
	for _i: int in 30:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if item != null and (item as Dictionary)["tier"] == 2:
				seen_t2 = true
				assert_true(eligible_ids.has((item as Dictionary)["id"] as String), "T2 shop item outside the family pool")
	assert_true(seen_t2, "expected at least one T2 in the family-filtered shop")


# Regression: with a higher tier unlocked the T1/higher mix must VARY across rerolls,
# not lock to the old "always 1×T1 + 4×higher". Every slot rolls T1 ~70% independently.
func test_reroll_mix_varies_after_unlock() -> void:
	var state := _make_state()
	state["run_discoveries"] = ["arc", "static", "surge"]
	var seen_counts: Dictionary = {}
	for _i: int in 60:
		var s := ShopSystem.reroll_shop(state, true)
		var t1: int = 0
		for item: Variant in s["shop_items"]:
			if item != null and (item as Dictionary)["tier"] == 1:
				t1 += 1
		seen_counts[t1] = true
	assert_gt(seen_counts.size(), 1, "T1 count should vary round to round, not be fixed")


func test_reroll_shows_tier3_after_unlock() -> void:
	var state := _make_state()
	state["run_discoveries"] = ["glacier", "blizzard"]  # 2 distinct T3
	var found_t3: bool = false
	for _i: int in 40:
		var s := ShopSystem.reroll_shop(state, true)
		for item: Variant in s["shop_items"]:
			if item != null and (item as Dictionary)["tier"] == 3:
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


# ── resolve_drop: outcome-reporting shop intake ───────────────────────────────

func test_resolve_drop_buy_into_empty_reports_bought() -> void:
	var state := _state_with_shop_item(0, "water")
	var r := ShopSystem.resolve_drop(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_eq(r["outcome"], "bought")
	assert_not_null((r["state"] as Dictionary)["inventory"][0])


func test_resolve_drop_buy_onto_matching_level1_reports_merged() -> void:
	var state := _state_with_inv_item(0, "water")
	state["shop_items"][0] = ElementData.find("water").duplicate()
	var r := ShopSystem.resolve_drop(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": 0})
	assert_eq(r["outcome"], "merged")
	assert_eq(((r["state"] as Dictionary)["inventory"][0] as Dictionary)["level"], 2)


func test_resolve_drop_rejects_when_gold_insufficient() -> void:
	var state := _state_with_shop_item(0, "water")
	state["gold"] = 0
	var r := ShopSystem.resolve_drop(state, {"zone": "shop", "slot": 0}, {"zone": "inventory", "slot": -1})
	assert_eq(r["outcome"], "rejected")


func test_resolve_drop_grid_merge_same_element_reports_merged() -> void:
	var state := _make_state()
	for slot: int in [0, 1]:
		var elem: Dictionary = ElementData.find("fire").duplicate()
		elem["element_id"] = "fire"
		elem["level"] = 1
		state["battle_grid"][slot] = elem
	var r := ShopSystem.resolve_drop(state, {"zone": "grid", "slot": 0}, {"zone": "grid", "slot": 1})
	assert_eq(r["outcome"], "merged")
	# level_up_grid lands the result in the lower index (mini) and clears the other.
	assert_eq(((r["state"] as Dictionary)["battle_grid"][0] as Dictionary)["level"], 2)
	assert_null((r["state"] as Dictionary)["battle_grid"][1])


func test_resolve_drop_grid_swap_different_elements_reports_swapped() -> void:
	var state := _make_state()
	var fire: Dictionary = ElementData.find("fire").duplicate()
	fire["element_id"] = "fire"
	fire["level"] = 1
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["battle_grid"][0] = fire
	state["battle_grid"][1] = water
	var r := ShopSystem.resolve_drop(state, {"zone": "grid", "slot": 0}, {"zone": "grid", "slot": 1})
	assert_eq(r["outcome"], "swapped")
	assert_eq(((r["state"] as Dictionary)["battle_grid"][0] as Dictionary)["element_id"], "water")


func test_resolve_drop_inventory_non_mergeable_reports_rejected() -> void:
	var state := _state_with_inv_item(0, "fire")
	var water: Dictionary = ElementData.find("water").duplicate()
	water["element_id"] = "water"
	water["level"] = 1
	state["inventory"][1] = water
	var r := ShopSystem.resolve_drop(state, {"zone": "inventory", "slot": 0}, {"zone": "inventory", "slot": 1})
	assert_eq(r["outcome"], "rejected")


# ── drag-drop intake seam: drag_to_loc + can_drop ─────────────────────────────

func test_drag_to_loc_translates_shop_payload() -> void:
	assert_eq(ShopSystem.drag_to_loc({"type": "shop", "shop_slot": 2}), {"zone": "shop", "slot": 2})


func test_drag_to_loc_translates_grid_and_inventory() -> void:
	assert_eq(ShopSystem.drag_to_loc({"type": "grid", "slot": 1}), {"zone": "grid", "slot": 1})
	assert_eq(ShopSystem.drag_to_loc({"type": "inventory", "slot": 3}), {"zone": "inventory", "slot": 3})


func test_drag_to_loc_empty_for_unknown_or_missing() -> void:
	assert_true((ShopSystem.drag_to_loc({"type": "junk"})).is_empty())
	assert_true((ShopSystem.drag_to_loc({"type": "grid"})).is_empty())  # no slot


func test_can_drop_shop_to_inventory_with_gold() -> void:
	var state := _state_with_shop_item(0, "water")
	assert_true(ShopSystem.can_drop(state, {"type": "shop", "shop_slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_drop_rejects_when_gold_insufficient() -> void:
	var state := _state_with_shop_item(0, "water")
	state["gold"] = 0
	assert_false(ShopSystem.can_drop(state, {"type": "shop", "shop_slot": 0}, {"zone": "inventory", "slot": 0}))


func test_can_drop_rejects_non_dictionary_payload() -> void:
	assert_false(ShopSystem.can_drop(_make_state(), null, {"zone": "inventory", "slot": 0}))


func test_can_drop_grid_to_inventory_allowed() -> void:
	var state := _make_state()
	var elem: Dictionary = ElementData.find("fire").duplicate()
	elem["element_id"] = "fire"; elem["level"] = 1
	state["battle_grid"][0] = elem
	assert_true(ShopSystem.can_drop(state, {"type": "grid", "slot": 0}, {"zone": "inventory", "slot": 1}))


func test_can_drop_grid_onto_same_grid_slot_rejected() -> void:
	assert_false(ShopSystem.can_drop(_make_state(), {"type": "grid", "slot": 2}, {"zone": "grid", "slot": 2}))
