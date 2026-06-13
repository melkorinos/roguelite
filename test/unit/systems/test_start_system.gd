extends GutTest

# StartSystem (ADR 0016): the round-1 Starting Pick now offers Keystone Augments and
# grants the chosen one via AugmentSystem.


func _state() -> Dictionary:
	return GameState.create()


func _rng(value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = value
	return r


# ── starting_options ──────────────────────────────────────────────────────────

func test_starting_options_returns_offer_count() -> void:
	assert_eq(StartSystem.starting_options().size(), TuningData.KEYSTONE_OFFER_COUNT)


func test_starting_options_are_distinct() -> void:
	var seen: Dictionary = {}
	for opt: Variant in StartSystem.starting_options(TuningData.KEYSTONE_OFFER_COUNT, _rng(3)):
		var id: String = (opt as Dictionary)["id"] as String
		assert_false(seen.has(id), "duplicate option: " + id)
		seen[id] = true


func test_starting_options_include_family_and_status_axes() -> void:
	# Framework B spread guarantee: an offer always carries at least one of each axis.
	var kinds: Dictionary = {}
	for opt: Variant in StartSystem.starting_options(TuningData.KEYSTONE_OFFER_COUNT, _rng(11)):
		kinds[(opt as Dictionary)["axis_kind"] as String] = true
	assert_true(kinds.has("family"), "offer missing a Family-axis Keystone")
	assert_true(kinds.has("status"), "offer missing a Status-axis Keystone")


func test_starting_options_are_keystones() -> void:
	for opt: Variant in StartSystem.starting_options(TuningData.KEYSTONE_OFFER_COUNT, _rng(5)):
		assert_eq((opt as Dictionary)["source_type"] as String, "keystone")


# ── apply_starting_pick ───────────────────────────────────────────────────────

func test_apply_starting_pick_adds_augment_and_marks_done() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "ashen_affinity")
	assert_eq((s["augments"] as Array).size(), 1)
	assert_eq((s["augments"] as Array)[0]["id"] as String, "ashen_affinity")
	assert_true(s["starting_pick_done"] as bool)


func test_apply_starting_pick_materializes_run_state_keystone() -> void:
	# Verdant Vigor is a run_state bonus_hp Keystone → hp_bonus materializes immediately.
	var s := StartSystem.apply_starting_pick(_state(), "verdant_vigor")
	assert_eq(s["hp_bonus"] as int, TuningData.KEYSTONE_BONUS_HP)


func test_apply_starting_pick_is_once_only() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "ashen_affinity")
	var again := StartSystem.apply_starting_pick(s, "plague_pact")
	assert_eq((again["augments"] as Array).size(), 1)


func test_apply_starting_pick_ignores_unknown_id() -> void:
	var s := StartSystem.apply_starting_pick(_state(), "nonexistent")
	assert_false(s["starting_pick_done"] as bool)
	assert_true((s["augments"] as Array).is_empty())


func test_apply_starting_pick_does_not_mutate_input() -> void:
	var st := _state()
	StartSystem.apply_starting_pick(st, "ashen_affinity")
	assert_false(st["starting_pick_done"] as bool)
	assert_true((st["augments"] as Array).is_empty())
