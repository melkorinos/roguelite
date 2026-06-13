extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func _fixture() -> Dictionary:
	return GhostFixtures.get_fixture(1)


func test_to_battle_sets_phase() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	assert_eq(s["phase"], "battle")


func test_to_battle_resets_timer() -> void:
	var state := _make_state()
	state["battle_timer"] = 7.5
	var s := PhaseSystem.to_battle(state, _fixture())
	assert_eq(s["battle_timer"], 0.0)


func test_to_battle_preserves_gold() -> void:
	var state := _make_state()
	state["gold"] = 7
	var s := PhaseSystem.to_battle(state, _fixture())
	assert_eq(s["gold"], 7)


func test_to_battle_does_not_mutate_original() -> void:
	var state := _make_state()
	PhaseSystem.to_battle(state, _fixture())
	assert_eq(state["phase"], "shop")


func test_advance_round_increments_round() -> void:
	var state := _make_state()
	state["round"] = 3
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["round"], 4)


func test_advance_round_scales_player_hp_with_round() -> void:
	var state := _make_state()
	state["player_hp"] = 12
	var s := PhaseSystem.advance_round(state)
	var expected: int = TuningData.BASE_PLAYER_HP + ((s["round"] as int) - 1) * TuningData.HP_PER_ROUND
	assert_eq(s["player_hp"] as int, expected)


# Regression: the HP-bar max (player_starting_hp) must track the round-scaled HP, so
# the shop never shows current > max (the "33/30 after round 1" bug).
func test_advance_round_keeps_starting_hp_in_step_with_player_hp() -> void:
	var s := PhaseSystem.advance_round(_make_state())
	assert_eq(s["player_starting_hp"] as int, s["player_hp"] as int)


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
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	var grid: Array = s["opponent_grid"]
	var has_element: bool = false
	for slot: Variant in grid:
		if slot != null:
			has_element = true
			break
	assert_true(has_element)


func test_to_battle_sets_positive_opponent_hp() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	assert_gt(s["opponent_hp"] as int, 0)


func test_to_battle_initialises_battle_stats_with_player_and_opponent() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	var bstats: Dictionary = s["battle_stats"] as Dictionary
	assert_true(bstats.has("player"))
	assert_true(bstats.has("opponent"))


func test_to_battle_battle_stats_has_four_player_slots() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_eq(pstats.size(), 4)


func test_to_battle_battle_stats_has_four_opponent_slots() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	var ostats: Array = (s["battle_stats"] as Dictionary)["opponent"] as Array
	assert_eq(ostats.size(), 4)


func test_to_battle_clears_battle_events() -> void:
	var state := _make_state()
	state["battle_events"] = [{"side": "player", "slot": 0}]
	var s := PhaseSystem.to_battle(state, _fixture())
	assert_eq((s["battle_events"] as Array).size(), 0)


func test_to_battle_resets_element_timers_to_zero() -> void:
	var state := _make_state()
	state["element_timers"] = [1.5, 2.0, 0.5, 3.0]
	var s := PhaseSystem.to_battle(state, _fixture())
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

func test_advance_round_life_loss_scales_with_opponent_hp_left() -> void:
	# Loss is proportional to opponent HP remaining (no buckets): round(ratio × MAX).
	for case: Array in [[14, 20], [10, 20], [5, 20]]:
		var state := _make_state()
		state["player_hp"] = 0
		state["opponent_hp"] = case[0]
		state["opponent_starting_hp"] = case[1]
		var s := PhaseSystem.advance_round(state)
		var ratio: float = float(case[0] as int) / float(case[1] as int)
		var expected_loss: int = int(round(ratio * float(TuningData.MAX_LIFE_LOSS)))
		assert_eq(s["lives"] as int, 100 - expected_loss, "ratio %.2f" % ratio)


func test_advance_round_sets_eliminated_when_life_reaches_0() -> void:
	var state := _make_state()
	state["lives"] = TuningData.MAX_LIFE_LOSS
	state["player_hp"] = 0
	state["opponent_hp"] = 20   # opponent at full → ratio 1.0 → max life loss
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_lte(s["lives"] as int, 0)
	assert_eq(s["phase"], "eliminated")


func test_advance_round_sets_shop_phase_on_surviving_loss() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 5    # narrow loss → small life loss, survives
	state["opponent_starting_hp"] = 20
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["phase"], "shop")


# ── advance_round: gold income ────────────────────────────────────────────────

func test_advance_round_adds_gold_per_round() -> void:
	var state := _make_state()
	var gold_before: int = state["gold"] as int
	var s := PhaseSystem.advance_round(state)
	assert_eq(s["gold"] as int, gold_before + TuningData.GOLD_PER_ROUND)


# ── to_battle: opponent_starting_hp + player_hp reset ────────────────────────

