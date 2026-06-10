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


# A combat state with EMPTY boards on both sides, so no element fires or statuses act
# — only the Sandstorm (ADR 0012) can change HP. Lets storm behaviour be asserted in
# isolation.
func _storm_state(player_hp: int, opp_hp: int, timer: float) -> Dictionary:
	var s := _make_state()
	s["phase"] = "battle"
	s["player_hp"] = player_hp
	s["opponent_hp"] = opp_hp
	s["battle_timer"] = timer
	return s


# ── compute_opponent_hp ───────────────────────────────────────────────────────

func test_compute_opponent_hp_round_one_is_base() -> void:
	assert_eq(BattleSystem.compute_opponent_hp(1), TuningData.OPPONENT_BASE_HP)


func test_compute_opponent_hp_scales_by_round() -> void:
	var round_num: int = 5
	var growth: float = 1.0 + float(TuningData.OPPONENT_HP_GROWTH_PERCENT) / 100.0 * float(round_num - 1)
	var expected: int = maxi(TuningData.OPPONENT_HP_MIN, int(round(float(TuningData.OPPONENT_BASE_HP) * growth)))
	assert_eq(BattleSystem.compute_opponent_hp(round_num), expected)


func test_compute_opponent_hp_grows_each_round() -> void:
	assert_gt(BattleSystem.compute_opponent_hp(6), BattleSystem.compute_opponent_hp(1))


# Only damage-dealers deal direct hit damage now (most elements are pure-effect), so
# damage-asserting tests use Boulder (T2, base 4, in ElementData.DAMAGE_DEALERS).
const DEALER := "boulder"

func _dealer_cooldown() -> float:
	return float(ElementData.find(DEALER)["cooldown_deciseconds"] as int) / 10.0

func _dealer_opponent() -> Dictionary:
	return { "grid": [ElementData.instantiate(DEALER, 1), null, null, null], "round": 1 }


# ── tick_battle ───────────────────────────────────────────────────────────────

func test_tick_battle_player_damages_opponent_at_cooldown() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element(DEALER), _fixture())
	var s := BattleSystem.tick_battle(state, _dealer_cooldown())
	assert_lt(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_tick_battle_does_not_fire_before_cooldown() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element(DEALER), _fixture())
	# Tick just under the EFFECTIVE cooldown (base × the global firing-rate dial).
	var base_ds: int = ElementData.find(DEALER)["cooldown_deciseconds"] as int
	var effective: float = float(StatusSystem.effective_cooldown_deciseconds(base_ds, StatusSystem.empty_statuses())) / 10.0
	var s := BattleSystem.tick_battle(state, effective - 0.1)
	assert_eq(s["opponent_hp"] as int, state["opponent_hp"] as int)


func test_tick_battle_opponent_damages_player() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _dealer_opponent())
	var s := BattleSystem.tick_battle(state, _dealer_cooldown())
	assert_lt(s["player_hp"] as int, state["player_hp"] as int)


func test_tick_battle_sets_result_when_opponent_hp_zero() -> void:
	var state := PhaseSystem.to_battle(_state_with_player_element(DEALER), _fixture())
	state["opponent_hp"] = 1
	var s := BattleSystem.tick_battle(state, _dealer_cooldown())
	assert_eq(s["phase"], "result")


func test_tick_battle_sets_result_when_player_hp_zero() -> void:
	var state := PhaseSystem.to_battle(_make_state(), _dealer_opponent())
	state["player_hp"] = 1
	var s := BattleSystem.tick_battle(state, _dealer_cooldown())
	assert_eq(s["phase"], "result")


# ── Sandstorm (ADR 0012) ──────────────────────────────────────────────────────
# The 30 s mark is the storm START, not a hard end: crossing it with both sides
# healthy keeps the fight going (the storm now whittles them down to a KO).
func test_tick_battle_does_not_end_at_time_limit_alone() -> void:
	var s := _storm_state(200, 200, TuningData.BATTLE_TIME_LIMIT - 0.05)
	s = BattleSystem.tick_battle(s, 0.1)  # crosses the limit; storm deals BASE to each
	assert_eq(s["phase"], "battle")


