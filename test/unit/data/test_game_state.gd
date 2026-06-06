extends GutTest


func test_create_returns_shop_phase() -> void:
	var state := GameState.create()
	assert_eq(state["phase"], "shop")


func test_create_starts_at_round_1() -> void:
	var state := GameState.create()
	assert_eq(state["round"], 1)


func test_create_has_correct_starting_gold() -> void:
	var state := GameState.create()
	assert_eq(state["gold"], 20)


func test_create_has_correct_starting_hp() -> void:
	var state := GameState.create()
	assert_eq(state["player_hp"], 30)
	assert_eq(state["opponent_hp"], 20)


func test_create_inventory_has_six_empty_slots() -> void:
	var state := GameState.create()
	assert_eq(state["inventory"].size(), 6)
	for slot: Variant in state["inventory"]:
		assert_null(slot)


func test_create_has_100_life() -> void:
	var state := GameState.create()
	assert_eq(state["lives"], 100)


func test_create_has_0_wins() -> void:
	var state := GameState.create()
	assert_eq(state["wins"], 0)


func test_create_has_opponent_starting_hp_0() -> void:
	var state := GameState.create()
	assert_eq(state["opponent_starting_hp"], 0)
