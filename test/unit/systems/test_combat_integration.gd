extends GutTest

# Battle-interaction / composition coverage (the layer unit tests miss): drives REAL
# combat through PhaseSystem.to_battle → BattleSystem.tick_battle and asserts that a
# modifier actually changes the fight's outcome — not just that it set a field.
#
# Pattern: A/B with the SAME board + SAME seed (round 1 → hash("combat:1")), one run with
# a modifier and one without, asserting the HP delta moves the right way. This proves the
# whole chain pick → Augment → begin_combat injection → status field → tick math → HP,
# end to end, and survives internal refactors (it asserts behaviour, not internals).


# An opponent that does nothing, so the only thing moving opponent_hp is the player's
# own statuses — isolates the effect under test.
func _idle_opponent() -> Dictionary:
	return { "grid": [null, null, null, null], "round": 1 }


func _with_player_elements(ids: Array) -> Dictionary:
	var s := GameState.create()
	var grid: Array = s["battle_grid"] as Array
	for i: int in mini(ids.size(), grid.size()):
		grid[i] = ElementData.instantiate(ids[i] as String, 1)
	return s


# Advances combat in faithful fixed steps (like simulate_battle) up to `seconds`, so DOT
# status ticks fire on their real 1 s cadence rather than collapsing into one big step.
func _advance(state: Dictionary, seconds: float) -> Dictionary:
	var elapsed: float = 0.0
	while elapsed < seconds and (state["phase"] as String) != "result":
		state = BattleSystem.tick_battle(state, BattleSystem.COMBAT_STEP_SECONDS)
		elapsed += BattleSystem.COMBAT_STEP_SECONDS
	return state


# ── (A) flat amplify Keystone changes the fight ───────────────────────────────

func test_ashen_affinity_makes_burns_deal_more_over_a_fight() -> void:
	# Fire applies Burn each fire; Ashen Affinity sets the opponent's burn tick bonus +1,
	# so every burn tick hurts more → opponent ends the window at LOWER HP.
	var base := _with_player_elements(["fire"])

	var without := PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	without = _advance(without, 8.0)

	var with_keystone := StartSystem.apply_starting_pick(base.duplicate(true), "ashen_affinity")
	with_keystone = PhaseSystem.to_battle(with_keystone, _idle_opponent())
	with_keystone = _advance(with_keystone, 8.0)

	assert_lt(with_keystone["opponent_hp"] as int, without["opponent_hp"] as int,
		"Ashen Affinity should make the player's burns deal more damage over the fight")


# ── (A) scaling Keystone rides the board count, end to end ────────────────────

func test_emberswarm_scales_burn_with_fire_count() -> void:
	# Emberswarm = burn tick bonus × Fire pieces on board. Same board (2 Fire) in both
	# runs, so the only difference is the scaled keystone → more damage with it.
	var base := _with_player_elements(["fire", "fire"])

	var without := PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	without = _advance(without, 8.0)

	var with_keystone := StartSystem.apply_starting_pick(base.duplicate(true), "emberswarm")
	with_keystone = PhaseSystem.to_battle(with_keystone, _idle_opponent())
	with_keystone = _advance(with_keystone, 8.0)

	assert_lt(with_keystone["opponent_hp"] as int, without["opponent_hp"] as int,
		"Emberswarm should scale burn by the Fire count, dealing more over the fight")


# ── (B) two sources buffing one field compose additively ──────────────────────

func test_two_sources_stack_the_same_modifier_field() -> void:
	# The core composition worry: a Keystone and an element ability both buffing burn must
	# ADD, not overwrite. set_status_field accumulates with += — assert two applications
	# from independent virtual sources reach 2.
	var s := GameState.create()
	var atom: Dictionary = { "kind": "set_status_field", "status": "burn", "field": "tick_damage_bonus", "value": 1, "target": "opponent" }
	s = AbilitySystem.apply_external_effects(s, [atom], "player")
	s = AbilitySystem.apply_external_effects(s, [atom], "player")
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["tick_damage_bonus"] as int, 2,
		"two sources buffing burn.tick_damage_bonus stack additively")


# ── (C) a pure-effect DOT element's reported damage includes its ticks ────────
# Regression guard for the Summary bug (DOT element showed Dmg/DPS 0): summary_rows must
# fold DOT contribution into the displayed damage, not just direct hits.

func test_pure_effect_poison_element_reports_dot_damage_in_summary() -> void:
	var state := PhaseSystem.to_battle(_with_player_elements(["fungus"]), _idle_opponent())
	state = _advance(state, 6.0)  # fungus fires → poisons → ticks
	var rows: Array[Dictionary] = BattleSystem.summary_rows(state, "player")
	assert_gt(rows.size(), 0, "an occupied board yields a summary row")
	assert_gt(rows[0]["damage"] as int, 0, "poison element's Summary damage includes its DOT ticks")
	assert_gt(rows[0]["dps"] as float, 0.0, "and therefore a non-zero DPS")
