extends GutTest

# AugmentSystem (ADR 0016): the universal Augment seam shared by Keystone / Event
# Reward / Trinket. Validates the atom vocabulary + the four scope apply functions.


func _state() -> Dictionary:
	return GameState.create()


func _augment(effects: Array) -> Dictionary:
	return { "id": "test", "name": "Test", "source_type": "keystone", "effects": effects }


# ── validate_atom ─────────────────────────────────────────────────────────────

func test_validate_run_state_atom_ok() -> void:
	assert_eq(AugmentSystem.validate_atom({ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }).size(), 0)


func test_validate_combat_atom_delegates_to_ability_vocabulary() -> void:
	# A combat-scope set_status_field is a real ability atom → no errors.
	var atom: Dictionary = { "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "target": "own" }
	assert_eq(AugmentSystem.validate_atom(atom).size(), 0)


func test_validate_rejects_unknown_scope() -> void:
	assert_gt(AugmentSystem.validate_atom({ "kind": "bonus_hp", "scope": "nowhere", "amount": 1 }).size(), 0)


func test_validate_rejects_unknown_kind() -> void:
	assert_gt(AugmentSystem.validate_atom({ "kind": "bonus_mana", "scope": "run_state", "amount": 1 }).size(), 0)


func test_validate_rejects_missing_required_field() -> void:
	assert_gt(AugmentSystem.validate_atom({ "kind": "bonus_hp", "scope": "run_state" }).size(), 0)


func test_validate_rejects_scope_mismatch() -> void:
	# bonus_hp is a run_state kind; tagging it combat must fail (combat delegates to the
	# ability vocabulary, which has no bonus_hp kind).
	assert_gt(AugmentSystem.validate_atom({ "kind": "bonus_hp", "scope": "combat", "amount": 1 }).size(), 0)


# ── add_augment + materialize_run_state ───────────────────────────────────────

func test_add_augment_materializes_flat_hp() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }]))
	assert_eq(s["hp_bonus"] as int, 30)
	assert_eq((s["augments"] as Array).size(), 1)


func test_add_augment_materializes_percent_and_reroll() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([
		{ "kind": "bonus_hp_percent", "scope": "run_state", "amount": 20 },
		{ "kind": "reroll_discount", "scope": "run_state", "amount": 1 },
	]))
	assert_eq(s["hp_bonus_percent"] as int, 20)
	assert_eq(s["reroll_discount"] as int, 1)


func test_materialize_sums_across_augments() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }]))
	s = AugmentSystem.add_augment(s, _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 10 }]))
	assert_eq(s["hp_bonus"] as int, 40)


func test_materialize_is_idempotent() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }]))
	# Re-running the full recompute must not double-count.
	s = AugmentSystem.materialize_run_state(s)
	assert_eq(s["hp_bonus"] as int, 30)


func test_add_augment_does_not_mutate_input() -> void:
	var st := _state()
	AugmentSystem.add_augment(st, _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }]))
	assert_true((st["augments"] as Array).is_empty())
	assert_eq(st["hp_bonus"] as int, 0)


# ── shop_weights ──────────────────────────────────────────────────────────────

func test_shop_weights_empty_with_no_augments() -> void:
	assert_true(AugmentSystem.shop_weights(_state()).is_empty())


func test_shop_weights_accumulates_family_copies() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([{ "kind": "shop_weight", "scope": "shop_gen", "family": "light", "copies": 2 }]))
	s = AugmentSystem.add_augment(s, _augment([{ "kind": "shop_weight", "scope": "shop_gen", "family": "light", "copies": 1 }]))
	assert_eq(AugmentSystem.shop_weights(s)["light"] as int, 3)


# ── apply_combat_start ────────────────────────────────────────────────────────

