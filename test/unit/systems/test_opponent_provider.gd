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


func test_get_opponent_grid_has_four_slots() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1))
	assert_eq((g["grid"] as Array).size(), 4)


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
	for i: int in 4:
		var a: Variant = (g1["grid"] as Array)[i]
		var b: Variant = (g2["grid"] as Array)[i]
		if a == null:
			assert_null(b)
		else:
			assert_eq((a as Dictionary)["element_id"], (b as Dictionary)["element_id"])


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