func test_no_sandstorm_damage_before_start() -> void:
	var s := _storm_state(200, 200, 10.0)
	s = BattleSystem.tick_battle(s, 1.0)  # timer 11.0, well before the storm
	assert_eq(s["player_hp"] as int, 200)
	assert_eq(s["opponent_hp"] as int, 200)


func test_sandstorm_first_tick_hits_both_sides_for_base() -> void:
	var s := _storm_state(200, 200, TuningData.BATTLE_TIME_LIMIT - 0.05)
	s = BattleSystem.tick_battle(s, 0.1)  # crosses into the storm: storm-second 0
	assert_eq(s["player_hp"] as int, 200 - TuningData.SANDSTORM_BASE_DAMAGE)
	assert_eq(s["opponent_hp"] as int, 200 - TuningData.SANDSTORM_BASE_DAMAGE)
	assert_eq(s["sandstorm_ticks"] as int, 1)


func test_sandstorm_escalates_each_second() -> void:
	var s := _storm_state(200, 200, TuningData.BATTLE_TIME_LIMIT - 0.05)
	s = BattleSystem.tick_battle(s, 0.1)  # storm-second 0 → BASE
	s = BattleSystem.tick_battle(s, 1.0)  # storm-second 1 → BASE + RAMP
	var expected_loss: int = TuningData.SANDSTORM_BASE_DAMAGE \
		+ (TuningData.SANDSTORM_BASE_DAMAGE + TuningData.SANDSTORM_RAMP_PER_SECOND)
	assert_eq(s["player_hp"] as int, 200 - expected_loss)
	assert_eq(s["opponent_hp"] as int, 200 - expected_loss)
	assert_eq(s["sandstorm_ticks"] as int, 2)


# The storm guarantees a KO, so the fight always resolves by elimination (equal boards
# → mutual KO same tick → draw), not a flat timeout — and well before the hard cap.
func test_sandstorm_resolves_fight_by_elimination() -> void:
	var s := BattleSystem.simulate_battle(_storm_state(200, 200, 0.0))
	assert_eq(s["phase"], "result")
	assert_lte(s["player_hp"] as int, 0)
	assert_lte(s["opponent_hp"] as int, 0)
	assert_gt(s["battle_timer"] as float, TuningData.BATTLE_TIME_LIMIT)
	assert_lte(s["battle_timer"] as float, TuningData.SANDSTORM_HARD_CAP_SECONDS + 1.0)


# The hard cap is a pure determinism backstop: even HP the storm can't chew through by
# the cap force-ends the fight (both still alive → opponent survives → a loss).
func test_tick_battle_ends_at_hard_cap_even_if_both_alive() -> void:
	var s := _storm_state(100000, 100000, 0.0)
	s = BattleSystem.tick_battle(s, TuningData.SANDSTORM_HARD_CAP_SECONDS + 0.1)
	assert_eq(s["phase"], "result")
	assert_gt(s["player_hp"] as int, 0)
	assert_gt(s["opponent_hp"] as int, 0)


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
	var state := PhaseSystem.to_battle(_state_with_player_element(DEALER), _fixture())
	var s := BattleSystem.tick_battle(state, _dealer_cooldown())
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
	var state := PhaseSystem.to_battle(_state_with_player_element(DEALER), _fixture())
	(state["player_frozen_seconds"] as Array)[0] = 1.0
	var blocked := BattleSystem.tick_battle(state, 1.0)  # freeze drains to 0, no fire this tick
	assert_eq(blocked["opponent_hp"] as int, state["opponent_hp"] as int)
	var released := BattleSystem.tick_battle(blocked, _dealer_cooldown())  # now unfrozen → fires
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
	_silence_opponent(st)  # isolate the player's on-hit apply (no opponent cleanse interference)
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


# ── on_activate abilities through the combat tick ─────────────────────────────

