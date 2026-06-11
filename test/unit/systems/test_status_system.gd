extends GutTest


# ── helpers ───────────────────────────────────────────────────────────────────

func _s() -> Dictionary:
	return StatusSystem.empty_statuses()


func _apply(s: Dictionary, effect: String) -> Dictionary:
	return (StatusSystem.apply_effect(s, effect) as Dictionary)["statuses"] as Dictionary


func _tick_s(s: Dictionary) -> Dictionary:
	return (StatusSystem.tick(s) as Dictionary)["statuses"] as Dictionary


func _tick_dmg(s: Dictionary) -> int:
	return (StatusSystem.tick(s) as Dictionary)["damage"] as int


# ── empty_statuses — tracer bullet ───────────────────────────────────────────

func test_empty_statuses_has_all_keys() -> void:
	var s: Dictionary = _s()
	for key: String in ["burn", "poison", "armor", "plating", "blind", "shock", "slow", "haste", "weaken", "curse"]:
		assert_true(s.has(key), "missing key: %s" % key)


func test_empty_statuses_all_numeric_fields_are_zero() -> void:
	var s: Dictionary = _s()
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["armor"] as Dictionary)["value"] as int, 0)
	assert_eq((s["plating"] as Dictionary)["value"] as int, 0)
	assert_eq((s["blind"] as Dictionary)["percent"] as int, 0)
	assert_eq((s["shock"] as Dictionary)["n"] as int, 0)
	assert_eq((s["slow"] as Dictionary)["n"] as int, 0)
	assert_eq((s["haste"] as Dictionary)["reduction"] as int, 0)
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 0)
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 0)
	assert_eq(s["cooldown_modifier_deciseconds"] as int, 0)


# ── apply_effect — stacking effects ──────────────────────────────────────────

func test_apply_burn_increments_stacks() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


func test_apply_burn_twice_stacks() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 2)


func test_apply_burn_hp_delta_zero() -> void:
	var r: Dictionary = StatusSystem.apply_effect(_s(), "burn")
	assert_eq(r["hp_delta"] as int, 0)


func test_apply_poison_increments_stacks() -> void:
	var s: Dictionary = _apply(_s(), "poison")
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, 1)


func test_apply_armor_increments_value() -> void:
	var s: Dictionary = _apply(_s(), "armor")
	assert_eq((s["armor"] as Dictionary)["value"] as int, 1)


func test_apply_plating_increments_value() -> void:
	var s: Dictionary = _apply(_s(), "plating")
	assert_eq((s["plating"] as Dictionary)["value"] as int, 1)


func test_apply_blind_increments_percent() -> void:
	var s: Dictionary = _apply(_s(), "blind")
	assert_eq((s["blind"] as Dictionary)["percent"] as int, 15)


func test_apply_blind_caps_at_50_percent() -> void:
	var s: Dictionary = _s()
	for _i: int in 5:
		s = _apply(s, "blind")
	assert_eq((s["blind"] as Dictionary)["percent"] as int, 50)


func test_apply_shock_increments_n() -> void:
	var s: Dictionary = _apply(_s(), "shock")
	assert_eq((s["shock"] as Dictionary)["n"] as int, 1)


func test_apply_haste_increments_reduction() -> void:
	var s: Dictionary = _apply(_s(), "haste")
	assert_eq((s["haste"] as Dictionary)["reduction"] as int, 3)  # deciseconds


func test_apply_weaken_increments_stacks_and_sets_ticks() -> void:
	var s: Dictionary = _apply(_s(), "weaken")
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 1)
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 3)


func test_apply_weaken_twice_stacks_accumulate_ticks_refresh() -> void:
	var s: Dictionary = _apply(_apply(_s(), "weaken"), "weaken")
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 2)
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 3)