func test_to_battle_stores_opponent_starting_hp() -> void:
	var s := PhaseSystem.to_battle(_make_state(), _fixture())
	assert_gt(s["opponent_starting_hp"] as int, 0)
	assert_eq(s["opponent_starting_hp"] as int, s["opponent_hp"] as int)


func test_to_battle_scales_player_hp_with_round() -> void:
	var state := _make_state()
	state["player_hp"] = 5
	var s := PhaseSystem.to_battle(state, _fixture())
	var expected: int = TuningData.BASE_PLAYER_HP + ((s["round"] as int) - 1) * TuningData.HP_PER_ROUND
	assert_eq(s["player_hp"] as int, expected)
	assert_eq(s["player_starting_hp"] as int, s["player_hp"] as int)


func test_to_battle_adds_hp_bonus_reward() -> void:
	var state := _make_state()
	state["hp_bonus"] = 7
	var s := PhaseSystem.to_battle(state, _fixture())
	var expected: int = TuningData.BASE_PLAYER_HP + ((s["round"] as int) - 1) * TuningData.HP_PER_ROUND + 7
	assert_eq(s["player_hp"] as int, expected)


# ── to_battle: opponent_snapshot storage ─────────────────────────────────────

func test_to_battle_stores_opponent_snapshot() -> void:
	var snap := GhostFixtures.get_fixture(2)
	var s := PhaseSystem.to_battle(_make_state(), snap)
	assert_eq((s["opponent_snapshot"] as Dictionary)["player_id"], snap["player_id"])


func test_to_battle_reads_grid_from_snapshot() -> void:
	var snap := GhostFixtures.get_fixture(2)
	var s := PhaseSystem.to_battle(_make_state(), snap)
	var snap_grid: Array = snap["grid"] as Array
	var state_grid: Array = s["opponent_grid"] as Array
	assert_eq(state_grid.size(), 4)
	for i: int in 4:
		if snap_grid[i] == null:
			assert_null(state_grid[i])
		else:
			assert_eq((state_grid[i] as Dictionary)["element_id"],
					(snap_grid[i] as Dictionary)["element_id"])


# ── resolve_round (the single Round-outcome resolver) ─────────────────────────

# Regression: opponent alive at the end is a loss even with a big HP lead, so the
# result shown matches the Run progression (no shown-vs-applied split at timeout).
func test_resolve_round_timeout_with_hp_lead_is_a_loss() -> void:
	var r := PhaseSystem.resolve_round(_result_state(25, 5, 30))
	assert_eq(r["outcome"], "opponent_wins")
	assert_false(r["is_win"] as bool)
	assert_eq(r["event"], "round_loss")
	assert_eq(r["next_phase"], "shop")


func test_resolve_round_win_event_and_phase() -> void:
	var r := PhaseSystem.resolve_round(_result_state(10, 0, 20))
	assert_true(r["is_win"] as bool)
	assert_eq(r["event"], "round_win")
	assert_eq(r["next_phase"], "shop")


func test_resolve_round_draw_counts_as_win() -> void:
	var r := PhaseSystem.resolve_round(_result_state(0, 0, 20))
	assert_eq(r["outcome"], "draw")
	assert_true(r["is_win"] as bool)
	assert_eq(r["event"], "round_win")


func test_resolve_round_victory_event_at_threshold() -> void:
	var r := PhaseSystem.resolve_round(_result_state(10, 0, 20, TuningData.WIN_THRESHOLD - 1))
	assert_eq(r["event"], "match_win")
	assert_eq(r["next_phase"], "victory")
	assert_true(r["is_victory"] as bool)


func test_resolve_round_eliminated_event_on_fatal_loss() -> void:
	var r := PhaseSystem.resolve_round(_result_state(0, 20, 20, 0, TuningData.MAX_LIFE_LOSS))
	assert_eq(r["event"], "match_eliminated")
	assert_eq(r["next_phase"], "eliminated")
	assert_true(r["is_eliminated"] as bool)


func test_resolve_round_does_not_mutate_state() -> void:
	var s := _result_state(0, 14, 20)
	PhaseSystem.resolve_round(s)
	assert_eq(s["lives"] as int, 100)


# ── describe_result ───────────────────────────────────────────────────────────

func _result_state(player_hp: int, opp_hp: int, opp_start: int, wins: int = 0, lives: int = 100) -> Dictionary:
	var s := _make_state()
	s["phase"] = "result"
	s["player_hp"] = player_hp
	s["opponent_hp"] = opp_hp
	s["opponent_starting_hp"] = opp_start
	s["wins"] = wins
	s["lives"] = lives
	return s


func test_describe_result_player_win_increments_wins_after() -> void:
	var s := _result_state(10, 0, 20)
	var dr := PhaseSystem.describe_result(s)
	assert_eq(dr["outcome"], "player_wins")
	assert_eq(dr["wins_after"] as int, 1)
	assert_eq(dr["lives_lost"] as int, 0)


