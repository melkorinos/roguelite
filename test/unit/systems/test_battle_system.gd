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
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(state, cooldown)
	assert_lt(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_tick_battle_does_not_fire_before_cooldown() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
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
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
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
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	BattleSystem.tick_battle(state, cooldown)
	assert_eq(state["opponent_hp"] as int, original_hp)


func test_tick_battle_accumulates_fires_in_battle_stats() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(state, cooldown)
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_eq((pstats[0] as Dictionary)["fires"], 1)


func test_tick_battle_accumulates_damage_in_battle_stats() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(state, cooldown)
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_gt((pstats[0] as Dictionary)["damage"] as int, 0)


func test_tick_battle_advances_battle_timer() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _fixture())
	var s := BattleSystem.tick_battle(state, 1.5)
	assert_eq(s["battle_timer"] as float, 1.5)


# ── select_freeze_target — anti-permalock ─────────────────────────────────────

func _grid4(occupied: Array) -> Array:
	var grid: Array = [null, null, null, null]
	for i: int in occupied:
		var elem: Dictionary = ElementData.find("fire").duplicate()
		elem["element_id"] = "fire"
		elem["level"] = 1
		grid[i] = elem
	return grid


func test_select_freeze_target_picks_first_occupied() -> void:
	assert_eq(BattleSystem.select_freeze_target(_grid4([0, 1, 2, 3]), -1), 0)


func test_select_freeze_target_skips_last_frozen_slot() -> void:
	assert_eq(BattleSystem.select_freeze_target(_grid4([0, 1, 2, 3]), 0), 1)


func test_select_freeze_target_refreezes_when_no_alternative() -> void:
	assert_eq(BattleSystem.select_freeze_target(_grid4([2]), 2), 2)


func test_select_freeze_target_returns_minus_one_when_empty() -> void:
	assert_eq(BattleSystem.select_freeze_target(_grid4([]), -1), -1)


# ── freeze in combat — skip fire + countdown ──────────────────────────────────

func test_frozen_player_element_does_not_fire() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	(state["player_frozen_seconds"] as Array)[0] = 5.0
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(state, cooldown)
	assert_eq(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_freeze_releases_element_after_it_expires() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	(state["player_frozen_seconds"] as Array)[0] = 1.0
	var blocked := BattleSystem.tick_battle(state, 1.0)  # freeze drains to 0, no fire this tick
	assert_eq(blocked["opponent_hp"] as int, state["opponent_hp"] as int)
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var released := BattleSystem.tick_battle(blocked, cooldown)  # now unfrozen → fires
	assert_lt(released["opponent_hp"] as int, blocked["opponent_hp"] as int)


# ── seeded RNG + on-hit passives ──────────────────────────────────────────────

func _battle_with_player_ability(element_id: String, ability: Dictionary) -> Dictionary:
	var st := _make_state()
	var elem: Dictionary = ElementData.find(element_id).duplicate()
	elem["element_id"] = element_id
	elem["level"] = 1
	elem["ability"] = ability
	st["battle_grid"][0] = elem
	return PhaseSystem.to_battle(st, _fixture())


func test_on_hit_passive_applies_status_at_full_chance() -> void:
	var ability: Dictionary = { "trigger": "passive_on_hit",
		"effects": [{ "status": "weaken", "chance": 100, "target": "opponent" }] }
	var st := _battle_with_player_ability("fire", ability)
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(st, cooldown)
	assert_gt(((s["opponent_statuses"] as Dictionary)["weaken"] as Dictionary)["stacks"] as int, 0)


func test_on_hit_passive_never_applies_at_zero_chance() -> void:
	var ability: Dictionary = { "trigger": "passive_on_hit",
		"effects": [{ "status": "weaken", "chance": 0, "target": "opponent" }] }
	var st := _battle_with_player_ability("fire", ability)
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(st, cooldown)
	assert_eq(((s["opponent_statuses"] as Dictionary)["weaken"] as Dictionary)["stacks"] as int, 0)


func test_combat_is_deterministic_given_seed() -> void:
	# Two runs from the same combat-start state must produce identical results,
	# even with a probabilistic on-hit passive in play.
	var ability: Dictionary = { "trigger": "passive_on_hit",
		"effects": [{ "status": "weaken", "chance": 50, "target": "opponent" }] }
	var st := _battle_with_player_ability("blaze", ability)
	var run_a: Dictionary = st.duplicate(true)
	var run_b: Dictionary = st.duplicate(true)
	for _i: int in 20:
		run_a = BattleSystem.tick_battle(run_a, 0.5)
	for _i: int in 20:
		run_b = BattleSystem.tick_battle(run_b, 0.5)
	assert_eq(run_a["opponent_hp"] as int, run_b["opponent_hp"] as int)
	assert_eq(((run_a["opponent_statuses"] as Dictionary)["weaken"] as Dictionary)["stacks"] as int,
		((run_b["opponent_statuses"] as Dictionary)["weaken"] as Dictionary)["stacks"] as int)


# ── simulate_battle (fixed-step headless sim) ─────────────────────────────────

func test_simulate_battle_reaches_result() -> void:
	var st := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var s := BattleSystem.simulate_battle(st)
	assert_eq(s["phase"] as String, "result")


func test_simulate_battle_is_deterministic() -> void:
	var st := PhaseSystem.to_battle(_state_with_player_element("blaze"), _fixture())
	var a := BattleSystem.simulate_battle(st.duplicate(true))
	var b := BattleSystem.simulate_battle(st.duplicate(true))
	assert_eq(a["opponent_hp"] as int, b["opponent_hp"] as int)
	assert_eq(a["player_hp"] as int, b["player_hp"] as int)


# ── battle_stats effects tally (Summary) ──────────────────────────────────────

func test_battle_stats_counts_on_fire_effects() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element("fire"), _fixture())
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(state, cooldown)
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_gt((pstats[0] as Dictionary)["effects"] as int, 0)  # fire applied burn