func test_apply_effect_potency_scales_quantity() -> void:
	# potency = applying element's Level → that many stacks/points per application.
	var burn: Dictionary = (StatusSystem.apply_effect(_s(), "burn", 3) as Dictionary)["statuses"] as Dictionary
	assert_eq((burn["burn"] as Dictionary)["stacks"] as int, 3)
	var armor: Dictionary = (StatusSystem.apply_effect(_s(), "armor", 2) as Dictionary)["statuses"] as Dictionary
	assert_eq((armor["armor"] as Dictionary)["value"] as int, 2)


func test_apply_effect_potency_defaults_to_one() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


func test_apply_curse_adds_a_stack() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 1)


func test_apply_curse_stacks_accumulate() -> void:
	var s: Dictionary = _apply(_apply(_s(), "curse"), "curse")
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 2)


# ── apply_effect — per-source attribution ledger (Contribution Bars) ──────────
# A DOT status pool is shared across appliers, but each application records the
# stacks it added under its source slot in `by_source`, so tick damage can later
# be split back to the element that laid each stack.

func test_apply_burn_records_stacks_under_source_slot() -> void:
	var r: Dictionary = StatusSystem.apply_effect(_s(), "burn", 2, 3)  # potency 2, source slot 3
	var burn: Dictionary = (r["statuses"] as Dictionary)["burn"] as Dictionary
	assert_eq(burn["stacks"] as int, 2, "aggregate stacks unchanged by attribution")
	assert_eq((burn["by_source"] as Dictionary)[3] as int, 2, "source slot 3 credited its 2 stacks")


# ── apply_effect — instant effects ───────────────────────────────────────────

func test_apply_heal_hp_delta_is_1() -> void:
	var r: Dictionary = StatusSystem.apply_effect(_s(), "heal")
	assert_eq(r["hp_delta"] as int, 1)


func test_apply_heal_statuses_unchanged() -> void:
	var r: Dictionary = StatusSystem.apply_effect(_s(), "heal")
	assert_eq(((r["statuses"] as Dictionary)["burn"] as Dictionary)["stacks"] as int, 0)


func test_apply_leech_hp_delta_is_1() -> void:
	var r: Dictionary = StatusSystem.apply_effect(_s(), "leech")
	assert_eq(r["hp_delta"] as int, 1)


func test_apply_cleanse_removes_1_from_burn() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	s = _apply(s, "cleanse")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


func test_apply_cleanse_removes_1_from_each_debuff() -> void:
	var s: Dictionary = _s()
	s = _apply(s, "burn")
	s = _apply(s, "poison")
	s = _apply(s, "shock")
	s = _apply(s, "weaken")
	s = _apply(s, "blind")
	s = _apply(s, "cleanse")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["shock"] as Dictionary)["n"] as int, 0)
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["blind"] as Dictionary)["percent"] as int, 0)


func test_apply_cleanse_floors_at_zero() -> void:
	var s: Dictionary = _apply(_s(), "cleanse")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0)
	assert_eq((s["blind"] as Dictionary)["percent"] as int, 0)


# ── apply_effect — immutability ───────────────────────────────────────────────

func test_apply_effect_does_not_mutate_input() -> void:
	var s: Dictionary = _s()
	StatusSystem.apply_effect(s, "burn")
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0)


# ── slow_pct ──────────────────────────────────────────────────────────────────

func test_slow_pct_zero_is_zero() -> void:
	assert_eq(StatusSystem.slow_pct(0), 0.0)


func test_slow_pct_5_is_25() -> void:
	assert_almost_eq(StatusSystem.slow_pct(5), 25.0, 0.1)


func test_slow_pct_10_is_33() -> void:
	assert_almost_eq(StatusSystem.slow_pct(10), 33.3, 0.1)


func test_slow_pct_never_reaches_50() -> void:
	assert_lt(StatusSystem.slow_pct(1000), 50.0)


# ── stack cap (infinite-build guard) ──────────────────────────────────────────

func test_poison_stacks_are_capped() -> void:
	var s: Dictionary = _s()
	for _i: int in 200:
		s = _apply(s, "poison")
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, StatusSystem.MAX_STACKS)