func test_combat_start_applies_set_status_field_to_player() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([
		{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "target": "own" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_eq(((s["player_statuses"] as Dictionary)["burn"] as Dictionary)["tick_damage_bonus"] as int, 1)


func test_combat_start_suppress_sets_side_flag() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([
		{ "kind": "suppress", "scope": "combat", "status": "heal", "target": "own" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_true((s["player_statuses"] as Dictionary)["suppress_heal"] as bool)


func test_combat_start_is_noop_without_combat_atoms() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([{ "kind": "bonus_hp", "scope": "run_state", "amount": 30 }]))
	var before: bool = (s["player_statuses"] as Dictionary)["suppress_heal"] as bool
	s = AugmentSystem.apply_combat_start(s)
	assert_eq((s["player_statuses"] as Dictionary)["suppress_heal"] as bool, before)


# ── apply_round_result ────────────────────────────────────────────────────────

func _gold_augment(result: String, amount: int) -> Dictionary:
	return _augment([{ "kind": "bonus_gold_on_result", "scope": "round_result", "result": result, "amount": amount }])


func test_round_result_pays_on_win() -> void:
	var s := AugmentSystem.add_augment(_state(), _gold_augment("win", 5))
	var gold: int = s["gold"] as int
	var out := AugmentSystem.apply_round_result(s, { "is_win": true })
	assert_eq(out["gold"] as int, gold + 5)


func test_round_result_skips_win_atom_on_loss() -> void:
	var s := AugmentSystem.add_augment(_state(), _gold_augment("win", 5))
	var gold: int = s["gold"] as int
	var out := AugmentSystem.apply_round_result(s, { "is_win": false })
	assert_eq(out["gold"] as int, gold)


func test_round_result_any_pays_on_loss() -> void:
	var s := AugmentSystem.add_augment(_state(), _gold_augment("any", 3))
	var gold: int = s["gold"] as int
	var out := AugmentSystem.apply_round_result(s, { "is_win": false })
	assert_eq(out["gold"] as int, gold + 3)


# ── scale_by resolver (combat atoms ride a board count) ───────────────────────

func _state_with_board(pieces: Array) -> Dictionary:
	var s := _state()
	var grid: Array = s["battle_grid"] as Array
	for i: int in mini(pieces.size(), grid.size()):
		grid[i] = pieces[i]
	return s


func test_scaling_combat_atom_scales_by_family_count() -> void:
	# Two Fire pieces → burn tick bonus = per-unit (1) × 2.
	var s := _state_with_board([ElementData.instantiate("fire", 1), ElementData.instantiate("fire", 1)])
	s = AugmentSystem.add_augment(s, _augment([
		{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "scale_by": "family_count:fire", "target": "opponent" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["tick_damage_bonus"] as int, 2)


func test_scaling_combat_atom_scales_by_family_levels() -> void:
	# Earth Lv3 → armor floor = per-unit (1) × 3 levels.
	var s := _state_with_board([ElementData.instantiate("earth", 3)])
	s = AugmentSystem.add_augment(s, _augment([
		{ "kind": "set_status_field", "scope": "combat", "status": "armor", "field": "floor", "value": 1, "scale_by": "family_levels:earth", "target": "own" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_eq(((s["player_statuses"] as Dictionary)["armor"] as Dictionary)["floor"] as int, 3)


func test_scaling_is_zero_without_matching_pieces() -> void:
	var s := _state_with_board([ElementData.instantiate("water", 1)])
	s = AugmentSystem.add_augment(s, _augment([
		{ "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "scale_by": "family_count:fire", "target": "opponent" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_eq(((s["opponent_statuses"] as Dictionary)["burn"] as Dictionary)["tick_damage_bonus"] as int, 0)


func test_set_side_field_combat_atom_applies() -> void:
	var s := AugmentSystem.add_augment(_state(), _augment([
		{ "kind": "set_side_field", "scope": "combat", "field": "outgoing_damage_flat", "amount": -2, "target": "own" },
	]))
	s = AugmentSystem.apply_combat_start(s)
	assert_eq((s["player_statuses"] as Dictionary)["outgoing_damage_flat"] as int, -2)


# ── combat-atom validation ────────────────────────────────────────────────────

func test_validate_accepts_scaling_combat_atom() -> void:
	var atom: Dictionary = { "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "scale_by": "family_count:fire", "target": "opponent" }
	assert_eq(AugmentSystem.validate_atom(atom).size(), 0)


func test_validate_rejects_unknown_scale_by() -> void:
	var atom: Dictionary = { "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "tick_damage_bonus", "value": 1, "scale_by": "moon_phase", "target": "opponent" }
	assert_gt(AugmentSystem.validate_atom(atom).size(), 0)


func test_validate_rejects_unregistered_status_field() -> void:
	var atom: Dictionary = { "kind": "set_status_field", "scope": "combat", "status": "burn", "field": "not_a_field", "value": 1, "target": "opponent" }
	assert_gt(AugmentSystem.validate_atom(atom).size(), 0)


func test_validate_rejects_unknown_side_field() -> void:
	var atom: Dictionary = { "kind": "set_side_field", "scope": "combat", "field": "not_a_side_field", "amount": 1, "target": "own" }
	assert_gt(AugmentSystem.validate_atom(atom).size(), 0)
