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


# ── (A) full mitigation stack on ONE hit ──────────────────────────────────────
# compute_incoming_damage IS the whole defensive pipeline. These pin the exact
# arithmetic AND the application order. Code is truth: the order is
# weaken(attacker) → plating → armor → curse — NOT the handoff's "armor→plating",
# and blind is NOT here at all (it's a fire-time miss, tested separately below).

func _attacker_with_weaken(stacks: int) -> Dictionary:
	var a: Dictionary = StatusSystem.empty_statuses()
	var w: Dictionary = a["weaken"] as Dictionary
	w["stacks"] = stacks
	w["ticks"] = 1  # weaken only bites while ticks > 0
	return a


func _defender(plating: int, armor: int, armor_floor: int, curse: int) -> Dictionary:
	var d: Dictionary = StatusSystem.empty_statuses()
	(d["plating"] as Dictionary)["value"] = plating
	var ar: Dictionary = d["armor"] as Dictionary
	ar["value"] = armor
	ar["floor"] = armor_floor
	var c: Dictionary = d["curse"] as Dictionary
	c["stacks"] = curse
	c["damage_amplifier"] = TuningData.CURSE_DOT_AMPLIFIER if curse > 0 else 0
	return d


func test_full_mitigation_stack_exact_arithmetic() -> void:
	# raw 10 → weaken(2): 8 → plating(3): 5 → armor(2 pts): 3 → curse(+1): 4.
	var hit: Dictionary = StatusSystem.compute_incoming_damage(10, _attacker_with_weaken(2), _defender(3, 2, 0, 1))
	assert_eq(hit["damage"] as int, 4, "weaken→plating→armor→curse compose to exactly 4")
	var def_s: Dictionary = hit["defender_statuses"] as Dictionary
	assert_eq((def_s["armor"] as Dictionary)["value"] as int, 0, "the 2 armor points were spent")
	assert_eq((def_s["curse"] as Dictionary)["stacks"] as int, 0, "a surviving hit spends one curse charge")