func test_armor_value_is_capped() -> void:
	var s: Dictionary = _s()
	for _i: int in 200:
		s = _apply(s, "armor")
	assert_eq((s["armor"] as Dictionary)["value"] as int, StatusSystem.MAX_STACKS)


# ── effective_cooldown_deciseconds ────────────────────────────────────────────

func test_effective_cooldown_no_statuses_applies_global_multiplier() -> void:
	# base × the global firing-rate dial, no statuses
	var expected: int = maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(25.0 * TuningData.COMBAT_COOLDOWN_MULTIPLIER)))
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, _s()), expected)


func test_effective_cooldown_floors_at_10_deciseconds() -> void:
	assert_eq(StatusSystem.effective_cooldown_deciseconds(5, _s()), TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS)


func test_effective_cooldown_shock_slows_fire() -> void:
	# shock n=5 → slow_pct 25%, applied on top of the globally-scaled base
	var s: Dictionary = _s()
	for _i: int in 5:
		s = _apply(s, "shock")
	var scaled: float = 25.0 * TuningData.COMBAT_COOLDOWN_MULTIPLIER
	var expected: int = maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(scaled * (1.0 + StatusSystem.slow_pct(5) / 100.0))))
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), expected)


# ── tick ─────────────────────────────────────────────────────────────────────

func test_tick_burn_deals_damage_equal_to_stacks() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	assert_eq(_tick_dmg(s), 1)


func test_tick_burn_with_2_stacks_deals_2() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	assert_eq(_tick_dmg(s), 2)


func test_tick_burn_decrements_stacks() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	s = _tick_s(s)
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


func test_tick_burn_expires_at_zero_and_deals_no_damage() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	s = _tick_s(s)
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 0)
	assert_eq(_tick_dmg(s), 0)


func test_tick_burn_with_curse_deals_bonus() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "curse")
	assert_eq(_tick_dmg(s), 2)  # stacks=1 + curse_bonus=1


# ── tick — per-source attribution (Contribution Bars) ─────────────────────────

func test_tick_burn_attributes_damage_to_source_slots() -> void:
	# slot 0 lays 3 burn stacks, slot 1 lays 1 → tick deals 4, split 3:1 by source.
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "burn", 3, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "burn", 1, 1) as Dictionary)["statuses"] as Dictionary
	var r: Dictionary = StatusSystem.tick(s)
	assert_eq(r["damage"] as int, 4 * TuningData.BURN_DAMAGE_PER_STACK)
	var burn_attr: Dictionary = (r["attribution"] as Dictionary)["burn"] as Dictionary
	assert_eq(burn_attr[0] as int, 3 * TuningData.BURN_DAMAGE_PER_STACK, "slot 0 credited 3 stacks' worth")
	assert_eq(burn_attr[1] as int, 1 * TuningData.BURN_DAMAGE_PER_STACK, "slot 1 credited 1 stack's worth")


func test_tick_burn_decrement_draws_down_largest_source() -> void:
	# by_source {0:3, 1:1}; the per-tick -1 stack comes off the largest source (slot 0).
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "burn", 3, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "burn", 1, 1) as Dictionary)["statuses"] as Dictionary
	s = _tick_s(s)
	var burn: Dictionary = s["burn"] as Dictionary
	assert_eq(burn["stacks"] as int, 3, "aggregate dropped by 1")
	var by_source: Dictionary = burn["by_source"] as Dictionary
	assert_eq(by_source[0] as int, 2, "largest source (slot 0) lost the stack")
	assert_eq(by_source[1] as int, 1, "slot 1 untouched")