func test_battle_stats_counts_ability_effects_at_combat_start() -> void:
	# Boulder: combat_start applies 4 [armor] to own side → 4 effect applications.
	var st := _make_state()
	var elem: Dictionary = ElementData.find("boulder").duplicate()
	elem["element_id"] = "boulder"
	elem["level"] = 1
	st["battle_grid"][0] = elem
	var s := PhaseSystem.to_battle(st, _fixture())
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	assert_eq((pstats[0] as Dictionary)["effects"] as int, 4)


func test_battle_stats_tracks_effects_by_status() -> void:
	# Boulder: combat_start applies 4 [armor] → breakdown { armor: 4 }.
	var st := _make_state()
	var elem: Dictionary = ElementData.find("boulder").duplicate()
	elem["element_id"] = "boulder"
	elem["level"] = 1
	st["battle_grid"][0] = elem
	var s := PhaseSystem.to_battle(st, _fixture())
	var pstats: Array = (s["battle_stats"] as Dictionary)["player"] as Array
	var by_status: Dictionary = (pstats[0] as Dictionary)["effects_by_status"] as Dictionary
	assert_eq(by_status["armor"] as int, 4)


# ── timed commands (Innate Ability / Replay seam) ─────────────────────────────

func _deal3_command() -> Dictionary:
	return { "effects": [{ "kind": "deal_damage", "amount": 3, "target": "opponent" }] }


func test_queue_command_appends_pending() -> void:
	var st := PhaseSystem.to_battle(_make_state(), _fixture())
	var s := BattleSystem.queue_command(st, 1.0, _deal3_command(), "player")
	assert_eq((s["pending_commands"] as Array).size(), 1)


func test_command_fires_at_its_time() -> void:
	# Empty player grid → opponent_hp only changes via the command.
	var st := PhaseSystem.to_battle(_make_state(), _fixture())
	st = BattleSystem.queue_command(st, 1.0, _deal3_command(), "player")
	var before: int = st["opponent_hp"] as int
	var s := BattleSystem.tick_battle(st, 1.0)
	assert_eq(s["opponent_hp"] as int, before - 3)


func test_command_does_not_fire_before_its_time() -> void:
	var st := PhaseSystem.to_battle(_make_state(), _fixture())
	st = BattleSystem.queue_command(st, 5.0, _deal3_command(), "player")
	var before: int = st["opponent_hp"] as int
	var s := BattleSystem.tick_battle(st, 1.0)
	assert_eq(s["opponent_hp"] as int, before)


func test_command_fires_only_once() -> void:
	var st := PhaseSystem.to_battle(_make_state(), _fixture())
	st = BattleSystem.queue_command(st, 0.5, _deal3_command(), "player")
	var before: int = st["opponent_hp"] as int
	var s := BattleSystem.tick_battle(st, 1.0)
	s = BattleSystem.tick_battle(s, 1.0)
	assert_eq(s["opponent_hp"] as int, before - 3)


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