func test_describe_result_draw_increments_wins_after() -> void:
	var s := _result_state(0, 0, 20)
	var dr := PhaseSystem.describe_result(s)
	assert_eq(dr["outcome"], "draw")
	assert_eq(dr["wins_after"] as int, 1)


func test_describe_result_loss_scales_with_opponent_hp_left() -> void:
	for case: Array in [[14, 20], [10, 20], [5, 20]]:
		var s := _result_state(0, case[0], case[1])
		var dr := PhaseSystem.describe_result(s)
		var ratio: float = float(case[0] as int) / float(case[1] as int)
		var expected_loss: int = int(round(ratio * float(TuningData.MAX_LIFE_LOSS)))
		assert_eq(dr["outcome"], "opponent_wins")
		assert_eq(dr["lives_lost"] as int, expected_loss, "ratio %.2f" % ratio)
		assert_eq(dr["lives_after"] as int, 100 - expected_loss)


func test_describe_result_is_victory_at_9_wins_player_win() -> void:
	var s := _result_state(10, 0, 20, 9)
	var dr := PhaseSystem.describe_result(s)
	assert_true(dr["is_victory"] as bool)
	assert_eq(dr["wins_after"] as int, 10)


func test_describe_result_is_not_victory_below_10() -> void:
	var s := _result_state(10, 0, 20, 7)
	var dr := PhaseSystem.describe_result(s)
	assert_false(dr["is_victory"] as bool)


func test_describe_result_is_eliminated_when_life_reaches_0() -> void:
	var s := _result_state(0, 20, 20, 0, TuningData.MAX_LIFE_LOSS)  # full-margin loss wipes remaining Life
	var dr := PhaseSystem.describe_result(s)
	assert_true(dr["is_eliminated"] as bool)
	assert_lte(dr["lives_after"] as int, 0)


func test_describe_result_is_not_eliminated_on_win() -> void:
	var s := _result_state(10, 0, 20, 0, 1)
	var dr := PhaseSystem.describe_result(s)
	assert_false(dr["is_eliminated"] as bool)


func test_describe_result_does_not_mutate_state() -> void:
	var s := _result_state(0, 14, 20)
	PhaseSystem.describe_result(s)
	assert_eq(s["lives"] as int, 100)


# ── forfeit ───────────────────────────────────────────────────────────────────

func test_forfeit_sets_phase_to_eliminated() -> void:
	var s := _make_state()
	var out := PhaseSystem.forfeit(s)
	assert_eq(out["phase"], "eliminated")


func test_forfeit_does_not_mutate_original() -> void:
	var s := _make_state()
	PhaseSystem.forfeit(s)
	assert_eq(s["phase"], "shop")


# ── begin_combat (shared combat-setup seam) ───────────────────────────────────
# to_battle and the balance harness are the two adapters over begin_combat; these
# lock the shared contract so the harness can't drift from real combat.

func test_begin_combat_sets_phase_hp_and_seed_from_config() -> void:
	var s := _make_state()
	var out := PhaseSystem.begin_combat(s, [null, null, null, null], {
		"player_hp": 130, "opponent_hp": 90, "combat_seed": 42,
	})
	assert_eq(out["phase"], "battle")
	assert_eq(out["player_hp"] as int, 130)
	assert_eq(out["player_starting_hp"] as int, 130)
	assert_eq(out["opponent_hp"] as int, 90)
	assert_eq(out["opponent_starting_hp"] as int, 90)
	var expected := RandomNumberGenerator.new()
	expected.seed = 42
	assert_eq(out["combat_rng_state"], expected.state)


func test_begin_combat_sizes_each_side_from_its_own_board() -> void:
	# Asymmetric boards (Grid Growth, ADR 0014): per-side arrays size independently.
	var s := _make_state()
	s["battle_grid"] = CombatState.empty_slots(6)  # grown player board
	var out := PhaseSystem.begin_combat(s, CombatState.empty_slots(4), {
		"player_hp": 100, "opponent_hp": 100, "combat_seed": 1,
	})
	assert_eq((out["element_timers"] as Array).size(), 6, "player per-slot arrays match its 6-slot board")
	assert_eq((out["opponent_timers"] as Array).size(), 4, "opponent per-slot arrays match its 4-slot board")
	assert_eq(((out["battle_stats"] as Dictionary)["player"] as Array).size(), 6)


func test_begin_combat_fires_combat_start_abilities() -> void:
	# Boulder's combat_start grants armor — proof begin_combat ran resolve_combat_start.
	var s := _make_state()
	var elem: Dictionary = ElementData.find("boulder").duplicate()
	elem["element_id"] = "boulder"
	elem["level"] = 1
	s["battle_grid"][0] = elem
	var out := PhaseSystem.begin_combat(s, [null, null, null, null], {
		"player_hp": 130, "opponent_hp": 130, "combat_seed": 7,
	})
	assert_gt(((out["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0)