func test_tick_poison_attributes_damage_to_source_slots() -> void:
	# poison stacks never decrease, so by_source is stable; split mirrors burn.
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "poison", 1, 2) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "poison", 3, 5) as Dictionary)["statuses"] as Dictionary
	var r: Dictionary = StatusSystem.tick(s)
	assert_eq(r["damage"] as int, 4 * TuningData.POISON_DAMAGE_PER_STACK)
	var attr: Dictionary = (r["attribution"] as Dictionary)["poison"] as Dictionary
	assert_eq(attr[2] as int, 1 * TuningData.POISON_DAMAGE_PER_STACK, "slot 2 credited 1 stack")
	assert_eq(attr[5] as int, 3 * TuningData.POISON_DAMAGE_PER_STACK, "slot 5 credited 3 stacks")


func test_cleanse_draws_down_burn_source_ledger() -> void:
	# cleanse removes a stack from the aggregate; the ledger must follow (largest-first).
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "burn", 3, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "burn", 1, 1) as Dictionary)["statuses"] as Dictionary
	s = _apply(s, "cleanse")
	var burn: Dictionary = s["burn"] as Dictionary
	assert_eq(burn["stacks"] as int, 3, "aggregate cleansed by 1")
	var by_source: Dictionary = burn["by_source"] as Dictionary
	assert_eq(by_source[0] as int, 2, "largest source lost the cleansed stack")
	assert_eq(by_source[1] as int, 1, "slot 1 untouched")


func test_apply_into_full_pool_credits_only_real_added_stacks() -> void:
	# Pool already at MAX_STACKS from slot 0; slot 1 applying more lands nothing,
	# so the ledger stays in sync (sum == aggregate) and slot 1 is credited 0.
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "burn", StatusSystem.MAX_STACKS, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "burn", 5, 1) as Dictionary)["statuses"] as Dictionary
	var burn: Dictionary = s["burn"] as Dictionary
	assert_eq(burn["stacks"] as int, StatusSystem.MAX_STACKS, "aggregate capped")
	var by_source: Dictionary = burn["by_source"] as Dictionary
	assert_eq(by_source[0] as int, StatusSystem.MAX_STACKS, "slot 0 holds the full pool")
	assert_false(by_source.has(1), "slot 1 credited nothing — pool was full")


func test_compute_incoming_damage_attributes_blocked_to_armor_source() -> void:
	# Defender slot 4 laid 5 armor; a 3-damage hit is fully absorbed → slot 4 is
	# credited 3 HP blocked, and its armor ledger depletes by the points spent.
	var def_s: Dictionary = _s()
	def_s = (StatusSystem.apply_effect(def_s, "armor", 5, 4) as Dictionary)["statuses"] as Dictionary
	var r: Dictionary = StatusSystem.compute_incoming_damage(3, _s(), def_s)
	assert_eq(r["damage"] as int, 0, "hit fully absorbed")
	var blocked: Dictionary = r["blocked_by_source"] as Dictionary
	assert_eq(blocked[4] as int, 3 * TuningData.ARMOR_ABSORB_PER_POINT, "slot 4 credited the HP it blocked")
	var armor_after: Dictionary = (r["defender_statuses"] as Dictionary)["armor"] as Dictionary
	assert_eq(armor_after["value"] as int, 2, "armor spent 3 points")
	assert_eq((armor_after["by_source"] as Dictionary)[4] as int, 2, "ledger follows the spend")


func test_tick_armor_absorbing_burn_credits_blocked_to_armor_source() -> void:
	# Armor that soaks burn-tick damage is the defender's Contribution, and its ledger
	# must deplete by the points spent (kept in sync with the aggregate).
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "burn", 2, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "armor", 2, 3) as Dictionary)["statuses"] as Dictionary
	var r: Dictionary = StatusSystem.tick(s)
	# raw_burn = 2, absorbed = min(2, 2/2) = 1
	assert_eq((r["blocked_by_source"] as Dictionary)[3] as int, 1, "armor slot 3 credited 1 blocked")
	var armor: Dictionary = (r["statuses"] as Dictionary)["armor"] as Dictionary
	assert_eq((armor["by_source"] as Dictionary)[3] as int, 1, "armor ledger spent 1 point")


