extends GutTest


func _ctx(day: int, round_num: int) -> Dictionary:
	return {"day": day, "round": round_num}


# ── return shape ──────────────────────────────────────────────────────────────

func test_get_opponent_returns_player_id_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	assert_true(g.has("player_id"))


func test_get_opponent_returns_grid_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	assert_true(g.has("grid"))


func test_get_opponent_returns_source_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	assert_true(g.has("source"))


func test_get_opponent_grid_scales_with_round() -> void:
	# Opponent board size is round-scaled (ADR 0014 G4 follow-up): small early,
	# growing to match the player's Grid Growth, capped at GRID_HARD_MAX.
	assert_eq((OpponentProvider.get_opponent(_ctx(1, 1))["grid"] as Array).size(), 2)
	assert_eq((OpponentProvider.get_opponent(_ctx(1, 9))["grid"] as Array).size(), 6)
	assert_lte((OpponentProvider.get_opponent(_ctx(1, 30))["grid"] as Array).size(), TuningData.GRID_HARD_MAX)


# ── day-seeded source ─────────────────────────────────────────────────────────

func test_get_opponent_source_is_day_seeded() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	assert_eq(g["source"], "day_seeded")


# ── round-based tier scaling ──────────────────────────────────────────────────

func test_early_round_opponent_is_tier1_only() -> void:
	# Rounds 1-2 → only T1 elements.
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_lte((slot as Dictionary)["tier"] as int, 1)


func test_mid_round_opponent_capped_at_tier2() -> void:
	# Rounds 3-4 → up to T2, never higher.
	var g := OpponentProvider.get_opponent(_ctx(1, 3))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_lte((slot as Dictionary)["tier"] as int, 2)


func test_late_round_opponent_capped_at_tier4() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 9))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_lte((slot as Dictionary)["tier"] as int, 4)


# ── determinism ───────────────────────────────────────────────────────────────

func test_same_context_produces_same_grid() -> void:
	var g1 := OpponentProvider.get_opponent(_ctx(42, 3))
	var g2 := OpponentProvider.get_opponent(_ctx(42, 3))
	assert_eq((g1["grid"] as Array).size(), (g2["grid"] as Array).size())
	for i: int in (g1["grid"] as Array).size():
		var a: Variant = (g1["grid"] as Array)[i]
		var b: Variant = (g2["grid"] as Array)[i]
		if a == null:
			assert_null(b)
		else:
			assert_eq((a as Dictionary)["element_id"], (b as Dictionary)["element_id"])


# ── round-scaled power (G4): level + max-tier bias ────────────────────────────

func test_early_ghost_elements_are_level_one() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_eq((slot as Dictionary)["level"] as int, 1)


func test_late_ghost_elements_level_up_with_round() -> void:
	# Round 9 is past both GHOST_LEVEL_ROUND_BREAKS → Level 3.
	var g := OpponentProvider.get_opponent(_ctx(1, 9))
	var saw_element: bool = false
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			saw_element = true
			assert_eq((slot as Dictionary)["level"] as int, 3)
	assert_true(saw_element)


func test_ghost_fields_its_max_tier() -> void:
	# At round 9 (max tier 4) the top-tier fraction guarantees at least one T4 slot.
	var g := OpponentProvider.get_opponent(_ctx(1, 9))
	var max_tier: int = 0
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			max_tier = maxi(max_tier, (slot as Dictionary)["tier"] as int)
	assert_eq(max_tier, 4)


func test_ghost_has_no_duplicate_elements() -> void:
	var g := OpponentProvider.get_opponent(_ctx(7, 9))
	var seen: Dictionary = {}
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			var id: String = (slot as Dictionary)["element_id"] as String
			assert_false(seen.has(id), "duplicate ghost element: " + id)
			seen[id] = true


func test_different_round_produces_different_grid() -> void:
	var g1 := OpponentProvider.get_opponent(_ctx(1, 3))
	var g2 := OpponentProvider.get_opponent(_ctx(1, 4))
	var ids1: Array[String] = []
	var ids2: Array[String] = []
	for slot: Variant in g1["grid"] as Array:
		if slot != null:
			ids1.append((slot as Dictionary)["element_id"])
	for slot: Variant in g2["grid"] as Array:
		if slot != null:
			ids2.append((slot as Dictionary)["element_id"])
	# Different rounds should produce different grids (may collide ~1/pool^n times).
	assert_ne(ids1, ids2)
