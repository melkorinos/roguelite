extends GutTest


func test_zero_floats_sized_to_slot_count() -> void:
	var arr := CombatState.zero_floats()
	assert_eq(arr.size(), CombatState.SLOT_COUNT)
	for v: Variant in arr:
		assert_eq(v as float, 0.0)


func test_empty_slots_are_all_null() -> void:
	var arr := CombatState.empty_slots()
	assert_eq(arr.size(), CombatState.SLOT_COUNT)
	for v: Variant in arr:
		assert_null(v)


func test_explicit_count_overrides_slot_count() -> void:
	assert_eq(CombatState.zero_floats(9).size(), 9)
	assert_eq(CombatState.empty_slots(6).size(), 6)
	assert_eq((CombatState.empty_battle_stats(9)["player"] as Array).size(), 9)


func test_empty_stat_row_shape() -> void:
	var row := CombatState.empty_stat_row()
	assert_eq(row["fires"] as int, 0)
	assert_eq(row["damage"] as int, 0)
	assert_eq(row["effects"] as int, 0)
	assert_eq((row["effects_by_status"] as Dictionary).size(), 0)


func test_empty_stat_rows_are_independent_dicts() -> void:
	var rows := CombatState.empty_stat_rows()
	(rows[0] as Dictionary)["fires"] = 5
	assert_eq((rows[1] as Dictionary)["fires"] as int, 0)


func test_empty_battle_stats_has_both_sides() -> void:
	var stats := CombatState.empty_battle_stats()
	assert_true(stats.has("player"))
	assert_true(stats.has("opponent"))
	assert_eq((stats["player"] as Array).size(), CombatState.SLOT_COUNT)
	assert_eq((stats["opponent"] as Array).size(), CombatState.SLOT_COUNT)


func test_reset_zeroes_all_per_slot_arrays() -> void:
	var state := GameState.create()
	state["battle_timer"] = 7.0
	(state["element_timers"] as Array)[0] = 3.0
	(state["player_frozen_seconds"] as Array)[1] = 2.0
	state["player_last_frozen_slot"] = 2
	CombatState.reset(state)
	assert_eq(state["battle_timer"] as float, 0.0)
	assert_eq((state["element_timers"] as Array)[0] as float, 0.0)
	assert_eq((state["player_frozen_seconds"] as Array)[1] as float, 0.0)
	assert_eq(state["player_last_frozen_slot"] as int, -1)


func test_reset_provides_fresh_status_pools() -> void:
	var state := GameState.create()
	CombatState.reset(state)
	assert_true((state["player_statuses"] as Dictionary).has("burn"))
	assert_true((state["opponent_statuses"] as Dictionary).has("burn"))


func test_reset_returns_same_dict_reference() -> void:
	var state := GameState.create()
	assert_eq(CombatState.reset(state), state)


func test_reset_sizes_player_arrays_to_player_count() -> void:
	var state := GameState.create()
	CombatState.reset(state, 6, 4)
	assert_eq((state["element_timers"] as Array).size(), 6)
	assert_eq((state["player_frozen_seconds"] as Array).size(), 6)
	assert_eq((state["player_ability_timers"] as Array).size(), 6)
	assert_eq((state["battle_stats"]["player"] as Array).size(), 6)


func test_reset_sizes_opponent_arrays_to_opponent_count() -> void:
	var state := GameState.create()
	CombatState.reset(state, 6, 4)
	assert_eq((state["opponent_timers"] as Array).size(), 4)
	assert_eq((state["opponent_frozen_seconds"] as Array).size(), 4)
	assert_eq((state["opponent_ability_timers"] as Array).size(), 4)
	assert_eq((state["battle_stats"]["opponent"] as Array).size(), 4)


func test_reset_opponent_count_defaults_to_player_count() -> void:
	var state := GameState.create()
	CombatState.reset(state, 8)
	assert_eq((state["element_timers"] as Array).size(), 8)
	assert_eq((state["opponent_timers"] as Array).size(), 8)