func test_tick_plating_reducing_dot_credits_blocked_to_plating_source() -> void:
	# Steel's plating shaves the DOT tick total; the shaved HP is a Damage Blocked
	# Contribution credited to the plating element.
	var s: Dictionary = _s()
	s = (StatusSystem.apply_effect(s, "poison", 3, 0) as Dictionary)["statuses"] as Dictionary
	s = (StatusSystem.apply_effect(s, "plating", 2, 4) as Dictionary)["statuses"] as Dictionary
	(s["plating"] as Dictionary)["reduces_dot"] = true
	var r: Dictionary = StatusSystem.tick(s)
	# poison dealt 3, plating shaves 2 → blocked 2
	assert_eq((r["blocked_by_source"] as Dictionary)[4] as int, 2, "plating slot 4 credited 2 blocked")


func test_compute_incoming_damage_credits_plating_blocked() -> void:
	# Plating's flat reduction on a direct hit is also Damage Blocked.
	var def_s: Dictionary = _s()
	def_s = (StatusSystem.apply_effect(def_s, "plating", 2, 7) as Dictionary)["statuses"] as Dictionary
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, _s(), def_s)
	assert_eq((r["blocked_by_source"] as Dictionary)[7] as int, 2 * TuningData.PLATING_REDUCTION_PER_POINT,
		"plating slot 7 credited its flat reduction")


func test_tick_burn_with_armor_absorbs_at_half_rate() -> void:
	# burn=2, armor=2 → raw=2, absorbed=min(2,1)=1, hp=1, armor_after=1
	var s: Dictionary = _apply(_apply(_apply(_apply(_s(), "burn"), "burn"), "armor"), "armor")
	var r: Dictionary = StatusSystem.tick(s)
	assert_eq(r["damage"] as int, 1)
	assert_eq(((r["statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 1)


func test_tick_poison_deals_damage_equal_to_stacks() -> void:
	var s: Dictionary = _apply(_apply(_s(), "poison"), "poison")
	assert_eq(_tick_dmg(s), 2)


func test_tick_poison_stacks_do_not_decrease() -> void:
	var s: Dictionary = _apply(_s(), "poison")
	s = _tick_s(s)
	assert_eq((s["poison"] as Dictionary)["stacks"] as int, 1)


func test_tick_poison_permanent_damage_every_tick() -> void:
	var s: Dictionary = _apply(_s(), "poison")
	for _i: int in 5:
		assert_eq(_tick_dmg(s), 1)
		s = _tick_s(s)


func test_tick_poison_with_curse_deals_bonus() -> void:
	var s: Dictionary = _apply(_apply(_s(), "poison"), "curse")
	assert_eq(_tick_dmg(s), 2)


func test_tick_weaken_decrements_ticks() -> void:
	var s: Dictionary = _apply(_s(), "weaken")
	s = _tick_s(s)
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 2)


func test_tick_weaken_stacks_stay_during_tick() -> void:
	var s: Dictionary = _apply(_apply(_s(), "weaken"), "weaken")
	s = _tick_s(s)
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 2)


func test_tick_weaken_expires_after_3_ticks() -> void:
	var s: Dictionary = _apply(_s(), "weaken")
	for _i: int in 3:
		s = _tick_s(s)
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 0)
	assert_eq((s["weaken"] as Dictionary)["stacks"] as int, 1)  # stacks still present


func test_tick_consumes_one_curse_stack_per_dot_tick() -> void:
	# A DOT tick (burn) is a damaging event → amplify + consume one curse charge.
	var s: Dictionary = _apply(_apply(_s(), "curse"), "burn")
	s = _tick_s(s)
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 0)


func test_tick_does_not_consume_curse_without_dot() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	s = _tick_s(s)
	assert_eq((s["curse"] as Dictionary)["stacks"] as int, 1)


func test_tick_emits_poison_tick_event() -> void:
	var s: Dictionary = _apply(_s(), "poison")
	var r: Dictionary = StatusSystem.tick(s)
	assert_true((r["events"] as Array).has("on_poison_tick"))