func test_plating_applies_before_armor() -> void:
	# raw 4, plating 3, armor 3: code order (plating first) leaves dmg 1 for armor to
	# soak, spending only 1 armor point (2 left). Armor-first would have spent 3 (0 left).
	# Final dmg is 0 either way — armor REMAINING is the witness to the order.
	var hit: Dictionary = StatusSystem.compute_incoming_damage(4, StatusSystem.empty_statuses(), _defender(3, 3, 0, 0))
	assert_eq(hit["damage"] as int, 0, "fully mitigated")
	assert_eq(((hit["defender_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 2,
		"plating ran first, so armor only had to spend 1 of its 3 points")


func test_blind_suppresses_the_fire_it_does_not_reduce_damage() -> void:
	# Blind is NOT in compute_incoming_damage; it's a fire-time miss that cancels the
	# whole shot. A 100%-blinded side that should fire repeatedly deals 0 over a window.
	var base: Dictionary = _with_player_elements(["fire"])
	var state: Dictionary = PhaseSystem.to_battle(base, _idle_opponent())
	var blind: Dictionary = (state["player_statuses"] as Dictionary)["blind"] as Dictionary
	blind["percent"] = 100
	var before_hp: int = state["opponent_hp"] as int
	state = _advance(state, 6.0)
	var fires: int = 0
	for row: Dictionary in BattleSystem.summary_rows(state, "player"):
		fires += row["fires"] as int
	assert_eq(fires, 0, "a fully-blinded side never lands a fire")
	# fire is pure-effect (0 direct), so HP only moves via burn it can't apply while blind.
	assert_eq(state["opponent_hp"] as int, before_hp, "no fires → no burn applied → no HP lost")


# ── (C) curse charge / primer consumption semantics ───────────────────────────
# The user's explicit worry: a curse charge is spent ONLY on a damaging event, never
# on a non-damaging one (a fully-mitigated hit, a frozen slot, a no-DOT tick). And a
# DOT primer fires exactly once. Code is truth.

func _cursed_defender(stacks: int) -> Dictionary:
	var d: Dictionary = StatusSystem.empty_statuses()
	var c: Dictionary = d["curse"] as Dictionary
	c["stacks"] = stacks
	c["damage_amplifier"] = TuningData.CURSE_DOT_AMPLIFIER
	return d


func test_curse_direct_hit_spends_one_charge() -> void:
	var hit: Dictionary = StatusSystem.compute_incoming_damage(10, StatusSystem.empty_statuses(), _cursed_defender(2))
	assert_eq(hit["damage"] as int, 10 + TuningData.CURSE_DOT_AMPLIFIER, "a damaging hit is amplified")
	assert_eq(((hit["defender_statuses"] as Dictionary)["curse"] as Dictionary)["stacks"] as int, 1, "and spends one charge")


func test_curse_fully_mitigated_hit_spends_nothing() -> void:
	# raw 4 vs plating 3 + armor 3 → dmg 0. A 0-damage hit (the same class of event as
	# a freeze) neither amplifies nor consumes.
	var hit: Dictionary = StatusSystem.compute_incoming_damage(4, StatusSystem.empty_statuses(), _defender(3, 3, 0, 2))
	assert_eq(hit["damage"] as int, 0, "hit mitigated to 0")
	assert_eq(((hit["defender_statuses"] as Dictionary)["curse"] as Dictionary)["stacks"] as int, 2,
		"a non-damaging event spends no curse charge")


func test_curse_dot_tick_spends_one_charge() -> void:
	var statuses: Dictionary = _cursed_defender(2)
	(statuses["poison"] as Dictionary)["stacks"] = 1
	var res: Dictionary = StatusSystem.tick(statuses)
	assert_eq(res["damage"] as int, TuningData.POISON_DAMAGE_PER_STACK + TuningData.CURSE_DOT_AMPLIFIER, "the DOT tick is amplified")
	assert_eq(((res["statuses"] as Dictionary)["curse"] as Dictionary)["stacks"] as int, 1, "a DOT tick spends one charge")


func test_curse_unchanged_by_nondamaging_tick() -> void:
	# No DOT present → tick deals 0 → curse is untouched. A frozen slot is the same
	# case from the curse's point of view: it produces no damaging event.
	var res: Dictionary = StatusSystem.tick(_cursed_defender(2))
	assert_eq(res["damage"] as int, 0, "no DOT → no tick damage")
	assert_eq(((res["statuses"] as Dictionary)["curse"] as Dictionary)["stacks"] as int, 2, "no charge spent on a non-damaging tick")


func test_dot_primer_is_consumed_exactly_once() -> void:
	var statuses: Dictionary = StatusSystem.empty_statuses()
	var burn: Dictionary = statuses["burn"] as Dictionary
	burn["stacks"] = 3
	burn["next_tick_bonus"] = 5
	var first: Dictionary = StatusSystem.tick(statuses)
	assert_eq(first["damage"] as int, 3 * TuningData.BURN_DAMAGE_PER_STACK + 5, "the primer adds to the first tick")
	var second: Dictionary = StatusSystem.tick(first["statuses"] as Dictionary)
	assert_eq(second["damage"] as int, 2 * TuningData.BURN_DAMAGE_PER_STACK, "the primer is gone on the next tick")


func test_cleanse_floors_at_zero_and_leaves_curse() -> void:
	var statuses: Dictionary = _cursed_defender(2)
	(statuses["burn"] as Dictionary)["stacks"] = 1
	(statuses["poison"] as Dictionary)["stacks"] = 1
	# Massive potency >> stacks: must floor at 0, never go negative.
	var res: Dictionary = StatusSystem.apply_effect(statuses, "cleanse", 99)
	var s: Dictionary = res["statuses"] as Dictionary
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0, "burn floored at 0")
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, 0, "poison floored at 0")
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 2, "curse is not cleansable (code truth)")


# ── (B) per-modifier field A/B: each field proves it changes a real fight ──────
# Style: inject the field (as its ability/keystone would set it) into ONE of two
# otherwise-identical fights (same board, same seed) and assert the outcome delta moves
# the right way. The ability→field wiring is locked separately (test_ability_data /
# test_keystone_data validate every set_status_field/set_side_field); these prove the
# field, once set, is honoured end-to-end by the tick/damage math.

