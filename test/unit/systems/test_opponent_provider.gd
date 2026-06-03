extends GutTest


func _ctx(day: int, round_num: int, shop_tier: int) -> Dictionary:
	return {"day": day, "round": round_num, "shop_tier": shop_tier}


# ── return shape ──────────────────────────────────────────────────────────────

func test_get_opponent_returns_player_id_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	assert_true(g.has("player_id"))


func test_get_opponent_returns_grid_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	assert_true(g.has("grid"))


func test_get_opponent_returns_source_key() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	assert_true(g.has("source"))


func test_get_opponent_grid_has_four_slots() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	assert_eq((g["grid"] as Array).size(), 4)


# ── day-seeded source ─────────────────────────────────────────────────────────

func test_get_opponent_source_is_day_seeded() -> void:
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	assert_eq(g["source"], "day_seeded")


func test_get_opponent_grid_elements_respect_shop_tier() -> void:
	# shop_tier=1 → only T1 elements should appear
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 1))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_lte((slot as Dictionary)["tier"] as int, 1)


func test_get_opponent_t2_context_may_include_t2_elements() -> void:
	# With shop_tier=2 the pool includes T2, so at least one T2 can appear.
	# We just verify no element exceeds the tier cap.
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 2))
	for slot: Variant in g["grid"] as Array:
		if slot != null:
			assert_lte((slot as Dictionary)["tier"] as int, 2)


# ── determinism ───────────────────────────────────────────────────────────────

func test_same_context_produces_same_grid() -> void:
	var g1 := OpponentProvider.get_opponent(_ctx(42, 3, 1))
	var g2 := OpponentProvider.get_opponent(_ctx(42, 3, 1))
	for i: int in 4:
		var a: Variant = (g1["grid"] as Array)[i]
		var b: Variant = (g2["grid"] as Array)[i]
		if a == null:
			assert_null(b)
		else:
			assert_eq((a as Dictionary)["element_id"], (b as Dictionary)["element_id"])


func test_different_round_produces_different_grid() -> void:
	var g1 := OpponentProvider.get_opponent(_ctx(1, 1, 2))
	var g2 := OpponentProvider.get_opponent(_ctx(1, 2, 2))
	var ids1: Array[String] = []
	var ids2: Array[String] = []
	for slot: Variant in g1["grid"] as Array:
		if slot != null:
			ids1.append((slot as Dictionary)["element_id"])
	for slot: Variant in g2["grid"] as Array:
		if slot != null:
			ids2.append((slot as Dictionary)["element_id"])
	# Different rounds should produce different grids (may fail ~1/pool_size^4 times)
	assert_ne(ids1, ids2)


# ── fixture fallback ──────────────────────────────────────────────────────────

func test_fallback_to_fixture_when_shop_tier_zero() -> void:
	# shop_tier=0 → empty pool → fixture fallback
	var g := OpponentProvider.get_opponent(_ctx(1, 1, 0))
	assert_eq(g["source"], "fixture")