func test_tick_emits_burn_tick_event() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	var r: Dictionary = StatusSystem.tick(s)
	assert_true((r["events"] as Array).has("on_burn_tick"))


func test_tick_emits_no_events_when_idle() -> void:
	assert_true((StatusSystem.tick(_s())["events"] as Array).is_empty())


func test_tick_no_damage_on_empty_statuses() -> void:
	assert_eq(_tick_dmg(_s()), 0)


func test_tick_does_not_mutate_input() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	StatusSystem.tick(s)
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


# ── curse expansion: permanence + damage amplifier ────────────────────────────

func test_curse_consumed_by_incoming_hit() -> void:
	var def: Dictionary = _apply(_s(), "curse")  # stacks 1, base amplifier
	var r: Dictionary = StatusSystem.compute_incoming_damage(3, _s(), def)
	assert_eq(((r["defender_statuses"] as Dictionary)["curse"] as Dictionary)["stacks"] as int, 0)


func test_curse_damage_amplifier_increases_incoming_while_active() -> void:
	var def: Dictionary = _apply(_s(), "curse")
	(def["curse"] as Dictionary)["damage_amplifier"] = 1
	var r: Dictionary = StatusSystem.compute_incoming_damage(3, _s(), def)
	assert_eq(r["damage"] as int, 4)


func test_curse_damage_amplifier_ignored_when_curse_inactive() -> void:
	var def: Dictionary = _s()
	(def["curse"] as Dictionary)["damage_amplifier"] = 2
	var r: Dictionary = StatusSystem.compute_incoming_damage(3, _s(), def)
	assert_eq(r["damage"] as int, 3)


# ── tick damage bonuses (Blaze / Underrot patterns) ───────────────────────────

func test_burn_tick_damage_bonus_adds_to_each_tick() -> void:
	var s: Dictionary = _apply(_s(), "burn")  # 1 stack
	(s["burn"] as Dictionary)["tick_damage_bonus"] = 1
	assert_eq(_tick_dmg(s), 2)  # 1 stack + 1 bonus


func test_poison_tick_damage_bonus_adds_to_each_tick() -> void:
	var s: Dictionary = _apply(_s(), "poison")  # 1 stack
	(s["poison"] as Dictionary)["tick_damage_bonus"] = 2
	assert_eq(_tick_dmg(s), 3)  # 1 stack + 2 bonus


# ── shock effective_stack_bonus (Plasma pattern) ──────────────────────────────

func test_shock_effective_stack_bonus_increases_slow() -> void:
	# bonus 5 with no real shock → slow computed as if n=5 (25%), on the scaled base
	var s: Dictionary = _s()
	(s["shock"] as Dictionary)["effective_stack_bonus"] = 5
	var scaled: float = 25.0 * TuningData.COMBAT_COOLDOWN_MULTIPLIER
	var expected: int = maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(scaled * (1.0 + StatusSystem.slow_pct(5) / 100.0))))
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), expected)


# ── signed cooldown_modifier_deciseconds (Mud / Lodestone patterns) ───────────

func test_cooldown_modifier_penalty_increases_effective_cooldown() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = 8
	# +8 absolute, on top of the globally-scaled base
	var expected: int = maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(25.0 * TuningData.COMBAT_COOLDOWN_MULTIPLIER + 8.0)))
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), expected)


func test_cooldown_modifier_reduction_decreases_effective_cooldown() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = -5
	var expected: int = maxi(TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS, int(round(25.0 * TuningData.COMBAT_COOLDOWN_MULTIPLIER - 5.0)))
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), expected)


func test_cooldown_modifier_reduction_respects_floor() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = -50
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), TuningData.EFFECTIVE_CD_FLOOR_DECISECONDS)


# ── passive modifiers (steel / mountain / blackice patterns) ──────────────────

