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
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 0)
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


func test_apply_curse_sets_ticks() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 3)


func test_apply_curse_reapply_refreshes_ticks() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	s = _tick_s(s)  # ticks_remaining → 2
	s = _apply(s, "curse")
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 3)


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


# ── effective_cooldown_deciseconds ────────────────────────────────────────────

func test_effective_cooldown_no_statuses_returns_base() -> void:
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, _s()), 25)


func test_effective_cooldown_floors_at_10_deciseconds() -> void:
	assert_eq(StatusSystem.effective_cooldown_deciseconds(5, _s()), 10)


func test_effective_cooldown_shock_slows_fire() -> void:
	# shock n=5 → slow_pct=25% → 25 * 1.25 = 31.25 → round 31
	var s: Dictionary = _s()
	for _i: int in 5:
		s = _apply(s, "shock")
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), 31)


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


func test_tick_curse_decrements_ticks() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	s = _tick_s(s)
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 2)


func test_tick_curse_expires_after_3_ticks() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	for _i: int in 3:
		s = _tick_s(s)
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 0)


func test_tick_no_damage_on_empty_statuses() -> void:
	assert_eq(_tick_dmg(_s()), 0)


func test_tick_does_not_mutate_input() -> void:
	var s: Dictionary = _apply(_s(), "burn")
	StatusSystem.tick(s)
	assert_eq((s["burn"] as Dictionary)["stacks"] as int, 1)


# ── curse expansion: permanence + damage amplifier ────────────────────────────

func test_curse_permanent_does_not_tick_down() -> void:
	var s: Dictionary = _apply(_s(), "curse")
	(s["curse"] as Dictionary)["is_permanent"] = true
	for _i: int in 5:
		s = _tick_s(s)
	assert_eq((s["curse"] as Dictionary)["ticks_remaining"] as int, 3)


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
	# bonus 5 with no real shock → slow computed as if n=5 → 25% → 25 * 1.25 = 31
	var s: Dictionary = _s()
	(s["shock"] as Dictionary)["effective_stack_bonus"] = 5
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), 31)


# ── signed cooldown_modifier_deciseconds (Mud / Lodestone patterns) ───────────

func test_cooldown_modifier_penalty_increases_effective_cooldown() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = 8
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), 33)


func test_cooldown_modifier_reduction_decreases_effective_cooldown() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = -5
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), 20)


func test_cooldown_modifier_reduction_respects_floor() -> void:
	var s: Dictionary = _s()
	s["cooldown_modifier_deciseconds"] = -50
	assert_eq(StatusSystem.effective_cooldown_deciseconds(25, s), 10)


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
