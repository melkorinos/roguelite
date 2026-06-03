extends GutTest


func _make_state() -> Dictionary:
	return GameState.create()


func _fixture() -> Dictionary:
	return GhostFixtures.get_fixture(1)


func _state_with_player_element(element_id: String) -> Dictionary:
	var state := _make_state()
	var elem: Dictionary = ElementData.find(element_id).duplicate()
	elem["element_id"] = element_id
	elem["level"] = 1
	state["battle_grid"][0] = elem
	return state


# ── create_opponent_grid ──────────────────────────────────────────────────────

func test_create_opponent_grid_round1_contains_fire_and_water() -> void:
	var grid := BattleSystem.create_opponent_grid(1)
	var ids: Array = []
	for slot: Variant in grid:
		if slot != null:
			ids.append((slot as Dictionary)["element_id"])
	assert_true(ids.has("fire"))
	assert_true(ids.has("water"))


func test_create_opponent_grid_has_four_slots() -> void:
	var grid := BattleSystem.create_opponent_grid(1)
	assert_eq(grid.size(), 4)


func test_create_opponent_grid_level_1_at_round_1() -> void:
	var grid := BattleSystem.create_opponent_grid(1)
	assert_eq((grid[0] as Dictionary)["level"], 1)


func test_create_opponent_grid_level_2_at_round_4() -> void:
	var grid := BattleSystem.create_opponent_grid(4)
	assert_eq((grid[0] as Dictionary)["level"], 2)


# ── compute_opponent_hp ───────────────────────────────────────────────────────

func test_compute_opponent_hp_has_minimum_of_15() -> void:
	var grid: Array = [null, null, null, null]
	assert_eq(BattleSystem.compute_opponent_hp(grid), 15)


func test_compute_opponent_hp_enforces_minimum_for_low_damage() -> void:
	# fire damage=2, so 1 element → 2*5=10 < 15 → clamped to 15
	var elem: Dictionary = ElementData.find("fire").duplicate()
	elem["element_id"] = "fire"
	elem["level"] = 1
	var grid: Array = [elem, null, null, null]
	assert_eq(BattleSystem.compute_opponent_hp(grid), 15)


func test_compute_opponent_hp_sums_damage_across_all_elements() -> void:
	# lava damage=3; 4 slots → 4*3*5=60
	var lava: Dictionary = ElementData.find("lava").duplicate()
	lava["element_id"] = "lava"
	lava["level"] = 1
	var grid: Array = [lava, lava.duplicate(), lava.duplicate(), lava.duplicate()]
	assert_eq(BattleSystem.compute_opponent_hp(grid), 60)


# ── tick_battle ───────────────────────────────────────────────────────────────

func test_tick_battle_player_damages_opponent_at_cooldown() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = ElementData.find("fire")["cooldown"]
	var s := BattleSystem.tick_battle(state, cooldown)
	assert_lt(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_tick_battle_does_not_fire_before_cooldown() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = ElementData.find("fire")["cooldown"]
	var s := BattleSystem.tick_battle(state, cooldown - 0.1)
	assert_eq(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_tick_battle_opponent_damages_player() -> void:
	# Tier-1 fixture has fire (cooldown 2.5) — tick past it
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	var s := BattleSystem.tick_battle(state, 3.0)
	assert_lt(s["player_hp"] as int, state["player_hp"] as int)


func test_tick_battle_sets_result_when_opponent_hp_zero() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	state["opponent_hp"] = 1
	var cooldown: float = ElementData.find("fire")["cooldown"]
	var s := BattleSystem.tick_battle(state, cooldown)
	assert_eq(s["phase"], "result")


func test_tick_battle_sets_result_when_player_hp_zero() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	state["player_hp"] = 1
	# Tier-1 fixture fire cooldown is 2.5 — one tick at 3.0 kills player
	var s := BattleSystem.tick_battle(state, 3.0)
	assert_eq(s["phase"], "result")


func test_tick_battle_sets_result_at_time_limit() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	var s := BattleSystem.tick_battle(state, BattleSystem.BATTLE_TIME_LIMIT + 0.1)
	assert_eq(s["phase"], "result")


func test_tick_battle_returns_state_unchanged_when_already_result() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	state["phase"] = "result"
	var s := BattleSystem.tick_battle(state, 1.0)
	assert_eq(s["phase"], "result")
	assert_eq(s["battle_timer"] as float, state["battle_timer"] as float)


func test_tick_battle_does_not_mutate_original() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var original_hp: int = state["opponent_hp"]
	var cooldown: float = ElementData.find("fire")["cooldown"]
	BattleSystem.tick_battle(state, cooldown)
	assert_eq(state["opponent_hp"] as int, original_hp)


func test_tick_battle_accumulates_fires_in_battle_stats() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = ElementData.find("fire")["cooldown"]
	var s := BattleSystem.tick_battle(state, cooldown)
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_eq((pstats[0] as Dictionary)["fires"], 1)


func test_tick_battle_accumulates_damage_in_battle_stats() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = ElementData.find("fire")["cooldown"]
	var s := BattleSystem.tick_battle(state, cooldown)
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_gt((pstats[0] as Dictionary)["damage"] as int, 0)


func test_tick_battle_advances_battle_timer() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	var s := BattleSystem.tick_battle(state, 1.5)
	assert_eq(s["battle_timer"] as float, 1.5)


# ── compute_result ────────────────────────────────────────────────────────────

func test_compute_result_player_wins_when_opponent_hp_lower() -> void:
	var state := _make_state()
	state["player_hp"] = 20
	state["opponent_hp"] = 5
	assert_eq(BattleSystem.compute_result(state), "player_wins")


func test_compute_result_opponent_wins_when_player_hp_lower() -> void:
	var state := _make_state()
	state["player_hp"] = 5
	state["opponent_hp"] = 20
	assert_eq(BattleSystem.compute_result(state), "opponent_wins")


func test_compute_result_draw_on_equal_hp() -> void:
	var state := _make_state()
	state["player_hp"] = 10
	state["opponent_hp"] = 10
	assert_eq(BattleSystem.compute_result(state), "draw")