func test_weaken_duration_bonus_extends_ticks() -> void:
	var s: Dictionary = _s()
	(s["weaken"] as Dictionary)["duration_bonus"] = 2
	s = _apply(s, "weaken")
	assert_eq((s["weaken"] as Dictionary)["ticks"] as int, 5)  # 3 + 2


func test_plating_reduces_dot_when_flagged() -> void:
	# 2 burn stacks → 2 dot; plating value 1 with reduces_dot → 1 damage.
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	var plating: Dictionary = s["plating"] as Dictionary
	plating["value"] = 1
	plating["reduces_dot"] = true
	assert_eq(_tick_dmg(s), 1)


func test_plating_does_not_reduce_dot_when_unflagged() -> void:
	var s: Dictionary = _apply(_apply(_s(), "burn"), "burn")
	(s["plating"] as Dictionary)["value"] = 1  # reduces_dot stays false
	assert_eq(_tick_dmg(s), 2)


func test_armor_floor_prevents_depletion_below_floor() -> void:
	# armor 3, floor 2, big hit → only 1 absorbable, armor lands on floor.
	var def: Dictionary = _s()
	var armor: Dictionary = def["armor"] as Dictionary
	armor["value"] = 3
	armor["floor"] = 2
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, _s(), def)
	assert_eq(((r["defender_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 2)
	assert_eq(r["damage"] as int, 4)  # 5 - 1 absorbed


# ── compute_incoming_damage ───────────────────────────────────────────────────

func test_compute_no_effects_returns_raw() -> void:
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, _s(), _s())
	assert_eq(r["damage"] as int, 5)


func test_compute_weaken_reduces_raw() -> void:
	var atk: Dictionary = _apply(_apply(_s(), "weaken"), "weaken")
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, atk, _s())
	assert_eq(r["damage"] as int, 3)  # 5 - 2 stacks


func test_compute_weaken_expired_ticks_no_reduction() -> void:
	var atk: Dictionary = _apply(_s(), "weaken")
	for _i: int in 3:
		atk = _tick_s(atk)
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, atk, _s())
	assert_eq(r["damage"] as int, 5)


func test_compute_plating_reduces_all_incoming() -> void:
	var def: Dictionary = _s()
	(def["plating"] as Dictionary)["value"] = 2
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, _s(), def)
	assert_eq(r["damage"] as int, 3)


func test_compute_armor_absorbs_physical() -> void:
	var def: Dictionary = _apply(_apply(_s(), "armor"), "armor")
	# armor=2, raw=3 → absorbed=2, damage=1
	var r: Dictionary = StatusSystem.compute_incoming_damage(3, _s(), def)
	assert_eq(r["damage"] as int, 1)


# ── Status Tray: is_active / active_statuses / describe ───────────────────────

func test_is_active_false_on_empty() -> void:
	assert_false(StatusSystem.is_active("burn", _s()))


func test_is_active_true_after_apply() -> void:
	assert_true(StatusSystem.is_active("burn", _apply(_s(), "burn")))


func test_is_active_weaken_false_after_ticks_expire() -> void:
	# Weaken stacks persist but it stops being active once its ticks run out.
	var s: Dictionary = _apply(_s(), "weaken")
	for _i: int in TuningData.WEAKEN_DURATION_TICKS:
		s = _tick_s(s)
	assert_false(StatusSystem.is_active("weaken", s))


func test_is_active_skips_dead_slow() -> void:
	var s: Dictionary = _apply(_s(), "slow")
	assert_false(StatusSystem.is_active("slow", s))


func test_active_statuses_empty_is_empty() -> void:
	assert_eq(StatusSystem.active_statuses(_s()).size(), 0)


func test_active_statuses_lists_in_registry_order() -> void:
	# armor is registered after burn → burn first.
	var s: Dictionary = _apply(_apply(_s(), "armor"), "burn")
	assert_eq(StatusSystem.active_statuses(s), ["burn", "armor"] as Array[String])