func _silence_opponent(st: Dictionary) -> void:
	# Null the opponent board so only the player's element moves combat state
	# (opponent_hp is already set from the pre-null grid). Keeps fire counts and
	# leech deterministic without opponent blind/weaken interference.
	var opp_grid: Array = st["opponent_grid"] as Array
	for i: int in opp_grid.size():
		opp_grid[i] = null


func test_on_activate_ability_applies_through_tick() -> void:
	var ability: Dictionary = { "trigger": "on_activate",
		"effects": [{ "kind": "apply_status", "status": "poison", "amount": 1, "target": "opponent" }] }
	var st := _battle_with_player_ability("fire", ability)
	_silence_opponent(st)  # isolate the player's on_activate apply (no opponent cleanse interference)
	var cooldown: float = float(ElementData.find("fire")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(st, cooldown)
	assert_eq(((s["opponent_statuses"] as Dictionary)["poison"] as Dictionary)["stacks"] as int, 1)


func test_shrapnel_applies_shock_only_every_third_fire() -> void:
	var st := PhaseSystem.to_battle(_state_with_player_element("shrapnel"), _fixture())
	_silence_opponent(st)
	var cooldown: float = float(ElementData.find("shrapnel")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(st, cooldown)        # fire 1
	s = BattleSystem.tick_battle(s, cooldown)              # fire 2
	assert_eq(((s["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int, 0, "no shock before the 3rd fire")
	s = BattleSystem.tick_battle(s, cooldown)              # fire 3 → shock
	assert_eq(((s["opponent_statuses"] as Dictionary)["shock"] as Dictionary)["n"] as int, 1, "shock on the 3rd fire")


func test_rainbow_periodic_heals_and_armors_own_side() -> void:
	# rainbow is periodic (every 5s) → all four colors are live, unlike the inert
	# combat_start version. Heal + armor land on the own side after one interval.
	var st := PhaseSystem.to_battle(_state_with_player_element("rainbow"), _fixture())
	_silence_opponent(st)
	var before_hp: int = st["player_hp"] as int
	var s := BattleSystem.tick_battle(st, 5.0)
	assert_gt(s["player_hp"] as int, before_hp, "rainbow periodic should heal its own side")
	assert_gt(((s["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0, "rainbow periodic should grant armor")


func test_gore_lifesteals_and_weakens_on_fire() -> void:
	var st := PhaseSystem.to_battle(_state_with_player_element("gore"), _fixture())
	_silence_opponent(st)
	var before_hp: int = st["player_hp"] as int
	var cooldown: float = float(ElementData.find("gore")["cooldown_deciseconds"] as int) / 10.0
	var s := BattleSystem.tick_battle(st, cooldown)
	assert_gt(s["player_hp"] as int, before_hp, "gore should lifesteal for the damage it dealt")
	assert_gt(((s["opponent_statuses"] as Dictionary)["weaken"] as Dictionary)["stacks"] as int, 0, "gore should also apply weaken")


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

func test_compute_result_player_wins_when_opponent_eliminated() -> void:
	var state := _make_state()
	state["player_hp"] = 20
	state["opponent_hp"] = 0
	assert_eq(BattleSystem.compute_result(state), "player_wins")


# Regression: an opponent still alive at the end is a LOSS even with a big HP lead
# (a 30 s timeout). Win = opponent eliminated, not the higher HP bar.
func test_compute_result_opponent_wins_when_opponent_survives_despite_hp_lead() -> void:
	var state := _make_state()
	state["player_hp"] = 20
	state["opponent_hp"] = 5
	assert_eq(BattleSystem.compute_result(state), "opponent_wins")


func test_compute_result_opponent_wins_when_player_eliminated() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 20
	assert_eq(BattleSystem.compute_result(state), "opponent_wins")


func test_compute_result_draw_on_mutual_elimination() -> void:
	var state := _make_state()
	state["player_hp"] = 0
	state["opponent_hp"] = 0
	assert_eq(BattleSystem.compute_result(state), "draw")
