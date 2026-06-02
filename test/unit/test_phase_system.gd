extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func test_to_battle_sets_phase() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	assert_eq(s["phase"], "battle")


func test_to_battle_resets_timer() -> void:
	var state := _make_state()
	state["battle_timer"] = 7.5
	var s := PhaseSystem.to_battle(state)
	assert_eq(s["battle_timer"], 0.0)


func test_to_battle_preserves_gold() -> void:
	var state := _make_state()
	state["gold"] = 7
	var s := PhaseSystem.to_battle(state)
	assert_eq(s["gold"], 7)


func test_to_battle_does_not_mutate_original() -> void:
	var state := _make_state()
	PhaseSystem.to_battle(state)
	assert_eq(state["phase"], "shop")


func test_advance_round_increments_round() -> void:
	var state := _make_state()
	state["round"] = 3
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["round"], 4)


func test_advance_round_does_not_reset_player_hp() -> void:
	var state := _make_state()
	state["player_hp"] = 12
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["player_hp"], 12)


func test_advance_round_sets_phase_to_shop() -> void:
	var state := _make_state()
	state["phase"] = "result"
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["phase"], "shop")


func test_advance_round_does_not_mutate_original() -> void:
	var state := _make_state()
	state["round"] = 2
	PhaseSystem.advance_round(state)
	assert_eq(state["round"], 2)


# ── to_battle: battle state initialisation ───────────────────────────────────

func test_to_battle_populates_opponent_grid() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	var grid: Array = s["opponent_grid"]
	var has_element: bool = false
	for slot: Variant in grid:
		if slot != null:
			has_element = true
			break
	assert_true(has_element)


func test_to_battle_sets_positive_opponent_hp() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	assert_gt(s["opponent_hp"] as int, 0)


func test_to_battle_initialises_battle_stats_with_player_and_opponent() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	var bstats: Dictionary = s["battle_stats"] as Dictionary
	assert_true(bstats.has("player"))
	assert_true(bstats.has("opponent"))


func test_to_battle_battle_stats_has_four_player_slots() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_eq(pstats.size(), 4)


func test_to_battle_battle_stats_has_four_opponent_slots() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	var ostats: Array = (s["battle_stats"] as Dictionary)["opponent"] as Array
	assert_eq(ostats.size(), 4)


func test_to_battle_clears_battle_events() -> void:
	var state := _make_state()
	state["battle_events"] = [{"side": "player", "slot": 0}]
	var s := PhaseSystem.to_battle(state)
	assert_eq((s["battle_events"] as Array).size(), 0)


func test_to_battle_resets_element_timers_to_zero() -> void:
	var state := _make_state()
	state["element_timers"] = [1.5, 2.0, 0.5, 3.0]
	var s := PhaseSystem.to_battle(state)
	for t: Variant in s["element_timers"]:
		assert_eq(t as float, 0.0)


# ── advance_round: state resets ───────────────────────────────────────────────

func test_advance_round_resets_shop_items_to_null_array() -> void:
	var state := _make_state()
	state["shop_items"][0] = ElementData.find("water").duplicate()
	var s := PhaseSystem.advance_round(state)
	for item: Variant in s["shop_items"]:
		assert_null(item)


func test_advance_round_clears_battle_events() -> void:
	var state := _make_state()
	state["battle_events"] = [{"side": "opponent", "slot": 1}]
	var s := PhaseSystem.advance_round(state)
	assert_eq((s["battle_events"] as Array).size(), 0)


# ── to_battle: opponent_starting_hp + player_hp reset ────────────────────────

# ── advance_round: win tracking ──────────────────────────────────────────────

func test_advance_round_increments_wins_when_player_wins() -> void:
	var state := _make_state()
	state["player_hp"] = 10
	state["opponent_hp"] = 0
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["wins"], 1)


func test_advance_round_increments_wins_on_draw() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 0
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["wins"], 1)


func test_advance_round_sets_victory_phase_at_10_wins() -> void:
	var state := _make_state()
	state["wins"] = 9
	state["player_hp"] = 10
	state["opponent_hp"] = 0
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["wins"], 10)
	assert_eq(s["phase"], "victory")


func test_advance_round_does_not_increment_wins_on_loss() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 15
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["wins"], 0)


# ── advance_round: Lives deduction ───────────────────────────────────────────

func test_advance_round_deducts_3_lives_on_hard_loss() -> void:
	# opponent has 70% of starting HP remaining → hard loss
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 14
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["lives"], 7)


func test_advance_round_deducts_2_lives_on_medium_loss() -> void:
	# opponent has exactly 50% remaining → medium loss
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 10
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["lives"], 8)


func test_advance_round_deducts_1_life_on_close_loss() -> void:
	# opponent has 25% remaining → close loss
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 5
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["lives"], 9)


func test_advance_round_sets_eliminated_when_lives_reach_0() -> void:
	var state := _make_state()
	state["lives"] = 3
	state["player_hp"] = 0
	state["opponent_hp"] = 14   # hard loss → –3
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["lives"], 0)
	assert_eq(s["phase"], "eliminated")


func test_advance_round_sets_shop_phase_on_surviving_loss() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 5    # close loss → –1
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["phase"], "shop")


# ── advance_round: gold income ────────────────────────────────────────────────

func test_advance_round_adds_5_gold() -> void:
	var state := _make_state()
	state["gold"] = 3
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["gold"], 8)


# ── to_battle: opponent_starting_hp + player_hp reset ────────────────────────

func test_to_battle_stores_opponent_starting_hp() -> void:
	var s := PhaseSystem.to_battle(_make_state())
	assert_gt(s["opponent_starting_hp"] as int, 0)
	assert_eq(s["opponent_starting_hp"] as int, s["opponent_hp"] as int)


func test_to_battle_resets_player_hp_to_30() -> void:
	var state := _make_state()
	state["player_hp"] = 5
	var s := PhaseSystem.to_battle(state)
	assert_eq(s["player_hp"], 30)