func test_describe_burn_reports_per_tick_and_stacks() -> void:
	var s: Dictionary = _apply(_apply(_apply(_s(), "burn"), "burn"), "burn")
	var per_tick: int = 3 * TuningData.BURN_DAMAGE_PER_STACK
	assert_eq(StatusSystem.describe("burn", s), "Burning: %d damage/tick · 3 stacks left" % per_tick)


func test_describe_haste_reports_seconds() -> void:
	var s: Dictionary = _apply(_s(), "haste")
	var secs: float = float(TuningData.HASTE_REDUCTION_DECISECONDS) / 10.0
	assert_eq(StatusSystem.describe("haste", s), "Hasted: fires %.1fs sooner" % secs)


func test_describe_shock_reports_slow_percent() -> void:
	var s: Dictionary = _s()
	for _i: int in 5:
		s = _apply(s, "shock")
	assert_eq(StatusSystem.describe("shock", s), "Shocked: cooldowns %d%% slower" % int(round(StatusSystem.slow_pct(5))))


func test_describe_weaken_reports_reduction_and_duration() -> void:
	var s: Dictionary = _apply(_s(), "weaken")
	assert_eq(StatusSystem.describe("weaken", s),
		"Weakened: -%d damage per hit · %ds left" % [TuningData.WEAKEN_DAMAGE_REDUCTION_PER_STACK, TuningData.WEAKEN_DURATION_TICKS])


func test_chip_badge_shows_stack_count() -> void:
	var s: Dictionary = _apply(_apply(_apply(_s(), "burn"), "burn"), "burn")
	assert_eq(StatusSystem.chip_badge("burn", s), "3")


func test_chip_badge_empty_when_inactive() -> void:
	assert_eq(StatusSystem.chip_badge("burn", _s()), "")


func test_chip_badge_armor_shows_value() -> void:
	var s: Dictionary = _apply(_apply(_s(), "armor"), "armor")
	assert_eq(StatusSystem.chip_badge("armor", s), "2")


func test_chip_badge_curse_shows_stacks() -> void:
	var s: Dictionary = _apply(_apply(_s(), "curse"), "curse")
	assert_eq(StatusSystem.chip_badge("curse", s), "2")


func test_every_tray_status_has_emoji_and_valence() -> void:
	for name: Variant in EffectRegistry.EFFECTS:
		var entry: Dictionary = EffectRegistry.EFFECTS[name] as Dictionary
		assert_true(entry.has("emoji") and (entry["emoji"] as String) != "", "missing emoji: " + (name as String))
		assert_true((entry["valence"] as String) in ["buff", "debuff"], "bad valence: " + (name as String))


func test_compute_armor_depletes_in_returned_statuses() -> void:
	var def: Dictionary = _apply(_s(), "armor")  # armor=1
	var r: Dictionary = StatusSystem.compute_incoming_damage(5, _s(), def)
	assert_eq(r["damage"] as int, 4)
	assert_eq(((r["defender_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 0)


func test_compute_armor_fully_absorbs_small_hit() -> void:
	var def: Dictionary = _apply(_apply(_apply(_s(), "armor"), "armor"), "armor")  # armor=3
	var r: Dictionary = StatusSystem.compute_incoming_damage(2, _s(), def)
	assert_eq(r["damage"] as int, 0)
	assert_eq(((r["defender_statuses"] as Dictionary)["armor"] as Dictionary)["value"] as int, 1)


func test_compute_floors_at_zero() -> void:
	var atk: Dictionary = _apply(_apply(_apply(_s(), "weaken"), "weaken"), "weaken")
	var r: Dictionary = StatusSystem.compute_incoming_damage(2, atk, _s())
	assert_eq(r["damage"] as int, 0)


func test_compute_does_not_mutate_attacker() -> void:
	var atk: Dictionary = _s()
	StatusSystem.compute_incoming_damage(5, atk, _s())
	assert_eq((atk["armor"] as Dictionary)["value"] as int, 0)