# An opponent whose board fires back at the player (direct damage / DOT), so player-side
# defensive fields have something to bite on.
func _attacking_opponent(ids: Array) -> Dictionary:
	var grid: Array = []
	for i: int in CombatState.SLOT_COUNT:
		grid.append(ElementData.instantiate(ids[i] as String, 1) if i < ids.size() else null)
	return { "grid": grid, "round": 1 }


func _total_fires(state: Dictionary, side: String) -> int:
	var fires: int = 0
	for row: Dictionary in BattleSystem.summary_rows(state, side):
		fires += row["fires"] as int
	return fires


func test_outgoing_damage_flat_penalty_lowers_player_damage() -> void:
	var base: Dictionary = _with_player_elements(["blood"])  # a direct-damage dealer
	var without: Dictionary = _advance(PhaseSystem.to_battle(base.duplicate(true), _idle_opponent()), 8.0)
	var with_penalty: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	(with_penalty["player_statuses"] as Dictionary)["outgoing_damage_flat"] = -3
	with_penalty = _advance(with_penalty, 8.0)
	assert_gt(with_penalty["opponent_hp"] as int, without["opponent_hp"] as int,
		"a flat outgoing penalty leaves the opponent at higher HP")


func test_cooldown_modifier_penalty_lowers_fire_count() -> void:
	var base: Dictionary = _with_player_elements(["blood"])
	var without: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	without["opponent_hp"] = 100000  # don't let a KO truncate the window
	without = _advance(without, 8.0)
	var slower: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	slower["opponent_hp"] = 100000
	(slower["player_statuses"] as Dictionary)["cooldown_modifier_deciseconds"] = 40
	slower = _advance(slower, 8.0)
	assert_lt(_total_fires(slower, "player"), _total_fires(without, "player"),
		"a positive cooldown modifier makes the side fire fewer times in the window")


func test_suppress_heal_blocks_a_nature_healer() -> void:
	# Forest heals own every 2nd activation. With an idle opponent the player takes no
	# damage, so without suppression its HP climbs above the lowered start; with it, flat.
	var base: Dictionary = _with_player_elements(["forest"])
	var without: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	without["player_hp"] = 50
	without = _advance(without, 10.0)
	var suppressed: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	suppressed["player_hp"] = 50
	(suppressed["player_statuses"] as Dictionary)["suppress_heal"] = true
	suppressed = _advance(suppressed, 10.0)
	assert_lt(suppressed["player_hp"] as int, without["player_hp"] as int,
		"suppress_heal stops the healer's HP gain")
	assert_eq(suppressed["player_hp"] as int, 50, "a suppressed side gains no HP from heal")


func test_armor_floor_caps_absorption_and_retains_armor() -> void:
	# floor lowers absorbable capacity (absorbable = value - floor) but keeps that many
	# stacks: the floored side blocks LESS yet ends with armor still standing.
	var opp: Dictionary = _attacking_opponent(["blood", "blood"])
	var no_floor: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	no_floor["player_hp"] = 100000
	var armor_nf: Dictionary = (no_floor["player_statuses"] as Dictionary)["armor"] as Dictionary
	armor_nf["value"] = 5
	armor_nf["floor"] = 0
	no_floor = _advance(no_floor, 8.0)
	var floored: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	floored["player_hp"] = 100000
	var armor_f: Dictionary = (floored["player_statuses"] as Dictionary)["armor"] as Dictionary
	armor_f["value"] = 5
	armor_f["floor"] = 3
	floored = _advance(floored, 8.0)
	var nf_left: int = ((no_floor["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int
	var f_left: int = ((floored["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int
	assert_gte(f_left, 3, "the floor keeps armor from dropping below 3")
	assert_lt(nf_left, f_left, "without a floor, armor was spent further down")


func test_plating_reduces_dot_shaves_incoming_burn() -> void:
	# Opponent burns the player; plating with reduces_dot shaves each DOT tick, so the
	# player ends the window at higher HP than with plain (direct-only) plating.
	var opp: Dictionary = _attacking_opponent(["fire", "fire"])
	var off: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	off["player_hp"] = 100000
	var plating_off: Dictionary = (off["player_statuses"] as Dictionary)["plating"] as Dictionary
	plating_off["value"] = 3
	plating_off["reduces_dot"] = false
	off = _advance(off, 8.0)
	var on: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	on["player_hp"] = 100000
	var plating_on: Dictionary = (on["player_statuses"] as Dictionary)["plating"] as Dictionary
	plating_on["value"] = 3
	plating_on["reduces_dot"] = true
	on = _advance(on, 8.0)
	assert_gt(on["player_hp"] as int, off["player_hp"] as int,
		"plating.reduces_dot shaves DOT, so the player takes less burn")


func test_weaken_duration_bonus_extends_the_damage_cut() -> void:
	# Opponent attacks; the player weakens it. A duration bonus keeps the weaken active for
	# more ticks, so the opponent's output stays suppressed longer → player keeps more HP.
	var opp: Dictionary = _attacking_opponent(["blood", "blood"])
	var short: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	short["player_hp"] = 100000
	short["opponent_statuses"] = StatusSystem.apply_effect(short["opponent_statuses"] as Dictionary, "weaken", 3)["statuses"]
	short = _advance(short, 8.0)
	var long: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	long["player_hp"] = 100000
	(long["opponent_statuses"] as Dictionary)["weaken"]["duration_bonus"] = 6
	long["opponent_statuses"] = StatusSystem.apply_effect(long["opponent_statuses"] as Dictionary, "weaken", 3)["statuses"]
	long = _advance(long, 8.0)
	assert_gt(long["player_hp"] as int, short["player_hp"] as int,
		"a longer weaken suppresses the opponent's damage for more of the fight")


func test_shock_effective_stack_bonus_slows_the_opponent_more() -> void:
	# Opponent is shocked; the effective_stack_bonus makes the slow behave as if more
	# stacks exist, so the opponent fires fewer times across the window.
	var opp: Dictionary = _attacking_opponent(["blood", "blood"])
	var low: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	low["player_hp"] = 100000
	(low["opponent_statuses"] as Dictionary)["shock"]["n"] = 2
	low = _advance(low, 8.0)
	var high: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), opp)
	high["player_hp"] = 100000
	var shock_high: Dictionary = (high["opponent_statuses"] as Dictionary)["shock"] as Dictionary
	shock_high["n"] = 2
	shock_high["effective_stack_bonus"] = 6
	high = _advance(high, 8.0)
	assert_lt(_total_fires(high, "opponent"), _total_fires(low, "opponent"),
		"a higher effective shock bonus slows the opponent into fewer fires")


# ── (D) timing as a fight consequence ─────────────────────────────────────────
# Cooldown math is unit-tested; these prove the FIGHT consequence: haste → more fires,
# shock → fewer fires, a frozen slot → zero fires while frozen. Same board + seed; the
# only difference is the timing modifier, so the fire-count delta is the modifier's doing.

func _fires_by_slot(state: Dictionary, side: String) -> Dictionary:
	var by_slot: Dictionary = {}
	for row: Dictionary in BattleSystem.summary_rows(state, side):
		by_slot[row["slot"] as int] = row["fires"] as int
	return by_slot


func test_haste_makes_the_side_fire_more() -> void:
	var base: Dictionary = _with_player_elements(["water"])
	var control: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	control["opponent_hp"] = 100000
	control = _advance(control, 12.0)
	var hasted: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	hasted["opponent_hp"] = 100000
	# Apply the real haste_timers atom (Air's on-fire effect) once per second — the actual
	# mechanism that speeds firing: it shaves every own cooldown timer.
	var elapsed: float = 0.0
	var next_haste: float = 1.0
	while elapsed < 12.0 and (hasted["phase"] as String) != "result":
		hasted = BattleSystem.tick_battle(hasted, BattleSystem.COMBAT_STEP_SECONDS)
		elapsed += BattleSystem.COMBAT_STEP_SECONDS
		if elapsed >= next_haste:
			hasted = AbilitySystem.apply_external_effects(hasted, [{ "kind": "haste_timers", "target": "own" }], "player")
			next_haste += 1.0
	assert_gt(_total_fires(hasted, "player"), _total_fires(control, "player"),
		"haste (timer shave) makes the side fire more in the same window")


func test_shock_makes_the_side_fire_fewer() -> void:
	var base: Dictionary = _with_player_elements(["water"])
	var control: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	control["opponent_hp"] = 100000
	control = _advance(control, 12.0)
	var shocked: Dictionary = PhaseSystem.to_battle(base.duplicate(true), _idle_opponent())
	shocked["opponent_hp"] = 100000
	(shocked["player_statuses"] as Dictionary)["shock"]["n"] = 5
	shocked = _advance(shocked, 12.0)
	assert_lt(_total_fires(shocked, "player"), _total_fires(control, "player"),
		"shock slows the side into fewer fires over the window")


func test_frozen_slot_does_not_fire_while_frozen() -> void:
	var state: Dictionary = PhaseSystem.to_battle(_with_player_elements(["water", "water"]), _idle_opponent())
	state["opponent_hp"] = 100000
	(state["player_frozen_seconds"] as Array)[0] = 5.0  # freeze outlasts the window below
	state = _advance(state, 4.0)
	var fires: Dictionary = _fires_by_slot(state, "player")
	assert_eq(fires[0] as int, 0, "the frozen slot fires 0 while frozen")
	assert_gt(fires[1] as int, 0, "the unfrozen slot keeps firing")


# ── (E) side isolation: buffs/debuffs never bleed to the wrong side ────────────

func test_self_buff_does_not_leak_to_the_opponent() -> void:
	# Boulder's combat_start applies armor to its OWN side only.
	var state: Dictionary = PhaseSystem.to_battle(_with_player_elements(["boulder"]), _idle_opponent())
	assert_gt(((state["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0,
		"boulder armored its own side")
	assert_eq(((state["opponent_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0,
		"the opponent received none of the player's armor")


func test_debuff_lands_only_on_the_target_side() -> void:
	# Fire burns the OPPONENT; the player never burns itself.
	var state: Dictionary = PhaseSystem.to_battle(_with_player_elements(["fire"]), _idle_opponent())
	state["opponent_hp"] = 100000
	state = _advance(state, 4.0)
	assert_gt(((state["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0,
		"fire burned the opponent")
	assert_eq(((state["player_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0,
		"the player never burned itself")


func test_apply_external_effects_routes_to_the_named_side_only() -> void:
	# Directly exercises the atom dispatcher's side routing (target own vs opponent).
	var s: Dictionary = PhaseSystem.to_battle(_with_player_elements([]), _idle_opponent())
	s = AbilitySystem.apply_external_effects(s, [{ "kind": "apply_status", "status": "armor", "amount": 3, "target": "own" }], "player")
	assert_gt(((s["player_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0, "own-target buff hit the player")
	assert_eq(((s["opponent_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0, "and not the opponent")
	s = AbilitySystem.apply_external_effects(s, [{ "kind": "apply_status", "status": "burn", "amount": 3, "target": "opponent" }], "player")
	assert_gt(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0, "opponent-target debuff hit the opponent")
	assert_eq(((s["player_statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0, "and not the player")


# ── leech (Blood T1): the last T1 status mechanic ─────────────────────────────
# Closes the 12th T1 effect. Blood is a direct-damage dealer with an on-fire leech: each
# landing hit heals its own side by the damage dealt. Idle opponent (no damage back) +
# lowered start HP → the only thing that can move player HP UP is the leech itself.
# NOTE: leech_heal does NOT honour suppress_heal (only the `heal` effect does), so a
# Plague-Pact "cannot heal" side would still lifesteal — flagged as a design follow-up,
# deliberately NOT asserted here.
func test_leech_heals_its_own_side_on_a_damaging_hit() -> void:
	var state: Dictionary = PhaseSystem.to_battle(_with_player_elements(["blood"]), _idle_opponent())
	state["opponent_hp"] = 100000
	state["player_hp"] = 50
	state = _advance(state, 12.0)
	assert_gt(state["player_hp"] as int, 50, "Blood's leech heals its own side as it lands hits")
